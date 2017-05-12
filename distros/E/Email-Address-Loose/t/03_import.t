use strict;
use warnings;
use Test::More tests => 2;

use Email::Address;
use Email::Address::Loose -override;

my $docomo = 'rfc822.@docomo.ne.jp';

my @emails;
@emails = Email::Address->parse($docomo);
ok @emails == 1, "loose already";

Email::Address::Loose->globally_unoverride;
@emails = Email::Address->parse($docomo);
ok @emails == 0, "restore";
