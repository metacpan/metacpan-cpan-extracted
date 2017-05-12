use strict;
use warnings FATAL => 'all';

use Test::More tests => 13;
use Data::Dumper;
use Carp;

BEGIN { $SIG{__DIE__} = sub { confess("# " . $_[0]); }; };

BEGIN { use_ok('HTML::Tested::Value::Tree');
	use_ok('HTML::Tested', "HTV");
	use_ok('HTML::Tested::Test');
};

use constant INPUT_TREE => [ {
	value => 'a',
	children => [ {
		value => 'b',
		children => [ {
			value => 'g',
		} ],
	}, {
		value => 'c',
		children => [ {
			value => 'f',
		} ],
	} ]
}, {
	value => 'e',
} ];

is(HTML::Tested::Value::Tree->value_to_string('name'
			, { input_tree => INPUT_TREE,
collapsed_format => '%value%', selected_format => '%value% 1',
selection_attribute => "value", selection_tree => {
	a => { c => { f => 1 } },
} }), <<ENDS);
<ul>
  <li>
    a 1
    <ul>
      <li>
        b
      </li>
      <li>
        c 1
        <ul>
          <li>
            f 1
          </li>
        </ul>
      </li>
    </ul>
  </li>
  <li>
    e
  </li>
</ul>
ENDS

is(HTML::Tested::Value::Tree->value_to_string('name'
			, { input_tree => INPUT_TREE,
selection_attribute => "value", selection_tree => {
	a => { c => { f => 1 } },
} }), <<ENDS);
<ul>
  <li>
    <span class="selected">a</span>
    <ul>
      <li>
        <a href="#">b</a>
      </li>
      <li>
        <span class="selected">c</span>
        <ul>
          <li>
            <span class="selected">f</span>
          </li>
        </ul>
      </li>
    </ul>
  </li>
  <li>
    <a href="#">e</a>
  </li>
</ul>
ENDS

is(HTML::Tested::Value::Tree->value_to_string('name'
			, { input_tree => INPUT_TREE,
selection_attribute => "value", selections => [ 'e', 'f' ], }), <<ENDS);
<ul>
  <li>
    <span class="selected">a</span>
    <ul>
      <li>
        <a href="#">b</a>
      </li>
      <li>
        <span class="selected">c</span>
        <ul>
          <li>
            <span class="selected">f</span>
          </li>
        </ul>
      </li>
    </ul>
  </li>
  <li>
    <span class="selected">e</span>
  </li>
</ul>
ENDS

package T;
use base 'HTML::Tested';
__PACKAGE__->ht_add_widget(::HTV."::Tree", 'v'
, collapsed_format => '<a href="%href%">%label%</a>'
, selected_format => '<span class="selected">%label%</span>'
, input_tree => [ {
	label => 'News',
	href => '/root/news',
}, {
	label => 'Blogs',
	href => '/root/blog/John',
	children => [ {
		label => 'John',
		href => '/root/blog/John',
	}, {
		label => 'Alice',
		href => '/root/blog/Alice',
	} ],
} ]);

package main;

my $object = T->new;
is_deeply($object->v, undef);
my $stash = {};
$object->ht_render($stash);
is_deeply($stash, { v => <<ENDS }) or diag(Dumper($stash));
<ul>
  <li>
    <a href="/root/news">News</a>
  </li>
  <li>
    <a href="/root/blog/John">Blogs</a>
  </li>
</ul>
ENDS

my $arg = {};
$object->v($arg);
my $old_res = $stash;
$stash = {};
$object->ht_render($stash);
is_deeply($stash, $old_res) or diag(Dumper($stash));
is_deeply($arg, {});

$arg->{selections} = [ '/root/blog/Alice' ];
$stash = {};
$object->ht_set_widget_option('v', 'selection_attribute', 'href');
$object->ht_render($stash);
is_deeply($stash, { v => <<ENDS }) or diag(Dumper($stash));
<ul>
  <li>
    <a href="/root/news">News</a>
  </li>
  <li>
    <span class="selected">Blogs</span>
    <ul>
      <li>
        <a href="/root/blog/John">John</a>
      </li>
      <li>
        <span class="selected">Alice</span>
      </li>
    </ul>
  </li>
</ul>
ENDS
is_deeply($arg, { selections => [ '/root/blog/Alice' ] });

is_deeply([ HTML::Tested::Test->check_stash(ref($object), $stash, { v => {
	selections => [ '/root/blog/Alice' ]
	, selection_attribute => 'href'
} }) ], []);

