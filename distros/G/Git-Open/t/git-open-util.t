use strict;
use warnings;
use Test::More;

use FindBin;
use lib "$FindBin::Bin/lib";

use TestSetup;

use Git::Open::Util;

my $app = Git::Open::Util->new();
subtest 'create correct service' => sub {
    is( $app->service, 'github' );
};

subtest _remote_url => sub {
    my $url =  $app->remote_url();
    is( $url, 'http://github.com/abc/xzy', 'Get remote url' );
};

subtest  _current_branch => sub {
    my $branch =  $app->current_branch();
    is( $branch, 'masterxx', 'Get current branch' );
};


test_gen(
    'no parameters passed',
    {},
    'http://github.com/abc/xzy/'
);

subtest 'branch url' => sub {
    test_gen(
        'Normal case',
        {
            branch => 'develop'
        },
        'http://github.com/abc/xzy/tree/develop'
    );

    test_gen(
        'Emptry branch',
        {
            branch => ''
        },
        'http://github.com/abc/xzy/tree/masterxx'
    );
};

subtest url_compare_opts => sub {
    test_gen(
        'Normal case',
        {
            compare => 'master-develop'
        },
        'http://github.com/abc/xzy/compare/master...develop'
    );
};

sub test_gen {
    my $test_name = shift;
    my $args = shift;
    my $extected = shift;

    my $url = $app->generate_url($args);
    is( $url, $extected, $test_name );
};

done_testing();
