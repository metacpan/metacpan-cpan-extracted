###############################################################################
#
# This file copyright (c) 2009-2011 by Randy J. Ray, all rights reserved
#
# Copying and distribution are permitted under the terms of the Artistic
# License 2.0 (http://www.opensource.org/licenses/artistic-license-2.0.php) or
# the GNU LGPL (http://www.opensource.org/licenses/lgpl-2.1.php).
#
###############################################################################
#
#   Description:    Export environment variables as constant subs
#
#   Functions:      import
#
#   Environment:    Umm, yeah... that's kind of the point of it all...
#
###############################################################################

package Env::Export;

use 5.006001;
use strict;
use warnings;
use vars qw($VERSION);
use subs qw(import);

use Carp qw(croak carp);

$VERSION = '0.22';
$VERSION = eval $VERSION; ## no critic(ProhibitStringyEval)

###############################################################################
#
#   Sub Name:       import
#
#   Description:    Do the actual import work, namespace wrangling, etc.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $class    in      scalar    Class we're called in
#                   @patterns in      list      One or more patterns or
#                                                 keywords used to select %ENV
#                                                 keys to export
#
#   Environment:    Yeah
#
#   Returns:        void
#
###############################################################################
sub import ## no critic(ProhibitExcessComplexity)
{
    my ($class, @patterns) = @_;
    my $me = "${class}::import";

    ## no critic(ProhibitNoStrict)
    ## no critic(ProhibitProlongedStrictureOverride)
    ## no critic(ProhibitNoWarnings)
    no strict 'refs';
    no warnings qw(redefine prototype);

    if (! @patterns)
    {
        return; # Nothing to do if they didn't request anything
    }

    my ($calling_pkg) = caller;
    my $callersym = \%{"${calling_pkg}::"};

    # Values that are tweaked by keywords that may appear in the @patterns
    # stream:
    my $warn     = 1;
    my $link     = 0;
    my $prefix   = q{};
    my $override = 0;
    my $split    = q{};

    # Establish the set of allowable %ENV keys that are eligible for export.
    # This will avoid repeated iterations over %ENV later, and will remove
    # any keys that could not be used to create valid sub names
    my @choices = grep { /^[A-Za-z_]\w*$/ } keys %ENV;
    # This list will accumulate the set of subs to be created, in the form of
    # metadata:
    my @subs = ();

    while (my $pat = shift @patterns)
    {
        # This would be a lot cleaner if I could assume the presence of the
        # "switch" statement. But I'm not ready to limit this code to 5.10+

        # Because ":split" only applies to the very next argument after it,
        # we have to handle it specially. It gets cleared at the end of every
        # iteration of this loop, so if it is here, peel off the next argument
        # then re-assign $pat to the one after that.
        if ($pat eq ':split')
        {
            $split = shift @patterns;
            $pat   = shift @patterns;
        }

        # Do the keywords first, in most cases they just flip flags back and
        # forth
        if ($pat =~ /^:(no)?warn$/) ## no critic(ProhibitCascadingIfElse)
        {
            $warn = $1 ? 0 : 1;
        }
        elsif ($pat =~ /^:(no)?prefix$/)
        {
            $prefix = $1 ? q{} : shift @patterns;
        }
        elsif ($pat =~ /^:(no)?override$/)
        {
            $override = $1 ? 0 : 1;
        }
        elsif ($pat =~ /^:(no)?link$/)
        {
            $link = $1 ? 0 : 1;
        }
        elsif ($pat eq ':all')
        {
            for (@choices)
            {
                push @subs, { key      => $_,
                              warn     => $warn,
                              prefix   => $prefix,
                              override => $override,
                              link     => $link,
                              split    => $split, };
            }
        }
        # Now handle explicit names, shell-style patterns and regexen:
        # Pre-compiled Perl regexen:
        elsif (ref($pat) eq 'Regexp')
        {
            # Add an entry to @subs for each matching key
            for (grep { $_ =~ $pat } @choices)
            {
                push @subs, { key      => $_,
                              warn     => $warn,
                              prefix   => $prefix,
                              override => $override,
                              link     => $link,
                              split    => $split, };
            }
        }
        # Shell style (* => .*, ? => ., ?* => .+):
        elsif ($pat =~ /[*?]/)
        {
            # Change the shell-style globbing patterns to regex equivalents
            $pat =~ s/[?][*]/.+/g;
            $pat =~ s/[*]/.*/g;
            $pat =~ s/[?]/./g;
            $pat = qr/^$pat$/;

            # Add an entry to @subs for each matching key
            for (grep { $_ =~ $pat } @choices)
            {
                push @subs, { key      => $_,
                              warn     => $warn,
                              prefix   => $prefix,
                              override => $override,
                              link     => $link,
                              split    => $split, };
            }
        }
        # Lastly, acceptable strings:
        elsif ($pat =~ /^[A-Za-z_]\w*$/)
        {
            # Just add a single entry to @subs for the string
            push @subs, { key      => $pat,
                          warn     => $warn,
                          prefix   => $prefix,
                          override => $override,
                          link     => $link,
                          split    => $split, };
        }
        # And if we got here it was almost certainly a pattern that would not
        # be a valid Perl subname. Note that this is not suppressed by :nowarn.
        else
        {
            carp "$me: Unrecognized pattern or keyword '$pat', skipped";
        }

        # Since :split is defined to apply to only the next name or pattern,
        # we have to clear it every iteration just to be safe...
        $split = q{};
    }

    foreach (@subs)
    {
        my $subname = "$_->{prefix}$_->{key}";
        my $envkey  = $_->{key};

        if (exists($callersym->{$subname}) &&
            defined(&{$callersym->{$subname}}) &&
            ! $_->{override})
        {
            # We don't overwrite existing subroutines unless they OK'd it
            # with :override
            if ($_->{warn})
            {
                carp "$me: Will not redefine ${calling_pkg}::$subname, " .
                    'skipping';
            }
            next;
        }

        $subname = "${calling_pkg}::$subname";

        # This may look like a great candidate for a lookup-table of code
        # blocks to eval, but I'd actually prefer to avoid that as it would
        # also require multiple substitutions each iteration as well...
        if ($_->{link})
        {
            if ($_->{split})
            {
                my $localsplit = $_->{split};
                *{$subname} = sub () {
                    return split $localsplit, $ENV{$envkey};
                };
            }
            else
            {
                *{$subname} = sub () {
                    return $ENV{$envkey};
                };
            }
        }
        else
        {
            if ($_->{split})
            {
                my @value = split $_->{split}, $ENV{$envkey};
                *{$subname} = sub () {
                    return @value;
                };
            }
            else
            {
                my $value = $ENV{$envkey};
                *{$subname} = sub () {
                    return $value;
                };
            }
        }
    }

    return;
}

