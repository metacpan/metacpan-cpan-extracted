#!/usr/bin/perl -w

$| = 1;
print " perl -MDev::Bollocks -e'print Dev::Bollocks->rand(),\"\\n\"'\n";
use Dev::Bollocks; print " ",Dev::Bollocks->rand(),"\n";
