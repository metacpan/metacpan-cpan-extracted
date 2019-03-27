use strict;
use warnings;
use 5.010;

use Device::Firewall::PaloAlto;


use Test::More tests => 3;

is( Device::Firewall::PaloAlto::Op::_gen_op_xml('show routing route'), '<show><routing><route></route></routing></show>', "CMD to XML" );
is( Device::Firewall::PaloAlto::Op::_gen_op_xml('show interface', 'all'), '<show><interface>all</interface></show>', "CMD to XML with variable" );
is( Device::Firewall::PaloAlto::Op::_gen_op_xml('show arp', { name => 'all' }), q{<show><arp><entry name="all"/></arp></show>}, "CMD to XML with attribute" );

