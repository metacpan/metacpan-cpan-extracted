use strict;
use warnings;

use Config;
use HTML::Mason::Tests;

my $tests = make_tests();
$tests->run;

sub make_tests {
    my $group = HTML::Mason::Tests->tests_class->new(
        name        => 'has space',
        description => 'compiler test for paths with spaces'
    );

    $group->add_test(
        name        => 'whatever',
        description => 'error in component in path with spaces',
        component   => <<'EOF',
% $foo = 1;
EOF
        expect_error => qr/.+line 1/,
    );

    return $group;
}