1;

__END__

=head1 NAME

Env::Export - Export %ENV values as constant subroutines

=head1 SYNOPSIS

    use Env::Export 'PATH';

    # This will fail at compile time if the $ENV{PATH}
    # environment variable didn't exist:
    print PATH, "\n";

    # regular constant sub, works fully qualified, too!
    package Foo;
    print main::PATH, "\n";

=head1 DESCRIPTION

This module exports the requested environment variables from C<%ENV> as
constants, represented by subroutines that have the same names as the
specified environment variables.

Specification of the environment values to export may be by explicit name,
shell-style glob pattern or by regular expression. Any number of names or
patterns may be passed in.

=head1 SUBROUTINES/METHODS

The only subroutine/method provided by this package is B<import>, which
handles the exporting of the requested environment variables.

=head1 EXPORT

Any environment variable whose name would be a valid Perl identifier (must
match the pattern C<^[A-Za-z_]\w*$>) may be exported this way. No values are
exported by default, all must be explicitly requested. If you request a name
that does not match the above pattern, a warning is issued and the name is
removed from the exports list.

=head1 EXTENDED SYNTAX

The full range of syntax acceptable to the invocation of B<Env::Export>
covers keywords and patterns, not just simple environment variable names.
Some of the keywords act as flags, some only do their part when they appear
in the arguments stream.

