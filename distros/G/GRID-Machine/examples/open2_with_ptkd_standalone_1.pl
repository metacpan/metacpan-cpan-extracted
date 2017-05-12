#!/usr/local/bin/perl -w
use strict;
use IPC::Open2;
my $command = "/usr/bin/ssh -X localhost perl -d:ptkdb";
my ( $readpipe, $writepipe );
my $pid = open2( $readpipe, $writepipe, $command);
{
local $/ = '__END__';
my $x = <>;
print $writepipe "$x\n";
}
print $writepipe "Hello\n";
print <$readpipe>;

