
package Base;

use v5.20;
use strict;

use Exporter::Proxy qw( dispatch=frobnicate );

sub foo { [ @_, 'FOO' ] }
sub bar { [ @_, 'BAR' ] }

package Derived;

use v5.20;
use strict;
use List::Util qw( first );

use Test::More;
use Test::Deep;

Base->import;

plan tests => 4;

my @expect  = qw( frobnicate );
my @found   = Base->exports;

cmp_deeply \@found, \@expect, "Base exports @found (@expect)";

ok __PACKAGE__->can( 'frobnicate' ), 'frobnicate exported';

for
(
    [ foo => qw( a b c ) ], 
    [ bar => qw( i j k ) ],
)
{
    my ( $name, @argz ) = @$_;

    # order checks that the name is spliced off properly
    # in the dispatcher.

    my $expect  = [ 'Derived', @argz, uc $name ];
    my $found   = __PACKAGE__->frobnicate( $name => @argz  );

    cmp_deeply \@found, \@expect, "$name => @$found (@$expect)";
}


__END__
