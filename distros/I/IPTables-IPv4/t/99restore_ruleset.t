#!/usr/bin/perl

use IPTables::IPv4;
use FileHandle;

print "1..0\n";

$fh = new FileHandle("</tmp/ruleset.txt");
eval(join('', <$fh>));
close($fh);

%IPTables::IPv4 = %{$rules};
# vim: ts=4
