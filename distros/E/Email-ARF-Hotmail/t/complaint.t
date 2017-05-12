#!/usr/bin/perl -w

use strict;
use Test::More tests => 5;

use Email::ARF::Hotmail;

# FH because we're being backcompat to pre-lexical
sub readfile {
	my $fn = shift;
	open FH, "$fn" or die $!;
	local $/;
	my $text = <FH>;
	close FH;
	return $text;
}

my $message = readfile('t/corpus/hotmail.msg');

my $report = Email::ARF::Hotmail->create_report($message);

my $des = $report->description;
$des =~ s/\R*//g;

is($des, "An email abuse report from hotmail", "description is right");
is($report->field("Source-IP"), "1.2.3.4", "source IP is right");
is($report->field("Feedback-Type"), "abuse", "feedback type is right");
is($report->field("User-Agent"), "Email::ARF::Hotmail-conversion", "user agent is right");
is($report->field("Version"), "0.1", "version is right");
