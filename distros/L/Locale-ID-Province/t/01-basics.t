#!perl

use 5.010;
use strict;
use warnings;
use Log::Any::IfLOG '$log';

use Test::More 0.98;

use Locale::ID::Province qw(
                               list_id_provinces
                       );

subtest list_id_provinces => sub {
    my $res = list_id_provinces(iso3166_2_code => 'ID-JB');
    is($res->[0], 200, "status");
    is(scalar(@{$res->[2]}), 1, "num");
    is($res->[2][0], 'Jawa Barat', "ind_name");
};

done_testing();
