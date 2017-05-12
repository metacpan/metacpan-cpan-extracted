use strict;
use warnings FATAL => 'all';

use Test::More tests => 6;
use Data::Dumper;

BEGIN { use_ok('HTML::Tested', "HTV"); 
	use_ok('HTML::Tested::Test'); 
	use_ok('HTML::Tested::Value::EditBox');
}

package T;
use base 'HTML::Tested';
__PACKAGE__->ht_add_widget(::HTV."::EditBox", 'v');

package main;

my $object = T->new({ v => 'b' });
is($object->v, 'b');

my $stash = {};
$object->ht_render($stash);
is_deeply($stash, { v => <<ENDS }) or diag(Dumper($stash));
<input type="text" name="v" id="v" value="b" />
ENDS

$object->v('>b');
$object->ht_render($stash);
is_deeply($stash, { v => <<ENDS }) or diag(Dumper($stash));
<input type="text" name="v" id="v" value="&gt;b" />
ENDS

