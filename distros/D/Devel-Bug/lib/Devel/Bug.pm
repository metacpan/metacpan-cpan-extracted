# Devel::Bug - Transparent inline debugging probe (pure Perl)
#
# Copyright (C) 2026 Kevin Shea
# This library is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.

package Devel::Bug;

our $VERSION = '0.08';

use v5.20;
use utf8;

use strict;
use warnings;

use Term::ANSIColor;
use Carp qw(croak carp);


use constant BUG_OPTIONS => {
    label      => [ ''                         ],
    noterm     => [ '',  qw(n noterminal)      ],
    out        => [ '*', qw(o output)          ],
    delims     => [ '+', qw(d delimiters)      ],
    color      => [ '+'                        ],
    infocolor  => [ '',  qw(ic)                ],
    labelcolor => [ '',  qw(lc)                ],
    valcolor   => [ '',  qw(vc valuecolor)     ],
    multiline  => [ '',  qw(m ml)              ],
    indices    => [ '',  qw(i @ index indexes) ],
    keyval     => [ '',  qw(k kv %)            ],
    package    => [ '',  qw(p pkg)             ],
    filename   => [ '',  qw(f fn)              ],
    lineno     => [ '',  qw(l ln line)         ],
    val        => [ '*', qw(v value override)  ],
    pp         => [ ''                         ],
};

use constant USE_OPTIONS => {
    %{ +BUG_OPTIONS },
    bug => [ '' ],
};

