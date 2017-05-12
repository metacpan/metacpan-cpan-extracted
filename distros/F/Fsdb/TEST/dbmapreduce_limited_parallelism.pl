#!/usr/bin/perl

# sleep 1;
print "#fsdb key\n";
sleep 2;  # go slow to block up parallelism
print $ARGV[0]. "-x" . "\n";
exit 0;
