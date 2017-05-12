use Test::More 'no_plan';
use warnings;
use strict;

package Foo::Bar;
use Gapp::Moose;


use Gapp::Actions -declare => [qw( New Edit Delete )];

use Test::More;

action New => (
    label => 'New',
    tooltip => 'New',
    icon => 'gtk-new',
    code => sub {
        my ( $action, $arg ) = @_;
        return 1;
    }
);

action Edit => (
    label => 'New',
    tooltip => 'New',
    icon => 'gtk-new',
    code => sub {
        my ( $action, $arg ) = @_;
        return $arg;
    }
);

ok perform( New ),  'performed action';

ok perform ( sub { return 1; } ), 'performed code-ref';

ok perform ( [ New, 1 ] ), 'performed array action';
 
ok perform ( [ sub { return $_[0] }, 1 ] ), 'performed array code-ref';

1;
