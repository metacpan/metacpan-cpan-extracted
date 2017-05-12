use strict;
use warnings FATAL => 'all';

use Test::More tests => 6;
use Data::Dumper;

BEGIN { use_ok('HTML::Tested::List::Pager');
	use_ok('HTML::Tested', "HTV");
	use_ok('HTML::Tested::Value::Marked');
	use_ok('HTML::Tested::List');
}

my $id = 1;

package L;
use base 'HTML::Tested';
__PACKAGE__->ht_add_widget("HTML::Tested::List", 'l1', 'LR', renderers => [
	HTML::Tested::List::Pager->new(2),
	'HTML::Tested::List::Renderer',
]);

package LR;
use base 'HTML::Tested';
__PACKAGE__->ht_add_widget(::HTV."::Marked", 'v1');

sub ht_id { return $id++; }

package main;

my $object = L->new({ l1 => [ map { LR->new({ v1 => $_ }) } qw(a b) ] });
my $stash = {};
$object->ht_render($stash);
is_deeply($stash, { l1_current_page => '',
			l1 => [ { v1 => '<!-- l1__1__v1 --> a' }, 
				{ v1 => '<!-- l1__2__v1 --> b' } ] }) 
	or diag(Dumper($stash));
is($object->l1_current_page, undef);

