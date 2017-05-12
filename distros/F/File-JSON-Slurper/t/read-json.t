#! perl

use strict;
use warnings;
use lib 't/lib';

use File::JSON::Slurper                 qw/ read_json /;
use File::JSON::Slurper::TestSupport    qw/ file_json_slurper_tests /;
use Test::More 0.88;


foreach my $test (file_json_slurper_tests()) {
    my $ref = read_json("t/data/$test->{filename}");
    is_deeply($ref, $test->{data}, $test->{description});
}

done_testing;

