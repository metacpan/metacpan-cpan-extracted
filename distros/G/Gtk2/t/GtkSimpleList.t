# vim: set syntax=perl :
#
# $Id$
#

#########################
# GtkSimpleList Tests
# 	- rm
#########################

use Gtk2::TestHelper tests => 46;

require_ok( 'Gtk2::SimpleList' );

Gtk2::SimpleList->add_column_type(
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
Gtk2::SimpleList->add_column_type(
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

ok( my $list = Gtk2::SimpleList->new(
			'Text Field'    => 'text',
			'Int Field'     => 'int',
			'Double Field'  => 'double',
			'Bool Field'    => 'bool',
			'Scalar Field'  => 'scalar',
			'Pixbuf Field'  => 'pixbuf',
			'Ralacs Field'  => 'ralacs',
			'Sum of Array'  => 'sum_of_array',
			'Markup Field'  => 'markup',
		) );
# $sw->add($list);

my $quitbtn = Gtk2::Button->new_from_stock('gtk-quit');
$quitbtn->signal_connect( clicked => sub { Gtk2->main_quit; 1 } );
$vb->pack_start($quitbtn, 0, 0, 0);

# begin exercise of SimpleList

# this could easily fail, so we'll catch and work around it
my $pixbuf;
eval { $pixbuf = $win->render_icon ('gtk-ok', 'menu') };
if( $@ )
{
	$pixbuf = undef;
}
my $undef;
my $scalar = 'scalar';

@{$list->{data}} = (
	[ 'one', 1, 11, 1, undef, $pixbuf, undef, [0, 1, 2], '<big>one</big>' ],
	[ 'two', 2, 22, 0, undef, undef, $scalar, [1, 2, 3], '<big>two</big>' ],
	[ 'three', 3, 33, 1, $scalar, $pixbuf, undef, [2, 3, 4], '<big>three</big>' ],
	[ 'four', 4, 44, 0, $scalar, $undef, $scalar, [3, 4, 5], '<big>four</big>' ],
);
ok( scalar(@{$list->{data}}) == 4 );

ok( $list->signal_connect( row_activated => sub
	{
		print STDERR "row_activated: @_";
		1;
	} ) );

my $count = 0;
run_main sub {
		my $ldata = $list->{data};

		ok( scalar(@$ldata) == 4 );

		# test the initial values we put in there
		ok(
			$ldata->[0][0] eq 'one' and
			$ldata->[1][0] eq 'two' and
			$ldata->[2][0] eq 'three' and
			$ldata->[3][0] eq 'four' and
			$ldata->[0][1] == 1 and
			$ldata->[1][1] == 2 and
			$ldata->[2][1] == 3 and
			$ldata->[3][1] == 4 and
			$ldata->[0][2] == 11 and
			$ldata->[1][2] == 22 and
			$ldata->[2][2] == 33 and
			$ldata->[3][2] == 44 and
			$ldata->[0][3] == 1 and
			$ldata->[1][3] == 0 and
			$ldata->[2][3] == 1 and
			$ldata->[3][3] == 0 and
			not defined($ldata->[0][4]) and
			not defined($ldata->[1][4]) and
			$ldata->[2][4] eq $scalar and
			$ldata->[3][4] eq $scalar and
			$ldata->[0][5] == $pixbuf and
			not defined($ldata->[1][5]) and
			$ldata->[2][5] == $pixbuf and
			not defined($ldata->[3][5]) and
			eq_array($ldata->[0][7], [0, 1, 2]) and
			eq_array($ldata->[1][7], [1, 2, 3]) and
			eq_array($ldata->[2][7], [2, 3, 4]) and
			eq_array($ldata->[3][7], [3, 4, 5]) and
			$ldata->[0][8] eq '<big>one</big>' and
			$ldata->[1][8] eq '<big>two</big>' and
			$ldata->[2][8] eq '<big>three</big>' and
			$ldata->[3][8] eq '<big>four</big>'
		);

		is (push (@$ldata, [ 'pushed', 1, 10, undef ]), 5);
		ok( scalar(@$ldata) == 5 );
		push @$ldata, [ 'pushed', 2, 20, undef ];
		ok( scalar(@$ldata) == 6 );
		push @$ldata, [ 'pushed', 3, 30, undef ];
		ok( scalar(@$ldata) == 7 );

		ok (eq_array (pop @$ldata, ['pushed', 3, 30, 0, 
					undef, undef, undef, undef, undef]));
		ok( scalar(@$ldata) == 6 );
		pop @$ldata;
		ok( scalar(@$ldata) == 5 );
		pop @$ldata;
		ok( scalar(@$ldata) == 4 );

		is (unshift (@$ldata, [ 'unshifted', 1, 10, undef ]), 5);
		ok( scalar(@$ldata) == 5 );
		unshift @$ldata, [ 'unshifted', 2, 20, undef ];
		ok( scalar(@$ldata) == 6 );
		unshift @$ldata, [ 'unshifted', 3, 30, undef ];
		ok( scalar(@$ldata) == 7 );

		ok (eq_array (shift @$ldata, ['unshifted', 3, 30, 0, 
					undef, undef, undef, undef, undef]));
		ok( scalar(@$ldata) == 6 );
		shift @$ldata;
		ok( scalar(@$ldata) == 5 );
		shift @$ldata;
		ok( scalar(@$ldata) == 4 );

		# make sure we're back to the initial values we put in there
		ok(
			$ldata->[0][0] eq 'one' and
			$ldata->[1][0] eq 'two' and
			$ldata->[2][0] eq 'three' and
			$ldata->[3][0] eq 'four' and
			$ldata->[0][1] == 1 and
			$ldata->[1][1] == 2 and
			$ldata->[2][1] == 3 and
			$ldata->[3][1] == 4 and
			$ldata->[0][2] == 11 and
			$ldata->[1][2] == 22 and
			$ldata->[2][2] == 33 and
			$ldata->[3][2] == 44 and
			$ldata->[0][3] == 1 and
			$ldata->[1][3] == 0 and
			$ldata->[2][3] == 1 and
			$ldata->[3][3] == 0 and
			not defined($ldata->[0][4]) and
			not defined($ldata->[1][4]) and
			$ldata->[2][4] eq $scalar and
			$ldata->[3][4] eq $scalar and
			$ldata->[0][5] == $pixbuf and
			not defined($ldata->[1][5]) and
			$ldata->[2][5] == $pixbuf and
			not defined($ldata->[3][5]) and
			eq_array($ldata->[0][7], [0, 1, 2]) and
			eq_array($ldata->[1][7], [1, 2, 3]) and
			eq_array($ldata->[2][7], [2, 3, 4]) and
			eq_array($ldata->[3][7], [3, 4, 5]) and
			$ldata->[0][8] eq '<big>one</big>' and
			$ldata->[1][8] eq '<big>two</big>' and
			$ldata->[2][8] eq '<big>three</big>' and
			$ldata->[3][8] eq '<big>four</big>'
		);

		$ldata->[1][0] = 'getting deleted';
		ok( $ldata->[1][0] eq 'getting deleted' );

		$ldata->[1] = [ 'right now', -1, -11, 1, undef ];
		ok(
			$ldata->[1][0] eq 'right now' and
			$ldata->[1][1] == -1 and
			$ldata->[1][2] == -11 and
			$ldata->[1][3] == 1
	       	);

		$ldata->[1] = 'bye';
		ok( $ldata->[1][0] eq 'bye' );

		delete $ldata->[1];
		ok( scalar(@$ldata) == 3 );

		ok( exists($ldata->[0]) );
		ok( exists($ldata->[0][0]) );

		@{$list->{data}} = ();
		ok( scalar(@$ldata) == 0 );
		
		push @{$list->{data}}, (
			[ 'pushed', 1, 10, undef ],
			[ 'pushed', 2, 10, undef ],
			[ 'pushed', 3, 10, undef ],
			[ 'pushed', 4, 10, undef ],
		);
		unshift @{$list->{data}}, (
			[ 'unshifted', 1, 10, undef ],
			[ 'unshifted', 2, 10, undef ],
			[ 'unshifted', 3, 10, undef ],
			[ 'unshifted', 4, 10, undef ],
		);

		is( scalar(@{$list->{data}}), 8 );

		my @ret;
		
		@ret = splice @{$list->{data}}, 2, 2,
				[ 'spliced', 1, 10, undef ],
				[ 'spliced', 2, 10, undef ];
		is_deeply (\@ret, 
			[ [ 'unshifted', 2, 10, 0, 
			    undef, undef, undef, undef, undef ],
			  [ 'unshifted', 1, 10, 0, 
			    undef, undef, undef, undef, undef ] ], 'splice @, 2, 2 @');
		
		@ret = splice @{$list->{data}}, -2, 1,
			[ 'negspliced', 1, 10, undef ],
			[ 'negspliced', 2, 10, undef ],
			[ 'negspliced', 3, 10, undef ];
		is_deeply (\@ret, 
			[ [ 'pushed', 3, 10, 0, 
			    undef, undef, undef, undef, undef ] ], 'splice @, -2, 1 @');

		@ret = splice @{$list->{data}}, 8;
		is_deeply (\@ret, 
			[ [ 'negspliced', 3, 10, 0, 
			    undef, undef, undef, undef, undef ],
			  [ 'pushed', 4, 10, 0, 
			    undef, undef, undef, undef, undef ] ], 'splice @, 8');

		@ret = splice @{$list->{data}}, -2;
		is_deeply (\@ret, 
			[ [ 'negspliced', 1, 10, 0, 
			    undef, undef, undef, undef, undef ],
			  [ 'negspliced', 2, 10, 0, 
			    undef, undef, undef, undef, undef ] ], 'splice @, -2');
		
		@ret = splice @{$list->{data}}, -2, 0, 
			[ 'norem', 1, 10, undef ],
			[ 'norem', 2, 10, undef ];
		is_deeply (\@ret, [], 'splice @, -2, 0, @');

		@ret = splice @{$list->{data}};
		is_deeply (\@ret, 
			[ [ 'unshifted', 4, 10, 0,
			    undef, undef, undef, undef, undef ],
			  [ 'unshifted', 3, 10, 0,
			    undef, undef, undef, undef, undef ],
			  [ 'spliced', 1, 10, 0,
			    undef, undef, undef, undef, undef ],
			  [ 'spliced', 2, 10, 0,
			    undef, undef, undef, undef, undef ],
			  [ 'norem', 1, 10, 0,
			    undef, undef, undef, undef, undef ],
			  [ 'norem', 2, 10, 0,
			    undef, undef, undef, undef, undef ],
			  [ 'pushed', 1, 10, 0,
			    undef, undef, undef, undef, undef ],
			  [ 'pushed', 2, 10, 0,
			    undef, undef, undef, undef, undef ] ], 'splice @');
};

# end exercise of SimpleList

ok(1);

# each of these should result in exceptions.
eval { Gtk2::SimpleList->new; };
ok( $@ =~ m/no columns/i, 'no args' );

eval { Gtk2::SimpleList->new ('foo'); };
ok( $@ =~ m/no columns/i, 'odd number of params' );

eval { Gtk2::SimpleList->new ('foo' => 'bar'); };
ok( $@ =~ m/unknown column type/i, 'bad column type' );

eval { Gtk2::SimpleList->new_from_treeview; };
ok( $@ =~ m/not a Gtk2::TreeView/i, 'no args triggers invalid treeview first' );

eval { Gtk2::SimpleList->new_from_treeview ('foo'); };
ok( $@ =~ m/not a Gtk2::TreeView/i, 'invalid treeview reference' );

my $tv = Gtk2::TreeView->new;
eval { Gtk2::SimpleList->new_from_treeview ($tv, 'bar'); };
ok( $@ =~ m/no columns/i, 'odd number of params' );

eval { Gtk2::SimpleList->new_from_treeview ($tv, 'bar', 'baz'); };
ok( $@ =~ m/unknown column type/i, 'unknown column type' );

eval { Gtk2::SimpleList->new_from_treeview ($tv, 'bar', 'text', 'baz'); };
ok( $@ =~ m/expecting pairs/i, 'odd number of params beyond the required first' );

$tv = undef;

__END__

Copyright (C) 2003-2005 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.
