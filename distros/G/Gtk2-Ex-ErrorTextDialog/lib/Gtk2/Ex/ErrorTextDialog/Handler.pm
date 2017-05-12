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


# If there's both errors and warnings from a "require" file then a
# $SIG{'__WARN__'} handler can run while PL_error_count is non-zero.  In
# that case it's not possible to load modules within the warn handler, they
# get "BEGIN not safe after compilation error".
#
# The strategy against this is to pre-load enough to get a message to STDERR
# and install a Glib idle handler to load Gtk2::Ex::ErrorTextDialog and
# create that dialog.
#
package Gtk2::Ex::ErrorTextDialog::Handler;
use 5.008001; # for utf8::is_utf8() and PerlIO::get_layers()
use strict;
use warnings;
use Devel::GlobalDestruction ();
use Glib;
use Encode;
use I18N::Langinfo;  # CODESET
use PerlIO;          # for F_UTF8

our $VERSION = 11;

# set this to 1 for some diagnostic prints (to STDERR)
use constant DEBUG => 0;

my $_idle_another_message;
my $_idle_recursions = 0;
my $_idle_handler_id;

our $exception_handler_depth = 0;

sub exception_handler {
  my ($msg) = @_;
  if (DEBUG) { print STDERR "exception_handler() $exception_handler_depth\n"; }

  # Normally $SIG handlers run with themselves shadowed out, and the Glib
  # exception handler doesn't re-invoke, so suspect warnings or errors in
  # the code here won't recurse normally, but have this as some protection
  # just in case.
  #
  if ($exception_handler_depth >= 3) {
    return 1; # stay installed
  }
  if ($exception_handler_depth >= 2) {
    print STDERR "ErrorTextDialog Handler: ignoring recursive exception_handler calls\n";
    return 1; # stay installed
  }
  local $exception_handler_depth = $exception_handler_depth + 1;
  if (DEBUG) { print STDERR "  depth now $exception_handler_depth\n"; }

  #--------------------------------------------

  if (_fh_prints_wide('STDERR')) {
    $msg = _maybe_locale_bytes_to_wide ($msg);
  }
  print STDERR $msg;

  #--------------------------------------------

  if ($_idle_recursions == 4) {
    $_idle_recursions++;
    print STDERR "ErrorTextDialog Handler: repeated messages adding to dialog, skip GUI from now on\n";

  } elsif ($_idle_recursions < 4
           && ! Devel::GlobalDestruction::in_global_destruction()) {
    $_idle_another_message = 1;
    push @Gtk2::Ex::ErrorTextDialog::_instance_pending, $msg;

    # try to protect against unbounded growth of @_instance_pending
    if (@Gtk2::Ex::ErrorTextDialog::_instance_pending > 500) {
      splice @Gtk2::Ex::ErrorTextDialog::_instance_pending, 0, -500,
        '[Big slew of pending messages truncated ...]';
    }

    $_idle_handler_id ||= Glib::Idle->add
      (\&_idle_handler, undef, Glib::G_PRIORITY_HIGH);
  }

  if (DEBUG) { print STDERR "exception_handler() end\n"; }
  return 1; # stay installed
}

# $_idle_handler_id is zapped at the start so exception_handler() will add
# another _idle_handler() for any further messages generated within the
# present _idle_handler() run.  Anything before popup_add_message() will be
# covered by the present run, but anything after it needs another run.
#
# $_idle_recursions is incremented at the start as a worst case assumption
# that the code will die.  Then if the code runs successfully to the end it
# can be cleared.  It's cleared only if there were no further messages
# generated from within _idle_handler().  Further messages are noted by
# exception_handler() setting $_idle_another_message.
#
sub _idle_handler {
  $_idle_recursions++;
  $_idle_another_message = 0;
  undef $_idle_handler_id;
  if (DEBUG) { print STDERR "idle_handler() runs $_idle_recursions\n"; }

  require Gtk2::Ex::ErrorTextDialog;
  Gtk2::Ex::ErrorTextDialog->popup_add_message (undef);

  if (! $_idle_another_message) {
    $_idle_recursions = 0;
  }
  if (DEBUG) {
    print STDERR "idle_handler() end, recursions now $_idle_recursions\n";
  }
  return 0; # Glib::SOURCE_REMOVE
}

