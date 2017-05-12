package Gtk2::Ex::Entry::Pango;

=head1 NAME

Gtk2::Ex::Entry::Pango - Gtk2 Entry that accepts Pango markup.

=head1 SYNOPSIS

	use Gtk2::Ex::Entry::Pango;
	
	
	# You can use any method defined in Gtk2::Entry or set_markup()
	my $entry = Gtk2::Ex::Entry::Pango->new();
	$entry->set_markup('<i>Pan</i><b>go</b> is <span color="red">fun</span>');
	
	
	# Create a simple search field
	my $search = Gtk2::Ex::Entry::Pango->new();
	$search->set_empty_markup("<span color='grey' size='smaller'>Search...</span>");
	
	
	# Realtime validation - accept only ASCII letters
	my $validation = Gtk2::Ex::Entry::Pango->new();
	$validation->signal_connect(changed => sub {
		my $text = $validation->get_text;
	
		# Validate the entry's text
		if ($text =~ /^[a-z]*$/) {
			return;
		}
	
		# Mark the string as being erroneous
		my $escaped = Glib::Markup::escape_text($text);
		$validation->set_markup("<span underline='error' underline_color='red'>$escaped</span>");
		$validation->signal_stop_emission_by_name('changed');
	});

=head1 HIERARCHY

C<Gtk2::Ex::Entry::Pango> is a subclass of L<Gtk2::Entry>.

	Glib::Object
	+----Glib::InitiallyUnowned
	     +----Gtk2::Object
	          +----Gtk2::Widget
	               +----Gtk2::Entry
	                    +----Gtk2::Ex::Entry::Pango

=head1 DESCRIPTION