use constant OPTION_ALIASES => do {
    my (%h, $opt, $spec);
    @h{ @{$spec}[1..$#$spec] }= ( $opt ) x $#$spec while ($opt, $spec)= each %{ +USE_OPTIONS };
    \%h;
};

use constant CALLER_INFO => qw(package filename lineno);


# Terminal detection helpers. (Extracated from DESTROY to facilitate testing.)
sub _isTerm    { -t $_[0] }
sub _sttyWidth { (qx(stty size 2>/dev/null)=~/^\d+\s+(\d+)/)[0] || 0 }

sub _tspWidth {
    my $w= eval { require Term::Size::Perl; (Term::Size::Perl::chars($_[0]))[0] };
    $@ and carp qq(Unable to load Term::Size::Perl: specify option 'noterm => 1' to suppress this warning);
    $w || 0;
}

# Takes an ARRAY REF and returns a list of ARRAY refs of pairs of elements from it.
sub _pairs { my $a= $_[0]; map [ $a->[ $_<<1 ], $a->[ ($_<<1) + 1 ] ], 0..$#$a>>1 }


# Validate options according to provided definitions.
sub validate {
    my $optDefs= shift;

    # Get label and option flags, if present.
    my $label= @_ & 1? shift : '';
    ($label, my $flags)= split /:/, defined($label) && $label, 2;

    unshift @_,
        label => defined($label) && $label,
        map { $_ => 1 } split //, defined($flags) && $flags;

    # Get key/value options.
    my @options;

    foreach (_pairs \@_) {
        my $opt= lc $_->[0];    # option names are case insensitive
        local $_= $_->[1];

        # Convert an alias option name to its primary name.
        $opt= OPTION_ALIASES->{$opt} if exists OPTION_ALIASES->{$opt};

        # Confirm option name actually exists.
        exists $optDefs->{$opt} or croak qq(Unknown option '$opt');

        # Confirm and process option values and their types.
        my $type= $optDefs->{$opt}[0];

        $type eq '+'
        ?   (defined and $_= m{^(?:on|1)$}i? 1 : m{^(?:auto|)$}i? '' : m{^off$}i? undef : croak qq(Illegal option value: $opt => '$_'))
        :   ($type eq '*' or $optDefs->{$opt}[0] eq ref or croak qq(Option '$opt' may not be type '@{[ ref || '(SCALAR)' ]}'));

        push @options, $opt => $_;
    }

    @options;
}


my %OPTIONS;

sub import {
    shift;

    %OPTIONS= (
        validate(USE_OPTIONS, out => *STDERR, delims => 'auto', color => 'auto', lc => 'bold', vc => 'red on_grey23'),     # defaults
        validate(USE_OPTIONS, @_)
    );

    # Default name under which to export bug().
    my $bug= 'bug';

    # Caller may export bug() under a different name or suppress export.
    if (exists $OPTIONS{bug}) {
        # Don't export anything if explicity set to falsy.
        $bug= $OPTIONS{bug} or return;

        # Export bug() under a different name.
        $bug=~/^ (?: [a-z]\w* | _\w+ ) $/ix or croak qq(Illegal characters in 'bug' replacement subroutine name '$bug');
        delete $OPTIONS{bug};
    }

    # Export bug().
    no strict 'refs';
    *{ (caller).'::'.$bug }= \&bug;
}


# Debugging utility class.
#   Allows for inlining a temporary "bug" sub which will output intermediate expression data.
#   Ex:     my $infoPN= $CV_INFO_DIR."/".(bug('relpath')= substr($_, length($sourceDir) + 1));
#   Output: relpath=(...)

# To preserve list context, use form: (bug 'list')= ( some list );

sub bug :lvalue {
    # Create object and populate it with options from import and bug().
    my $self= bless { %OPTIONS, validate BUG_OPTIONS, @_ }, __PACKAGE__;

    # Get extra info to include with output.
    my %info;

    @info{ (CALLER_INFO) }= caller;
    $info{lineno}= "line $info{lineno}";

    $self->{info}= join(' ', map $info{$_}, grep $self->{$_}, CALLER_INFO);

    # Tie an array or scalar, for list or scalar context respectively.
    # Implicit return (no return keyword) avoids "Bizarre copy of ARRAY in return".
    if (wantarray) { $self->{data}= [];          tie my @a, __PACKAGE__, $self; @a }
    else           { $self->{data}= \my $scalar; tie my $s, __PACKAGE__, $self; $s }
}

# Just pass along self object constructed in bug(), which invokes these via tie().
sub TIESCALAR { $_[1] }
sub TIEARRAY  { $_[1] }

# Methods for tied array.
sub CLEAR     {    $_[0]->{data}= [] }
sub FETCHSIZE { @{ $_[0]->{data} }   }

# Shared methods:              SCALAR                           ARRAY
sub FETCH     { @_ == 1?  ${ $_[0]->{data} }         :  $_[0]->{data}[ $_[1] ]         }
sub STORE     { @_ == 2? (${ $_[0]->{data} }= $_[1]) : ($_[0]->{data}[ $_[1] ]= $_[2]) }

# Format and output captured values upon destruction of temporary tied variable.
sub DESTROY {
    my $self= $_[0];
    my $override= exists $self->{val};

    my ($data, $delims, $color, $multiline, $indices, $keyval, $ic, $lc, $vc)=
        @{$self}{ qw(data delims color multiline indices keyval infocolor labelcolor valcolor) };

    my $isScalar= ref($data) eq 'SCALAR';

    $indices||= '';

    # Get terminal width if requested and available.
    my $termW= (not $self->{noterm} and _isTerm($self->{out}))? _sttyWidth() || _tspWidth($self->{out}) : 0;

    # Get the pretty printer sub.
    my $ppSub;

    if (defined $self->{pp}) {
        eval {
            # Caller specified sub in Module::sub form.
            my $pp= $self->{pp};
            my ($ppPN)= $pp=~/^(.+)::.+$/i or die qq(Invalid pretty-printer '$pp' specified: expected 'Module::sub' form);

            $ppPN=~s{::}{/}g;  # get module path with slashes for require

            # Load the module.
            eval { require "$ppPN.pm" } or die $@;

            # Confirm sub callable and save ref to it.
            no strict 'refs';
            defined &$pp or die qq(Invalid pretty-printer '$pp');
            $ppSub= \&$pp;
        } or carp $@;
    }

    # If no pretty printer specified or loading it didn't work, try the default.
    $ppSub||= do { no warnings 'once'; require Data::Dumper; $Data::Dumper::Indent= 1; \&Data::Dumper::Dumper };

    # Make a string representation of the data.
    my $toString= sub {
        my $color= $_[0];   # color the text with ANSI colors?
        my $ml=    $_[1] || $multiline || $indices? "\n" : '';  # multiline?

        my $label= $self->{label};
        my $info=  $self->{info};

        local $_;

        # Return a string representation of the value, coloring if needed.
        my $cv= sub {
            my $txt= ref $_[0]? $ppSub->($_[0]) : defined $_[0]? $_[0] : 'UNDEF';
            ($color and $vc)? colored($txt, $vc) : $txt;
        };

        # Make a string representation of the data.
        my $i= 0;

        my $vals=
            $ml.(
            join $ml || ' ',
                map { $ml? "  $_" : $_ }    # multiline?
                      $override? ( $cv->($self->{val}) )                                                    # vals => ... override used
                    : $isScalar? ( $cv->($$data) )                                                          # single scalar
                    : $keyval?   ( map { ($indices && $i++.': ').$cv->($_->[0]).' => '.$cv->($_->[1]) } _pairs($data) ) # list of key/val pairs
                    :            ( map { ($indices && $i++.': ').$cv->($_) } @$data )                       # list
            ).$ml;

        # Format info, label and vals, coloring if needed.
        $info=  ($color and $ic)? colored($info, $ic).': ' : "$info: " if length $info;
        $label= ($color and $lc)? colored($label, $lc).'=' : "$label=" if length $label;
        $vals=  '('.$vals.')' if $delims or defined($delims) and ($ml or not $color or length($vals) == 0);

        $info.$label.$vals;
    };

    # Call toString once for possible sizing, then again if necessary for coloring and/or wrapping.
    my $str;

    $str= $toString->($color and not $termW);
    $str= $toString->(defined($color), $termW < length $str) if $termW;

    # Ouput the string.
    print { $self->{out} } $str."\n";
}


# Catch if user code attempts to use this like a regular object.
sub AUTOLOAD {
    our $AUTOLOAD;
    croak qq(Attempt to call unneeded non-existent subroutine '$AUTOLOAD': class @{[ __PACKAGE__ ]} intended for inline logging only);
}

# If these get called, they need to be no-ops, since we're only using the tied array for logging.
sub EXTEND    { }
sub STORESIZE { }



1;

__END__

=encoding UTF-8

=head1 NAME

Devel::Bug - Transparent inline debugging probe (pure Perl)

=head1 SYNOPSIS

    use Devel::Bug;                           # output to STDERR
    use Devel::Bug out => *STDOUT;            # redirect output
    use Devel::Bug ':pfl';                    # package + filename + lineno by default
    use Devel::Bug ':pfl', out => *STDOUT;    # label:flags with options
    use Devel::Bug bug => 'dbg';              # export under a different name

    # Scalar: value passes through; appears on STDERR (no label)
    my $result = bug = substr($str, $offset);
    # OUTPUT: (value)

    # Inline in any expression
    my $path = $dir . '/' . (bug('label') = substr($str, $offset));
    # OUTPUT: label=(images/logo.png)

    # List: parens around bug() are required to force list-context assignment
    my @items = (bug 'items') = get_items();
    # OUTPUT: items=(foo bar baz)

    # Flags in the label string
    my @items = (bug 'items:@')  = get_items();   # N: index prefixes
    my %hash  = (bug 'data:%')   = get_pairs();   # key => value format
    my %hash  = (bug 'data:@%')  = get_pairs();   # both
    my @items = (bug 'items:m')  = get_items();   # multiline

    # Per-call options
    my $x = (bug 'result', vc => 'green') = compute();

=head1 DESCRIPTION

C<Devel::Bug> exports C<bug()>, named for the wiretap sense of the word:
plant it inline inside any existing assignment to tap into values as they
flow through your code.
The value(s) assigned I<through> C<bug()> will reach the left-hand side unmodified;
the only side effect is output to the configured filehandle.
I<For list assignments>, C<bug()> must be I<wrapped in parentheses> to force list context:
C<(bug ...) = list_expr()>. Without them C<bug>
is called in scalar context and captures only a single value.

Output format:

    label=(value)               # scalar
    label=(v1 v2 v3)            # list
    label=(a => 1 b => 2)       # keyval
    pkg file line: label=(...)  # with caller info enabled

By default, ANSI colors are applied when the output handle is a terminal,
and multiline layout is applied automatically when output would overflow the
terminal width.
Both behaviors are configurable; see C<color>, C<delims>, and C<noterm>.

=head1 IMPORT AND CALL OPTIONS

Options apply in two contexts: as import-time defaults via C<use> or
C<import()>, and as per-call overrides passed directly to C<bug()>.

    use Devel::Bug out => *STDOUT, lineno => 1;       # import-time defaults
    my $x = (bug 'result', vc => 'green') = ...;      # per-call override

Options follow an optional label:flags string as key/value pairs
(see L</LABEL:FLAGS SYNTAX>).
The C<bug> option (export name) is only valid at import time.

=head2 Output

=over 4

=item B<out> (aliases: B<output>, B<o>)

Filehandle to print to.
Accepts anything C<print> accepts as an indirect filehandle:
typeglobs, lexical filehandles, and filehandle objects.
Default: C<*STDERR>.

    use Devel::Bug out => *STDOUT;    # typeglob
    use Devel::Bug out => $fh;        # lexical filehandle or object

=back

=head2 Caller information

When enabled, the corresponding field is prepended to every line of output.

=over 4

=item B<package> (aliases: B<pkg>, B<p>)

Calling package name.

=item B<filename> (aliases: B<fn>, B<f>)

Source filename.

=item B<lineno> (aliases: B<line>, B<ln>, B<l>)

Source line number.

=back

=head2 Display

=over 4

=item B<multiline> (aliases: B<ml>, B<m>)

Print each value on its own indented line.

=item B<indices> (aliases: B<indexes>, B<index>, B<i>, B<@>)

Prefix each list element with C<N:>. Implies multiline.

=item B<keyval> (aliases: B<kv>, B<k>, B<%>)

Treat the list as alternating key/value pairs and format each as
C<< key => value >>.
Combine with C<indices>/C<@> to add C<N:> prefixes;
the index counts pairs, not individual elements. Implies multiline.

=item B<delims> (aliases: B<delimiters>, B<d>)

Controls whether the value is wrapped in parentheses.
Three states:

=over 4

=item C<on> (also C<1>)

Always wrap in parentheses.

=item C<off> (also C<undef>)

Never wrap in parentheses.

=item C<auto> (also C<''>, default)

Wrap when output is not colored; omit when colored
(color already delineates the value visually).

=back

=back

=head2 Colors

=over 4

=item B<color>

Controls when ANSI colors are applied.
Three states:

=over 4

=item C<on> (also C<1>)

Always apply colors, even to non-terminal output.

=item C<off> (also C<undef>)

Never apply colors.

=item C<auto> (also C<''>, default)

Apply colors only when the output handle is a terminal.

=back

=item B<infocolor> (alias: B<ic>)

L<Term::ANSIColor> color specification for the caller-info prefix,
e.g. C<'bold'>, C<'cyan on_black'>. Default: none.

=item B<labelcolor> (alias: B<lc>)

Color specification for the label. Default: C<'bold'>.

=item B<valcolor> (aliases: B<vc>, B<valuecolor>)

Color specification for values. Default: C<'red on_grey23'>.

=back

=head2 Terminal detection

=over 4

=item B<noterm> (aliases: B<noterminal>, B<n>)

Disable terminal width detection.
When set, neither C<stty> nor L<Term::Size::Perl> is consulted, making
both entirely optional.
With C<noterm> enabled, terminal-width-based multiline layout is suppressed,
and C<color =E<gt> 'auto'> behaves as if the output is not a terminal.

A warning is issued if terminal detection is attempted, C<stty size> fails,
and L<Term::Size::Perl> cannot be loaded.
Set C<noterm> to suppress both the detection and the warning.

=back

=head2 Pretty-printer

=over 4

=item B<pp>

Fully-qualified name of the function used to format reference values,
in the form C<'Module::Name::function'>.
The function is called with the reference as its first argument and
must return a string.
The module is loaded automatically on first use.
If the specified module cannot be loaded or the named sub does not exist,
a warning is issued and the default is used instead.

Default: C<'Data::Dumper::Dumper'>.

    use Devel::Bug pp => 'Data::Dump::pp';          # import-time default
    my $x = (bug 'data', pp => 'Data::Dump::pp') = get_data();  # per-call

=back

=head2 Alternative display value

=over 4

=item B<val> (aliases: B<value>, B<v>, B<override>)

Display a different value in the output than the one being assigned.
The actual assigned value still passes through unchanged.

Use this when the assigned value is opaque or uninteresting, but a
related value at the same point in the code is more informative.
Particularly useful in ternary expressions, where the probe fires only
when that branch is taken.

    # Without bug(): a do {} block is needed to log and still return a value
    my $installed =
        $sub =~ /^(.+)::/
        ?   do {
                print "package=($1)\n";
                *{ $caller . '::' . $name }= \&{ $sub }
            }
        :   carp "Cannot determine package from '$sub'";

    # With bug(): val => $1 is displayed; the glob assignment passes through
    my $installed =
        $sub =~ /^(.+)::/
        ?   bug('package', val => $1)=
                *{ $caller . '::' . $name }= \&{ $sub }
        :   carp "Cannot determine package from '$sub'";

=back

=head2 Export name

=over 4

=item B<bug>

Rename or suppress the exported function.

    use Devel::Bug bug => 'tap';   # exports as tap()
    use Devel::Bug bug => '';      # suppresses export  ('', 0, undef all work)

The name must be a valid Perl identifier (C</^[a-z]\w*$/i> or C</^_\w+$/>).
This option is only valid at import time; it may not be passed to C<bug()>.

=back

=head1 LABEL:FLAGS SYNTAX

A label:flags string may optionally appear as the I<first> argument to C<bug()> or C<use> (C<import()>).

The string has the form C<label:flags>, where both parts are optional.
A leading colon means an empty label; the characters after the colon
each enable a boolean option by its single-char alias.

    use Devel::Bug ':pfl';            # empty label, flags p, f, l
    use Devel::Bug 'app:pf';          # label 'app', flags p, f
    use Devel::Bug 'app';             # label 'app', no flags

    my @r = (bug 'data:@%') = ...;   # label 'data', flags @ and %
    my @r = (bug ':m')      = ...;   # empty label, flag m

Flag characters:

    @   i   indices      %   k   keyval       m   multiline
    p       package      f       filename     l   lineno
    d       delims       n       noterm

=head1 CHAINING

Bug probes can be placed at different points in a pipeline to capture
each intermediate value independently.

    my @data = (1, 2, 3, 4, 5, 6);
    my @doubled =
        (bug 'doubled')=      # parens make this a list assignment; bug() passes the whole list through
        map  { $_ * 2 }
        (bug 'evens')=        # parens force list context; without them bug() captures only one value
        grep { $_ % 2 == 0 } @data;

    # OUTPUT:
    # doubled=(4 8 12)
    # evens=(2 4 6)

C<'evens'> captures the elements that passed the grep; C<'doubled'> captures
those elements after multiplication.
Output fires left-to-right as Perl frees temporaries at end-of-statement,
which is the reverse of data flow - hence C<'doubled'> prints before C<'evens'>.

=head1 DEPENDENCIES

L<Term::ANSIColor>, L<Data::Dumper>.

Terminal width detection first tries C<stty size>. L<Term::Size::Perl> is
loaded on demand only if C<stty> is unavailable or returns no output, and
is never consulted when C<noterm> is set.

L<Data::Dump> and other pretty-printer modules are optional;
see the C<pp> option.

=head1 AUTHOR

Kevin Shea

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

