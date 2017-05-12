use strict;
use warnings;

use File::Spec;
use HTML::Mason::Tests;

my $tests = make_tests();
$tests->run;

sub make_tests {
    my $group = HTML::Mason::Tests->tests_class->new(
        name        => 'flush-in-content',
        description => 'recursive calls with $m->content'
    );

    #------------------------------------------------------------

    $group->add_support(
        path      => '/widget',
        component => <<'EOF',
<div>\
<% $content |n %>\
</div>\
<%init>
my $content = $m->content;
</%init>
EOF
    );

    #------------------------------------------------------------

    $group->add_support(
        path      => '/block',
        component => <<'EOF',
<block></block>\
% $m->flush_buffer;
EOF
    );

    #------------------------------------------------------------

    $group->add_test(
        name => 'flush-in-deep-content',
        description =>
            'make sure flush does not flush when we are in $m->content()',
        component => <<'EOF',
<&| widget &><&| widget &><& block &></&></&>
EOF
        expect => <<'EOF',
<div><div><block></block></div></div>
EOF
    );

    return $group;
}

