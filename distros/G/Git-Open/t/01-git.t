use strict;
use warnings;
use Test::More;


use Test::Mock::Cmd 'qx' => {
    'git ls-remote --get-url' => sub { 
      return "git\@github.com:abc/xzy.git\n" 
    },
    'git symbolic-ref --short HEAD' => sub { return "masterxx\n"; }
};

use Git::Open;

my @possible_cases = (
    {
        opt => {
            compare => ''
        },
        expected_url => 'https://github.com/abc/xzy/compare'
    },
    {
        opt => {
            branch => ''
        },
        expected_url => 'https://github.com/abc/xzy/tree/masterxx'
    },
    {
        opt => {},
        expected_url => 'https://github.com/abc/xzy/'
    }
);

for my $case ( @possible_cases ) {

    my $app = Git::Open->new( $case->{opt} );
    is( $app->get_url, $case->{expected_url} );
}

done_testing();
