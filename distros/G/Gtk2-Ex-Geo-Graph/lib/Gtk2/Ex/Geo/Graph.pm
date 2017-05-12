package Gtk2::Ex::Geo::Graph;

=pod

=head1 NAME

Gtk2::Ex::Geo::Graph - Geospatial graphs for Gtk2::Ex::Geo

=cut

use strict;
use warnings;
use Carp;
use File::Spec;
use Graph;
use Glib qw/TRUE FALSE/;
use Gtk2;
use Gtk2::Ex::Geo;
use Gtk2::Ex::Geo::Dialogs qw/:all/;

our @ISA = qw(Gtk2::Ex::Geo::Layer);

our $VERSION = 0.01;

use vars qw/$NODE_RAY/;

$NODE_RAY = 7;

sub registration {
    my $dialogs;
    my $commands = [
	tag => 'graph',
	label => 'Graph',
	tip => 'Graph commands.',
	{
	    label => 'New',
	    tip => 'Create a new empty graph',
	    sub => sub {
		my(undef, $gui) = @_;
		my $layer = Gtk2::Ex::Geo::Graph->new( name => 'graph' );
		$gui->add_layer($layer);
	    }
	},
	{
	    label => 'Open...',
	    tip => 'Read a graph from a file',
	    sub => sub {
		my(undef, $gui) = @_;
		my $filename = file_chooser('Open a saved graph', 'open');
		if ($filename) {
		    my($volume, $directories, $file) = File::Spec->splitpath($filename);
		    my @file = split /\./, $file;
		    my $layer = Gtk2::Ex::Geo::Graph->new( name => $file[0] );
		    $layer->open($filename);
		    $gui->add_layer($layer);
		}
	    }
	}
	];
    return { dialogs => $dialogs, commands => $commands };
}

sub new {
    my($package, %params) = @_;
    my $self = Gtk2::Ex::Geo::Layer->new(%params);
    $self->{graph} = Graph->new;
    $self->{index} = 1;
    return bless $self => $package;
}

sub close {
    my($self, $gui) = @_;
    $self->lost_focus($gui);
    $self->SUPER::close(@_);
}

sub save {
    my($self, $filename) = @_;
    open(my $fh, '>', $filename) or croak $!;
    for my $v ($self->{graph}->vertices) {
	print $fh "$v->{index}\t$v->{point}->{X}\t$v->{point}->{Y}\n";
    }
    print $fh "edges\n";
    for my $e ($self->{graph}->edges) {
	my($u, $v) = @$e;
	my $w = $self->{graph}->get_edge_weight($u, $v);
	print $fh "$u->{index}\t$v->{index}\t$w\n";
    }
    CORE::close $fh;
}

sub open {
    my($self, $filename) = @_;
    open(my $fh, '<', $filename) or croak $!;
    $self->{graph} = Graph->new;
    my $vertex = 1;
    my %vertices;
    while (<$fh>) {
	chomp;
	my @l = split /\t/;
	$vertex = 0, next if $l[0] eq 'edges';
	if ($vertex) {
	    my $v = { index => $l[0],
		      point => Geo::OGC::Point->new($l[1], $l[2]) };
	    $vertices{$l[0]} = $v;
	    $self->{graph}->add_vertex($v);
	} else {
	    my $u = $vertices{$l[0]};
	    my $v = $vertices{$l[1]};
	    $self->{graph}->add_weighted_edge($u, $v, $l[2]);
	}
    }
    CORE::close $fh;
}

sub world {
    my $self = shift;
    my($minx, $miny, $maxx, $maxy);
    for my $v ($self->{graph}->vertices) {
	unless (defined $minx) {
	    $maxx = $minx = $v->{point}->{X};
	    $maxy = $miny = $v->{point}->{Y};
	} else {
	    $minx = min($minx, $v->{point}->{X});
	    $miny = min($miny, $v->{point}->{Y});
	    $maxx = max($maxx, $v->{point}->{X});
	    $maxy = max($maxy, $v->{point}->{Y});
	}
    }
    return ($minx, $miny, $maxx, $maxy) if defined $minx;
    return ();
}

sub render {
    my($self, $pb, $cr, $overlay, $viewport) = @_;

    my @s = @{$self->selected_features()};
    my %selected = map { (ref($_) eq 'HASH' ? $_ : $_->[0].$_->[1] ) => 1 } @s;

    my $a = $self->alpha/255.0;
    my @color = $self->single_color;
    for (@color) {
	$_ /= 255.0;
	$_ *= $a;
    }

    $cr->set_line_width(1);
    $cr->set_source_rgba(@color);
    
    for my $v ($self->{graph}->vertices) {
	my @p = $overlay->point2surface($v->{point}->{X}, $v->{point}->{Y});
	for (@p) {
	    $_ = bounds($_, -10000, 10000);
	}
	$cr->arc(@p, $NODE_RAY, 0, 2*3.1415927);
	$cr->fill_preserve if $selected{$v};
	$cr->stroke;
    }
    for my $e ($self->{graph}->edges) {
	my($u, $v) = @$e;
	my @p = $overlay->point2surface($u->{point}->{X}, $u->{point}->{Y});
	my @q = $overlay->point2surface($v->{point}->{X}, $v->{point}->{Y});
	for (@p, @q) {
	    $_ = bounds($_, -10000, 10000);
	}
	$cr->move_to(@p);
	$cr->line_to(@q);
	$cr->set_line_width(3) if $selected{$u.$v};
	$cr->stroke;
	$cr->set_line_width(1) if $selected{$u.$v};
    }
    
}

