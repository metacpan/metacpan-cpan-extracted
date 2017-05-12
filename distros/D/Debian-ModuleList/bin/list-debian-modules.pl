#!/usr/bin/perl

use Debian::ModuleList;

my @list = Debian::ModuleList::list_modules();
print $_ . "\n" foreach (@list);
