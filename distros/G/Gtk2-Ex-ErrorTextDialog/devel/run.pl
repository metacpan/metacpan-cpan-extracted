#!/usr/bin/perl -w

# Copyright 2007, 2008, 2009, 2010, 2011 Kevin Ryde

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

use 5.008;
use strict;
use warnings;

BEGIN {
  $ENV{'LANG'} = 'ja_JP.utf8';
  $ENV{'LC_ALL'} = 'ja_JP.utf8';
  delete $ENV{'LANGUAGE'};

  $ENV{'LANG'} = 'de_DE';
  $ENV{'LC_ALL'} = 'de_DE';
  $ENV{'LANGUAGE'} = 'de';

  require POSIX;
  print "setlocale to ",POSIX::setlocale(POSIX::LC_ALL(),""),"\n";
}

use Gtk2;
use Gtk2::Ex::ErrorTextDialog;
use Gtk2::Ex::ErrorTextDialog::Handler;

use FindBin;
use lib::abs $FindBin::Bin;
my $progname = $FindBin::Script;

print "$progname: MessageDialog has 'text': ",
  Gtk2::MessageDialog->find_property('text')?"yes":"no","\n";

print "$progname: STDERR prints wide ",
  (Gtk2::Ex::ErrorTextDialog::Handler::_fh_prints_wide('STDERR')
   ? "yes" : "no"), "\n";

{
  require Encode;
  require I18N::Langinfo;
  my $charset = I18N::Langinfo::langinfo (I18N::Langinfo::CODESET());
  { no warnings 'once';
    local $PerlIO::encoding::fallback = Encode::PERLQQ; # \x{1234} style
    (binmode (STDOUT, ":encoding($charset)") &&
     binmode (STDERR, ":encoding($charset)"))
      or die "Cannot set :encoding on stdout/stderr: $!\n";
  }
}

print "$progname: STDERR prints wide ",
  (Gtk2::Ex::ErrorTextDialog::Handler::_fh_prints_wide('STDERR')
   ? "yes" : "no"), "\n";

print "$progname: _locale_charset_or_ascii() is ",
  Gtk2::Ex::ErrorTextDialog::Handler::_locale_charset_or_ascii(), "\n";

{
  require Locale::Messages;
  print "$progname: dgettext of 'Error' in gtk20 is ",
    Locale::Messages::dgettext('gtk20','Error'),"\n";
}
{
  my @layers = PerlIO::get_layers('STDERR', output => 1, details => 1);
  require Data::Dumper;
  printf "$progname: last flags %#X\n", $layers[-1];
  print Data::Dumper->Dump([\@layers],['STDERR layers']);
}

Gtk2->disable_setlocale;  # leave LC_NUMERIC alone for version nums
Gtk2->init;
my $toplevel = Gtk2::Window->new ('toplevel');
$toplevel->signal_connect (destroy => sub {
                             print "$progname: quit\n";
                             Gtk2->main_quit;
                           });

my $vbox = Gtk2::VBox->new (0, 0);
$toplevel->add ($vbox);

# Gtk2::Ex::ErrorTextDialog->popup;

