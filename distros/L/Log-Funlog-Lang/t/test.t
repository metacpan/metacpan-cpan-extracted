#!/usr/bin/perl -w
use Test::More qw(no_plan);
use strict;
BEGIN {
    use_ok('Log::Funlog::Lang');
}
my @fun=Log::Funlog::Lang->new('en');
ok( $#fun == 1,'Array returned is 2 elements long');
ok(ref($fun[1]) eq 'ARRAY', '... and second element is an array');
ok($fun[0] eq 'en',"Language asked: 'en', language returned: 'en'");
@fun=Log::Funlog::Lang->new('zz');
ok($fun[0] eq 'en',"Asking a not existing language ('zz') and language returned is 'en'");
