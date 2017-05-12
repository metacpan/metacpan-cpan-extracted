#!/usr/bin/perl -w -T

use strict;
use MIME::Explode;
use Benchmark;

my $start = new Benchmark;

my $mail = shift(@ARGV) || die("no args");
die("Unable to open file \"$mail\"") unless(-e $mail);

my $decode_subject = 1;
my $tmp_dir = "tmp";

my $output = "file.tmp";
my $explode = MIME::Explode->new(
	output_dir         => $tmp_dir,
	mkdir              => 0755,
	decode_subject     => $decode_subject,
	check_content_type => 1,
	content_types      => ["image/gif", "image/jpeg", "image/bmp"],
	types_action       => "exclude",
);

open(MAIL, "<$mail") or die("Couldn't open $mail for reading: $!\n");
open(OUTPUT, ">$output") or die("Couldn't open $output for writing: $!\n");
#my $headers = $explode->parse(\*MAIL);
my $headers = $explode->parse(\*MAIL, \*OUTPUT);
close(OUTPUT);
close(MAIL);

print "Number of messages: ", $explode->nmsgs, "\n";

for my $part (sort{ $a cmp $b } keys(%{$headers})) {
	print "---------------------------\n";
	for my $k (keys(%{$headers->{$part}})) {
		if(ref($headers->{$part}->{$k}) eq "ARRAY") {
			for my $i (0 .. $#{$headers->{$part}->{$k}}) {
				print "$part => $k => $i => ", $headers->{$part}->{$k}->[$i], "\n";
			}
		} elsif(ref($headers->{$part}->{$k}) eq "HASH") {
			for my $ks (keys(%{$headers->{$part}->{$k}})) {
				if(ref($headers->{$part}->{$k}->{$ks}) eq "ARRAY") {
					print "$part => $k => $ks => ", join(($ks eq "charset") ? " " : "", @{$headers->{$part}->{$k}->{$ks}}), "\n";
				} else {
					print "$part => $k => $ks => ", $headers->{$part}->{$k}->{$ks}, "\n";
				}
			}
		} else {
			print "$part => $k => ", $headers->{$part}->{$k}, "\n";
		}
	}
}

my $finish = new Benchmark;
my $diff = timediff($finish, $start);
my $strtime = timestr($diff);
print STDERR "\n\nTime: $strtime\n";

print "\n";
                                                                                
print "Clean the directory \"$tmp_dir\"? [y/n]:";
my $clean = <>;
chomp $clean;

if($clean eq "y") {
	if(my $e = $explode->clean_all()) {
		print "Error: $e\n";
	}
}
exit(0);