{
  my $button = Gtk2::Button->new_with_label ("add_message()");
  $button->signal_connect (clicked => sub {
                             print "$progname: add\n";
                             require Gtk2::Ex::ErrorTextDialog;
                             Gtk2::Ex::ErrorTextDialog->popup_add_message("\
hello
fdjsk
fsdjkl
\x{C1}

fsdjk fkjsd kfj sdk
ksdjfksdksdjf s
");
# \x{2028}\x{2029}\x{2014}\x{204A}
                           });
  $vbox->pack_start ($button, 0,0,0);
}

{
  my $button = Gtk2::Button->new_with_label ("die() error");
  $button->signal_connect (clicked => \&induce_an_error);
  $vbox->pack_start ($button, 0,0,0);

  sub induce_an_error {
    print "$progname: inducing an error\n";
    level1();
  }
  sub level1 {
    level2();
  }
  sub level2 {
    level3();
  }
  sub level3 {
    nosuchfunc("an ff - \x{FF}");
  }
}
{
  my $button = Gtk2::Button->new_with_label ("die() propagated error");
  $button->signal_connect (clicked => \&induce_a_propagated_error);
  $vbox->pack_start ($button, 0,0,0);

  sub induce_a_propagated_error {
    print "$progname: inducing a propagated error\n";
    eval { die 'an error' };
    die;
  }
}
{
  my $button = Gtk2::Button->new_with_label ("warn() message");
  $button->signal_connect
    (clicked => sub {
       print "$progname: inducing an warning\n";
       warn "some sort of perl warning, utf8 bullet \x{2022} end";
     });
  $vbox->pack_start ($button, 0,0,0);
}
{
  my $button = Gtk2::Button->new_with_label ("warn() continuation");
  $button->signal_connect (clicked => sub {
                             print "$progname: inducing an warning and continuation\n";
                             warn "first part of the warning";
                             warn "\t(an extra remark)";
                             warn "\ta second extra";
                           });
  $vbox->pack_start ($button, 0,0,0);
}
{
  my $button = Gtk2::Button->new_with_label ("g_warning()");
  $button->signal_connect
    (clicked => sub {
       print "$progname: calling g_warning\n";
       Glib->warning (undef, "warning about something, utf8 bullet \x{2022} end");
     });
  $vbox->pack_start ($button, 0,0,0);
}
{
  my $button = Gtk2::Button->new_with_label ("g_log()");
  $button->signal_connect (clicked => sub {
                             print "$progname: calling g_log\n";
                             Glib->log ('My-Domain', 'info', 'an informational log message');
                           });
  $vbox->pack_start ($button, 0,0,0);
  Glib::Log->set_handler ('My-Domain', ['warning','info'],
                          \&Gtk2::Ex::ErrorTextDialog::Handler::log_handler);
  if (Glib::Log->can('set_default_handler')) {
    Glib::Log->set_default_handler (\&Gtk2::Ex::ErrorTextDialog::Handler::log_handler);
  }
}
{
  my $n = 1;
  my $button = Gtk2::Button->new_with_label ("popup_add_message()");
  $button->signal_connect (clicked => sub {
                             Gtk2::Ex::ErrorTextDialog->popup_add_message ("hello world $n");
                             $n++;
                           });
  $vbox->pack_start ($button, 0,0,0);
}
{
  my $button = Gtk2::Button->new_with_label ("big add_message()");
  $button->signal_connect
    (clicked => sub {
       Gtk2::Ex::ErrorTextDialog->popup_add_message
           (join ("\n", 1 .. 50));
     });
  $vbox->pack_start ($button, 0,0,0);
}
{
  my $button = Gtk2::Button->new_with_label ("present() dialog");
  $button->signal_connect
    (clicked => sub {
       Gtk2::Ex::ErrorTextDialog->instance->present;
     });
  $vbox->pack_start ($button, 0,0,0);
}
{
  package MyGlobalDestructionBadObject;
  sub new {
    my ($class) = @_;
    my $self = bless { }, $class;
    $self->{'circular_reference'} = $self;
    return $self;
  }
  sub DESTROY {
    warn "$progname: warning within MyGlobalDestructionBadObject DESTROY";
  }
  package main;
  my $button = Gtk2::Button->new_with_label
    ("induce global destruction\nerror on exit");
  $button->signal_connect
    (clicked => sub {
       MyGlobalDestructionBadObject->new;
       print "$progname: will give a warning on exit\n";
     });
  $vbox->pack_start ($button, 0,0,0);
}
{
  my $button = Gtk2::Button->new_with_label ("load MyRunawayWarnAndError.pm");
  $button->signal_connect
    (clicked => sub {
       print "$progname: loading MyRunawayWarnAndError\n";
#        local $SIG{'__WARN__'} = sub {
#          print STDERR "(WARNING):\n";
#          warn @_;
#        };
#        local $SIG{'__DIE__'} = sub {
#          print STDERR "(DIE):\n";
#          die @_;
#        };
       require MyRunawayWarnAndError;
     });
  $vbox->pack_start ($button, 0,0,0);
}
{
  my $button = Gtk2::Button->new_with_label ("emit 'clear' signal");
  my $id;
  $button->signal_connect
    (clicked => sub {
       my $dialog = Gtk2::Ex::ErrorTextDialog->instance;
       $id ||= $dialog->signal_connect (clear => sub {
                                          print "$progname: clear signal\n";
                                        });
       $dialog->signal_emit('clear');
     });
  $vbox->pack_start ($button, 0,0,0);
}


$SIG{'__WARN__'} = sub {
  print STDERR "$progname __WARN__ handler:\n";
  print STDERR "  utf8 ",utf8::is_utf8($_[0])?"yes":"no","\n";
  goto \&Gtk2::Ex::ErrorTextDialog::Handler::exception_handler;
};

# $SIG{'__WARN__'} = sub {
#   require Devel::StackTrace;
#   my $trace = Devel::StackTrace->new;
#   my $str = $trace->as_string;
#   print "--------------\n$str\n---------------\n";
#   goto \&Gtk2::Ex::ErrorTextDialog::Handler::exception_handler;
# };
# $SIG{'__WARN__'} = \&Gtk2::Ex::ErrorTextDialog::Handler::exception_handler;

if (0) {
  my $stacktrace;
  require Devel::StackTrace;
  sub my_die_handler {
    $stacktrace = Devel::StackTrace->new (no_refs => 1);
    die;
  }
  $SIG{__DIE__} = \&my_die_handler;
  sub my_exception_handler_with_stacktrace {
    my ($msg) = @_;
    if (defined $stacktrace) {
      $msg = "$msg";
      $msg =~ /\n$/ or $msg .= "\n";
      $msg .= $stacktrace;
      Gtk2::Ex::ErrorTextDialog::Handler::exception_handler ($msg);
    }
  }
  Glib->install_exception_handler (\&my_exception_handler_with_stacktrace);
} elsif (0) {
  Glib->install_exception_handler
    (\&Gtk2::Ex::ErrorTextDialog::Handler::exception_handler);
} else {
  Glib->install_exception_handler
    (sub {
       print STDERR "Glib exception handler:\n";
       goto \&Gtk2::Ex::ErrorTextDialog::Handler::exception_handler;
     });
}


# Glib::Log->set_default_handler (sub {
#                                   my $dialog = Gtk2::Ex::ErrorTextDialog->popup;
#                                   $dialog->glog_handler(@_);
#                                 });
# sub glog_handler {
#   my ($self, $log_domain, $log_level, $message) = @_;
#   my $str = ((defined $log_domain ? "$log_domain-" : "** ")
#              . "\U$log_level\E: "
#              . (defined $message ? $message : "(no message)"));
#   $self->add_message ($str);
# }


$toplevel->show_all;
Gtk2->main;
exit 0;
