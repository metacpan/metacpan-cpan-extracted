use strict;
use warnings;

use lib 'lib';

use Email::ARF::Report;

my $message = <<'END_MESSAGE';
From:  some@guy.com
Subject: lul!!
Message-Id: <abc@def.gh>

This...
  ...is...
    ...CAKETOWN!
END_MESSAGE

my $nl = $/;
$message =~ s{$nl}{\x0d\x0a}g;

print $message;

print '-' x 72, "\n";

my %fields;
$fields{'Source-IP'}     = "1.2.3.4";
$fields{'Feedback-Type'} = "abuse";
my $description = "This is an abuse report in ARF format.";

my $report = Email::ARF::Report->create(
  original_email => $message,
  description    => $description,
  fields         => \%fields,
);

$report->{mime}{mycrlf} = "\x0d\x0a";

print $report->as_string;
