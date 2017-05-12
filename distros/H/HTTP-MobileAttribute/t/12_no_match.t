use strict;
use warnings;
use Test::More tests => 1;
use HTTP::MobileAttribute::Agent::AirHPhone;
use HTTP::MobileAttribute::Request;

local $^W = 1;

my $agent = HTTP::MobileAttribute::Agent::AirHPhone->new(
    {
        request => HTTP::MobileAttribute::Request->new('DoCoMo/1.0'),
        carrier_longname => 'AirHPhone',
    }
);

my $warn = do {
    my $warn;
    local $SIG{__WARN__} = sub {
        $warn .= "@_";
    };
    $agent->parse();
    $warn;
};
like $warn, qr{please contact the author};

