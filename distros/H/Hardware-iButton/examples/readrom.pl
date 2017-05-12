#!/usr/bin/perl -w

use Hardware::iButton::Connection;

$c = new Hardware::iButton::Connection "/dev/ttyS8" or die;
$s = $c->reset();
print "reset returned $s\n";

@id = $c->readrom();
printf("family code: 0x%02x\n", $id[0]);
print "id: ", join(' ', map { sprintf('%02X', $_) } @id[1..6]), "\n";
printf("CRC: 0x%02x\n", $id[7]);
