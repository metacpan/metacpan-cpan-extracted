use strict;
use warnings;
use Test::More;

use FindBin;
use lib "$FindBin::Bin/lib";

use TestSetup;

use Git::Open;

my @possible_cases = (
    {
        opt => {
            compare => ''
        },
        expected_url => 'http://github.com/abc/xzy/compare'
    },
    {
        opt => {
            branch => ''
        },
        expected_url => 'http://github.com/abc/xzy/tree/masterxx'
    },
    {
        opt => {},
        expected_url => 'http://github.com/abc/xzy/'
    }
);

for my $case ( @possible_cases ) {

    my $app = Git::Open->new( $case->{opt} );
    is( $app->get_url, $case->{expected_url} );
}

done_testing();
