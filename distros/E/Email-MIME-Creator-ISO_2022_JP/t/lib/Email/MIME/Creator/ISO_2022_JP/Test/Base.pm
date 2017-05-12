package Email::MIME::Creator::ISO_2022_JP::Test::Base;

use strict;
use warnings;
use Test::Classy::Base;
use Email::MIME;
use Encode;
use utf8;

sub subject { 'テスト'; }
sub body    { '本文'; }

sub has_utf8_subject {
  my ($class, $email) = @_;

  ok $email =~ /^Subject:\s*=\?UTF-8\?/im, $class->message('has utf-8 encoded subject');
}

sub has_iso_2022_jp_subject {
  my ($class, $email) = @_;

  ok $email =~ /^Subject:\s*=\?ISO-2022-JP\?/im, $class->message('has iso-2022-jp encoded subject');
}

sub has_iso_2022_jp_body {
  my ($class, $email) = @_;

  my $body_jis = quotemeta(encode(jis => $class->body));
  ok $email =~ /^$body_jis/m, $class->message('has jis encoded body');
}

sub has_date_headers {
  my ($class, $email, $num) = @_;

  my @dates = $email =~ /^Date:/mg;
  ok (($num ? @dates == $num : @dates), $class->message("date occurs " . @dates . " time(s)"));
}

sub import_iso_2022_jp {
  require Email::MIME::Creator::ISO_2022_JP;
  Email::MIME::Creator::ISO_2022_JP->import;
}

sub unimport_iso_2022_jp {
  Email::MIME::Creator::ISO_2022_JP->unimport;
}

1;