sub menu_items {
    my($self) = @_;
    my @items;
    push @items, ( 'S_ave...' => sub {
	my($self, $gui) = @{pop()};
	my $filename = file_chooser('Open a saved graph', 'save');	
	if ($filename) {
	    if (-e $filename) {
		my $dialog = Gtk2::MessageDialog->new(undef, 'destroy-with-parent',
						      'question',
						      'yes_no',
						      "Overwrite existing $filename?");
		my $ret = $dialog->run;
		$dialog->destroy;
		return if $ret eq 'no';
	    }
	    $self->save($filename);
	}});
    push @items, ( 'Nodes...' => \&open_nodes_dialog );
    push @items, ( 'Links...' => \&open_links_dialog );
    push @items, ( 1 => 0 );
    push @items, $self->SUPER::menu_items();    
    return @items;
}

sub open_nodes_dialog {
    my($self, $gui) = @{pop()};
    my $dialog = Gtk2::Dialog->new('Nodes of '.$self->name, undef, [], 'gtk-close' => 'close');
    $dialog->set_default_size(600, 500);
    $dialog->set_modal(0);
    $dialog->signal_connect(response => sub { 
	$_[0]->destroy;
	delete $self->{nodes_view};
	delete $self->{nodes_dialog} }, $self);
    my $model = Gtk2::TreeStore->new(qw/Glib::Int/);
    my $view = Gtk2::TreeView->new();
    my $selection = $view->get_selection;
    $selection->set_mode('multiple');
    $selection->signal_connect( changed => \&nodes_selected, [$self, $gui] );
    $view->set_model($model);
    my $i = 0;
    my @columns = qw /id/;
    for my $column (@columns) {
	my $cell = Gtk2::CellRendererText->new;
	my $col = Gtk2::TreeViewColumn->new_with_attributes($column, $cell, text => $i++);
	$view->append_column($col);
    }
    my @v;
    for my $v ($self->{graph}->vertices) {
	push @v, $v;
    }
    for my $v (sort {$a->{index} <=> $b->{index}} @v) {
	my $iter = $model->append(undef);
	$model->set($iter, 0, $v->{index});
    }
    my $list = Gtk2::ScrolledWindow->new();
    $list->set_policy("never", "automatic");
    $list->add($view);
    $dialog->get_content_area()->add($list);
    $dialog->show_all;
    $self->{nodes_dialog} = $dialog;
    $self->{nodes_view} = $view;
}

sub nodes_selected {
    my($selection) = @_;
    my($self, $gui) = @{pop()};
    return if $self->{ignore_cursor_change};
    my $selected = get_selected_from_selection($selection);
    $self->select();
    for my $v ($self->{graph}->vertices) {
	push @{$self->selected_features}, $v if $selected->{$v->{index}};
    }
    $gui->{overlay}->render;
}

sub open_links_dialog {
    my($self, $gui) = @{pop()};
    my $dialog = Gtk2::Dialog->new('Nodes of '.$self->name, undef, [], 'gtk-close' => 'close');
    $dialog->set_default_size(600, 500);
    $dialog->set_transient_for(undef);
    $dialog->signal_connect(response => sub { $_[0]->destroy });
    $dialog->show_all;
}

sub bounds {
    $_[0] < $_[1] ? $_[1] : ($_[0] > $_[2] ? $_[2] : $_[0]);
}

sub got_focus {
    my($self, $gui) = @_;
    my $o = $gui->{overlay};
    $self->{_tag1} = $o->signal_connect(
	drawing_changed => \&drawing_changed, [$self, $gui]);
    $self->{_tag2} = $o->signal_connect(
	new_selection => \&new_selection, [$self, $gui]);
    $self->{_tag3} = $o->signal_connect(
	key_press_event => \&key_pressed, [$self, $gui]);
    $gui->set_interaction_mode('Draw');
    $gui->set_interaction_geometry('Line');
    $o->{show_selection} = 0;
}

sub lost_focus {
    my($self, $gui) = @_;
    for (qw/_tag1 _tag2 _tag3/) {
	$gui->{overlay}->signal_handler_disconnect($self->{$_}) if $self->{$_};
	delete $self->{$_};
    }
}

