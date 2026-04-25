package Loo;

use 5.008003;
use strict;
use warnings;

our $VERSION = '0.12';

use Exporter 'import';
our @EXPORT_OK = qw(Dump cDump ncDump dDump);

our $USE_COLOUR;

require XSLoader;
XSLoader::load('Loo', $VERSION);

sub include_dir {
    my $dir = $INC{'Loo.pm'};
    $dir =~ s{Loo\.pm$}{Loo/include};
    return $dir;
}

1;

__END__

=head1 NAME

Loo - Pure XS data introspector and code deparser with customisable colour output

=head1 SYNOPSIS

    use Loo qw(Dump cDump ncDump dDump);

    # Functional - colour auto-detected
    print Dump({ name => 'Perl', version => 5.40 });

    # Always colour
    print cDump([1, 2, 3]);

    # Never colour
    print ncDump(\%ENV);

    # Deparse a code reference
    print dDump(sub { my ($x) = @_; return $x * 2 });

    # OO interface
    my $loo = Loo->new([{ key => 'value' }], ['data']);
    $loo->Indent(1)->Sortkeys(1)->Theme('monokai');
    print $loo->Dump;

    # Custom indentation: 4 spaces
    my $loo = Loo->new([{ key => 'value' }]);
    $loo->Indentwidth(4);
    print $loo->Dump;

    # Use tabs instead of spaces
    my $loo = Loo->new([{ key => 'value' }]);
    $loo->Usetabs(1)->Indentwidth(1);
    print $loo->Dump;

    # Deparse via OO
    my $loo = Loo->new([\&Some::function]);
    $loo->Deparse(1);
    print $loo->Dump;

=head1 DESCRIPTION

Loo is a pure XS Perl data introspector and code deparser with built-in
ANSI colour support. It provides a L<Data::Dumper>-compatible interface
for serialising Perl data structures, and can also deparse code references
back to Perl source by walking the op tree directly in C.

Colour output is auto-detected based on C<$ENV{NO_COLOR}>, terminal
capability (C<-t STDOUT>), and C<$ENV{TERM}>, but can be forced on or
off via the functional shortcuts or OO methods.

=head1 EXPORTS

The following functions are available for import:

=over 4

=item Dump(@values)

Dump values with colour auto-detected.

=item cDump(@values)

Dump values with colour always enabled.

=item ncDump(@values)

Dump values with colour always disabled (plain text).

=item dDump(@values)

Dump values with deparse mode enabled. Code references are deparsed
back to Perl source; other values are dumped normally.

=back

=head1 METHODS

=head2 new(\@values, \@names)

    my $loo = Loo->new(\@values);
    my $loo = Loo->new(\@values, \@names);

Create a new Loo object.  C<\@values> is an array reference of the
values to dump.  C<\@names> is an optional array reference of variable
names (without sigils) to use in the output instead of the default
C<$VAR1>, C<$VAR2>, etc.

=head2 Dump

    my $output = $loo->Dump;

Produce the dump string.

=head2 Colour(\%spec)

    $loo->Colour({
        string_fg  => 'green',
        key_fg     => 'magenta',
        number_bg  => 'bright_black',
    });

Set colour configuration.  Keys are colour element names with a C<_fg>
or C<_bg> suffix.  The recognised element names are:

    string    number    key       brace     bracket   paren
    arrow     comma     undef     blessed   regex     code
    variable  quote     keyword   operator  comment

Valid colour values are standard ANSI names: C<black>, C<red>, C<green>,
C<yellow>, C<blue>, C<magenta>, C<cyan>, C<white>, and their C<bright_>
variants (e.g. C<bright_red>).

Returns C<$self> for chaining.

=head2 Theme($name)

    $loo->Theme('monokai');

Apply a built-in colour theme.  Available themes:

=over 4

=item C<default> - standard colour scheme

=item C<light> - optimised for light terminal backgrounds

=item C<monokai> - Monokai-inspired palette

=item C<none> - disables all colour element settings

=back

Returns C<$self> for chaining.

=head2 Data::Dumper-compatible accessors

The following methods mirror the L<Data::Dumper> interface.  Each accepts
an optional value (and returns C<$self> for chaining) or no arguments
(and returns the current value).

=over 4

=item Indent($n)

Indentation style (0-3).  Default: C<2>.

=item Indentwidth($n)

Number of characters per indentation level.  Default: C<2>.  For example,
set to C<4> for four-space indentation:

    $loo->Indentwidth(4);

=item Usetabs($bool)

When true, use tab characters for indentation instead of spaces.
Default: C<0> (spaces).

    $loo->Usetabs(1);

When combined with C<Indentwidth>, the width controls how many tab
characters are emitted per level (typically you want C<Indentwidth(1)>
with C<Usetabs(1)> for one tab per level):

    $loo->Usetabs(1)->Indentwidth(1);

=item Pad($string)

Prefix string added to every line of output.  Default: C<"">.

=item Varname($prefix)

Variable name prefix.  Default: C<"VAR">.

=item Terse($bool)

When true, omit the C<$VARn = > prefix.  Default: C<0>.

=item Purity($bool)

When true, emit extra statements to recreate circular references and
tied values.  Default: C<0>.

=item Useqq($bool)

When true, use double-quoted strings (with escape sequences) instead
of single-quoted.  Default: C<0>.

=item Quotekeys($bool)

When true, always quote hash keys.  Default: C<1>.

=item Sortkeys($value)

When set to a true value, sort hash keys alphabetically.  When set to
a code reference, use that subroutine to sort keys (it receives a hash
reference and should return an array reference of keys).  Default: C<0>.

=item Maxdepth($n)

Maximum depth to traverse.  C<0> means unlimited.  Default: C<0>.

=item Maxrecurse($n)

Maximum recursion depth before croaking.  Default: C<1000>.

=item Pair($string)

String used between hash keys and values.  Default: C<" =E<gt> ">.

=item Trailingcomma($bool)

When true, add a trailing comma after the last element in hashes and
arrays.  Default: C<0>.

=item Deepcopy($bool)

When true, perform a deep copy of the structure.  Default: C<0>.

=item Freezer($method)

Name of a method to call on objects before dumping.  Default: C<"">.

=item Toaster($method)

Name of a method to call in the dump output to recreate objects.
Default: C<"">.

=item Bless($function)

Function name used for blessing in the output.  Default: C<"bless">.

=item Deparse($bool)

When true, deparse code references back to Perl source.  Default: C<0>.

=item Sparseseen($bool)

When true, only populate the "Seen" hash for repeated references.
Default: C<0>.

=back

=head1 UTILITY FUNCTIONS

=head2 Loo::strip_colour($string)

    my $plain = Loo::strip_colour($coloured_output);

Remove all ANSI escape sequences from a string.  Useful when you want to
post-process coloured output into plain text.

=head1 COLOUR AUTO-DETECTION

When using C<Dump()> or the OO interface without explicitly setting
colour, Loo auto-detects whether to enable ANSI colour output:

=over 4

=item * Colour is B<disabled> if C<$ENV{NO_COLOR}> is set (see L<https://no-color.org/>).

=item * Colour is B<disabled> if C<STDOUT> is not a terminal (C<-t STDOUT>).

=item * Colour is B<disabled> if C<$ENV{TERM}> is C<"dumb">.

=item * Otherwise colour is B<enabled>.

=back

Use C<cDump()> or C<ncDump()> to bypass auto-detection.

=head1 SEE ALSO

L<Data::Dumper>, L<B::Deparse>

=head1 AUTHOR

LNATION E<lt>email@lnation.orgE<gt>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
