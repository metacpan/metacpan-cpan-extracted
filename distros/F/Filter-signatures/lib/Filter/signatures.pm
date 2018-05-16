package Filter::signatures;
use strict;
use Filter::Simple;

use vars '$VERSION';
$VERSION = '0.13';

=head1 NAME

Filter::signatures - very simplistic signatures for Perl < 5.20

=head1 SYNOPSIS

    use Filter::signatures;
    no warnings 'experimental::signatures'; # does not raise an error
    use feature 'signatures'; # this now works on <5.20 as well

    sub hello( $name ) {
        print "Hello $name\n";
    }

    hello("World");

    sub hello2( $name="world" ) {
        print "Hello $name\n";
    }
    hello2(); # Hello world

=head1 DESCRIPTION

This module implements a backwards compatibility shim for formal Perl subroutine
signatures that were introduced to the Perl core with Perl 5.20.

=head1 CAVEATS

The technique used is a very simplistic transform to allow for using very
simplistic named formal arguments in subroutine declarations. This module
does not implement warning if more or fewer parameters than expected are
passed in.

The module also implements default values for unnamed parameters by
splitting the formal parameters on C<< /,/ >> and assigning the values
if C<< @_ >> contains fewer elements than expected. Function calls
as default values may work by accident. Commas within default values happen
to work due to the design of L<Filter::Simple>, which removes them for
the application of this filter.

Note that this module inherits all the bugs of L<Filter::Simple> and potentially
adds some of its own. Most notable is that Filter::Simple sometimes will
misinterpret the division operator C<< / >> as a leading character to starting
a regex match:

    my $wait_time = $needed / $supply;

This will manifest itself through syntax errors appearing where everything
seems in order. The hotfix is to add a comment to the code that "closes"
the misinterpreted regular expression:

    my $wait_time = $needed / $supply; # / for Filter::Simple

A better hotfix is to upgrade to Perl 5.20 or higher and use the native
signatures support there. No other code change is needed, as this module will
disable its functionality when it is run on a Perl supporting signatures.

=head2 Parentheses in default assignments

Ancient versions of Perl before version 5.10 do not have recursive regular
expressions. These will not be able to properly handle statements such
as

    sub foo ($timestamp = time()) {
    }

The hotfix is to rewrite these function signatures to not use parentheses. The
better approach is to upgrade to Perl 5.20 or higher.

=head2 Line Numbers

Due to a peculiarity of how Filter::Simple treats here documents in some
versions, line numbers may get out of sync if you use here documents.

If you spread your formal signatures across multiple lines, the line numbers
may also go out of sync with the original document.

=head2 C<< eval >>

L<Filter::Simple> does not trigger when using
code such as

  eval <<'PERL';
      use Filter::signatures;
      use feature 'signatures';

      sub foo (...) {
      }
  PERL

So, creating subroutines with signatures from strings won't work with
this module. The workaround is to upgrade to Perl 5.20 or higher.

=head2 Deparsing

The generated code does not deparse identically to the code generated on a
Perl with native support for signatures.

=head1 ENVIRONMENT

If you want to force the use of this module even under versions of
Perl that have native support for signatures, set
C<< $ENV{FORCE_FILTER_SIGNATURES} >> to a true value before the module is
imported.

=cut

my $have_signatures = eval {
    require feature;
    feature->import('signatures');
    1
};

sub kill_comment {
    my( $str ) = @_;
    my @strings = ($str =~ /$Filter::Simple::placeholder/g);
    for my $ph (@strings) {
        my $index = unpack('N',$ph);
        if( ref $Filter::Simple::components[$index] and ${ $Filter::Simple::components[$index] } =~ /^#/ ) {
            #warn ">> $str contains comment ${$Filter::Simple::components[$index]}";
            $str =~ s!\Q$;$ph$;\E!!g;
        };
    }
    $str
}

