use strict;
use warnings;

use Test::More tests => 2;

use Email::MIME::Kit;

my $kit = Email::MIME::Kit->new({
  source => 't/kits/test.mkit',
});

my $email = $kit->assemble({
  html => '<div>You got:<ul><li>10 dunks</li><li>2 fatalities</li></ul></div>',
  you  => 'Victor Fries',
});

my ($text, $html) = $email->subparts;

like(
  $text->body_str,
  qr{\x0d\x0a  \* 10 dunks\x0d\x0a},
  "text part includes html converted to text",
);

like(
  $html->body,
  qr{\Q<li>10 dunks</li>},
  "html part still includes html arg",
);
