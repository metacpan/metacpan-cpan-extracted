package File::JSON::Slurper::TestSupport;

use strict;
use warnings;
use parent 'Exporter';
use Const::Fast;

our @EXPORT_OK = qw/ file_json_slurper_tests /;

const my @TESTS =>
(

    {
        data        => [],
        filename    => 'empty-array.json',
        description => "an empty array",
    },

    {
        data        => {},
        filename    => 'empty-hash.json',
        description => "an empty hash",
    },

    {
        data        => {color => 'red', integer => 42},
        filename    => 'simple-hash.json',
        description => "a simple hash",
    },

);

sub file_json_slurper_tests
{
    return @TESTS;
}

1;
