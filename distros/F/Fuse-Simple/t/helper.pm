#!/usr/bin/perl -Tw
package t::helper;
use Exporter;
our @ISA = qw(Exporter);
our @EXPORT= qw($mountpt);
our $mountpt = "/tmp/fusemnt-".$ENV{LOGNAME};
1;
