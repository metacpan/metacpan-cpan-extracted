#!/usr/bin/perl -w

use strict;
use Test::More tests => 8;

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

my $message = readfile('t/corpus/hotmail-complaint.msg');

my $report = Email::ARF::Hotmail->create_report($message);

my $des = $report->description;
$des =~ s/\R*//g;

is($des, "An email abuse report from hotmail", "description is right");
is($report->field("Source-IP"), "5.6.7.8", "source IP is right");
is($report->field("Feedback-Type"), "abuse", "feedback type is right");
is($report->field("User-Agent"), "Email::ARF::Hotmail-conversion", "user agent is right");
is($report->field("Version"), "0.1", "version is right");
is($report->field("Original-Rcpt-To"), 'a@b.c', "Original rcpt to is right");

is($report->original_email->header("From"), 'John Smith <john.smith@email.example.com>', "Original email from is right");
my @parts = $report->original_email->parts;

my $body = $parts[0]->body;

like($body, qr/^helloworld/, "original mail body is right");

