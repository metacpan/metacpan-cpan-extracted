use strict;
use warnings;

use Test::More;

BEGIN { use_ok('HealthCheck::Diagnostic::SMTP') };

diag(qq(HealthCheck::Diagnostic::SMTP Perl $], $^X));

my $hc = HealthCheck::Diagnostic::SMTP->new;
my $res;

$res = $hc->check;
is $res->{info}, "host is required\n", 'Expected check error with no host';

local $@;
eval {
     $res = $hc->run;
};
is $@, "host is required\n", 'Expected run error with no host';

no warnings 'redefine';
local *HealthCheck::Diagnostic::SMTP::smtp_connect = sub {
    My::Happy::Net::SMTP->new;
};
use warnings 'redefine';

is_deeply $hc->run( host => 'localhost' ), {
    status => 'OK',
    info   => 'hi lol'
}, 'Expected successful response';

no warnings 'redefine';
local *HealthCheck::Diagnostic::SMTP::smtp_connect = sub {
    My::Sad::Net::SMTP->new;
};
use warnings 'redefine';

is_deeply $hc->run( host => 'localhost' ), {
    status => 'CRITICAL',
    info   => 'cant connect lol'
}, 'Expected successful response';

done_testing;

{
    package My::Happy::Net::SMTP;
    sub new    { bless {}, shift }
    sub banner { 'hi lol' }
    sub quit   {}
};
{
    package My::Sad::Net::SMTP;
    sub new    { $@ = 'cant connect lol'; return undef }
    sub banner { 'you wont see me' }
    sub quit   {}
};
