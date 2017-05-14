# static flags for optional behaviors; set in "rezrov"

package Games::Rezrov::ZOptions;

use strict;

my $INTERPRETER_ID = 6;
my $TANDY_BIT = 0;

my $SNOOP_OBJECTS = 0;
my $SNOOP_PROPERTIES = 0;
my $SNOOP_ATTR_TEST = 0;
my $SNOOP_ATTR_SET = 0;
my $SNOOP_ATTR_CLEAR = 0;

my $BEAUTIFY_LOCATIONS = 1;
my $HIGHLIGHT_OBJECTS = 0;

my $GUESS_TITLE = 1;
my $MAXIMUM_SCROLLING = 0;

my $CORRECT_TYPOS = 1;
# attempt to autocorrect typos a-la Nitfol

my $EMULATE_NOTIFY = 1;
# whether to emulate the "notify" score-notification command.
# useful when playing games without a status line (ie ZIO_dumb.pm)

my $NOTIFICATION_ON = 1;
# default startup state

my $EMULATE_OOPS = 1;
# whether to emulate the "oops" command for games that do not
# implement it

my $EMULATE_UNDO = 1;
# whether to emulate the "undo" command for games that do not support it

my $UNDO_SLOTS = 10;
# how many turns can we undo by default?

my $ALIASES = 1;
# for games that don't support them, alias:
#    "x" to "examine"
#    "g" to "again"
#    "z" to "wait"
#    "o" to "oops"

my $EMULATE_COMMAND_SCRIPT = 1;
# emulate the "#reco" and "#unre" commands for games that do not
# support them

my $COUNT_OPCODES = 0;
# print a count and summary of opcodes executed between inputs

my $WRITE_OPCODES = 0;
# write a report of opcodes being executed

my $MAGIC = 1;
# allow fun new words: "pilfer", "teleport", "bamf", "lingo", etc.

my $SHAMELESS = 1;
# allow shameless self-promotion

my $EMULATE_HELP = 1;
# pay attention to the "help" command

my $TIME_24 = 0;
# in "time games", show time in 24-hour format rather than AM/PM

my $PLAYBACK_DIE = 0;
# whether to exit after running a script file (for benchmarking)

my $END_OF_SESSION_MESSAGE = 1;
# display "end of session" message and pause when interpreter exits

1;

sub notifying {
  $NOTIFICATION_ON = $_[0] if @_;
  return ($EMULATE_NOTIFY and $NOTIFICATION_ON) ? 1 : 0;
}

sub SNOOP_OBJECTS {
  return (defined $_[0] ? $SNOOP_OBJECTS = $_[0] : $SNOOP_OBJECTS);
}

sub SNOOP_PROPERTIES {
  return (defined $_[0] ? $SNOOP_PROPERTIES = $_[0] : $SNOOP_PROPERTIES);
}

sub SNOOP_ATTR_TEST {
  return (defined $_[0] ? $SNOOP_ATTR_TEST = $_[0] : $SNOOP_ATTR_TEST);
}

sub SNOOP_ATTR_SET {
  return (defined $_[0] ? $SNOOP_ATTR_SET = $_[0] : $SNOOP_ATTR_SET);
}

sub SNOOP_ATTR_CLEAR {
  return (defined $_[0] ? $SNOOP_ATTR_CLEAR = $_[0] : $SNOOP_ATTR_CLEAR);
}

sub BEAUTIFY_LOCATIONS {
  return (defined $_[0] ? $BEAUTIFY_LOCATIONS = $_[0] : $BEAUTIFY_LOCATIONS);
}

sub GUESS_TITLE {
  return (defined $_[0] ? $GUESS_TITLE = $_[0] : $GUESS_TITLE);
}

sub MAXIMUM_SCROLLING {
  return (defined $_[0] ? $MAXIMUM_SCROLLING = $_[0] : $MAXIMUM_SCROLLING);
}

sub EMULATE_NOTIFY {
  return (defined $_[0] ? $EMULATE_NOTIFY = $_[0] : $EMULATE_NOTIFY);
}

sub EMULATE_OOPS {
  return (defined $_[0] ? $EMULATE_OOPS = $_[0] : $EMULATE_OOPS);
}

sub EMULATE_UNDO {
  return (defined $_[0] ? $EMULATE_UNDO = $_[0] : $EMULATE_UNDO);
}

sub ALIASES {
  return (defined $_[0] ? $ALIASES = $_[0] : $ALIASES);
}

sub COUNT_OPCODES {
  return (defined $_[0] ? $COUNT_OPCODES = $_[0] : $COUNT_OPCODES);
}

sub WRITE_OPCODES {
  return (defined $_[0] ? $WRITE_OPCODES = $_[0] : $WRITE_OPCODES);
}

sub MAGIC {
  return (defined $_[0] ? $MAGIC = $_[0] : $MAGIC);
}

sub HIGHLIGHT_OBJECTS {
  return (defined $_[0] ? $HIGHLIGHT_OBJECTS = $_[0] : $HIGHLIGHT_OBJECTS);
}

sub INTERPRETER_ID {
  return (defined $_[0] ? $INTERPRETER_ID = $_[0] : $INTERPRETER_ID);
}

sub TANDY_BIT {
  return (defined $_[0] ? $TANDY_BIT = $_[0] : $TANDY_BIT);
}

sub UNDO_SLOTS {
  return (defined $_[0] ? $UNDO_SLOTS = $_[0] : $UNDO_SLOTS);
}

sub EMULATE_COMMAND_SCRIPT {
  return (defined $_[0] ? $EMULATE_COMMAND_SCRIPT = $_[0] : $EMULATE_COMMAND_SCRIPT);
}

sub SHAMELESS {
  return (defined $_[0] ? $SHAMELESS = $_[0] : $SHAMELESS);
}

sub EMULATE_HELP {
  return (defined $_[0] ? $EMULATE_HELP = $_[0] : $EMULATE_HELP);
}

sub TIME_24 {
  return (defined $_[0] ? $TIME_24 = $_[0] : $TIME_24);
}

sub PLAYBACK_DIE {
  return (defined $_[0] ? $PLAYBACK_DIE = $_[0] : $PLAYBACK_DIE);
}

sub END_OF_SESSION_MESSAGE {
  return (defined $_[0] ? $END_OF_SESSION_MESSAGE = $_[0] : $END_OF_SESSION_MESSAGE);
}

sub CORRECT_TYPOS {
  return (defined $_[0] ? $CORRECT_TYPOS = $_[0] : $CORRECT_TYPOS);
}


