use strict;
use warnings;

use Test::More tests => 5;

use Email::MIME::Kit;

my $kit = Email::MIME::Kit->new({
  source => 't/kits/test.mkit',
});

my $email_1 = $kit->assemble({
  name => 'Reticulo Johnson',
  game => "eatin' pancakes",
  postlude => '  OUT!',
});


my $body_1 = $email_1->body;
$body_1 =~ s{[\n\r]*\z}{}g;
is(
  $body_1,
  q{Reticulo Johnson is my name, eatin' pancakes is my game.  OUT!},
  "template stuff happened",
);

my $email_2 = $kit->assemble({
  name => 'Bryan Allen',
  game => "nukin' jar cheese",
});

my $body_2 = $email_2->body;
$body_2 =~ s{[\n\r]*\z}{}g;
is(
  $body_2,
  q{Bryan Allen is my name, nukin' jar cheese is my game.},
  "template stuff happened",
);

my $fail_kit = Email::MIME::Kit->new({
  source => 't/kits/fail.mkit',
});

my $lived = eval { $fail_kit->assemble({ game => 'failing' }); 1 };

ok(! $lived, "we die if the template can't be assembled");

my $fail2_kit = Email::MIME::Kit->new({
  source => 't/kits/fail2.mkit',
});

my $lived2 = eval { $fail2_kit->assemble({ game => 'failing' }); 1 };
my $error  = $@;

ok(! $lived2, "we die if the template can't be assembled");
like($@, qr/DEATH/, "...and the error message is what we wanted");

