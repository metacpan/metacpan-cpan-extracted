#!/usr/local/bin/perl -w
use strict;
use IPC::Open2;
my $command = "/usr/bin/ssh -X localhost perl -d:ptkdb";
my ( $readpipe, $writepipe );
my $pid = open2( $readpipe, $writepipe, $command);
{
local $/ = '__END__';
my $x = <DATA>;
print $writepipe "$x\n";
}
print $writepipe "Hello\n";
print <$readpipe>;
__END__
$a = 4;
print "$a\n";
$b = <>;
print "$b\n";
$a = 4;
print "$a\n";
__END__

