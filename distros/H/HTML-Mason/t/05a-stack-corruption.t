use strict;
use warnings;

use HTML::Mason::Tests;

my $tests = make_tests();
$tests->run;

sub make_tests
{
    my $group = HTML::Mason::Tests->tests_class->new( name => 'stack_corruption',
                                                      description => 'tests for stack corruption',
                                                    );


    # The key to this test is that it first calls a component that in
    # turn has a comp-with-content call. That comp-with-content call
    # then calls $m->content (this is important).
    #
    # After that, _further_ component calls reveal stack corruption.
    $group->add_support( path => '/support/comp',
                         component => <<'EOF',
<&| .subcomp1 &>
<& .subcomp2 &>
</&>

<%def .subcomp1>
% $m->content;
</%def>

<%def .subcomp2>
content
</%def>
EOF
                       );

    $group->add_support( path => '/support/comp2',
                         component => <<'EOF',

EOF
                       );

    $group->add_test( name => 'stack_corruption',
                      description => 'test for stack corruption with comp-with-content call',
                      component => <<'EOF',
<& support/comp &>

<& support/comp2 &>

<& .callers &>

<%def .callers>
Stack at this point:
% for my $f ( $m->callers ) {
<% defined $f ? $f->path : 'undef' %>
% }
</%def>
EOF
                      expect => qr{/stack_corruption/stack_corruption:.callers\n(?!undef)},
                    );

    return $group;
}
