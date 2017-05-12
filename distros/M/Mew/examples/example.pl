package Foo;

use Moo;

has ar1 => ( is => 'ro' );
has ar2 => ( is => 'ro' );

package main;
use 5.020;
my $c = Foo->new( ar1 => 42, ar2 => 44 );
say $c->ar1;
say $c->ar2;

__END__

package Class;

use lib qw{lib ../lib};
use 5.020;
use Mew;
has  _foo  => PositiveNum;
has -_bar  => Bool;  # note the minus: it means attribute is not `required`
has  _type => Str, (default => 'text/html', chained => 1 );
has  _cust => ( is => 'rw', default => 'Zoffix' ); # standard Moo `has`

package main;

my $c = Class->new( foo => 42, bar => 1 );

say $c->_foo;
say $c->_bar;
say $c->_type( 9001 )->_cust;
say $c->_type;


