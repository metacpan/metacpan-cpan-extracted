#!/usr/local/bin/perl -w
use strict;
use IPC::Open2;

my $command = "/usr/bin/ssh -X localhost perl -d:ptkdb";

my $prog = << 'EOP';
$a = 4;
print "$a\n";
$b = <STDIN>;
print "$b\n";
$a = 4;
print "$a\n";
__END__
EOP

my ( $readpipe, $writepipe );
my $pid = open2( $readpipe, $writepipe, $command);

syswrite $writepipe, "$prog\n";

syswrite $writepipe, "Hello\n";

print <$readpipe>;

