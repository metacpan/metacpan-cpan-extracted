use Gtk;
use Tie::Array;
use strict;

=head1 NAME

Gtk::CListModel - A simple data model with Gtk::Clist views

=head1 SINOPSYS

	my $model = tie @data, 'Gtk::CListModel', 
		titles => ["Fruit", "Price", "Quantity"];
	# all data manipulation is done on @data now
	push @data, ["Oranges", 5, 16];
	# Create a view (a Gtk::Clist widget) to represent the data
	# Include only some of the data in the view (fruit type and price)
	# Also, do not include fruits that cost more than 6 price units.
	my $clist = $model->create_view('main', 
		titles => ['Fruit', 'Price'],
		filter => sub {$_[1] > 6? () : @_});
	
=head1 DESCRIPTION

Gtk::CListModel lets you keep your data in a perl array and easily create
a numer of different views on that data using Gtk::CList widgets.
The views can show only some of the columns, or a subset of the data or
even munge the data with user-defined filters.

All the data manipulations will be performed on a tied array and the changes
will be propagated to the views created for that data.

To create the model use C<tie>:

	my $model = tie @data, 'Gtk::CListModel', 
		titles => ["head1", "head2",...];

The C<titles> attribute should be an array reference with the titles of the
columns of data. They will be used also for the default titles in the views.

You can also provide the initial data using the C<data> attribute. Remember
that the data elements you insert and retreive from the @data array are
array references with as many items as the columns in the model. The order
is the one defined by the C<titles> attribute.

Later you can manipulate the @data array with the usual perl array operators, push, 
splice and so on.

=head1 METHODS

=over 2

=cut

package Gtk::CListModel;

@Gtk::CListModel::ISA = qw(Tie::Array);

sub TIEARRAY {
	my $class = shift;
	my $self = {@_};
	$self->{data} = [] unless $self->{data};
	die "Need titles\n" unless $self->{titles};
	return bless $self, $class;
}

sub FETCH {
	my ($self, $index) = @_;
	my $result = $self->{data}->[$index];
	# warn "FETCH($index) -> @$result\n";
	return $result;
}

sub FETCHSIZE {
	my $self = shift;
	return scalar(@{$self->{data}});
}

sub STORE {
	my ($self, $index, $data) = @_;
	die "Columns in data is different from columns in model" if @$data != @{$self->{titles}};
	my $result = $self->{data}[$index] = $data;
	# warn "STORE($index) -> @$result\n";
	foreach my $v (values %{$self->{views}}) {
		my $view = $v->[0];
		my @d = @$result;
		my @map = @{$v->[2]};
		my $i = 0;
		my $rindex = $index;
		if (exists $view->{_filter}) {
			@d = $view->{_filter}->(@d[@map]);
		} else {
			@d = @d[@map];
		}
		for ($i=0; $i < $view->rows; ++$i) {
			last if $index == $view->get_text($i, $view->{_hcol});
		}
		# warn "row $index remapped to clist row $i (total rows: ".$view->rows.")\n";
		$rindex = $i;
		if ($rindex >= $view->rows) { # not found: append
			# warn "append instead to $index\n";
			next unless @d;
			my $r = $view->append(@d, $index);
			if (exists $view->{_postfilter}) {
				$view->{_postfilter}->($view, $r, @d);
			}
			next;
		}
		$view->remove($rindex) unless @d;
		# warn "set on index $index\n";
		$i = 0;
		foreach my $d (@d) {
			$view->set_text($rindex, $i++, $d);
		}
		if (exists $view->{_postfilter}) {
			$view->{_postfilter}->($view, $rindex, @d);
		}
	}
	return $result;
}

sub STORESIZE {
	my $self = shift;
	my $count = shift;
	my $result = $#{$self->{data}} = $count-1;
	# warn "REMOVE $count\n";
	foreach my $v (values %{$self->{views}}) {
		my $view = $v->[0];
		$view->clear(), next unless $count;
		my ($i, $todo);
		$view->freeze;
		$todo = $view->rows - $count;
		# FIXME: optimize and handle autosort
		for ($i=0; $todo && $i < $view->rows;) {
			if ($view->get_text($i, $view->{_hcol}) >= $count) {
				$view->remove($i);
				$todo--;
			} else {
				$i++;
			}
		}
		$view->thaw;
	}
}

=item create_view ($name[, %options])

Create a Gtk::Clist widget that represents the data in the model.
The name can be used later to disconnect the view from the data.

Options can be one of the following:

=over 2

=item * titles

An array reference of the titles of the columns to display in the list
in the order they should appear in the view. The default is the titles
specified at the model creation.

=item * filter

A function that can manipulate the data just before it is inserted
in the Gtk::CList. The function will receive the data and can either
make a copy and modify the data or return an empty list. In the latter case
the data will not be added to the view or, if the corresponding row was
already present, it will be removed from the view.

=item * postfilter

A function that receives the view, the row and the data that was
just inserted/modified in the view. By default all the data is inserted
in the views as text. This filter can be used to display pixmaps, for
example or do any other kind of manipulations on the Gtk::CList row.

=back

=cut

sub create_view {
	my ($self, $name, %opts) = @_;
	my ($clist, @data, @map, @rt, $hcol, $i, @titles);

	die "View $name already exists" if exists $self->{views}{$name};

	@titles = @{$opts{titles}} if exists $opts{titles};
	@titles = @{$self->{titles}} unless @titles;
	$clist = new_with_titles Gtk::CList (@titles, '_hidden');
	$hcol = scalar(@titles);
	$clist->set_column_visibility($hcol, 0);
	$clist->set_name($name);
	$clist->{_hcol} = $hcol;
	$clist->{_filter} = $opts{filter} if exists $opts{filter};
	$clist->{_postfilter} = $opts{postfilter} if exists $opts{postfilter};

	@data = @{$self->{data}};
	# maps column names to indexes
	@rt = @{$self->{titles}};
	TITLE: foreach my $t (@titles) {
		for ($i=0; $i < @rt; ++$i) {
			push (@map, $i),next TITLE if $t eq $rt[$i];
		}
		die "Title $t not present in model";
	}
	$i = 0;
	foreach my $d (@data) {
		my @d = @$d;
		if (exists $clist->{_filter}) {
			@d = $clist->{_filter}->(@d[@map]);
		} else {
			@d = @d[@map];
		}
		$i++,next unless @d;
		my $r = $clist->append(@d, $i);
		if (exists $clist->{_postfilter}) {
			$clist->{_postfilter}->($clist, $r, @d);
		}
		$i++;
	}
	$self->{views}->{$name} = [$clist, [@titles], [@map]];
	return $clist;
}

=item remove_view ($name)

Disconnect the named view from the data. The current data displayed in the
view will not be affected, but changes in the model will not
propagate to this view anymore.

=cut

sub remove_view {
	my ($self, $name) = @_;
	$name = $name->get_name if ref $name; # can be the widget itself
	delete $self->{views}->{$name};
}

=item map_row ($clist, $row)

Get the index in the data array cooresponding to the row
displayed in the Gtk::CList widget.

=cut

sub map_row {
	my ($self, $clist, $row) = @_;
	return $clist->get_text($row, $clist->{_hcol});
}

=pod

=back

=head1 AUTHOR

Molaro Paolo lupus@debian.org

=cut

1;

