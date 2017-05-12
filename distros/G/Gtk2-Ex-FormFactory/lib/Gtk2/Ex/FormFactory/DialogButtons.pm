package Gtk2::Ex::FormFactory::DialogButtons;

use strict;

use base qw( Gtk2::Ex::FormFactory::Widget );

sub get_type { "dialog_buttons" }

sub get_buttons			{ shift->{buttons}			}
sub get_clicked_hook_before	{ shift->{clicked_hook_before}		}
sub get_clicked_hook_after	{ shift->{clicked_hook_after}		}

sub set_buttons			{ shift->{buttons}		= $_[1]	}
sub set_clicked_hook_before	{ shift->{clicked_hook_before}	= $_[1]	}
sub set_clicked_hook_after	{ shift->{clicked_hook_after}	= $_[1]	}

sub get_gtk_ok_button		{ shift->{gtk_ok_button}		}
sub get_gtk_cancel_button	{ shift->{gtk_cancel_button}		}
sub get_gtk_apply_button	{ shift->{gtk_apply_button}		}

sub set_gtk_ok_button		{ shift->{gtk_ok_button}	= $_[1]	}
sub set_gtk_cancel_button	{ shift->{gtk_cancel_button}	= $_[1]	}
sub set_gtk_apply_button	{ shift->{gtk_apply_button}	= $_[1]	}

sub new {
	my $class = shift;
	my %par = @_;
	my  ($buttons, $clicked_hook_before, $clicked_hook_after) =
	@par{'buttons','clicked_hook_before','clicked_hook_after'};
	
	my $self = $class->SUPER::new(@_);
	
	$buttons ||= { ok => 1, cancel => 1 };

	$self->set_buttons($buttons);
	$self->set_clicked_hook_before($clicked_hook_before);
	$self->set_clicked_hook_after($clicked_hook_after);
	
	return $self;
}

sub cleanup {
	my $self = shift;
	
	$self->SUPER::cleanup(@_);

	$self->set_gtk_ok_button(undef); 
	$self->set_gtk_cancel_button(undef);
	$self->set_gtk_apply_button(undef);

	1;
}


sub object_to_widget {
	my $self = shift;
	
	my $buttons;
	$buttons = $self->get_object_value if $self->get_attr;
	$buttons ||= "all";

	foreach my $button ( keys %{$self->get_buttons} ) {
		my $active = $buttons eq 'all' || $buttons->{$button};
		my $gtk_widget = $self->{"gtk_".$button."_button"};
		next if not $gtk_widget;
		if ( $self->get_inactive eq 'invisible' ) {
			if ( $active ) {
				$gtk_widget->show;
			} else {
				$gtk_widget->hide;
			}
		} else {
			$gtk_widget->set_sensitive($active);
		}
	}

	1;
}

sub cancel_button_clicked {
	my $self = shift;

	my $clicked_hook_before = $self->get_clicked_hook_before;
	my $clicked_hook_after  = $self->get_clicked_hook_after;
	my $default_handler = 1;
	$default_handler = &$clicked_hook_before("cancel")
		if $clicked_hook_before;
	return if not $default_handler;
	$self->get_form_factory->cancel;
	&$clicked_hook_after("cancel")
		if $clicked_hook_after;
	1;
}

sub apply_button_clicked {
	my $self = shift;

	my $clicked_hook_before = $self->get_clicked_hook_before;
	my $clicked_hook_after  = $self->get_clicked_hook_after;
	my $default_handler = 1;
	$default_handler = &$clicked_hook_before("apply")
		if $clicked_hook_before;
	return if not $default_handler;
	$self->get_form_factory->apply;
	&$clicked_hook_after("apply")
		if $clicked_hook_after;
	1;
}

sub ok_button_clicked {
	my $self = shift;

	my $clicked_hook_before = $self->get_clicked_hook_before;
	my $clicked_hook_after  = $self->get_clicked_hook_after;
	my $default_handler = 1;
	$default_handler = &$clicked_hook_before("ok")
		if $clicked_hook_before;
	return if not $default_handler;
	$self->get_form_factory->ok
	    if $self->get_form_factory;
	&$clicked_hook_after("ok")
		if $clicked_hook_after;

	1;
}

1;
__END__

=head1 NAME

Gtk2::Ex::FormFactory::DialogButtons - Standard Ok, Apply, Cancel Buttons

=head1 SYNOPSIS

  Gtk2::Ex::FormFactory::DialogButtons->new (
    clicked_hook_before => CODEREF,
    clicked_hook_after  => CODEREF,
    ...
    Gtk2::Ex::FormFactory::Container attributes
    Gtk2::Ex::FormFactory::Widget attributes
  );

=head1 DESCRIPTION

This class implements a typical Ok, Apply, Cancel buttonbox in
a Gtk2::Ex::FormFactory framework.

If you associate an application
object attribute the value needs to be a hash which may contain
the keys 'ok', 'apply' and 'cancel' to control the activity of
the correspondent buttons. Wheter inactive buttons should be
render insensitive or invisible is controlled by the
Gtk2::Ex::FormFactory::Widget attribute B<inactive>.

By default the following methods of the associated
Gtk2::Ex::FormFactory instance are triggered:

  Ok        Gtk2::Ex::FormFactory->ok
  Cancel    Gtk2::Ex::FormFactory->cancel
  Apply     Gtk2::Ex::FormFactory->apply

=head1 NOTES

No I<Cancel> and I<Apply> buttons are generated if the associated
Gtk2::Ex::FormFactory has the B<sync> attribute set. A synchronized
FormFactory applies all changes immediately to the underlying objects,
so there is no easy way of implementing the Apply and Cancel buttons.

You can implement these by your own e.g. by registering a copy of
your object to Gtk2::Ex::FormFactory::Context and hook into the
button clicks using the B<clicked_hook_before> attribute described
beyond.

=head1 OBJECT HIERARCHY

  Gtk2::Ex::FormFactory::Widget
  +--- Gtk2::Ex::FormFactory::DialogButtons

=head1 ATTRIBUTES

Attributes are handled through the common get_ATTR(), set_ATTR()
style accessors, but they are mostly passed once to the object
constructor and must not be altered after the associated FormFactory
was built.

=over 4

=item B<clicked_hook_before> = CODEREF("ok"|"apply"|"cancel")

Use this callback to hook into the clicked signal handler of the
buttons. Argument is the name of the button actually clicked ("ok", "apply"
or "cancel"). If the callback returns TRUE, Gtk2::Ex::FormFactory's
default handler for the button is called afterwards. Return
FALSE to prevent calling the default handler.

=item B<clicked_hook_after> = CODEREF("ok"|"apply"|"cancel")

This callback is called B<after> the default handler. This is useful
if you want to exit your program cleanly if your main dialog was
closed. First Gtk2::Ex::FormFactory closes the dialog window for you,
doing all necessary cleanup stuff. Afterward you simply call
Gtk2->main_quit to exit the program.

The callback's return value doesn't matter.

=back

For more attributes refer to Gtk2::Ex::FormFactory::Widget.

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
