use strict;
use warnings;
use utf8;

use Test::More tests => 2;
use lib 't/lib';

use Email::MIME::Kit;

{
  package TestFriend;
  sub new  { bless { name => $_[1] } => $_[0] }
  sub name { return $_[0]->{name} }
}

for my $kit (qw(encode encode-file)) {
  subtest "encoding with $kit" => sub {
    my $kit = Email::MIME::Kit->new({
      source     => "t/kits/$kit.mkit",
    });

    {
      my $email = $kit->assemble({
        friend   => TestFriend->new('Jimbo Johnson'),
        how_long => '10 years',
      });

      like(
        $email->as_string,
        qr{(?m:^Subject: Hello Jimbo Johnson[\x0d\x0a])},
        "plain ol' strings in the subject with 7-bit friend.name (qr{})",
      );

      like(
        $email->body_raw,
        qr{This goes out to Jimbo Johnson},
        "plain text body",
      );
    }

    {
      my $email = $kit->assemble({
        friend   => TestFriend->new('Jÿmbo Jºhnsøn'),
        how_long => '10 years',
      });

      like(
        $email->as_string,
        qr{^Subject: =\?UTF-8\?}m,
        "encoded words in the subject with 8-bit friend.name",
      );

      like(
        $email->header_obj->header_raw('Subject'),
        qr{\A=\?UTF-8\?}m,
        "subject is encoded",
      );

      is(
        $email->header_obj->header('Subject'),
        'Hello Jÿmbo Jºhnsøn',
        "...subject decodes properly",
      );

      like(
        $email->body_raw,
        qr{This goes out to J(?:=[0-9A-Fa-f]{2}){2}mbo},
        "q-p encoded body",
      );
    }
  };
}
