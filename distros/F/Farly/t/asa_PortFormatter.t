use strict;
use warnings;

use Test::Simple tests => 3;
use Farly::ASA::PortFormatter;

my $port_f = Farly::ASA::PortFormatter->new();

ok ($port_f->isa('Farly::ASA::PortFormatter'), "new");

ok ($port_f->as_string(101) eq "hostname", "as_string");

ok ($port_f->as_integer('ctiqbe') == 2748, "as_integer");
