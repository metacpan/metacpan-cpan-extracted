use strict;
use warnings FATAL => 'all';

use Test::More tests => 14;
use Data::Dumper;

BEGIN { use_ok('HTML::Tested', "HTV"); 
	use_ok('HTML::Tested::Test'); 
	use_ok('HTML::Tested::Value::PasswordBox'); 
}

package T;
use base 'HTML::Tested';
__PACKAGE__->ht_add_widget(::HTV."::PasswordBox", 'v');

package main;

my $object = T->new({ v => 'b' });
is($object->v, 'b');

my $stash = {};
$object->ht_render($stash);
is_deeply($stash, { v => <<ENDS }) or diag(Dumper($stash));
<input type="password" name="v" id="v" value="b" />
ENDS

package T2;
use base 'HTML::Tested';
__PACKAGE__->ht_add_widget(::HTV."::PasswordBox", 'p1');
__PACKAGE__->ht_add_widget(::HTV."::PasswordBox", p2 => check_mismatch => 'p1');

package main;

$object = T2->new;
is_deeply([ $object->ht_validate ], []);

$object->p1('a');
$object->p2('b');
my @res = $object->ht_validate;
is_deeply([ $res[0]->[0], $res[0]->[1] ], [ p2 => 'mismatch' ]);

$object->p1('b');
is_deeply([ $object->ht_validate ], []);

$object->p1(undef);
@res = $object->ht_validate;
is_deeply([ $res[0]->[0], $res[0]->[1] ], [ p2 => 'mismatch' ]);

package T3;
use base 'HTML::Tested';
__PACKAGE__->ht_add_widget(::HTV."::PasswordBox", 'p1' => constraints => [ [
	foo => sub { return $_[1]->p2 eq 'bar' } ] ]);
__PACKAGE__->ht_add_widget(::HTV."::PasswordBox", 'p2');

package main;
$object = T3->new({ p2 => 'bar' });
is_deeply([ $object->ht_validate ], []);

$object->p2('hi');
@res = $object->ht_validate;
is(@res, 1);
is($res[0]->[0], 'p1');
is($res[0]->[1], 'foo');
isa_ok($res[0]->[2], 'CODE');
