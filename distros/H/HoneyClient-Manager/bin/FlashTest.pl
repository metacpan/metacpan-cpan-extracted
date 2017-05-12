#!/usr/bin/perl -w -Ilib

# $Id: FlashTest.pl 783 2007-07-30 17:43:19Z kindlund $

use File::Temp ();
use HoneyClient::Agent::Driver::ActiveContent qw(process);

$ARGV[0] or die "Usage: FlashTest.pl <file.swf>\n";

open(SWF, $ARGV[0]);
binmode SWF;

my $tempFile = new File::Temp(SUFFIX => '.swf');
my $buffer;

while (
  read(SWF, $buffer, 65536) and print $tempFile $buffer
) {};

close(SWF);
$tempFile->close();

my %urls = HoneyClient::Agent::Driver::ActiveContent::process(
  file      => $tempFile,
  base_url  => 'http://foo.bar.com',
);

print "\nURLs:\n";

foreach (sort keys %urls) {
  print "\t$_\n";
}

use Data::Dumper;
$Data::Dumper::Terse = 0;
$Data::Dumper::Indent = 1;
print Dumper(\%urls) . "\n";
