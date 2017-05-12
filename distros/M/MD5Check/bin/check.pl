#!/usr/bin/perl

use warnings;
use strict;
use POSIX qw(strftime);
use MD5Check;


my $pattern = shift;
print $pattern,"\n";
print md5check($pattern);