sub drawing_changed {
    my($self, $gui) = @{$_[1]};
    my $drawing = $gui->{overlay}->{drawing};
    if ($drawing->isa('Geo::OGC::LineString') and $drawing->NumPoints == 2) {
	my $v1 = $self->find_vertex($gui, $drawing->StartPoint);
	my $v2 = $self->find_vertex($gui, $drawing->EndPoint);
	unless ($v1) {
	    $v1 = { point => $drawing->StartPoint->Clone };
	    $v1->{index} = $self->{index}++;
	    $self->{graph}->add_vertex($v1);
	}
	unless ($v2) {
	    $v2 = { point => $drawing->EndPoint->Clone };
	    $v2->{index} = $self->{index}++;
	    $self->{graph}->add_vertex($v2);
	}
	my $w = $drawing->Length;
	$self->{graph}->add_weighted_edge($v1, $v2, $w);
    }
    delete $gui->{overlay}->{drawing};
    $gui->{overlay}->render;
}

sub find_vertex {
    my($self, $gui, $point) = @_;
    my $d = -1;
    my $c;
    for my $v ($self->{graph}->vertices) {
	my $e = $point->Distance($v->{point});
	($c, $d) = ($v, $e) if $d < 0 or $e < $d;
    }
    return $c if $d/$gui->{overlay}->{pixel_size} < $NODE_RAY;
}

sub find_edge {
    my($self, $gui, $point) = @_;
    my $d = -1;
    my $c;
    for my $e ($self->{graph}->edges) {
	my $e2 = Geo::OGC::LineString->new;
	$e2->AddPoint($e->[0]->{point});
	$e2->AddPoint($e->[1]->{point});
	my $d2 = $point->Distance($e2);
	($c, $d) = ($e, $d2) if $d < 0 or $d2 < $d;
    }
    return $c if $d/$gui->{overlay}->{pixel_size} < $NODE_RAY;
}

sub new_selection {
    my($self, $gui) = @{$_[1]};
    my $selection = $gui->{overlay}->{selection};
    $self->select();
    $self->_select($gui, $selection);
    if ($self->{nodes_dialog}) {
	my $view = $self->{nodes_view};
	my $model = $view->get_model;
	my $selection = $view->get_selection;
	$self->{ignore_cursor_change} = 1;
	$selection->unselect_all;
	for my $v (@{$self->selected_features}) {
	    next if ref($v) eq 'ARRAY';
	    $model->foreach( \&select_in_selection, [$selection, $v->{index}]);
	    
	}
	delete $self->{ignore_cursor_change};
    }
    $gui->{overlay}->render;
}

sub select_in_selection {
    my($selection, $index) = @{pop()};
    my($model, $path, $iter) = @_;
    my($x) = $model->get($iter);
    if ($x == $index) {
	$selection->select_iter($iter);
	return 1;
    }
}

sub _select {
    my($self, $gui, $selection) = @_;
    if ($selection->isa('Geo::OGC::GeometryCollection')) {
	for my $g (@{$selection->{Geometries}}) {
	    $self->_select($gui, $g);
	}
    } elsif ($selection->isa('Geo::OGC::Point')) {
	my $v = $self->find_vertex($gui, $selection);
	push @{$self->selected_features}, $v if $v;
	unless ($v) {
	    my $e = $self->find_edge($gui, $selection);
	    push @{$self->selected_features}, $e if $e;
	}
    }
}

sub key_pressed {
    my($overlay, $event, $user) = @_;
    my $key = $event->keyval;
    return unless $key == $Gtk2::Gdk::Keysyms{Delete};
    my($self, $gui) = @{$user};
    my @v;
    my @e;
    for my $v (@{$self->selected_features()}) {
	if (ref $v eq 'HASH') {
	    push @v, $v;
	} else {
	    push @e, ($v->[0], $v->[1]);
	}
    }
    $self->{graph}->delete_vertices(@v);
    $self->{graph}->delete_edges(@e);
    $self->select();
    $gui->{overlay}->render;
}

sub open_properties_dialog {
    my($self, $gui) = @_;
}

sub shortest_path {
    my($self) = @_;
    my($u, $v);
    for my $x (@{$self->selected_features()}) {
	next unless ref $x eq 'HASH';
	$u = $x,next unless $u;
	$v = $x unless $v;
	last;
    }
    $self->select();
    return unless $u and $v;
    print STDERR "sp $u->$v\n";
    my @path = $self->{graph}->SP_Dijkstra($u, $v);
    print STDERR "sp @path\n";
    $self->selected_features(\@path);
    #$gui->{overlay}->render;
}

## @ignore
sub min {
    $_[0] > $_[1] ? $_[1] : $_[0];
}

## @ignore
sub max {
    $_[0] > $_[1] ? $_[0] : $_[1];
}

1;
