
package Base;

use v5.20;
use strict;

use Exporter::Proxy qw( foo bar );

sub foo {}
sub bar {}

our %foo = qw( this is a hash );
our @foo = qw( this is an array );
our $foo = 'this is a scalar';

our %bar = ( 'a' .. 'z' );
our @bar = (  1  ..  9  );
our $bar = 'blah blah blah';

package Derived;

use v5.20;
use List::Util qw( first );

use Test::More;
use Test::Deep;

Base->import( qw( foo ) );

plan tests => 9;

my @expect  = qw( foo bar );

my @found   = Base->exports;

cmp_deeply \@found, \@expect, "Base exports @found (@expect)";

ok %Derived::foo, __PACKAGE__ . ' has %foo';
ok @Derived::foo, __PACKAGE__ . ' has @foo';
ok $Derived::foo, __PACKAGE__ . ' has $foo';

ok __PACKAGE__->can( 'foo' ), __PACKAGE__ . ' can foo';

ok ! %Derived::bar, __PACKAGE__ . ' lacks %bar';
ok ! @Derived::bar, __PACKAGE__ . ' lacks @bar';
ok ! $Derived::bar, __PACKAGE__ . ' lacks $bar';

ok ! __PACKAGE__->can( 'bar' ), __PACKAGE__ . ' cannot bar';

__END__
