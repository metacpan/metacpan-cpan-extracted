
package Testify;
use v5.20;
use List::Util qw( first );

use Exporter::Proxy qw( foo );

use Test::More;
use Test::Deep;

plan tests => 3;

sub foo { 'foo' }

my %foo     = qw( this is a hash );
my @foo     = qw( this is an array );
my $foo     = 'this is a scalar';

my @expect  = qw( foo );

ok __PACKAGE__->can( $_ ), __PACKAGE__ . "can $_"
for qw( import exports );

my @found   = __PACKAGE__->exports;

cmp_deeply \@found, \@expect, "Testify exports @found (@expect)";

__END__