sub parse_argument_list {
    my( $name, $arglist, $whitespace ) = @_;
    (my $args=$arglist) =~ s!^\(\s*(.*)\s*\)!$1!s;
    my @args = map { kill_comment($_) } map { s!^\s*!!; s!\s*$!!; $_}
        $args =~ m!((?:[^,$;]+|\Q$;\E.{4}\Q$;\E)+)!sg; # a most simple argument parser
    my $res;
    # Adjust how man newlines we gobble
    $whitespace ||= '';
    #warn "[[$whitespace$args]]";
    my $padding = () = (($whitespace . $args) =~ /\n/smg);
    if( @args ) {
        my @defaults;
        for( 0..$#args ) {
            # Keep everything on one line
            $args[$_] =~ s/\n/ /g;

            # Named argument with default
            if( $args[$_] =~ /^\s*([\$\%\@]\s*\w+)\s*=/ ) {
                my $named = "$1";
                push @defaults, "$args[$_] if \@_ <= $_;";
                $args[$_] = $named;

            # Named argument
            } elsif( $args[$_] =~ /^\s*([\$\%\@]\s*\w+)\s*$/ ) {
                my $named = "$1";
                $args[$_] = $named;

            # Slurpy discard
            } elsif( $args[$_] =~ /^\s*\$\s*$/ ) {
                $args[$_] = 'undef';

            # Slurpy discard (at the end)
            } elsif( $args[$_] =~ /^\s*[\%\@]\s*$/ ) {
                $args[$_] = 'undef';
            } else {
                #use Data::Dumper;
                #warn Dumper \@Filter::Simple::components;
                #die "Weird, unparsed argument '$args[$_]'";
            };

        };

        # Make sure we return undef as the last statement of our initialization
        # See t/07*
        push @defaults, "();" if @defaults;

        $res = sprintf 'sub %s { my (%s)=@_;%s%s', $name, join(",", @args), join( "" , @defaults), "\n" x $padding;
        # die sprintf("Too many arguments for subroutine at %s line %d.\n", (caller)[1, 2]) unless @_ <= 2
        # die sprintf("Too few arguments for subroutine at %s line %d.\n", (caller)[1, 2]) unless @_ >= 2
    } else {
        $res = sprintf 'sub %s { @_==0 or warn "Subroutine %s called with parameters.";();', $name, $name;
    };

    return $res
}

# This is the version that is most downwards compatible but doesn't handle
# parentheses in default assignments
sub transform_arguments {
	# This should also support
	# sub foo($x,$y,@) { ... }, throwing away additional arguments
	# Named or anonymous subs
	no warnings 'uninitialized';
	s{\bsub(\s*)(\w*)(\s*)\((\s*)((?:[^)]*?\@?))(\s*)\)(\s*)\{}{
		parse_argument_list("$2","$5","$1$3$4$6$7")
	 }mge;
	$_
}

if( $] >= 5.010 ) {
    # Perl 5.10 onwards has recursive regex patterns, and comments, and stuff
    no warnings 'redefine';
    eval <<'PERL_5010_onwards';
sub transform_arguments {
	# This should also support
	# sub foo($x,$y,@) { ... }, throwing away additional arguments
	# Named or anonymous subs
    # We also want to handle arbitrarily deeply nested balanced parentheses here
	no warnings 'uninitialized';

    # For Perl 5.10 onwards we have nice recursive patterns and comments
	s{\bsub(\s*) #1
           (\w*) #2
           (\s*) #3
           \(
           (\s*) #4
           (     #5
                (          #6
                   (?:
                     (?>[^()]+)
                     |
                     \(\s*
                         (?6)? # recurse for parentheses
                     \s*\)
                     )
                )*
             \@?
           )
           (\s*)\)
           (\s*)\{}{
		parse_argument_list("$2","$5","$1$3$4$8$9")
	 }mgex;
	$_
}
PERL_5010_onwards
    die $@ if $@;
}

if( (! $have_signatures) or $ENV{FORCE_FILTER_SIGNATURES} ) {
FILTER_ONLY
    code_no_comments => \&transform_arguments,
    executable => sub {
            s!^(use\s+feature\s*(['"])signatures\2;)!#$1!mg;
            s!^(no\s+warnings\s*(['"])experimental::signatures\2;)!#$1!mg;
    },
    ;
    # Set up a fake 'experimental::signatures' warnings category
    { package # hide from CPAN
        experimental::signatures;
    eval {
        require warnings::register;
        warnings::register->import();
    }
    }

}

1;

=head1 SEE ALSO

L<perlsub/Signatures>

L<signatures> - a module that doesn't use a source filter but optree
modification instead

L<Sub::Signatures> - uses signatures to dispatch to different subroutines
based on which subroutine matches the signature

L<Method::Signatures> - this module implements subroutine signatures
closer to Perl 6, but requires L<PPI> and L<Devel::Declare>

L<Function::Parameters> - adds two new keywords for declaring subroutines and
parses their signatures. It supports more features than core Perl, closer to
Perl 6, but requires a C compiler and Pelr 5.14+.

=head1 REPOSITORY

The public repository of this module is
L<http://github.com/Corion/filter-signatures>.

=head1 SUPPORT

The public support forum of this module is
L<https://perlmonks.org/>.

=head1 BUG TRACKER

Please report bugs in this module via the RT CPAN bug queue at
L<https://rt.cpan.org/Public/Dist/Display.html?Name=Filter-signatures>
or via mail to L<filter-signatures-Bugs@rt.cpan.org>.

=head1 AUTHOR

Max Maischein C<corion@cpan.org>

=head1 COPYRIGHT (c)

Copyright 2015-2018 by Max Maischein C<corion@cpan.org>.

=head1 LICENSE

This module is released under the same terms as Perl itself.

=cut