C<Gtk2::Ex::Entry::Pango> is a C<Gtk2::Entry> that can accept Pango markup for
various purposes (for more information about Pango text markup language see 
L<http://library.gnome.org/devel/pango/stable/PangoMarkupFormat.html>).

The widget allows Pango markup to be used for input as an alternative to
C<set_text> or for setting a default value when the widget is empty. The default
value when empty is ideal for standalone text entries that have no accompanying
label (such as a text field for a search).

This widget allows for the text data to be entered either through the normal
methods provided by C<Gtk2::Entry> or to use the method L</set_markup>. It's
possible to switch between two methods for applying the text. The standard
C<Gtk2::Entry> methods will always apply a text without styles while
C<set_markup()> will use a style.

The widget C<Gtk2::Ex::Entry::Pango> keeps track of which style to apply by
listening to the signal I<changed>. This has some important consequences. If an
instance needs to provide it's own I<changed> listener that calls
C<set_markup()> then the signal I<changed> has to be stopped otherwise the
layout will be lost. The following code snippet show how to stop the emission of
the I<changed> signal:

	my $entry = Gtk2::Ex::Entry::Pango->new();
	$entry->signal_connect(changed => sub {
		
		# Validate the text 
		my $text = $entry->get_text;
		if (validate($text)) {
				return;
		}
		
		# Mark the text as being erroneous
		my $escaped = Glib::Markup::escape_text($text);
		$entry->set_markup("<span underline='error' underline_color='red'>$escaped</span>");
		$entry->signal_stop_emission_by_name('changed');
	});

Another important thing to note is that C<Gtk2::Entry::set_text()> will not
update it's content if the input text is the same as the text already stored.
This means that if set text is called with the same string it will not emit the
signal I<changed> and the widget will not pickup that the markup styles have to
be dropped. This is true even it the string displayed uses markup, as long as
the contents are the same C<set_text()> will not make an update. The method
L</clear_markup> can be used for safely clearing the markup text.

=head1 CAVEATS

A C<Gtk2::Entry> keeps track of both the text and the markup styles (Pango
layout) as two different entities . The markup styles are just styles applied
over the internal text. Because of this it's possible to have the widget display
a different text than the one stored internally.

Because a C<Gtk2::Entry> keeps track of both the text and the style layouts.
It's important to always keep track of both. If the styles and text are not
totally synchronized strange things will happen. In the worst case it's even
possible to make the C<Gtk2::Entry> widget display a different text than the one
stored (the text value). This can make things more confusing.

This widget tries as hard as possible to synchronize the text data and the
layout data.

=head1 INTERFACES

	Glib::Object::_Unregistered::AtkImplementorIface
	Gtk2::Buildable
	Gtk2::CellEditable
	Gtk2::Editable

=head1 METHODS

The following methods are added by this widget:

=head2 new

Creates a new instance.

=cut


use strict;
use warnings;

use Glib qw(TRUE FALSE);
# Gtk2 with Pango support
use Gtk2 1.100;
use Gtk2::Pango;
use Carp;

# Module version
our $VERSION = '0.10';


# Emty Pango attributes list that's used to clear the previous markup
my ($EMPTY_ATTRLIST) = ($Gtk2::VERSION >= 1.160)
	? (Gtk2::Pango::AttrList->new())
	: Gtk2::Pango->parse_markup('')
;


# See http://gtk2-perl.sourceforge.net/doc/pod/Glib/Object/Subclass.html
use Glib::Object::Subclass 'Gtk2::Entry' =>

	signals => {
		'changed'            => \&callback_changed,
		'expose-event'       => \&callback_expose_event,
		'button-press-event' => \&callback_button_press_event,

		'markup-changed' => {
			flags       => ['run-last'],
			param_types => ['Glib::String'],
		},

		'empty-markup-changed' => {
			flags       => ['run-last'],
			param_types => ['Glib::String'],
		},
	},


	properties => [
		Glib::ParamSpec->string(
			'markup',
			'Markup',
			'The Pango markup used for displaying the contents of the entry.',
			'',
			['writable'],
		),

		Glib::ParamSpec->string(
			'empty-markup',
			'Markup when empty',
			'The default Pango markup to display when the entry is empty.',
			'',
			['readable', 'writable'],
		),

		Glib::ParamSpec->boolean(
			'clear-on-focus',
			'Clear the markup when the widget has focus',
			'If the Pango markup to display has to cleared when the entry has focus.',
			TRUE,
			['readable', 'writable'],
		),
	],
;



#
# Gtk2 constructor.
#
sub INIT_INSTANCE {
	my $self = shift;

	# The Pango attributes to apply to the text. If set to undef then there are no
	# attributes and the text is rendered normally.
	$self->{attributes} = undef;
	
	# The Pango text and attributes to apply when the entry has no text.
	$self->{empty_attributes} = undef;
	$self->{empty_text} = '';
}



#
# Gtk2 generic property setter.
#
sub SET_PROPERTY {
	my ($self, $pspec, $value) = @_;
	
	my $field = $pspec->get_name;

	if ($field eq 'markup') {
		# The markup isn't stored, instead it is parsed and the attributes are
		# stored.
		$self->apply_markup($value);
	}
	elsif ($field eq 'empty_markup') {
		if (defined $value) {
			($self->{empty_attributes}, $self->{empty_text}) = Gtk2::Pango->parse_markup($value);
		}
		else {
			($self->{empty_attributes}, $self->{empty_text}) = (undef, '');
		}
		$self->{$field} = $value;
		$self->signal_emit('empty-markup-changed' => $value);
	}
	else {
		$self->{$field} = $value;
	}
}



=head2 set_markup

Sets the text of the entry using Pango markup. This method can die if the markup
is not valid and fails to parse (see L<Gtk2::Pango/parse_markup>).

Parameters:

=over

=item * $markup

The text to add to the entry, the text is expected to be using Pango markup.
This means that even if no markup is used special characters like E<lt>, E<gt>,
&, ' and " need to be escaped. Keep in mind that Pango markup is a subset of
XML.

You might want to use the following code snippet for escaping the characters:

	$entry->set_markup(
		sprintf "The <i>%s</i> <b>%s</b> fox <sup>%s</sup> over the lazy dog",
			map { Glib::Markup::escape_text($_) } qw(quick brown jumps)
	);

=back	

=cut

sub set_markup {
	my $self = shift;
	my ($markup) = @_;

	# NOTE: In order to have the markup applied properly both the widget's
	# internal text value and the Pango style have to be applied. Calling
	# $self->get_layout->set_markup($markup); is not enough as it will only apply
	# the markup and render the text in $markup but will not update the internal
	# text representation of the widget.
	#
	# For instance, if the text within the markup differs from the actual text in
	# the Gtk2::Entry and changes in width there will be some problems. Sure the
	# entry's text will be rendered properly but the entry will not have the right
	# data within it's buffer. This means that $self->get_text() will still return
	# the old text even though the widget displays the new string. Furthermore,
	# the widget will fail to edit text because the cursor could be placed at a
	# position that's further than the actual data in the widget.
	#
	# To solve this problem the new text has to be added to the entry and the
	# style has to be applied afterwards. The text is added to the widget through
	# $self->set(text => $text); by the method apply_markup() while the styles are
	# applied each time that the widget is rendered (see callback_changed()).
	$self->set(markup => $markup);
}



=head2 clear_markup

Clears the Pango markup that was applied to the widget. This method can be
called even if no markup was applied previously.

B<NOTE>: That this method will emit the signal I<markup-changed>. 

=cut

sub clear_markup {
	my $self = shift;
	$self->set_markup(undef);
}



=head2 set_empty_markup

Sets the Pango markup that was applied to the widget when there's the entry is
empty. This method can die if the markup is not valid and fails to parse
(see L<Gtk2::Pango/parse_markup>).

C<NOTE:> Setting an empty markup string has no effect on C<get_text>. When an
empty markup string is used the entry holds no data thus C<get_text> will return
an empty string.

Parameters:

=over

=item * $markup

The text to add to the entry, the text is expected to be using Pango markup.
Make sure to escape all characters with L<Glib::Markup/escape_text>. For more
details about escaping the markup see L</set_markup>.

=back	

=cut

sub set_empty_markup {
	my $self = shift;
	my ($markup) = @_;
	$self->set(empty_markup => $markup);
}



=head2 clear_empty_markup

Clears the Pango markup that was applied to the widget. This method can be
called even if no markup was applied previously.

=cut

sub clear_empty_markup {
	my $self = shift;
	$self->set_empty_markup(undef);
}



=head2 get_clear_on_focus

Returns if the widget's Pango markup will be cleared once the widget is focused
and has no user text.

=cut

sub get_clear_on_focus {
	my $self = shift;
	return $self->get('clear_on_focus');
}



=head2 set_clear_on_focus

Returns if the widget's Pango markup will be cleared once the widget is focused
and has no user text.

Parameters:

=over

=item * $value

A boolean value that dictates if the Pango markup has to be cleared when the
widget is focused and there's no text entered (the entry is empty).

=back	

=cut

sub set_clear_on_focus {
	my $self = shift;
	my ($value) = @_;
	return $self->set(clear_on_focus => $value);
}


#
# Applies the markup to the widget. The markup string is parsed into a text to
# be displayed and an attribute list (the styles to apply). The text is added
# normally to the widget as if it was a Gtk2::Entry, while the attributes are
# stored in order to be applied latter to the widget.
#
sub apply_markup {
	my $self = shift;
	my ($markup) = @_;

	# Parse the markup, this will die if the markup is invalid.
	my $text = '';
	$self->{attributes} = undef;
	if (defined $markup) {
		($self->{attributes}, $text) = Gtk2::Pango->parse_markup($markup);
	}

	
	if ($text eq $self->get_text) {
		# $widget->set_text() only changes the text if it's different, since this is
		# the same text we can just apply the markup and request a redraw.
		$self->set_layout_attributes();
		$self->request_redraw();
	}
	else {
		# Change the entry's text. Mark this as an internal change as we can't let
		# the 'changed' callback reset the markup.
		local $self->{internal} = TRUE;		
		$self->set(text => $text);
		
		if ($self->{internal}) {
			# The signal 'changed' wasn't emited (it can happen sometimes) so lets
			# request a refresh of the UI manually.
			$self->request_redraw();
		}
	}

	$self->signal_emit_markup_changed($markup);
}



#
# Schedules a redraw of the widget.
#
# The text region must be invalidated in order to be repainted. This is true
# even if the markup text is the same as the one in the widget. Remember that
# the text in the Pango markup could turn out to be the same text that was 
# previously in the widget but with new styles (this is most common when showing
# an error with a red underline). In such case the Gtk2::Entry will not refresh
# its appearance because the text didn't change. Here we are forcing the update.
#
sub request_redraw {
	my $self = shift;

	return unless $self->realized;

	my $size = $self->allocation;
	my $rectangle = Gtk2::Gdk::Rectangle->new(0, 0, $size->width, $size->height);
	$self->window->invalidate_rect($rectangle, TRUE);
}



#
# Notifies the others that the markup has changed by emitting the signal
# 'markup-changed'.
#
sub signal_emit_markup_changed {
	my $self = shift;
	my ($markup) = @_;
	$self->signal_emit('markup-changed'=> $markup);
}



#
# Applies the attributes to the widget. Gtk2::Pango::Layout::set_attributes()
# doesn't accept an undef value (a patch has been submitted in order to address
# this issue). So if the attributes are undef an empty attribute list has to be
# submitted instead.
#
sub set_layout_attributes {
	my $self = shift;

	if ($self->get_text ne '') {
		# There's text in the widget apply the attributes (the requested pango
		# text). If the're attributes simply clear the previous ones.
		my $attributes = $self->{attributes};
		if (! defined $attributes) {
			# Clear the previous attributes, just in case...
			$attributes = $EMPTY_ATTRLIST;
		}
		$self->get_layout->set_attributes($attributes);
	}
	elsif ($self->get_clear_on_focus and $self->has_focus) {
		# The widget has focus and is empty, if the user requested that it be
		# cleared when focused we have to honor it here.
		my $attributes = $EMPTY_ATTRLIST;
		$self->get_layout->set_text('');
		$self->get_layout->set_attributes($attributes);
		return;
	}
	elsif ($self->{empty_markup}) {
		# The widget is empty and the user wants it filled with a default text at
		# all times.
		$self->get_layout->set_text($self->{empty_text});
		$self->get_layout->set_attributes($self->{empty_attributes});
	}
}



#
# Called when the text of the entry is changed. The callback is used for monitor
# when the user resets the text of the widget without markup. In that case we
# need to erase the markup.
#
sub callback_changed {
	my $self = shift;

	if (! $self->{internal}) {
		# The text was changed as if it was a normal Gtk2::Entry either through
		# $widget->set_text($text) or $widget->set(text => $text). This means that
		# the markup style has to be removed from the widget. Now the widget will
		# rendered in plain text without any styles.
		$self->{attributes} = undef;
		$self->signal_emit_markup_changed(undef);
	}
	else {
		# Tell us that the callback was called
		$self->{internal} = FALSE;
	}

	
	# Apply the markup
	$self->set_layout_attributes();
	$self->request_redraw();
	
	return $self->signal_chain_from_overridden(@_);
}



#
# Called each time that the widget needs to be rendered. This happens quite
# often as an entry field can have a cursor blinking. Without this callback the
# Pango style would be lost at each redraw.
#
sub callback_expose_event {
	my $self = shift;
	my ($event) = @_;

	$self->set_layout_attributes();
	return $self->signal_chain_from_overridden(@_);
}



#
# This handler stops the widget from generating critical Pango warnings when the
# text selection gesture is performed. If there's no text in the widget we
# simply cancel the gesture.
#
# The gesture is done with: mouse button 1 pressed and dragged over the widget
# while the button is still pressed.
#
sub callback_button_press_event {
	my $self = shift;
	my ($event) = @_;
	
	if ($self->get_text or $event->button != 1) {
		# Propagate the event further since there's text in the widget
		return $self->signal_chain_from_overridden(@_);
	}
	
	# Give focus to the widget but stop the text selection
	$self->grab_focus();
	return TRUE;
}



# Return a true value
1;

=head1 PROPERTIES

The following properties are added by this widget:

=head2 markup

(string: writable)

The markup text used by this widget. This property is a string that's only
writable. That's right, there's no way for extracting the markup from the
widget.

=head2 empty-markup

(string: readable writable)

The markup text used by this widget when the entry field is empty. If this
property is set the entry will display a default string in the widget when
there's no text provided by the user.

=head2 clear-on-focus
			'',
			'Clear the markup when the widget has focus',
			'If the Pango markup to display has to cleared when the entry has focus.',
			TRUE,
			['readable', 'writable'],

(boolean: readable writable)

Indicates if the C<empty-makrup> has to be cleared when the entry is empty and
the widget has gained focus.

=head1 SIGNALS

=head2 markup-changed

Emitted when the markup has been changed.

Signature:

	sub markup_changed {
		my ($widget, $markup) = @_;
		# Returns nothing
	}

Parameters:

=over

=item * $markup

The new markup that's been applied. This field is a normal Perl string. If
C<$markup> is C<undef> then the markup was removed.

=back	

=head2 empty-markup-changed

Emitted when the markup used when the widget is empty has been changed.

Signature:

	sub empty_markup_changed {
		my ($widget, $markup) = @_;
		# Returns nothing
	}

Parameters:

=over

=item * $markup

The new markup that's been applied when the widget is empty. This field is a
normal Perl string. If C<$markup> is C<undef> then the markup was removed.

=back	

=head1 SEE ALSO

Take a look at the examples for getting some ideas or inspiration on how to use
this widget. For a more powerful text widget that supports more operations take
a look at L<Gtk2::TextView>.

=head1 AUTHORS

Emmanuel Rodriguez E<lt>potyl@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2010 by Emmanuel Rodriguez.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
