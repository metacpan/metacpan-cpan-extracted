package Filter::signatures;
use strict;
use Filter::Simple;

use vars '$VERSION';
$VERSION = '0.09';

=head1 NAME

Filter::signatures - very simplicistic signatures for Perl < 5.20

=head1 SYNOPSIS

    use Filter::signatures;
    no warnings 'experimental::signatures'; # does not raise an error
    use feature 'signatures'; # this now works on <5.16 as well

    sub hello( $name ) {
        print "Hello $name\n";
    }

    hello("World");

    sub hello2( $name="world" ) {
        print "Hello $name\n";
    }
    hello2(); # Hello world


=head1 CAVEATS

This implements a very simplicistic transform to allow for using very
simplicistic named formal arguments in subroutine declarations. This module
does not implement warning if more parameters than expected are passed in.

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

=head2 C<< eval >>

It seems that L<Filter::Simple> does not trigger when using
code such as

  eval <<'PERL';
      use Filter::signatures;
      use feature 'signatures';

      sub foo (...) {
      }
  PERL

So, creating subroutines with signatures from strings won't work with
this module. The workaround is to upgrade to Perl 5.20 or higher.

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

sub parse_argument_list {
    my( $name, $arglist ) = @_;
    (my $args=$arglist) =~ s!^\((.*)\)!$1!;
    my @args = split /\s*,\s*/, $args; # a most simple argument parser
    my $res;
    if( @args ) {
        my @defaults;
        for( 0..$#args ) {
            # Named argument
            if( $args[$_] =~ /^\s*([\$\%\@]\s*\w+)\s*=/ ) {
                my $named = "$1";
                push @defaults, "$args[$_] if \@_ <= $_;";
                $args[$_] = $named;

            # Slurpy discard
            } elsif( $args[$_] =~ /^\s*\$\s*$/ ) {
                $args[$_] = 'undef';

            # Slurpy discard (at the end)
            } elsif( $args[$_] =~ /^\s*[\%\@]\s*$/ ) {
                $args[$_] = 'undef';
            }
        };
        $res = sprintf 'sub %s { my (%s)=@_;%s', $name, join(",", @args), join( "" , @defaults);
    } else {
        $res = sprintf 'sub %s { @_==0 or warn "Subroutine %s called with parameters.";', $name, $name;
    };

    return $res
}

sub transform_arguments {
	# This should also support
	# sub foo($x,$y,@) { ... }, throwing away additional arguments
	# Named or anonymous subs
	no warnings 'uninitialized';
	s{\bsub\s*(\w*)\s*\(((?:[^)]*?\@?))\)\s*\{}{
		parse_argument_list("$1","$2")
	 }mge;
	 $_
}

if( (! $have_signatures) or $ENV{FORCE_FILTER_SIGNATURES} ) {
FILTER_ONLY
    code => \&transform_arguments,
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

L<Sub::Signatures>

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

Copyright 2015-2016 by Max Maischein C<corion@cpan.org>.

=head1 LICENSE

This module is released under the same terms as Perl itself.

=cut