sub log_handler {
  require Gtk2::Ex::ErrorTextDialog;
  exception_handler (Gtk2::Ex::ErrorTextDialog::_log_to_string (@_));
}

#-----------------------------------------------------------------------------
# generic helpers

# _fh_prints_wide($fh) returns true if wide chars can be printed to file
# handle $fh.
#
# PerlIO::get_layers() is pre-loaded, probably, but PerlIO::F_UTF8() from
# PerlIO.pm is not.
#
sub _fh_prints_wide {
  my ($fh) = @_;
  return (PerlIO::get_layers($fh, output => 1, details => 1))[-1] # top flags
    & PerlIO::F_UTF8();
}

# If $str is not wide, and it has some non-ascii, then try to decode them in
# the locale charset.  PERLQQ means bad stuff is escaped.
sub _maybe_locale_bytes_to_wide {
  my ($str) = @_;
  if (! utf8::is_utf8 ($str) && $str =~ /[^[:ascii:]]/) {
    require Encode;
    $str = Encode::decode (_locale_charset_or_ascii(),
                           $str, Encode::FB_PERLQQ());
  }
  return $str;
}

# _locale_charset_or_ascii() returns the locale charset from I18N::Langinfo,
# or 'ASCII' if nl_langinfo() is not available.
#
# langinfo() croaks "nl_langinfo() not implemented on this architecture" if
# not available.  Though anywhere able to run Gtk would have nl_langinfo(),
# wouldn't it?
#
my $_locale_charset_or_ascii;
sub _locale_charset_or_ascii {
  goto $_locale_charset_or_ascii;
}
BEGIN {
  $_locale_charset_or_ascii = sub {
    my $subr = sub { I18N::Langinfo::langinfo(I18N::Langinfo::CODESET()) };
    if (! eval { &$subr(); 1 }) {
      $subr = sub { 'ASCII' };
    }
    goto ($_locale_charset_or_ascii = $subr);
  };
}


1;
__END__

=for stopwords ErrorTextDialog Gtk2-Ex-ErrorTextDialog Perl-Gtk Gtk Gtk2
stringized iconified Iconifying charset PerlIO utf8 STDERR Ryde

=head1 NAME

Gtk2::Ex::ErrorTextDialog::Handler -- exception handlers using ErrorTextDialog

=head1 SYNOPSIS

 use Gtk2::Ex::ErrorTextDialog::Handler;
 Glib->install_exception_handler
   (\&Gtk2::Ex::ErrorTextDialog::Handler::exception_handler);

 $SIG{'__WARN__'}
   = \&Gtk2::Ex::ErrorTextDialog::Handler::exception_handler;

 Glib::Log->set_handler ('My-Domain', ['warning','info'],
   \&Gtk2::Ex::ErrorTextDialog::Handler::log_handler);

=head1 DESCRIPTION

This module supplies error and warning handler functions which print to
C<STDERR> and display in an ErrorTextDialog.  The handlers are reasonably
small and the idea is to keep memory use down by not loading the full
ErrorTextDialog until needed.  If your program works then the dialog won't
be needed at all!

See F<examples/simple.pl> in the Gtk2-Ex-ErrorTextDialog sources for a
complete program with this sort of error handler.

=head1 FUNCTIONS

=over 4

=item C<< Gtk2::Ex::ErrorTextDialog::Handler::exception_handler ($str) >>

A function suitable for use with C<< Glib->install_exception_handler >> (see
L<Glib/EXCEPTIONS>) or with Perl's C<< $SIG{'__WARN__'} >> (see
L<perlvar/%SIG>).

    Glib->install_exception_handler
      (\&Gtk2::Ex::ErrorTextDialog::Handler::exception_handler);

    $SIG{'__WARN__'}
      = \&Gtk2::Ex::ErrorTextDialog::Handler::exception_handler;

