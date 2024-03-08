##!/usr/bin/perl

print "loading...\n";
sleep 3;
print "string to transform: ";
my $data = <>;
print "transformed: ", uc( $data ), "\n";
