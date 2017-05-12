#! perl

use strict;
use warnings;
use lib 't/lib';

use File::JSON::Slurper                 qw/ write_json read_json /;
use File::JSON::Slurper::TestSupport    qw/ file_json_slurper_tests /;
use Test::More 0.88;

foreach my $test (file_json_slurper_tests()) {
    my $data = $test->{data};
    my $name = $test->{description};

    write_json('test.json', $data);
    my $read_data = read_json('test.json');

    is_deeply($data, $read_data, $name);
}
unlink('test.json');

done_testing;

