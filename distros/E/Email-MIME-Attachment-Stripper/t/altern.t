#!perl
use strict;
use warnings;

use Test::More tests => 3;

use_ok "Email::MIME::Attachment::Stripper";
use Email::MIME;

open IN, "t/Mail/altern.msg" or die "Can't read mail";
my $message = do { local $/; <IN>; };

sub parts {
  my ($msg) = @_;
  my ($ct) = ($msg->content_type =~ /^(.+?)(;|$)/);
  my @parts = ($ct, [ map { parts($_) } $msg->subparts ]);
  return \@parts;
}

{
	my $msg = Email::MIME->new($message);

  my $want = [
    'multipart/mixed' => [
      [
        'multipart/alternative' => [
          [ 'text/plain' => [] ],
          [ 'text/html'  => [] ],
        ],
      ],
      [
        'application/pdf' => [],
      ]
    ]
  ];

  is_deeply(parts($msg), $want, "the msg from disk is what we expect");

  my $stripper = Email::MIME::Attachment::Stripper->new($msg);

  my $want_stripped = [
    'multipart/mixed' => [
      [ 'text/plain' => [] ],
    ],
  ];

  is_deeply(
    parts($stripper->message),
    $want_stripped,
    "we strip down to what we want",
  );
}
