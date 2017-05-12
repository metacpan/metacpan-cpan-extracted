use strict;
use warnings FATAL => 'all';

use Test::More tests => 16;
use Data::Dumper;

BEGIN { use_ok('HTML::Tested', qw(HTV)); 
	use_ok('HTML::Tested::Test'); 
	use_ok('HTML::Tested::Value::Submit');
}

package T;
use base 'HTML::Tested';
__PACKAGE__->ht_add_widget(::HTV.'::Submit', 'v');

package main;

my $object = T->new({ v => 'b' });
is($object->v, 'b');

my $stash = {};
$object->ht_render($stash);
is_deeply($stash, { v => <<ENDS }) or diag(Dumper($stash));
<input type="submit" name="v" id="v" value="b" />
ENDS

$object->v('>b');
$object->ht_render($stash);
is_deeply($stash, { v => <<ENDS }) or diag(Dumper($stash));
<input type="submit" name="v" id="v" value="&gt;b" />
ENDS

$object->v(undef);
$object->ht_render($stash);
is_deeply($stash, { v => <<ENDS }) or diag(Dumper($stash));
<input type="submit" name="v" id="v" />
ENDS

package T2;
use base 'HTML::Tested';
__PACKAGE__->ht_add_widget(::HTV.'::Submit', 'v', default_value => 'b');

package main;

$object = T2->new;
is($object->v, undef);

$stash = {};
$object->ht_render($stash);
is_deeply($stash, { v => <<ENDS }) or diag(Dumper($stash));
<input type="submit" name="v" id="v" value="b" />
ENDS

$object->ht_set_widget_option("v", "is_disabled", 1);
$stash = {};
$object->ht_render($stash);
is_deeply($stash, { v => '' }) or diag(Dumper($stash));

is_deeply([ HTML::Tested::Test->check_stash(ref($object), 
		$stash, { v => 'HT_DISABLED' }) ], []);

$object = T2->new;
is($object->v, undef);

$stash = {};
$object->ht_render($stash);
is_deeply($stash, { v => <<ENDS }) or diag(Dumper($stash));
<input type="submit" name="v" id="v" value="b" />
ENDS

is_deeply([ HTML::Tested::Test->check_stash(ref($object), 
		$stash, { HT_NO_v => 'b' }) ], []);

is_deeply([ HTML::Tested::Test->check_text(ref($object), 
	'There is no v here', { HT_NO_v => 'b' }) ], []);

is_deeply([ HTML::Tested::Test->check_text(ref($object), 
	'There is <input type="submit" name="v" id="v" value="b" />'
		. "\n", { HT_NO_v => 'b' }) ], [
	'Unexpectedly found "<input type="submit" name="v" id="v" value="b"'
		. " />\n\" in "
		. '"There is <input type="submit" name="v" id="v" value="b"'
		. " />\n\""
]);

