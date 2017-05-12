package Email::MIME::Creator::ISO_2022_JP::Test::Basic;

use strict;
use warnings;
use Email::MIME::Creator::ISO_2022_JP::Test::Base 'base';

sub create_email {
  my $class = shift;

  return Email::MIME->create(
    header_str => [
      From    => '<ishigaki@cpan.org>',
      To      => '<ishigaki@cpan.org>',
      Subject => $class->subject,
    ],
    attributes => {
      content_type => 'text/plain',
      charset => 'iso-2022-jp',
      encoding => '7bit',
    },
    body_str => $class->body,
  )->as_string;
}

sub test_00_original : Tests(2) {
  my $class = shift;

  my $email = $class->create_email;

  $class->has_utf8_subject($email);
  $class->has_iso_2022_jp_body($email);
}

sub test_01_import : Tests(2) {
  my $class = shift;

  $class->import_iso_2022_jp;

  my $email = $class->create_email;

  $class->has_iso_2022_jp_subject($email);
  $class->has_iso_2022_jp_body($email);
}

sub test_02_unimport : Tests(2) {
  my $class = shift;

  $class->unimport_iso_2022_jp;

  my $email = $class->create_email;

  $class->has_utf8_subject($email);
  $class->has_iso_2022_jp_body($email);
}

sub test_03_import_again : Tests(2) {
  my $class = shift;

  $class->import_iso_2022_jp;

  my $email = $class->create_email;

  $class->has_iso_2022_jp_subject($email);
  $class->has_iso_2022_jp_body($email);
}

1;
