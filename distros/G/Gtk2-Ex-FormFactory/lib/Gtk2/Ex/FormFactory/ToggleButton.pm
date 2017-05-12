package Gtk2::Ex::FormFactory::ToggleButton;

use strict;

use base qw( Gtk2::Ex::FormFactory::Widget );

sub get_type    { "toggle_button"   }
sub has_label	{ 1		    }

sub get_true_label		{ shift->{true_label}		        }
sub get_false_label		{ shift->{false_label}	    		}
sub get_stock                   { shift->{stock}                        }
sub get_image                   { shift->{image}                        }
sub get_clicked_hook            { shift->{clicked_hook}                 }

sub set_true_label		{ shift->{true_label}		= $_[1]	}
sub set_false_label		{ shift->{false_label}		= $_[1]	}
sub set_stock                   { shift->{stock}                = $_[1] }
sub set_image                   { shift->{image}                = $_[1] }
sub set_clicked_hook            { shift->{clicked_hook}         = $_[1] }

sub new {
	my $class = shift;
	my %par = @_;
	my  ($true_label, $false_label, $label, $clicked_hook) =
        @par{'true_label','false_label','label','clicked_hook'};
        my  ($stock, $image) =
        @par{'stock','image'};

	my $self = $class->SUPER::new(@_);
	
        $true_label  = "Yes" if !defined($true_label)  && !$stock;
        $false_label = "No"  if !defined($false_label) && !$stock;
        $label       = $false_label unless defined $label;
        
	$self->set_label($label);
	$self->set_true_label($true_label);
	$self->set_false_label($false_label);
	$self->set_stock($stock);
	$self->set_image($image);
	$self->set_clicked_hook($clicked_hook);

	return $self;
}

sub object_to_widget {
	my $self = shift;

	$self->get_gtk_widget->set_active($self->get_object_value);

	$self->update_button_label;

	1;
}

sub widget_to_object {
	my $self = shift;
	
	$self->set_object_value ($self->get_gtk_widget->get_active ? 1 : 0);
	
	1;
}

sub backup_widget_value {
	my $self = shift;
	
	$self->set_backup_widget_value ($self->get_gtk_widget->get_active ? 1 : 0);
	
	1;
}

sub restore_widget_value {
	my $self = shift;
	
	$self->get_gtk_widget->set_active($self->get_backup_widget_value);
	
	1;
}

sub get_widget_check_value {
	$_[0]->get_gtk_widget->get_active;
}

sub connect_changed_signal {
	my $self = shift;

	$self->get_gtk_widget->signal_connect_after (
	  toggled => sub {
	  	$self->update_button_label;
	  	$self->widget_value_changed;
	  },
	);
	
	1;
}

sub update_button_label {
	my $self = shift;
	
        return if $self->get_true_label eq $self->get_false_label;

        my $gtk_widget;
        if ( $self->get_stock ) {
            my $gtk_align  = ($self->get_gtk_parent_widget->get_children)[0];
            my $gtk_hbox   = ($gtk_align->get_children)[0];
            $gtk_widget = ($gtk_hbox->get_children)[1];
        }
        else {
    	    $gtk_widget = $self->get_gtk_widget;
        }

	my $value = $self->get_gtk_widget->get_active;

    	if ( $value ) {
    	    $gtk_widget->set_label($self->get_true_label);
	} else {
	    $gtk_widget->set_label($self->get_false_label);
	}

	1;
}

1;

__END__

=head1 NAME

Gtk2::Ex::FormFactory::ToggleButton - A ToggleButton in a FormFactory framework

=head1 SYNOPSIS

  Gtk2::Ex::FormFactory::ToggleButton->new (
    true_label   => Label of the activated button,
    false_label  => Label of the deactivated button,
    stock        => Name of stock image for this button,
    clicked_hook => Coderef to called on clicking,
    image        => Filename of image to put on button,
    ...
    Gtk2::Ex::FormFactory::Widget attributes
  );

=head1 DESCRIPTION

This class implements a ToggleButton in a Gtk2::Ex::FormFactory framework.
The state of the ToggleButton is controlled by the associated application
object attribute, which should has a boolean value.

=head1 OBJECT HIERARCHY

  Gtk2::Ex::FormFactory::Intro

  Gtk2::Ex::FormFactory::Widget
  +--- Gtk2::Ex::FormFactory::ToggleButton

  Gtk2::Ex::FormFactory::Layout
  Gtk2::Ex::FormFactory::Rules
  Gtk2::Ex::FormFactory::Context
  Gtk2::Ex::FormFactory::Proxy

=head1 ATTRIBUTES

Attributes are handled through the common get_ATTR(), set_ATTR()
style accessors, but they are mostly passed once to the object
constructor and must not be altered after the associated FormFactory
was built.

=over 4

=item B<true_label> = SCALAR [optional]

Once the button is activated this label is set.

=item B<false_label> = SCALAR [optional]

Once the button is deactivated this label is set.

=item B<clicked_hook> = CODEREF [optional]

This is for convenience and connects the CODEREF to the clicked
signal of the button.

=item B<stock> = SCALAR [optional]

You may specify the name of a stock item here, which should be
added to the button, e.g. 'gtk-edit' for the standard Gtk Edit
stock item. You may combine B<stock> and B<label> arbitrarily.

=item B<image> = FILENAME [optional]

Use just this image for the button. No additional label is
applied.

=back

For more attributes refer to L<Gtk2::Ex::FormFactory::Widget>.

=head1 AUTHORS

 Jörn Reder <joern at zyn dot de>

=head1 COPYRIGHT AND LICENSE

Copyright 2004-2006 by Jörn Reder.

This library is free software; you can redistribute it and/or modify
it under the terms of the GNU Library General Public License as
published by the Free Software Foundation; either version 2.1 of the
License, or (at your option) any later version.

This library is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Library General Public License for more details.

You should have received a copy of the GNU Library General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307
USA.

=cut
