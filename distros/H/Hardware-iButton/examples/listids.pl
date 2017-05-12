#!/usr/bin/perl -w

#use blib;
use Hardware::iButton::Connection;

$c = new Hardware::iButton::Connection "/dev/ttyS8" or die;
$s = $c->reset();
print "reset returned $s\n";

@bs = $c->scan();

foreach $b (@bs) {
    print "fam ",$b->family," ser ",$b->serial," crc ",$b->crc,": ",
    $b->model(),"\n";
}
