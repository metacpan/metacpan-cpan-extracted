#!/usr/bin/perl -w
use strict;
use Test::More tests => 37;

sub read_file { local $/; local *FH; open FH, shift or die $!; return <FH> }
use_ok("Email::Simple");
# Very basic functionality test
my $file_contents = read_file("t/test-mails/josey-nofold");

for my $mail_text ($file_contents, \$file_contents) {
  my $mail_text_string = ref $mail_text ? $$mail_text : $mail_text;

  my $mail = Email::Simple->new($mail_text);
  isa_ok($mail, "Email::Simple");

  my $old_from;
  is($old_from = $mail->header("From"), 
     'Andrew Josey <ajosey@rdg.opengroup.org>',  
      "We can get a header");
  my $sc = 'Simon Cozens <simon@cpan.org>';
  is($mail->header_set("From", $sc), $sc, "Setting returns new value");
  is($mail->header("From"), $sc, "Which is consistently returned");

  is(
    $mail->header("Bogus"),
    undef,
    "missing header returns undef"
  );

  # Put andrew back:
  $mail->header_set("From", $old_from);

  my $body;
  like($body = $mail->body, qr/Austin Group Chair/, "Body has sane stuff in it");
  my $old_body;

  my $hi = "Hi there!\n";
  $mail->body_set($hi);
  is($mail->body, $hi, "Body can be set properly");

  my $bye = "Goodbye!\n";
  $mail->body_set(\$bye);
  is($mail->body, $bye, "Body can be set with a ref to a string, too");

  $mail->body_set($body);
  is(
    $mail->as_string,
    $mail_text_string,
    "Good grief, it's round-trippable"
  );

  is(
    Email::Simple->new($mail->as_string)->as_string,
    $mail_text_string,
    "Good grief, it's still round-trippable"
  );

  {
    my $email = Email::Simple->new($mail->as_string);

    $email->body_set(undef);
    is(
      $email->body,
      '',
      "setting body to undef makes ->body return ''",
    );

    $email->body_set(0);
    is(
      $email->body,
      '0',
      "setting body to false string makes ->body return that",
    );

    $email->header_set('Previously-Unknown' => 'wonderful species');
    is(
      $email->header('Previously-Unknown'),
      'wonderful species',
      "we can add headers that were previously not in the message",
    );
    like(
      $email->as_string,
      qr/Previously-Unknown: wonderful species/,
      "...and the show up in the stringification",
    );
  }

  {
    # With nasty newlines
    my $nasty = "Subject: test\n\rTo: foo\n\r\n\rfoo\n\r";
    my $mail = Email::Simple->new($nasty);
    my ($pos, $mycrlf) = Email::Simple->_split_head_from_body(\$nasty);
    is($pos, 26, "got proper header-end offset");
    is($mycrlf, "\n\r", "got proper line terminator");
    my $test = $mail->as_string;
    is($test, $nasty, "Round trip that too");
    is(Email::Simple->new($mail->as_string)->as_string, $nasty, "... twice");
  }
}