=head2 Specifying Names

In addition to recognizing environment variables by name, this module supports
a variety of extended syntax in the form of keywords, regular expressions and
shell-style globbing.

=head3 Regular expressions

Names can be specified by passing a pre-compiled regular expression in the
list of parameters:

    use Env::Export qr/^LC_/;

This would convert all the environment variables that start with the
characters C<LC_> (the locale/language variables used for character sets,
encoding, etc.) to subroutines. You wouldn't have to specify each one
separately, or go back and add to the list if/when you added more such
variables.

All Perl regular-expression syntax is accepted, so if you have both C<PATH>
and C<Path> defined, and happen to want both (but not C<PATHOLOGY>), you could
use the following:

    use Env::Export qr/^path$/i;

At present, regular expressions have to be pre-compiled (objects of the
C<Regexp> class). B<Env::Export> will not attempt to evaluate strings as
regular expressions.

=head3 Globbing

In addition to regular expressions, a simple form of shell-style "globbing"
is supported. The C<?> character can be used to match any single character,
and the C<*> character matches zero or more characters. As these actually
correspond to the regular expression sequences C<.> and C<.*>, what is
actually done is that the pattern is converted to a Perl regular expression
and evaluated against the list of viable C<%ENV> keys. The converted patterns
are also anchored at both ends.

This invocation:

    use Env::Export 'ORACLE*';

is exactly the same as this one:

    use Env::Export qr/^ORACLE.*$/;

=head3 The C<:all> keyword

This is the only one of the keywords that adds symbols to the list of
eventual exported entities. When it is encountered, all of the keys from
C<%ENV> that are valid identifiers (match the previously-specified pattern)
are set for export. Note the keywords in the next section, though, and the
examples shown later, as these can affect what actually gets produced by
referring to C<:all>.

=head2 Keywords and Flags

In addition to the C<:all> keyword, the following are recognized. The first
four act as flags, with the "no" version turning off the behavior and the
shorter version enabling it. The last keyword operates in a different way.

=over 4

=item :[no]warn

Enable or disable warnings sent by B<Env::Export>. By default, warnings are
enabled. If the user tries to redefine an existing subroutine, a warning is
issued. If warnings are disabled, then it will not be. Note that the
warning that signals an invalid export pattern cannot be suppressed by this
keyword. (It can by caught by C<$SIG{__WARN__}>, if you like.)

=item :[no]override

Enable or disable overriding existing functions. By default, overriding is
disabled, and you will see a warning instead that you tried to define a
function that already exists. If C<:override> is set, then the function in
question is replaced and no warning is issued.

Note that Perl itself will issue a mandatory warning if you redefine a
constant subroutine, and this warning cannot be suppressed (not even by the
C<no warnings> pragma). The C<:nowarn> keyword will not prevent it, either. It
can be caught by the B<__WARN__> pseudo-signal handler, if you choose.

=item :[no]prefix [ARG]

By default, the created functions are given the exact same names as the
environment variables they represent. If you prefer, you can specify a
prefix that will be applied to any names generated after the C<:prefix>
keyword is read. This keyword requires a single argument, a string, and
will prepend it to all function names until either a new prefix is given
by a subsequent C<:prefix>, or until C<:noprefix> is read. The C<:noprefix>
keyword clears any current prefix.

The following invocation:

    use Env::Export qw(:prefix ENV_ HOME PAGER :noprefix SHELL);

will result in the creation of C<ENV_HOME>, C<ENV_PAGER> and C<SHELL> as
functions.

=item :[no]link

These keywords control whether the functions created reflect subsequent
changes in the underlying environment. By default, the created functions
use a copy of the value of the given key at creation-time, so that they may
potentially be in-lined as constant subroutines. However, this means that a
change to the environment variable in question (by a third-party library, for
example) will never be reflected in the function. Specifying C<:link> causes
all subsequent functions to read the environment value each time, instead.
This is applied to each function created until C<:nolink> is encountered.

