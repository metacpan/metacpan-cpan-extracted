package Geo::Vector::Layer::Dialogs::Feature;
# @brief A dialog to create or edit a Geo::Vector::Feature

use strict;
use warnings;
use Carp;
use Glib qw/TRUE FALSE/;
use Gtk2::Ex::Geo::Dialogs qw/:all/;
use Geo::Vector::Feature;
use Geo::Vector::Layer::Dialogs qw/:all/;

## @ignore
sub open {
    my($self, $gui) = @_;

    # bootstrap:
    my($dialog, $boot) = $self->bootstrap_dialog
	($gui, 'feature_dialog', "Create a new feature to layer ".$self->name,
	 {
	     feature_dialog => [delete_event => \&close_feature_dialog, [$self, $gui]],
	     feature_cancel_button => [clicked => \&close_feature_dialog, [$self, $gui]],
	     feature_ok_button => [clicked => \&new_feature, [$self, $gui]],
	 },
	 [
	  'feature_class_comboboxentry'
	 ]
	);
    
    if ($boot) {
    }

    my $combo = $dialog->get_widget('feature_class_comboboxentry');
    my $model = $combo->get_model();
    $model->clear;
    #for my $class ('Feature') {
	#$model->set($model->append, 0, $class);
    #}
    $combo->child->set_text('Feature');
    
    return $dialog->get_widget('feature_dialog');
}

##@ignore
sub close_feature_dialog {
    my($self, $gui);
    for (@_) {
	next unless ref eq 'ARRAY';
	($self, $gui) = @{$_};
    }
    $self->hide_dialog('feature_dialog');
    1;
}

##@ignore
sub new_feature {
    my($self, $gui);
    for (@_) {
	next unless ref eq 'ARRAY';
	($self, $gui) = @{$_};
    }
    my $class = get_value_from_combo($self->{feature_dialog}, 'feature_class_comboboxentry');
    my $feature = Geo::Vector::Feature->new(class => $class);
    $self->feature($feature);
    $self->select(with_id => [$feature->FID]);
    $self->open_features_dialog($gui);
    $self->hide_dialog('feature_dialog');
    1;
}

1;
