# Copyright 2007, 2008, 2009, 2010, 2011, 2013 Kevin Ryde

# This file is part of Gtk2-Ex-ErrorTextDialog.
#
# Gtk2-Ex-ErrorTextDialog is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Gtk2-Ex-ErrorTextDialog is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-ErrorTextDialog.  If not, see <http://www.gnu.org/licenses/>.


package Gtk2::Ex::ErrorTextDialog;
use 5.008001; # for utf8::is_utf8()
use strict;
use warnings;
use Gtk2;
use List::Util 'max';
use Locale::TextDomain 1.16; # version 1.16 for bind_textdomain_filter()
use Locale::TextDomain ('Gtk2-Ex-ErrorTextDialog');
use Locale::Messages;
use POSIX ();
use Glib::Ex::ObjectBits;
use Gtk2::Ex::Units 14; # version 14 for char_width

our $VERSION = 11;

# set this to 1 for some diagnostic prints
use constant DEBUG => 0;

Locale::Messages::bind_textdomain_codeset ('Gtk2-Ex-ErrorTextDialog','UTF-8');
Locale::Messages::bind_textdomain_filter  ('Gtk2-Ex-ErrorTextDialog',
                                           \&Locale::Messages::turn_utf_8_on);

use Glib::Object::Subclass
  'Gtk2::MessageDialog',
  signals => { destroy => \&_do_destroy,

               clear =>
               { param_types => [],
                 return_type => undef,
                 class_closure => \&_do_clear,
                 flags => ['run-last','action'] },

               popup_save_dialog =>
               { param_types => [],
                 return_type => undef,
                 class_closure => \&_do_popup_save_dialog,
                 flags => ['run-last','action'] },
             },

  properties => [ Glib::ParamSpec->int
                  ('max-chars',
                   __('Maximum characters'),
                   'Maximum number of characters to retain, or -1 for unlimited.',
                   -1,                 # minimum
                   POSIX::INT_MAX(),   # maximum
                   200_000,            # default
                   Glib::G_PARAM_READWRITE) ];

use constant RESPONSE_CLEAR => 0;
use constant RESPONSE_SAVE  => 1;

# not yet documented ...
use constant _MESSAGE_SEPARATOR => "--------\n";

my $instance;
our @_instance_pending;

sub instance {
  my ($class) = @_;
  if (! $instance) {
    $instance = $class->new;
    $instance->signal_connect (delete_event=>\&Gtk2::Widget::hide_on_delete);
  }
  return $instance;
}

# return true if $class_or_self is the shared $instance
sub _is_instance {
  my ($class_or_self) = @_;
  return (! ref $class_or_self  # class name means the instance
          || ($instance && $class_or_self == $instance));
}

