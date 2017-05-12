## @class Gtk2::Ex::Geo::TreeDumper
# @brief The 'inspect' dialog
#
# From http://www.asofyet.org/muppet/software/gtk2-perl/treedumper.pl-txt
package Gtk2::Ex::Geo::TreeDumper;

use strict;
use Scalar::Util qw(blessed);
use Glib ':constants';
use Gtk2;

use base 'Gtk2::TreeView';

sub new {
    my $class = shift;
    my %args = (data => undef, @_);
    #my $self = bless Gtk2::TreeView->new, $class;
    my $self = bless {}, $class;
    $self->{tree_view} = bless Gtk2::TreeView->new, $class;
    $self->{tree_view}->insert_column_with_attributes
	(0, 'Data', Gtk2::CellRendererText->new, text => 0);
    $self->set_data ($args{data}) if exists $args{data};
    $self->set_title ($args{title});
    $self->{tree_view}->signal_connect (button_press_event => sub {
	my ($widget, $event) = @_;
	if ($event->button == 3) {
	    _do_context_menu ($widget, $event);
	    return TRUE;
	}
	return FALSE;
					});
    return $self;
}

sub _do_context_menu {
    my ($self, $event) = @_;
    my $menu = Gtk2::Menu->new;
    foreach my $method ('expand_all', 'collapse_all') {
	my $label = join ' ', map { ucfirst $_ } split /_/, $method;
	my $item = Gtk2::MenuItem->new ($label);
	$menu->append ($item);
	$item->show;
	$item->signal_connect (activate => sub {
	    $self->$method;
			       });
    }
    $menu->popup (undef, undef, undef, undef, $event->button, $event->time);
}

sub _fill_scalar {
    my ($self, $model, $parent, $name, $data) = @_;
    my $str = defined ($data) ? "$data" : "[undef]";
    $model->set ($model->append ($parent),
		 0, (defined($name) ? "$name " : ''). $str);
}

sub _fill_array {
    my ($self, $model, $parent, $name, $ref) = @_;
    my $iter = $model->append ($parent);
    my $refstr = "$ref" . (@$ref ? '' : ' [empty]');
    $model->set ($iter, 0, defined($name) ? "$name $refstr" : "$refstr");
    for (my $i = 0; $i < @$ref; $i++) {
	_fill_recursive ($self, $model, $iter, "[$i] =", $ref->[$i]);
    }
}

sub _fill_hash {
    my ($self, $model, $parent, $name, $ref) = @_;
    my $iter = $model->append ($parent);
    my $refstr = "$ref" . (%$ref ? '' : ' [empty]');
    $model->set ($iter, 0, defined($name) ? "$name $refstr" : "$refstr");
    foreach my $key (sort keys %$ref) {
	_fill_recursive ($self, $model, $iter, "$key =>", $ref->{$key});
    }
}

sub _fill_recursive {
    my ($self, $model, $parent, $name, $ref) = @_;
    return if ($name and $name eq 'buffer =>');
    if (blessed($ref) and $ref->isa('Graph')) {
	_fill_scalar ($self, $model, $parent, $name, 'Graph');
    } elsif (UNIVERSAL::isa $ref, 'HASH') {
	_fill_hash ($self, $model, $parent, $name, $ref);
    } elsif (UNIVERSAL::isa $ref, 'ARRAY') {
	_fill_array ($self, $model, $parent, $name, $ref);
    } else {
	_fill_scalar ($self, $model, $parent, $name, $ref);
    }
}

sub set_data {
    my ($self, $data) = @_;   
    my $model = Gtk2::TreeStore->new ('Glib::String');    
    _fill_recursive ($self, $model, undef, undef, $data);    
    $self->{tree_view}->set_model ($model);
}

sub set_title {
    my ($self, $title) = @_;
    if (defined $title and length $title) {
	$self->{tree_view}->get_column (0)->set_title ($title);
	$self->{tree_view}->set_headers_visible (TRUE);
    } else {
	$self->{tree_view}->set_headers_visible (FALSE);
    }
}

1;
