# Copyright 2009, 2010, 2011, 2013 Kevin Ryde

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


package Gtk2::Ex::ErrorTextDialog::SaveDialog;
use 5.008001; # for utf8::is_utf8()
use strict;
use warnings;
use Gtk2;
use Locale::TextDomain ('Gtk2-Ex-ErrorTextDialog');
use Gtk2::Ex::ErrorTextDialog; # for TextDomain utf8 setups

our $VERSION = 11;

use Glib::Object::Subclass
  'Gtk2::FileChooserDialog',
  signals => { delete_event => \&Gtk2::Widget::hide_on_delete };

# GtkFileChooserDialog dispatches properties to the GtkFileChooserWidget,
# but it's not ready to do so until after its "constructor()" code.
# INIT_INSTANCE runs before that (under g_type_create_instance()).
#
# This subclassed new() is a workaround, but one which of course is not run
# by non-perl GObject constructors like the GtkBuilder mechanism.
#
sub new {
  my $class = shift;
  my $self = $class->SUPER::new (@_);
  $self->set_action ('save');

  # new in gtk 2.8
  if ($self->can('set_do_overwrite_confirmation')) {
    $self->set_do_overwrite_confirmation (1);
  }

  # default filename based on the program name in $0, without directory or
  # any .pl suffix (g_get_prgname() is not wrapped, perl $0 being adequate)
  {
    my $filename = 'errors.utf8.txt';
    require File::Basename;
    my $prgname = File::Basename::basename ($0, '.pl');
    if ($prgname ne '') {
      $filename = Glib::filename_display_name($prgname) . "-$filename";
    }
    $self->set_current_name ($filename);
  }

  return $self;
}

sub INIT_INSTANCE {
  my ($self) = @_;

  $self->set_destroy_with_parent (1);

  { my $title = __('Save Errors');
    if (defined (my $appname = Glib::get_application_name())) {
      $title = "$appname: $title";
    }
    $self->set_title ($title);
  }

  $self->add_buttons ('gtk-save'   => 'accept',
                      'gtk-cancel' => 'cancel');

  # connect to self instead of a class handler since as of Gtk2-Perl 1.200 a
  # Gtk2::Dialog class handler for 'response' is called with response IDs as
  # numbers, not enum strings like 'accept'
  $self->signal_connect (response => \&_do_response);

  my $label = Gtk2::Label->new
    (__('Save error messages to a file (with UTF-8 encoding)'));
  $label->show;
  my $vbox = $self->vbox;
  $vbox->pack_start ($label, 0,0,0);
  $vbox->reorder_child ($label, 0);  # at the top of the dialog
}

sub _do_response {
  my ($self, $response) = @_;
  ### ErrorText-SaveDialog response: $response

  if ($response eq 'accept') {
    $self->save;

  } elsif ($response eq 'cancel') {
    # raise 'close' as per a keyboard Esc to close, which defaults to
    # raising 'delete-event', which in turn defaults to a destroy
    $self->signal_emit ('close');
  }
}

sub save {
  my ($self) = @_;
  my $error_dialog = $self->get_transient_for;
  my $filename = $self->get_filename;

  # Gtk2-Perl 1.200 $chooser->get_filename gives back wide chars (where it
  # almost certainly should be bytes)
  if (utf8::is_utf8($filename)) {
    $filename = Glib->filename_from_unicode ($filename);
  }
  $self->hide;
  _save_to_filename ($error_dialog, $filename);
}

# The die() message here might be an unholy amalgam of filename charset
# $filename, and locale charset $!.  It probably occurs in many other
# libraries too, and you're probably asking for trouble if your filename and
# locale charsets are different, so leave it as just this simple combination
# for now.
#
sub _save_to_filename {
  my ($error_dialog, $filename) = @_;
  my $text = $error_dialog->get_text;
  ### ErrorText-SaveDialog _save_to_filename()
  ### $filename
  ### $text
  ### text utf8: utf8::is_utf8($text)
  ### text utf8 valid: utf8::valid($text)

  my $out;
  (open $out, '>:utf8', $filename
   and print $out $text
   and close $out)
    or die "Cannot write file $filename: $!";
}

1;
__END__

=for stopwords ErrorTextDialog Gtk2-Ex-ErrorTextDialog Gtk SaveDialog filename Ryde

=head1 NAME

Gtk2::Ex::ErrorTextDialog::SaveDialog -- save for ErrorTextDialog

=for test_synopsis my ($errordialog)

=head1 SYNOPSIS

 use Gtk2::Ex::ErrorTextDialog::SaveDialog;
 my $save_dialog = Gtk2::Ex::ErrorTextDialog::SaveDialog->new
                     (transient_for => $errordialog);

=head1 WIDGET HIERARCHY

C<Gtk2::Ex::ErrorTextDialog::SaveDialog> is a subclass of
C<Gtk2::FileChooserDialog>.

    Gtk2::Widget
      Gtk2::Container
        Gtk2::Bin
          Gtk2::Window
            Gtk2::Dialog
              Gtk2::FileChooserDialog
                Gtk2::Ex::ErrorTextDialog::SaveDialog

=head1 DESCRIPTION

B<This is part of C<Gtk2::Ex::ErrorTextDialog> and really not meant for
external use.>

A SaveDialog is popped up by the "Save As" button in an ErrorTextDialog.  It
gets a filename from the user and saves the error text to that file.
SaveDialog is separate for modularity and to slightly reduce the code in the
main ErrorTextDialog, because a save may be wanted only rarely.

=head1 FUNCTIONS

=head2 Creation

=over 4

=item C<< $savedialog = Gtk2::Ex::ErrorTextDialog::SaveDialog->new (key=>value,...) >>

Create and return a new ErrorTextDialog.  Optional key/value pairs set
initial properties as per C<< Glib::Object->new >>.  The originating
ErrorTextDialog should be set as the C<transient-for> parent.

    my $savedialog = Gtk2::Ex::ErrorTextDialog::SaveDialog->new
                       (transient_for => $errordialog);

But note C<transient-for> as a property is new in Gtk 2.10.  Use the
C<set_transient_for> method (available in all Gtk) to support prior
versions,

    my $savedialog = Gtk2::Ex::ErrorTextDialog::SaveDialog->new;
    $savedialog->set_transient_for ($errordialog);

=back

=head1 SEE ALSO

L<Gtk2::Ex::ErrorTextDialog>, L<Gtk2::FileChooserDialog>, L<Gtk2::FileChooser>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/gtk2-ex-errortextdialog/>

=head1 LICENSE

Gtk2-Ex-ErrorTextDialog is Copyright 2007, 2008, 2009, 2010 Kevin Ryde

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

# Not sure about making this available yet ...
#
# =head2 Other
# 
# =over 4
# 
# =item C<< Gtk2::Ex::ErrorTextDialog->save_to_filename ($filename) >>
# 
# =item C<< $errordialog->save_to_filename ($filename) >>
# 
# Save the messages in the ErrorTextDialog to the given C<$filename>.
# C<$filename> should be raw bytes ready for a perl C<open>, not wide chars.
# 
# =back
