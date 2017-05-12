use strict;
use Test::More tests => 5;

use Email::Address;
use Email::Address::Loose;

my $docomo = 'rfc822.@docomo.ne.jp';

my @emails;
@emails = Email::Address->parse($docomo);
ok @emails == 0, "default";

Email::Address::Loose->globally_override;
@emails = Email::Address->parse($docomo);
ok @emails == 1, "loose";
is($emails[0]->address, $docomo);
is($emails[0]->user, 'rfc822.');

Email::Address::Loose->globally_unoverride;
@emails = Email::Address->parse($docomo);
ok @emails == 0, "restore";
