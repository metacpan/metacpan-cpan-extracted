#!/usr/bin/perl -w
use strict;
use Gnome2;

# $Id$

my $application = Gnome2::Program -> init("Test", "0.1", "libgnomeui");
my $client = Gnome2::Client -> master();

###############################################################################

$client -> signal_connect(die => sub {
  # No time to save anything, just die.
  Gtk2 -> main_quit();
});

$client -> signal_connect(save_yourself => sub {
  my ($client,
      $phase,
      $save_style,
      $shutting_down,
      $interact_style,
      $fast) = @_;

  if ($fast) { # We're in a hurry, so don't do anything that takes ages.
    unless (save_session_quickly()) {
      error("Saving session failed.") if ($interact_style & "error");
      return 0;
    }
  }
  else { # We've plenty of time.
    unless (save_session()) {
      if ($interact_style & "any") {
        question("Couldn't save session.  Do you want me to " .
                 "delete all your personal files in response?",
                 sub { delete_all_personal_files(); });
      }
      elsif ($interact_style & "error") {
        error("Saving session failed.");
      }

      return 0;
    }
  }

  return 1;
});

###############################################################################

my $app = Gnome2::App -> new("test", "Test");
my $box = Gtk2::VBox -> new(0, 0);

my $button_die = Gtk2::Button -> new("_Die");
my $button_save = Gtk2::Button -> new("_Save");
my $button_save_quickly = Gtk2::Button -> new("Save quickly");

# Normally, those events are fired by the session manager when the user logs
# out or kills the application via the session UI.  We emulate them here.
$button_die -> signal_connect(clicked => sub {
  $client -> signal_emit("die");
});

$button_save -> signal_connect(clicked => sub {
  $client -> request_save("local", 0, "any", 0, 0);
});

$button_save_quickly -> signal_connect(clicked => sub {
  $client -> request_save("local", 0, "errors", 1, 0);
});

$box -> pack_start($button_die, 0, 0, 0);
$box -> pack_start($button_save, 0, 0, 0);
$box -> pack_start($button_save_quickly, 0, 0, 0);

$app -> set_contents($box);
$app -> show_all();

$app -> signal_connect(destroy => sub {
  Gtk2 -> main_quit();
});

Gtk2 -> main();

###############################################################################

sub delete_all_personal_files {
  $| = 1;
  print "Deleting all personal files ...";
  select(undef, undef, undef, 0.25);
  print " done.\n";
}

sub error {
  my ($label) = @_;

  my $dialog = Gtk2::MessageDialog -> new($app,
                                          [qw(modal destroy-with-parent)],
                                          "error",
                                          "ok",
                                          $label);

  $dialog -> signal_connect(response => sub {
    my ($dialog, $response) = @_;
    $dialog -> hide();
  });

  $client -> save_error_dialog($dialog);
}

sub question {
  my ($label, $callback) = @_;

  my $dialog = Gtk2::MessageDialog -> new($app,
                                          [qw(modal destroy-with-parent)],
                                          "question",
                                          "yes-no",
                                          $label);

  $dialog -> signal_connect(response => sub {
    my ($dialog, $response) = @_;
    $callback -> () if ($response eq "yes");
    $dialog -> hide();
  });

  $client -> save_any_dialog($dialog);
}

sub save_session {
  select(undef, undef, undef, 0.5);
  return int(rand(2));
}

sub save_session_quickly {
  select(undef, undef, undef, 0.1);
  return int(rand(2));
}
