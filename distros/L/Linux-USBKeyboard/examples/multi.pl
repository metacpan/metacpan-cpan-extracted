#!/usr/bin/perl

use warnings;
use strict;

use IO::Select;

use lib 'lib';
use Linux::USBKeyboard;

my @kpid = (0x0e6a, 0x6001); # keypad
my @ccid = (0x0801, 0x0001); # magstripe reader
#  @ccid = (0x04d9, 0x1400);

my $kp = Linux::USBKeyboard->open(@kpid);
my $cc = Linux::USBKeyboard->open(@ccid);

my $sel = IO::Select->new;
$sel->add($kp);
$sel->add($cc);

while(my @ready = $sel->can_read) {
  #warn "ready count: ", scalar(@ready);
  foreach my $fh (@ready) {
    my $v;
    if($fh == $cc) { # treat linewise
      chomp($v = <$fh>);
    }
    else { # charwise
      $v = getc($fh);
    }
    print $fh->pid, " says: $v\n";
  }
}


# vim:ts=2:sw=2:et:sta
