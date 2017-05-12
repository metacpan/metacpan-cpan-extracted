package Email::MIME::Creator::ISO_2022_JP::Test::HeaderStrSet;

use strict;
use warnings;
use Email::MIME::Creator::ISO_2022_JP::Test::Base 'base';

sub create_email {
  my $class = shift;

  return Email::MIME->create(
    header_str => [
      From    => '<ishigaki@cpan.org>',
      To      => '<ishigaki@cpan.org>',
    ],
    attributes => {
      content_type => 'text/plain',
      charset => 'iso-2022-jp',
      encoding => '7bit',
    },
    body_str => $class->body,
  );
}

sub test_00_original : Test {
  my $class = shift;

  my $email = $class->create_email;

  $email->header_str_set(Subject => $class->subject);

  $class->has_utf8_subject($email->as_string);
}

sub test_01_import : Test {
  my $class = shift;

  $class->import_iso_2022_jp;

  my $email = $class->create_email;

  $email->header_str_set(Subject => $class->subject);

  $class->has_iso_2022_jp_subject($email->as_string);
}

sub test_02_unimport : Test {
  my $class = shift;

  $class->unimport_iso_2022_jp;

  my $email = $class->create_email;

  $email->header_str_set(Subject => $class->subject);

  $class->has_utf8_subject($email->as_string);
}

sub test_03_import_again : Test {
  my $class = shift;

  $class->import_iso_2022_jp;

  my $email = $class->create_email;

  $email->header_str_set(Subject => $class->subject);

  $class->has_iso_2022_jp_subject($email->as_string);
}

1;