In this example:

    use Env::Export qw(:link PATH :nolink HOME);

The function C<HOME> will never change (as it is highly unlikely to), while
C<PATH> will reflect any changes made to C<$ENV{PATH}> anywhere else in the
running program.

=item :split ARG

Several common environment variables act as lists of values separated by a
common delimiter (usually a colon, C<:>). These include "PATH",
"LD_LIBRARY_PATH", etc. Since users may want to always treat these values as
arrays, to save you the trouble of always splitting the elements out each
time you access the value the C<:split> keyword allows you to specify the
delimiter that should be applied. The function that gets created will then
return an array rather than a single element (although the array may have only
one element, of course). The delimiter may be a constant string or a
pre-compiled regular expression:

    use Env::Export qw(:split : PATH);

or

    # Exports HOME() as an array of pathname elements:
    use Env::Export (':split' => qr{/|\\}, 'HOME');

The C<:split> keyword does B<not> carry over to multiple specifications, and
I<must> appear immediately before the name or pattern it applies to. It does,
however, apply to all names that match a pattern. Thus, the following:

    use Env::Export qw(:split : *PATH*);

will match all environment variables that contain C<PATH> in their name, and
treat them all as arrays with C<:> as the delimiter.

=back

=head1 EXAMPLES

Here are some further examples, with explanations:

=over 4

=item B<use Env::Export qw(:all :prefix a :split : *PATH*);>

Exports all valid C<%ENV> keys as (scalar) functions. Additionally, any
keys that contain C<PATH> in the name are exported a second time with C<a>
prepended to the function name, and return arrays created by splitting the
value of the environment variable on the C<:> character. Thus, you would have
both C<PATH()> that returned the contents of C<$ENV{PATH}>, and C<aPATH()>
that returned the elements of the path after splitting.

=item B<use Env::Export qw(:split : :link PATH);>

Exports C<PATH()> as a scalar function that always reflects the current
value of C<$ENV{PATH}>. Because the C<:split> keyword was not immediately
before "PATH", it was not applied!

=item B<use Env::Export qw(:nowarn :override :link :prefix ENV_ :all);>

Every valid key in C<%ENV> is exported, with each new function name having
a prefix of C<ENV_> ("ENV_HOME", "ENV_PATH", etc.). Additionally, each
function reflects the current value of its underlying environment variable,
no warnings are issued (at least, not by B<Env::Export>), and any existing
functions are overridden by the newly-created ones.

=back

=head1 CAVEATS

While the C<:override> and C<:nooverride> keywords can manipulate the behavior
around redefining existing subroutines, Perl will always issue a warning if
you redefine an existing I<constant> subroutine. This warning cannot be
suppressed by the C<no warnings 'redefine'> pragma.

=head1 DIAGNOSTICS

B<Env::Export> only issues warnings, and should not throw any exceptions.

=head1 SEE ALSO

L<constant|constant>, L<perlvar/"Constant Functions">

=head1 AUTHOR

Randy J. Ray C<< <rjray at blackperl.com> >>

Original idea from a journal posting by Curtis "Ovid" Poe
(C<< <ovid at cpan.org> >>), built on a sample implementation done by
Steffen Mueller, C<< <smueller at cpan.org> >>.

=head1 BUGS

Please report any bugs or feature requests to
C<bug-env-export at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Env-Export>. I will be
notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Env-Export>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Env-Export>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Env-Export>

=item * Search CPAN

L<http://search.cpan.org/dist/Env-Export>

=item * Source code on GitHub

L<https://github.com/rjray/env-export>

=back

=head1 LICENSE AND COPYRIGHT

This file and the code within are copyright (c) 2009-2011 by Randy J. Ray.

Copying and distribution are permitted under the terms of the Artistic
License 2.0 (L<http://www.opensource.org/licenses/artistic-license-2.0.php>) or
the GNU LGPL 2.1 (L<http://www.opensource.org/licenses/lgpl-2.1.php>).

=cut
