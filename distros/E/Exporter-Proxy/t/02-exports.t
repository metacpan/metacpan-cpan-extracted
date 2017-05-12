
package Base;

use v5.10.0;
use strict;

use Exporter::Proxy qw( foo );

sub foo {}

our %foo = qw( this is a hash );
our @foo = qw( this is an array );
our $foo = 'this is a scalar';

package Derived;

use v5.10.0;
use strict;

use Test::More;

Base->import;

plan tests => 4;

ok %Derived::foo,           'Derived has %foo';
ok @Derived::foo,           'Derived has @foo';
ok $Derived::foo,           'Derived has $foo';

ok __PACKAGE__->can( 'foo' ),   'Derived can foo';

__END__
