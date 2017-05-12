package Geo::Raster::Layer::Dialogs::Properties::libral;
# @brief 

use strict;
use warnings;
use Carp;
use Glib qw/TRUE FALSE/;
use Gtk2::Ex::Geo::Dialogs qw/:all/;

## @ignore
sub open {
    my($self, $gui) = @_;

    # bootstrap:
    my($dialog, $boot) = $self->bootstrap_dialog
	($gui, 'libral_properties_dialog', "Properties of ".$self->name,
	 {
	     libral_properties_dialog => [delete_event => \&cancel_libral_properties, [$self, $gui]],
	     libral_properties_apply_button => [clicked => \&apply_libral_properties, [$self, $gui, 0]],
	     libral_properties_cancel_button => [clicked => \&cancel_libral_properties, [$self, $gui]],
	     libral_properties_ok_button => [clicked => \&apply_libral_properties, [$self, $gui, 1]],
	 });

    $self->{backup}->{name} = $self->name;
    $self->{backup}->{alpha} = $self->alpha;
    $self->{backup}->{nodata_value} = $self->nodata_value;
    my @world = $self->world();
    $self->{backup}->{world} = \@world;
    $self->{backup}->{cell_size} = $self->cell_size();

    $dialog->get_widget('libral_name_entry')->set_text($self->name);
    $dialog->get_widget('libral_alpha_spinbutton')->set_value($self->alpha);

    my @size = $self->size();
    $dialog->get_widget('libral_size_label')->set_text("@size");

    $dialog->get_widget('libral_min_x_entry')->set_text($world[0]);
    $dialog->get_widget('libral_min_y_entry')->set_text($world[1]);
    $dialog->get_widget('libral_max_x_entry')->set_text($world[2]);
    $dialog->get_widget('libral_max_y_entry')->set_text($world[3]);

    $dialog->get_widget('libral_cellsize_entry')->set_text($self->cell_size());

    my $nodata = $self->nodata_value();
    $nodata = '' unless defined $nodata;
    $dialog->get_widget('libral_nodata_entry')->set_text($nodata);

    @size = $self->value_range();
    my $text = defined $size[0] ? "@size" : "not available";
    $dialog->get_widget('libral_minmax_label')->set_text($text);

    return $dialog->get_widget('libral_properties_dialog');
}

##@ignore
sub apply_libral_properties {
    my($self, $gui, $close) = @{$_[1]};
    my $dialog = $self->{libral_properties_dialog};

    eval {
	my $name = $dialog->get_widget('libral_name_entry')->get_text;
	$self->name($name);
	my $alpha = $dialog->get_widget('libral_alpha_spinbutton')->get_value_as_int;
	$self->alpha($alpha);

	my @world;
	$world[0] = get_number_from_entry($dialog->get_widget('libral_min_x_entry'));
	$world[1] = get_number_from_entry($dialog->get_widget('libral_min_y_entry'));
	$world[2] = get_number_from_entry($dialog->get_widget('libral_max_x_entry'));
	$world[3] = get_number_from_entry($dialog->get_widget('libral_max_y_entry'));
	my $cell_size = get_number_from_entry($dialog->get_widget('libral_cellsize_entry'));
    
	my ($minX,$minY) = ($world[0], $world[1]);
	my ($maxX,$maxY) = ($world[2], $world[3]);
    
	for ($minX,$minY,$maxX,$maxY,$cell_size) {
	    $_ = undef if /^\s*$/;
	}
    
	$self->world(minX=>$minX, minY=>$minY, maxX=>$maxX, maxY=>$maxY, cell_size=>$cell_size);
	
	my $nodata = get_number_from_entry($dialog->get_widget('libral_nodata_entry'));
	$self->nodata_value($nodata);
    };
    $gui->message("$@") if $@;

    $self->hide_dialog('libral_properties_dialog') if $close;
    $gui->set_layer($self);
    $gui->{overlay}->render;
}

##@ignore
sub cancel_libral_properties {
    my($self, $gui);
    for (@_) {
	next unless ref CORE::eq 'ARRAY';
	($self, $gui) = @{$_};
    }

    $self->alpha($self->{backup}->{alpha});
    $self->name($self->{backup}->{name});
    $self->world( minX => $self->{backup}->{world}->[0], 
		  minY => $self->{backup}->{world}->[1],
		  cell_size => $self->{backup}->{cell_size} );
    $self->nodata_value($self->{backup}->{nodata});
    $self->hide_dialog('libral_properties_dialog');
    $gui->set_layer($self);
    $gui->{overlay}->render;
    1;
}
1;
