package Gtk2::Ex::Geo::Dialogs::Labeling;
# @brief 

use strict;
use warnings;
use Carp;
use Glib qw/TRUE FALSE/;

# labels dialog

sub open {
    my($self, $gui) = @_;

    my $dialog = $self->bootstrap_dialog
	($gui, 'labels_dialog', "Labels for ".$self->name,
	 {
	     labels_dialog => [delete_event => \&cancel_labels, [$self, $gui]],
	     labels_font_button => [clicked => \&labels_font, [$self, $gui, 0]],
	     labels_color_button => [clicked => \&labels_color, [$self, $gui, 0]],
	     apply_labels_button => [clicked => \&apply_labels, [$self, $gui, 0]],
	     cancel_labels_button => [clicked => \&cancel_labels, [$self, $gui]],
	     ok_labels_button => [clicked => \&apply_labels, [$self, $gui, 1]],
	 });

    # backup

    my $labeling = $self->{backup}->{labeling} = $self->labeling;
    
    # set up controllers

    my $schema = $self->schema;

    my $combo = $dialog->get_widget('labels_field_combobox');
    my $model = $combo->get_model;
    $model->clear;
    my $i = 0;
    my $active = 0;
    $model->set ($model->append, 0, 'No Labels');
    $active = $i if $labeling->{field} eq 'No Labels';
    $i++;
    for my $fname ($schema->field_names) {
	$model->set ($model->append, 0, $fname);
	$active = $i if $labeling->{field} eq $fname;
	$i++;
    }
    $combo->set_active($active);

    $combo = $dialog->get_widget('labels_placement_combobox');
    $model = $combo->get_model;
    $model->clear;
    $i = 0;
    $active = 0;
    my $h = \%Gtk2::Ex::Geo::Layer::LABEL_PLACEMENT;
    for my $e (sort {$h->{$a} <=> $h->{$b}} keys %$h) {
	$model->set ($model->append, 0, $e);
	$active = $i if $labeling->{placement} eq $e;
	$i++;
    }
    $combo->set_active($active);

    $dialog->get_widget('labels_font_label')->set_text($labeling->{font});
    $dialog->get_widget('labels_color_label')->set_text("@{$labeling->{color}}");
    $dialog->get_widget('labels_min_size_entry')->set_text($labeling->{min_size});
    $dialog->get_widget('labels_incremental_checkbutton')->set_active($labeling->{incremental});
    
    return $dialog->get_widget('labels_dialog');
}

##@ignore
sub apply_labels {
    my($self, $gui, $close) = @{$_[1]};
    my $dialog = $self->{labels_dialog};

    my $labeling = {};

    my $combo = $dialog->get_widget('labels_field_combobox');
    my $model = $combo->get_model;
    my $iter = $model->get_iter_from_string($combo->get_active());
    $labeling->{field} = $model->get_value($iter);

    $combo = $dialog->get_widget('labels_placement_combobox');
    $model = $combo->get_model;
    $iter = $model->get_iter_from_string($combo->get_active());
    $labeling->{placement} = $model->get_value($iter);

    $labeling->{min_size} = $dialog->get_widget('labels_min_size_entry')->get_text;
    $labeling->{font} = $dialog->get_widget('labels_font_label')->get_text;
    @{$labeling->{color}} = split(/ /, $dialog->get_widget('labels_color_label')->get_text);
    $labeling->{min_size} = $dialog->get_widget('labels_min_size_entry')->get_text;
    $labeling->{incremental} = $dialog->get_widget('labels_incremental_checkbutton')->get_active();

    $self->labeling($labeling);

    $self->hide_dialog('labels_dialog') if $close;
    $gui->set_layer($self);
    $gui->{overlay}->render;
}

##@ignore
sub cancel_labels {
    my($self, $gui);
    for (@_) {
	next unless ref eq 'ARRAY';
	($self, $gui) = @{$_};
    }

    $self->labeling($self->{labeling_backup});
    $self->hide_dialog('labels_dialog');
    $gui->set_layer($self);
    $gui->{overlay}->render;
    1;
}

##@ignore
sub labels_font {
    my($self, $gui) = @{$_[1]};
    my $font_chooser = Gtk2::FontSelectionDialog->new ("Select font for the labels");
    my $font_name = $self->{labels_dialog}->get_widget('labels_font_label')->get_text;
    $font_chooser->set_font_name($font_name);
    if ($font_chooser->run eq 'ok') {
	$font_name = $font_chooser->get_font_name;
	$self->{labels_dialog}->get_widget('labels_font_label')->set_text($font_name);
    }
    $font_chooser->destroy;
}

##@ignore
sub labels_color {
    my($self, $gui) = @{$_[1]};
    my @color = split(/ /, $self->{labels_dialog}->get_widget('labels_color_label')->get_text);
    my $color_chooser = Gtk2::ColorSelectionDialog->new('Choose color for the label font');
    my $s = $color_chooser->colorsel;    
    $s->set_has_opacity_control(1);
    my $c = Gtk2::Gdk::Color->new($color[0]*257,$color[1]*257,$color[2]*257);
    $s->set_current_color($c);
    $s->set_current_alpha($color[3]*257);
    if ($color_chooser->run eq 'ok') {
	$c = $s->get_current_color;
	@color = (int($c->red/257),int($c->green/257),int($c->blue/257));
	$color[3] = int($s->get_current_alpha()/257);
	$self->{labels_dialog}->get_widget('labels_color_label')->set_text("@color");
    }
    $color_chooser->destroy;
}

1;
