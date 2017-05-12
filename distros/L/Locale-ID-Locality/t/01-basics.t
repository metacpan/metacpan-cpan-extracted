#!perl

use 5.010;
use strict;
use warnings;
use Log::Any::IfLOG '$log';

use Test::More 0.98;

use Locale::ID::Locality qw(
                               list_id_localities
                       );

subtest list_id_localities => sub {
    my $res = list_id_localities(bps_code=>'3273', detail=>1);
    is($res->[0], 200, "status");
    is(scalar(@{$res->[2]}), 1, "num");
    is($res->[2][0]{ind_name}, 'BANDUNG', "ind_name");
    is($res->[2][0]{type}, 1, "type");
};

done_testing();
