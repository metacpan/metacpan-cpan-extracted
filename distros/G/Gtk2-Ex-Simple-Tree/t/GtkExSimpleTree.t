#
# $Header: /cvsroot/gtk2-perl-ex/Gtk2-Ex/Simple/Tree/t/GtkExSimpleTree.t,v 1.1.1.1 2004/10/21 00:00:58 rwmcfa1 Exp $
#

#########################
# GtkSimpleList Tests
# 	- rm
#########################

use Data::Dumper;
use Gtk2::TestHelper tests => 37;

require_ok('Gtk2::Ex::Simple::Tree');

Gtk2::Ex::Simple::Tree->add_column_type(
	'ralacs', 	# think about it for a second...
		type     => 'Glib::Scalar',
		renderer => 'Gtk2::CellRendererText',
		attr     => sub {
			my ($tree_column, $cell, $model, $iter, $i) = @_;
			my ($info) = $model->get ($iter, $i);
			$info = join('',reverse(split('', $info || '' )));
			$cell->set (text => $info );
		}
	);

# add a new type of column that sums up an array reference
Gtk2::Ex::Simple::Tree->add_column_type(
	'sum_of_array',
		type     => 'Glib::Scalar',
		renderer => 'Gtk2::CellRendererText',
		attr     => sub {
			my ($tree_column, $cell, $model, $iter, $i) = @_;
			my $sum = 0;
			my $info = $model->get ($iter, $i);
			foreach (@$info)
			{
				$sum += $_;
			}
			$cell->set (text => $sum);
		}
	);

my $win = Gtk2::Window->new;
$win->set_title('19.GtkSimpleList.t test');
$win->set_default_size(450, 350);

my $vb = Gtk2::VBox->new(0, 6);
$win->add($vb);

my $sw = Gtk2::ScrolledWindow->new;
$sw->set_policy (qw/automatic automatic/);
$vb->pack_start($sw, 1, 1, 0);

ok (my $stree = Gtk2::Ex::Simple::Tree->new(
			'Text Field'    => 'text',
			'Int Field'     => 'int',
			'Double Field'  => 'double',
			'Bool Field'    => 'bool',
			'Scalar Field'  => 'scalar',
		), 'Gtk2::Ex::Simple::Tree->new');
$sw->add ($stree);

my @data = (
	{
		value => [ 'one', 1, 1.1, 1, 'uno', ],
		children =>
		[
			{
				value => [ 'one-b', -1, 1.11, 1, 'uno-uno', ],
			},
		]
	},
	{
		value => [ 'two', 2, 2.2, 0, 'dos', ],
		children =>
		[
			{
				value => [ 'two-b', 2, 2.22, 0, 'dos-dos', ],
			},
		]
	},
	{
		value => [ 'three', 3, 3.3, 1, 'tres', ],
		children => [], # only required so size tests won't return undef
	},
	{
		value => [ 'four', 4, 4.4, 0, 'quatro', ],
		children =>
		[
			{
				value => [ 'four-b', 4, 4.44, 1, 'quatro-quatro', ],
				children =>
				[
					{
						value => [ 'four-b-b', 4, 4.444, 1, 'quatro-quatro-quatro', ],
					},
					{
						value => [ 'four-b-c', -4, 4.445, 0, 'quatro-quatro-quatro-dos', ],
					},
				]
			},
			{
				value => [ 'four-c', 4, 4.45, 1, 'quatro-quatro-dos', ],
			},
		]
	}
);

my $tdata = $stree->{data};
@{$stree->{data}} = @data;

$win->show_all;

ok (eq_array ($tdata, \@data), 'inital data');

is (scalar (@$tdata), scalar (@data), "top-level size");
foreach (0..3)
{
	ok (exists $tdata->[$_], "element $_ exists");
	is (scalar (@{$tdata->[$_]{children}}),
	    scalar (@{$data[$_]{children}}), "element $_ size");
}

$tdata->[3]{value}[1] = 6;
$data[3]{value}[1] = 6;
ok (eq_array ($tdata, \@data), 'top-level column store');

$tdata->[3]{children}[1]{value}[1] = 12;
$data[3]{children}[1]{value}[1] = 12;
ok (eq_array ($tdata, \@data), 'second level column store');

$tdata->[3]{children}[0]{children}[0]{value}[1] = 42;
$data[3]{children}[0]{children}[0]{value}[1] = 42;
ok (eq_array ($tdata, \@data), 'third level column store');

@{$tdata->[1]{value}} = ( 'store', -1, -1.1, 1, 'store', );
@{$data[1]{value}} = ( 'store', -1, -1.1, 1, 'store', );
ok (eq_array ($tdata, \@data), 'top-level row store');

@{$tdata->[1]{children}[0]{value}} = ( 'store', -2, -2.1, 0, 'store', );
@{$data[1]{children}[0]{value}} = ( 'store', -2, -2.1, 0, 'store', );
ok (eq_array ($tdata, \@data), 'second level row store');

@{$tdata->[3]{children}[0]{children}[0]{value}} = ( 'store', -3, -3.1, 1, 'store', );
@{$data[3]{children}[0]{children}[0]{value}} = ( 'store', -3, -3.1, 1, 'store', );
ok (eq_array ($tdata, \@data), 'third level row store');

