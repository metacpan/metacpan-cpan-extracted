#!perl
use strict;
use warnings;

use Test::More tests => 10;

BEGIN { use_ok('Email::ARF::Report'); }

my %code;

$code{string} = sub {
  my ($filename) = @_;
  open my $fh, '<', "t/messages/$filename.msg" or die "couldn't read file: $!";
  my $content = do { local $/; <$fh> };
  my $report = Email::ARF::Report->new($content);

  ok(
    $report->as_string eq $content,
    "string: $filename: report stringifies to content",
  );

  ok(
    $report->as_email->as_string eq $content,
    "string: $filename: report stringifies to content",
  );

  return $report;
};

$code{str_ref} = sub {
  my ($filename) = @_;
  open my $fh, '<', "t/messages/$filename.msg" or die "couldn't read file: $!";
  my $content = do { local $/; <$fh> };
  my $copy    = $content;
  my $report = Email::ARF::Report->new(\$content);

  ok(
    $report->as_string eq $copy,
    "str_ref: $filename: report stringifies to content",
  );

  ok(
    $report->as_email->as_string eq $copy,
    "str_ref: $filename: report stringifies to content",
  );

  return $report;
};

$code{object} = sub {
  my ($filename) = @_;
  open my $fh, '<', "t/messages/$filename.msg" or die "couldn't read file: $!";
  my $content = do { local $/; <$fh> };
  my $mime = Email::MIME->new($content);
  my $report = Email::ARF::Report->new($mime);

  ok(
    $report->as_string eq $content,
    "object: $filename: report stringifies to content",
  );

  ok(
    $report->as_email->as_string eq $content,
    "object: $filename: report stringifies to content",
  );

  return $report;
};

my %data = (
  example0 => { 'feedback-type' => 'abuse'   },
  example1 => { 'feedback-type' => 'opt-out' },
  example2 => { 'feedback-type' => 'abuse', 'source-ip' => '10.67.41.167' },
);

for my $code (keys %code) {
  while (my ($file, $attr) = each %data) {
    subtest "$file: $code" => sub {
      plan tests => 8 + keys(%$attr);

      my $report = $code{$code}->($file);
      isa_ok($report, 'Email::ARF::Report');

      is(
        $report->feedback_type,
        $attr->{'feedback-type'},
        "feedback_type"
      );

      is($report->user_agent,  'SomeGenerator/1.0', "user_agent");
      is($report->arf_version, '0.1',               "arf_version");

      for my $field (keys %$attr) {
        is($report->field($field), $attr->{$field}, "$field");
      }

      is(
        $report->original_email->header('subject'),
        'Earn money',
        "we can get headers from the original message via the report",
      );

      like(
        $report->description,
        qr/\QIP 10.67.41.167\E/,
        "we seem to be able to get the report description",
      );
    };
  }
}
