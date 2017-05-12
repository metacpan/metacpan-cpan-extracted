use strict;
use warnings;

use Test::Simple tests => 3;

use Farly::ASA::ICMPFormatter;

my $icmp = Farly::ASA::ICMPFormatter->new();

ok ($icmp->isa('Farly::ASA::ICMPFormatter'), "new");

ok ($icmp->as_string(3) eq "unreachable", "as_string");

ok ($icmp->as_integer('router-advertisement') == 9, "as_integer");