push @{$tdata}, { value => ['push', 1, 1.1, 1, 'push',], };
push @data, { value => ['push', 1, 1.1, 1, 'push',], };
ok (eq_array ($tdata, \@data), 'top-level push');

push @{$tdata->[4]{children}}, { value => ['push-b', 2, 2.2, 0, 'push-b',], };
push @{$data[4]{children}}, { value => ['push-b', 2, 2.2, 0, 'push-b',], };
ok (eq_array ($tdata, \@data), 'second level push');

push @{$tdata->[4]{children}[0]{children}}, { value => ['push-b-b', 3, 3.3, 1, 'push-b',], };
push @{$data[4]{children}[0]{children}}, { value => ['push-b-b', 3, 3.3, 1, 'push-b',], };
ok (eq_array ($tdata, \@data), 'third level push');

ok (eq_hash (pop (@{$tdata->[4]{children}[0]{children}}),
	     pop (@{$data[4]{children}[0]{children}})), 'third level pop');

ok (eq_hash (pop (@{$tdata->[4]{children}}),
	     pop (@{$data[4]{children}})), 'second level pop');

ok (eq_hash (pop (@{$tdata}),
	     pop (@data)), 'top-level level pop');


unshift @{$tdata}, { value => ['unshift', 1, 1.1, 1, 'unshift',], };
unshift @data, { value => ['unshift', 1, 1.1, 1, 'unshift',], };
ok (eq_array ($tdata, \@data), 'top-level unshift');

unshift @{$tdata->[0]{children}}, { value => ['unshift-b', 2, 2.2, 0, 'unshift-b',], };
unshift @{$data[0]{children}}, { value => ['unshift-b', 2, 2.2, 0, 'unshift-b',], };
ok (eq_array ($tdata, \@data), 'second level unshift');

unshift @{$tdata->[0]{children}[0]{children}}, { value => ['unshift-b-b', 3, 3.3, 1, 'unshift-b',], };
unshift @{$data[0]{children}[0]{children}}, { value => ['unshift-b-b', 3, 3.3, 1, 'unshift-b',], };
ok (eq_array ($tdata, \@data), 'third level unshift');

ok (eq_hash (shift (@{$tdata->[0]{children}[0]{children}}),
	     shift (@{$data[0]{children}[0]{children}})), 'third level shift');

ok (eq_hash (shift (@{$tdata->[0]{children}}),
	     shift (@{$data[0]{children}})), 'second level shift');

ok (eq_hash (shift (@{$tdata}),
	     shift (@data)), 'top-level level shift');

ok (eq_hash (delete ($tdata->[3]{children}[0]{children}[0]),
	     delete ($data[3]{children}[0]{children}[0])), 'third level delete');

# in a tree store when an element is deleted the one below it shifts up, that
# doesn't happen in a perl array, so we have to fake it. (with a shift)
shift @{$data[3]{children}[0]{children}};

ok (eq_hash (delete ($tdata->[3]{children}[0]),
	     delete ($data[3]{children}[0])), 'second level delete');

# same thing again, one level up
shift @{$data[3]{children}};

ok (eq_hash (delete ($tdata->[3]),
	     delete ($data[3])), 'top-level level delete');

ok (eq_hash (
	splice (@$tdata, 1, 1, {
		value => ['splice', 1, 1.1, 1, 'splice',],
		children => [
			{
				value => ['splice-b', 1, 1.1, 1, 'splice-b',],
			},
		]}),
	splice (@data, 1, 1, {
		value => ['splice', 1, 1.1, 1, 'splice',],
		children => [
			{
				value => ['splice-b', 1, 1.1, 1, 'splice-b',],
			},
		]})), 'toplevel splice 1');

ok (eq_array (
	[ splice (@$tdata, 0, 3, {
		value => ['splice', 1, 1.1, 1, 'splice',],
		children => [
			{
				value => ['splice-b', 1, 1.1, 1, 'splice-b',],
				children => [],
			},
		]})
	],
	[ splice (@data, 0, 3, {
		value => ['splice', 1, 1.1, 1, 'splice',],
		children => [
			{
				value => ['splice-b', 1, 1.1, 1, 'splice-b',],
				children => [],
			},
		]})
	]), 'toplevel splice 2');

ok (eq_array (
	[ splice (@$tdata, 1, 0, {
		value => ['splice 3', 1, 1.1, 1, 'splice',],
		children => [
			{
				value => ['splice-b', 1, 1.1, 1, 'splice-b',],
				children => [],
			},
		]})
	],
	[ splice (@data, 1, 0, {
		value => ['splice 3', 1, 1.1, 1, 'splice',],
		children => [
			{
				value => ['splice-b', 1, 1.1, 1, 'splice-b',],
				children => [],
			},
		]})
	]), 'toplevel splice 3');

ok (eq_array (
	[ splice (@{$tdata->[0]{children}}, 0, 3, {
		value => ['splice-b', 1, 1.1, 1, 'splice',],
		children => [
			{
				value => ['splice-c', 1, 1.1, 1, 'splice-b',],
			},
		]})
	],
	[ splice (@{$data[0]{children}}, 0, 3, {
		value => ['splice-b', 1, 1.1, 1, 'splice',],
		children => [
			{
				value => ['splice-c', 1, 1.1, 1, 'splice-b',],
			},
		]})
	]), 'second level splice 1');