The given C<$str> is printed to C<STDERR> and displayed in the shared
C<ErrorTextDialog> instance.  C<$str> can be an exception object too such as
a C<Glib::Error> and will be stringized for display.

=item C<< Gtk2::Ex::ErrorTextDialog::Handler::log_handler ($log_domain, $log_levels, $message) >>

A function suitable for use with C<< Glib::Log->set_handler >> (see
L<Glib::Log>).  It forms a message similar to the Glib default handler and
prints and displays per the C<exception_handler> function above.

    Glib::Log->set_handler ('My-Domain', ['warning','info'],
      \&Gtk2::Ex::ErrorTextDialog::Handler::log_handler);

As of Glib-Perl 1.200, various standard log domains are trapped already and
turned into Perl C<warn> calls (see L<Glib::xsapi/GLog> on
C<gperl_handle_logs_for>).  So if you trap C<< $SIG{'__WARN__'} >> then you
already get Glib and Gtk logs without any explicit C<Glib::Log> handlers.

=back

=head1 DETAILS

When an error occurs an existing ErrorTextDialog is raised so the error is
seen but it's not "presented", so it doesn't steal keyboard focus (unless
the window manager is focus-follows-mouse style).  This also means if the
dialog is iconified it's not re-opened for a new message, just the icon is
raised (by the window manager).  Iconifying is a good way to hide errors if
there's a big cascade.  But maybe this will change in the future.

The default action on closing the error dialog is to hide it, and past
messages are kept.  In an application it can be good to have a menu entry
etc which pops up the dialog with

    Gtk2::Ex::ErrorTextDialog->instance->present;

or similar, so the user can see past errors again after closing the dialog.

=head2 Wide Chars

If a message is a byte string then it's assumed to be in the locale charset.
If C<STDERR> takes wide chars (because it has a PerlIO encoding layer) then
the message is converted for the print.  The dialog always displays wide
chars (C<add_message> does a conversion if necessary).

If a message is a wide char string but C<STDERR> only takes raw bytes, then
currently they're just printed as normal and will generally provoke a "wide
char in print" warning.  Perhaps this will change in the future.

As of Perl-Gtk 1.222, C<< Glib->warning >> messages with wide chars don't
get through to Perl's C<warn> as wide but instead end up interpreted here as
locale bytes.  If your locale is utf8 then that's fine, but if not then
expect to see "A-grave" and similar odour of bad utf8, in both the GUI and
to STDERR.

=head2 Global Destruction

During "global destruction" of objects when Perl or a Perl thread is exiting
(see L<perlobj/Two-Phased Garbage Collection>), messages are printed to
C<STDERR> but not put to the dialog.  The dialog is an object and at that
point is either already destroyed or about to be destroyed.

Exceptions during global destruction can arise from C<DESTROY> methods on
Perl objects and C<destroy> etc signal emissions on Gtk objects.  Global
destruction is identified using C<Devel::GlobalDestruction>.

=head2 Idle Handler

Messages are printed to C<STDERR> immediately, but for the dialog are saved
away and added later under a high-priority Glib idle handler.  The handler
runs before Gtk resizing or redrawing so it should be the next thing seen by
the user.

This is important for C<$SIG{'__WARN__'}> handler calls which happen while a
Perl compile error is pending (C<< PL_parser->error_count >>).  It's not
possible to load the ErrorTextDialog module or any further modules while a
compile error is pending and attempting to do so gives a further error (see
L<perldiag/BEGIN not safe after errors--compilation aborted>).

If the process of adding messages to the dialog is itself causing further
errors or warnings then after a few attempts it's disabled and only
C<STDERR> used.  This shouldn't happen normally but the protection avoids
infinite repetition of errors if it does.

=head1 SEE ALSO

L<Gtk2::Ex::ErrorTextDialog>, L<Glib/EXCEPTIONS>, L<perlvar/%SIG>,
L<Glib::xsapi/GLog>, L<Devel::GlobalDestruction>

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
