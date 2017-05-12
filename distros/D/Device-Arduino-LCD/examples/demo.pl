#!/usr/bin/perl

use strict;
use Time::HiRes qw[ usleep ];
use FindBin;
use lib "$FindBin::Bin/../lib";

use Device::Arduino::LCD;

# instantiate an object, opening the serial port in the process.
my $lcd = Device::Arduino::LCD->new;

# clear the display.
$lcd->clear;

# print some text.
$lcd->first_line("Mr. Quux");
$lcd->second_line("(son of Foo)");

# print more text, scrolling upwards
$lcd->scroll_up(["is a", "wicked", "hacker."], 1, 1, 1);

# wipe the text away.
$lcd->scroll_left(50);

# print some dots.
for my $col (0 .. 15) {
  $lcd->place_string(".", 1, $col);

  # we have access to some PWM pins on the Arduino as well.
  $lcd->gauge_pct(1 => ((100/16) * $col));

  usleep 250_000;
}

# custom characters can be created on the fly and displayed.
$lcd->first_line("k. with a hat.");
$lcd->make_char(0 => 159,152,152,155,158,156,158,155);
$lcd->write_ascii(0, 2, 0);

# and the LCD & gauges can be reset.
sleep 2;
$lcd->reset;

# commands can be also be sent directly.  for instance, turn the
# cursor on and make it blink (eek).
$lcd->command(15);
sleep 2;

# make that stop.
$lcd->command(12);

# set the DDRAM address (row 2, char position 3) directly.  this is
# probably not any faster than place_string().
my ($row, $col) = (2, 3);
use constant { ddram_cmd => 128, row_multiplier => 64 };
$lcd->command( ddram_cmd + (row_multiplier * ($row - 1)) + ($col - 1));
$lcd->print_char('k');

sleep 2;
$lcd->reset;
