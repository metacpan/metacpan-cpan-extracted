use strict;
use warnings;

use Test::Simple tests => 3;
use Farly::ASA::ProtocolFormatter;

my $protocol_f = Farly::ASA::ProtocolFormatter->new();

ok ($protocol_f->isa('Farly::ASA::ProtocolFormatter'), "new");

ok ($protocol_f->as_string(89) eq "ospf", "as_string");

ok ($protocol_f->as_integer('ipinip') == 4, "as_integer");

