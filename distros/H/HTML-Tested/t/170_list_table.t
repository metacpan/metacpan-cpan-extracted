use strict;
use warnings FATAL => 'all';

use Test::More tests => 12;
use Data::Dumper;

BEGIN { use_ok('HTML::Tested::List'); 
	use_ok('HTML::Tested::Value');
	use_ok('HTML::Tested::Test');
}

package LR;
use base 'HTML::Tested';
__PACKAGE__->ht_add_widget("HTML::Tested::Value", 'v3', column_title => 'V3');
__PACKAGE__->ht_add_widget("HTML::Tested::Value", 'v2');
__PACKAGE__->ht_add_widget("HTML::Tested::Value", 'v1', column_title => 'V1');

package L;
use base 'HTML::Tested';
__PACKAGE__->ht_add_widget("HTML::Tested::List", 'l1', 'LR', render_table => 1);


package L2;
use base 'HTML::Tested';
__PACKAGE__->ht_add_widget("HTML::Tested::List", 'l1', 'LR');

package main;

is_deeply([ map { $_->name } @{ LR->Widgets_List } ], [ qw(v3 v2 v1) ]);
is(L->ht_get_widget_option("l1", "some_opt"), undef);

my $object = L->new({ l1 => [] });
is_deeply($object->l1, []);

$object->l1([ map {
	LR->new({ v1 => "1$_", v2 => "2$_", v3 => "3$_" })
} qw(a b) ]);

my $stash = {};
$object->ht_render($stash);
is_deeply($stash, { l1 => [ { v1 => '1a', v2 => '2a', v3 => '3a' }, 
				{ v1 => '1b', v2 => '2b', v3 => '3b' } ]
	, l1_table => <<ENDS
<table>
<tr>
<th>V3</th>
<th>V1</th>
</tr>
<tr>
<td>3a</td>
<td>1a</td>
</tr>
<tr>
<td>3b</td>
<td>1b</td>
</tr>
</table>
ENDS
}) or diag(Dumper($stash));

bless $object, 'L2';
$stash = {};
$object->ht_render($stash);
is_deeply($stash, { l1 => [ { v1 => '1a', v2 => '2a', v3 => '3a' }, 
				{ v1 => '1b', v2 => '2b', v3 => '3b' } ]
}) or diag(Dumper($stash));

eval {
package L3;
use base 'HTML::Tested';
__PACKAGE__->ht_add_widget('HTML::Tested::List', 'l1', 'L2', render_table => 1);
};

package main;
like($@, qr/No columns found!/);

package LR1;
use base 'HTML::Tested';
__PACKAGE__->ht_add_widget("HTML::Tested::Value", 'v3', column_title => '');

package L4;
use base 'HTML::Tested';
__PACKAGE__->ht_add_widget('HTML::Tested::List', 'l1'
		, 'LR1', render_table => 1);

package main;
$object = L4->new({ l1 => [ map {
	LR1->new({ v3 => "3$_" })
} qw(a b) ] });
$stash = {};
$object->ht_render($stash);
is_deeply($stash, { l1 => [ { v3 => '3a' }, { v3 => '3b' } ]
	, l1_table => <<ENDS
<table>
<tr>
<th></th>
</tr>
<tr>
<td>3a</td>
</tr>
<tr>
<td>3b</td>
</tr>
</table>
ENDS
}) or diag(Dumper($stash));

eval { HTML::Tested::Test->check_stash('L4', $stash, { l1 => [ {} ] }); };
like($@, qr/No v3 found/);

package HI;
use base 'HTML::Tested';
__PACKAGE__->ht_add_widget("HTML::Tested::Value", 'v');

package H;
use base 'HTML::Tested';
__PACKAGE__->ht_add_widget('HTML::Tested::List', 'l', 'HI', keep_holes => 1);

package main;
my $obj = H->ht_load_from_params(l__2__v => 'a', l__4__v => 'b');
is_deeply($obj->l, [ undef, { v => 'a' }, undef, { v => 'b' } ])
	or diag(Dumper($obj));