sub INIT_INSTANCE {
  my ($self) = @_;

  {
    my $title = __('Errors');
    if (defined (my $appname = Glib::get_application_name())) {
      $title = "$appname: $title";
    }
    $self->set_title ($title);
  }
  $self->set (message_type => 'error',
              resizable => 1);

  {
    my $check = $self->{'popup_checkbutton'}
      = Gtk2::CheckButton->new_with_mnemonic (__('_Popup on Error'));
    $check->set_active (1);
    Glib::Ex::ObjectBits::set_property_maybe
        ($check,
         # tooltip-text new in Gtk 2.12
         tooltip_text => __('Whether to popup this dialog when an error occurs.
If errors are occurring repeatedly you might not want a popup every time.'));

    $self->add_action_widget ($check, 'none');
  }
  {
    my $button = $self->add_button ('gtk-save-as', $self->RESPONSE_SAVE);
    Glib::Ex::ObjectBits::set_property_maybe
        ($button,
         # tooltip-text new in Gtk 2.12
         tooltip_text => __('Save the error messages to a file, perhaps to include in a bug report.
(Cut and paste works too, but saving may be better for very long messages.)'));
  }
  $self->add_buttons ('gtk-clear' => $self->RESPONSE_CLEAR,
                      'gtk-close' => 'close');

  # connect to self instead of a class handler because as of Gtk2-Perl 1.220
  # a Gtk2::Dialog class handler for 'response' is called with response IDs
  # as numbers, not enum strings like 'close'
  $self->signal_connect (response => \&_do_response);

  my $vbox = $self->vbox;

  my $scrolled = Gtk2::ScrolledWindow->new;
  $scrolled->set_policy ('never', 'always');
  $vbox->pack_start ($scrolled, 1,1,0);

  my $textbuf = $self->{'textbuf'} = Gtk2::TextBuffer->new;
  $textbuf->signal_connect ('changed', \&_do_textbuf_changed, $self);
  _do_textbuf_changed ($textbuf, $self);  # initial settings

  require Gtk2::Ex::TextView::FollowAppend;
  my $textview = $self->{'textview'}
    = Gtk2::Ex::TextView::FollowAppend->new_with_buffer ($textbuf);
  $textview->set (wrap_mode => 'char',
                  editable  => 0);
  $scrolled->add ($textview);

  $vbox->show_all;
  $self->set_default_size_chars (70, 20);
}

# 'destroy' class closure
# this can be called more than once!
sub _do_destroy {
  my ($self) = @_;
  if (DEBUG) { print "ErrorTextDialog destroy $self\n"; }

  # Break circular reference from $textbuf 'changed' signal userdata $self.
  # Nothing for $self->{'save_dialog'} as it's destroy-with-parent already.
  delete $self->{'textbuf'};

  if ($self->_is_instance) {
    # ready for subsequence instance() call to make a new one
    undef $instance;
  }
  $self->signal_chain_from_overridden;
}

# 'changed' signal on the textbuf
sub _do_textbuf_changed {
  my ($textbuf, $self) = @_;
  if (DEBUG) { print "ErrorTextDialog textbuf changed\n"; }
  my $any_errors = ($textbuf->get_char_count != 0);
  _message_dialog_set_text ($self, $any_errors
                            ? __('An error has occurred')
                            : __('No errors'));
  $self->set_response_sensitive ($self->RESPONSE_CLEAR, $any_errors);
}

# set_default_size() based on desired size_request() with a sensible rows
# and columns size for the TextView.  This is just a default, the user can
# resize to smaller.  Must have 'resizable' turned on in INIT_INSTANCE above
# to make this work (the default from GtkMessageDialog is resizable false).
#
# not documented yet ...
sub set_default_size_chars {
  my ($self, $width_chars, $height_lines) = @_;
  my $textview = $self->{'textview'};
  my $scrolled = $textview->get_parent;

  # Width set on textview so the vertical scrollbar is added on top.  But
  # height set on the scrolled since its vertical scrollbar means any
  # desired height from the textview is ignored.
  #
  Gtk2::Ex::Units::set_default_size_with_subsizes
      ($self,
       [ $scrolled, -1, $height_lines*Gtk2::Ex::Units::line_height($textview)],
       [ $textview, "$width_chars chars", -1 ]);
}

#-----------------------------------------------------------------------------
# button/response actions

sub _do_response {
  my ($self, $response) = @_;
  if ($response eq $self->RESPONSE_CLEAR) {
    $self->clear;

  } elsif ($response eq $self->RESPONSE_SAVE) {
    $self->popup_save_dialog;

  } elsif ($response eq 'close') {
    # as per a keyboard close, defaults to raising 'delete-event', which in
    # turn defaults to a destroy
    $self->signal_emit ('close');
  }
}

sub clear {
  my ($self) = @_;
  $self = $self->instance unless ref $self;
  $self->signal_emit ('clear');
}
sub _do_clear {
  my ($self) = @_;
  my $textbuf = $self->{'textbuf'};
  $textbuf->delete ($textbuf->get_start_iter, $textbuf->get_end_iter);
}

sub popup_save_dialog {
  my ($self) = @_;
  $self = $self->instance unless ref $self;
  $self->signal_emit ('popup-save-dialog');
}
sub _do_popup_save_dialog {
  my ($self) = @_;
  $self->_save_dialog->present;
}

# create and return the save dialog -- might make this public one day
sub _save_dialog {
  my ($self) = @_;
  return ($self->{'save_dialog'} ||= do {
    require Gtk2::Ex::ErrorTextDialog::SaveDialog;
    my $save_dialog = Gtk2::Ex::ErrorTextDialog::SaveDialog->new;
    # set_transient_for() is always available, whereas 'transient-for' as
    # property only since gtk 2.10
    $save_dialog->set_transient_for ($self);
    $save_dialog
  });
}

#-----------------------------------------------------------------------------
# messages

sub get_text {
  my ($self) = @_;
  return $self->{'textbuf'}->get('text');
}

sub add_message {
  my ($self, $msg) = @_;
  if (DEBUG) { print "add_message()\n"; }
  $self = $self->instance unless ref $self;

  require Gtk2::Ex::ErrorTextDialog::Handler;
  my $textbuf = $self->{'textbuf'};
  my @msgs;

  if ($self->_is_instance && @_instance_pending) {
    if (DEBUG) { print "  ", scalar(@_instance_pending), " pending\n"; }

    # copy the global in case some warning from the code here extending it,
    # making an infinite loop
    @msgs = @_instance_pending;
    @_instance_pending = ();

    foreach my $pending (@msgs) {
      $pending = Gtk2::Ex::ErrorTextDialog::Handler::_maybe_locale_bytes_to_wide ($pending);
      if ($pending !~ /\n$/) { $pending .= "\n"; }
    }

    # Various internal Perl_warn() and Perl_warner() calls have the warning
    # followed immediately by a second warn call with an extra remark about
    # what might be wrong.  The extras begin with a tab, join them up to the
    # initial warning instead of a separate message.  Do this after
    # bytes->wide crunch, just in case one is wide and the other bytes.
    #
    # The initial message and any continuations are always in
    # @_instance_pending together, because the idle handler deferring lets
    # the continuation go through $SIG{__WARN__} before the code here runs.
    #
    # die() gives similar tab continuations when "propagating" an error (see
    # L<perlfunc/die>), but in that case it's within a single string so
    # needs nothing special.
    #
    for (my $i = 0; $i < $#msgs; ) {
      if ($msgs[$i+1] =~ /^\t/) {
        $msgs[$i] .= splice @msgs, $i+1, 1;
      } else {
        $i++;
      }
    }
  }

  if (defined $msg) {
    $msg = Gtk2::Ex::ErrorTextDialog::Handler::_maybe_locale_bytes_to_wide ($msg);
    if ($msg !~ /\n$/) { $msg .= "\n"; }
    push @msgs, $msg;
  }

  # can have no messages here if the idle handler for @_instance_pending
  # runs after that array has been crunched by an explicit add_message()
  # call
  if (@msgs) {
    if ($textbuf->get_char_count) {
      unshift @msgs, ''; # want separator after existing textbuf text
    }
    my $text = join (_MESSAGE_SEPARATOR, @msgs);
    $textbuf->insert ($textbuf->get_end_iter, $text);
    _truncate ($self);
  }
}

sub _truncate {
  my ($self) = @_;
  my $max_chars = $self->get('max-chars');
  return if ($max_chars == -1);

  my $textbuf = $self->{'textbuf'};
  my $len = $textbuf->get_char_count;
  # extra 82 for $discard_message, possibly translated, and "\n\n"
  return if ($len <= $max_chars + 82);

  # TRANSLATORS: The code currently assumes this string is 80 chars or less.
  my $discard_message = __('[Older messages discarded]');

  $textbuf->delete ($textbuf->get_start_iter,
                    $textbuf->get_iter_at_offset ($len - $max_chars));
  $textbuf->insert ($textbuf->get_start_iter,
                    "$discard_message\n\n");
}

# not sure about this yet, an in particular which popup follows the
# popup-on-error checkbox and which is a programmatic always popup ...
#
# =item C<< Gtk2::Ex::ErrorTextDialog->popup_add_message ($str) >>
#
# =item C<< Gtk2::Ex::ErrorTextDialog->popup_add_message ($str, $parent) >>
#
# =item C<< $errordialog->popup_add_message ($str) >>
#
# =item C<< $errordialog->popup_add_message ($str, $parent) >>
#
# Add C<$str> to the error dialog with C<add_message> below, and popup the
# dialog so it's visible.
#
# Optional C<$parent> is a widget which the error relates to, or C<undef> for
# none.  C<$parent> may help the window manager position the error dialog when
# first displayed, but is not used after that.
#
# not documented yet ...
sub popup_add_message {
  my ($self, $msg, $parent) = @_;
  $self = $self->instance unless ref $self;

  if ($self->{'popup_checkbutton'}->get_active) {
    $self->popup ($parent);
  }
  $self->add_message ($msg);
}
# not documented yet ...
sub popup {
  my ($self, $parent) = @_;
  $self = $self->instance unless ref $self;

  if ($self->mapped) {
    # too intrusive to raise every time
    # $self->window->raise;
  } else {
    # allow for $parent a non-toplevel
    if ($parent) { $parent = $parent->get_toplevel; }
    $self->set_transient_for ($parent);
    $self->present;
    $self->set_transient_for (undef);
  }
}

# ENHANCE-ME: would prefer to show the same string as
# g_log_default_handler(), or even what gperl_log_handler() gives
sub _log_to_string {
  my ($log_domain, $log_level, $message) = @_;

  $log_level -= ['recursion','fatal'];
  $log_level = join('-', @$log_level) || 'LOG';

  return (($log_domain ? "$log_domain-" : "** ")
          . "\U$log_level\E: "
          . (defined $message ? $message : "(no message)"));
}

# probably not wanted ...
# sub popup_add_log {
#   my ($class_or_self, $log_domain, $log_level, $message, $parent) = @_;
#   $self->popup ($parent);
#   $self->add_log ($log_domain, $log_level, $message);
# }
# sub add_log {
#   my ($class_or_self, $log_domain, $log_level, $message) = @_;
#   $class_or_self->add_message
#     (_log_to_string ($log_domain, $log_level, $message));
# }

#-----------------------------------------------------------------------------
# generic helpers

# _message_dialog_set_text($messagedialog,$text) sets the text part of a
# Gtk2::MessageDialog.  Gtk 2.10 up has this as a 'text' property, or in
# past versions it's necessary to dig out the label child widget.
#
# It doesn't work to choose between the dialog or sub-widget and to make a
# set() or set_text() call on.  Gtk2::MessageDialog doesn't have a
# set_text() method, and Gtk2::Label doesn't have a 'text' property, so must
# have separate code for the old or new gtk.
#
# This is in a BEGIN block so the unused sub is garbage collected.
#
BEGIN {
  *_message_dialog_set_text = Gtk2::MessageDialog->find_property('text')
    ? sub {
      my ($dialog, $text) = @_;
      $dialog->set (text => $text);
    }
      : sub {
        my ($dialog, $text) = @_;
        my $label = ($dialog->{__PACKAGE__.'--text-widget'} ||= do {
          require List::Util;
          my $l;
          my @w = grep {$_->isa('Gtk2::HBox')} $dialog->vbox->get_children;
          for (;;) {
            if (! @w) {
              require Carp;
              Carp::croak ('_message_dialog_text_widget(): oops, label not found');
            }
            $l = List::Util::first (sub {ref $_ eq 'Gtk2::Label'}, @w)
              and last;
            @w = map {$_->isa('Gtk2::Box') ? $_->get_children : ()} @w;
          }
          $l
        });
        $label->set_text ($text);
      };
}

1;
__END__

# Unused stuff:

# Truncating on a message boundary ...
#
#   my $str = $textbuf->get('text');
#   my $from = length($str) - $max_chars;
#
#   # if $from is in the middle or just after a separator then that's the
#   # place to truncate; step back by length(_MESSAGE_SEPARATOR) to allow that
#   # to match
#   my $pos = index ($str, _MESSAGE_SEPARATOR,
#                    max (0, $from - length(_MESSAGE_SEPARATOR)));
#   if ($pos < 0) {
#     # $from is somewhere within some huge last message in the buffer, search
#     # backwards to the separator preceding it
#     $pos = rindex ($str, _MESSAGE_SEPARATOR, max (0, $from));
#     return if $pos < 0;  # only one message
#   }
#
#   $pos += length(_MESSAGE_SEPARATOR);
#   $textbuf->delete ($textbuf->get_start_iter,
#                     $textbuf->get_iter_at_offset($pos));

# append a newline to $textbuf if it's non-empty and doesn't already end
# with a newline
# sub _textbuf_ensure_final_newline {
#   my ($textbuf) = @_;
#   my $len = $textbuf->get_char_count || return;  # nothing added if empty
#
#   my $end_iter = $textbuf->get_end_iter;
#   if ($textbuf->get_text ($textbuf->get_iter_at_offset($len-1),
#                           $end_iter,
#                           0) # without invisible text
#       ne "\n") {
#     $textbuf->insert ($end_iter, "\n");
#   }
# }

=for stopwords ErrorTextDialog Gtk2-Ex-ErrorTextDialog charset unicode Popup
filename Gtk Ryde

=head1 NAME

Gtk2::Ex::ErrorTextDialog -- display error messages in a dialog

=head1 SYNOPSIS

 # explicitly adding a message
 use Gtk2::Ex::ErrorTextDialog;
 Gtk2::Ex::ErrorTextDialog->add_message ("Something went wrong");

 # handler for all Glib exceptions
 use Gtk2::Ex::ErrorTextDialog::Handler;
 Glib->install_exception_handler
   (\&Gtk2::Ex::ErrorTextDialog::Handler::exception_handler);

=head1 WIDGET HIERARCHY

C<Gtk2::Ex::ErrorTextDialog> is a subclass of C<Gtk2::MessageDialog>.  But
for now don't rely on more than C<Gtk2::Dialog>.

    Gtk2::Widget
      Gtk2::Container
        Gtk2::Bin
          Gtk2::Window
            Gtk2::Dialog
              Gtk2::MessageDialog
                Gtk2::Ex::ErrorTextDialog

=head1 DESCRIPTION

An ErrorTextDialog presents text error messages to the user in a
L<C<Gtk2::TextView>|Gtk2::TextView>.  It's intended for technical things
like Perl errors and warnings, rather than results of normal user
operations.

    +------------------------------------+
    |   !!    An error has occurred      |
    | +--------------------------------+ |
    | | Something at foo.pl line 123   | |
    | | -----                          | |
    | | Cannot whatever at Bar.pm line | |
    | | 456                            | |
    | |                                | |
    | +--------------------------------+ |
    +------------------------------------+
    |              Clear  Save-As  Close |
    +------------------------------------+

See L<Gtk2::Ex::ErrorTextDialog::Handler> for functions hooking Glib
exceptions and Perl warnings to display in an ErrorTextDialog.

ErrorTextDialog is good if there might be a long cascade of messages from
one problem, or errors repeated on every screen draw.  In that case the
dialog scrolls along but the app might still mostly work.

The Save-As button lets the user write the messages to a file, for example
for a bug report.  Cut-and-paste works in the usual way too.

=head1 FUNCTIONS

=head2 Creation

=over 4

=item C<< $errordialog = Gtk2::Ex::ErrorTextDialog->instance >>

Return an ErrorTextDialog object designed to be shared by all parts of the
program.  This object is used when the methods below are called as class
functions.

You can destroy this instance with C<< $errordialog->destroy >> in the usual
way if you want.  A subsequent call to C<instance> creates a new one.

=item C<< $errordialog = Gtk2::Ex::ErrorTextDialog->new (key=>value,...) >>

Create and return a new ErrorTextDialog.  Optional key/value pairs set
initial properties per C<< Glib::Object->new >>.  An ErrorTextDialog created
this way is separate from the C<instance()> one above.  But it's unusual to
want more than one error dialog.

=back

=head2 Messages

ErrorTextDialog works with string messages.  A horizontal separator line is
added between each message because it can be hard to tell one from the next
when long lines are wrapped.  Currently the separator is just some dashes,
but something slimmer might be possible.

=over 4

=item C<< Gtk2::Ex::ErrorTextDialog->add_message ($str) >>

=item C<< $errordialog->add_message ($str) >>

Add a message to the ErrorTextDialog.  C<$str> can be wide chars or raw
bytes and doesn't have to end with a newline.

If C<$str> is raw bytes it's assumed to be in the locale charset and is
converted to unicode for display.  Anything invalid in C<$str> is escaped,
currently just in C<PERLQQ> style so it will display, though not necessarily
very well (see L<Encode/Handling Malformed Data>).

=item C<< $str = Gtk2::Ex::ErrorTextDialog->get_text() >>

=item C<< $str = $errordialog->get_text() >>

Return a wide-char string of all the messages in the ErrorTextDialog.

=back

=head1 ACTION SIGNALS

The following are provided both as "action signals" for use from C<Gtk2::Rc>
key bindings and methods for use from program code.

=over 4

=item C<clear> action signal (no parameters)

Remove all messages from the dialog.  This is the "Clear" button action.

=item C<popup-save-dialog> action signal (no parameters)

Popup the Save dialog, which asks the user for a filename to save the error
messages to.  This is the "Save As" button action.

=item C<< Gtk2::Ex::ErrorTextDialog->clear() >>

=item C<< Gtk2::Ex::ErrorTextDialog->popup_save_dialog() >>

=item C<< $errordialog->clear() >>

=item C<< $errordialog->popup_save_dialog() >>

Emit the C<clear> or C<popup-save-dialog> signals, respectively.  The
default handler in those signals does the actual work of clearing or showing
the save dialog and as usual for action signals that's the place to override
or specialize in a subclass.

=item C<< $id = Gtk2::Ex::ErrorTextDialog->RESPONSE_CLEAR >>

=item C<< $id = Gtk2::Ex::ErrorTextDialog->RESPONSE_SAVE >>

Return the dialog respond ID for the clear and save actions.  These are the
responses raised by the clear and save buttons.  The clear response could be
raised explicitly with

    $errordialog->response ($errordialog->RESPONSE_CLEAR);
    # same as $errordialog->clear()

=back

=head2 Key Bindings

The stock Clear and Save-As button mnemonic keys invoke the clear and save
actions, but there's no further key bindings by default.  You can add keys
in the usual way from the C<Gtk2::Rc> mechanism.  The class is
C<Gtk2__Ex__ErrorTextDialog> so for example in your F<~/.gtkrc-2.0> file

    binding "my_error_keys" {
      bind "F5" { "popup-save-dialog" () }
    }
    class "Gtk2__Ex__ErrorTextDialog" binding:rc "my_error_keys"

See F<examples/keybindings.pl> in the sources for a complete program doing
this.

=head1 PROPERTIES

=over 4

=item C<max-chars> (integer, default 200000)

The maximum number of characters of message text to retain, or -1 for
unlimited.  If this size is exceeded old text is discarded, replaced by a
line

    [Older messages discarded]

The idea is to limit memory use if a program is spewing lots of warnings
etc.  An infinite or near-infinite stream probably still makes the program
unusable, but at least it won't consume ever more memory.

Currently truncation chops old text in the middle of a message.  This is
slightly unattractive but it's fastest and it means if there's a huge
message then at least part of it is retained.

=back

=head1 SEE ALSO

L<Gtk2::Ex::ErrorTextDialog::Handler>

L<Gtk2::Ex::Carp>, which presents messages one at a time.

=head1 HOME PAGE

L<http://user42.tuxfamily.org/gtk2-ex-errortextdialog/>

=head1 LICENSE

Gtk2-Ex-ErrorTextDialog is Copyright 2007, 2008, 2009, 2010, 2011, 2013 Kevin Ryde

Gtk2-Ex-ErrorTextDialog is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License as published
by the Free Software Foundation; either version 3, or (at your option) any
later version.

Gtk2-Ex-ErrorTextDialog is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
Public License for more details.

You should have received a copy of the GNU General Public License along
with Gtk2-Ex-ErrorTextDialog.  If not, see L<http://www.gnu.org/licenses/>.

=cut
