use strict;
use warnings;

use HTML::Mason::Tests;

my $tests = make_tests();
$tests->run;

sub make_tests
{
    my $group =
         HTML::Mason::Tests->tests_class->new( name => 'filter',
                                               description => 'Tests <%filter> specific problems' );

#------------------------------------------------------------

    $group->add_test( name => 'filter_and_shared',
                      description =>
                      'make sure <%filter> can see variables from <%shared>',
                      component => <<'EOF',
I am X
<%shared>
my $change_to = 'Y';
</%shared>
<%filter>
s/X/$change_to/;
</%filter>
EOF
                      expect => <<'EOF',
I am Y
EOF
                    );

#------------------------------------------------------------

    $group->add_test( name => 'filter_and_ARGS',
                      description =>
                      'make sure <%filter> can see variables %ARGS',
                      call_args => { change_to => 'Y' },
                      component => <<'EOF',
I am X
<%filter>
s/X/$ARGS{change_to}/;
</%filter>
EOF
                      expect => <<'EOF',
I am Y
EOF
                    );

#------------------------------------------------------------

    $group->add_test( name => 'filter_and_ARGS_assign',
                      description =>
                      'make sure <%filter> can see changes to %ARGS',
                      component => <<'EOF',
I am X
<%init>
$ARGS{change_to} = 'Y';
</%init>
<%filter>
s/X/$ARGS{change_to}/;
</%filter>
EOF
                      expect => <<'EOF',
I am Y
EOF
                    );

#------------------------------------------------------------

    $group->add_test( name => 'filter_and_args_section',
                      description =>
                      'make sure <%filter> can see variables from <%args> section',
                      component => <<'EOF',
I am X
<%args>
$change_to => 'Y'
</%args>
<%filter>
s/X/$change_to/;
</%filter>
EOF
                      expect => <<'EOF',
I am Y
EOF
                    );

#------------------------------------------------------------

    $group->add_test( name => 'filter_and_args_error',
                      description =>
                      'args error should not present a problem for <%filter>',
                      component => <<'EOF',
<%args>
$required
</%args>

foo

<%filter>
s/foo/bar/g;
</%filter>
EOF
                      expect_error => qr/no value sent for required parameter/,
                    );

#------------------------------------------------------------

    $group->add_support( path => '/support/has_filter',
                         component => <<'EOF',
lower case
<%filter>
$_ = uc $_;
</%filter>
EOF
                       );

    $group->add_test( name => 'filter_and_clear',
                      description => 'make sure <%filter> does not break $m->clear_buffer',
                      component => <<'EOF',
I should not show up.
<& support/has_filter &>
% $m->clear_buffer;
I should show up.
EOF
                      expect => <<'EOF',
I should show up.
EOF
                    );

#------------------------------------------------------------

    $group->add_test( name => 'filters_in_subcomps',
                      description => 'test <%filter> sections in subcomps only',
                      component => <<'EOF',
Main Component
<& .sub1 &>
<& .sub2 &>

<%def .sub1>
Sub 1
<%filter>
s/Sub/Subcomponent/;
</%filter>
</%def>

<%def .sub2>
Subcomp 2
<%filter>
s/Subcomp/Subcomponent/;
</%filter>
</%def>

EOF
                      expect => <<'EOF',
Main Component

Subcomponent 1


Subcomponent 2
EOF
                    );

#------------------------------------------------------------

    $group->add_test( name => 'filters_in_comp_and_subcomps',
                      description => 'test <%filter> sections in both main comp and subcomps',
                      component => <<'EOF',
Main Component (lowercase)
<& .sub1 &>
<& .sub2 &>

<%def .sub1>
Sub 1
<%filter>
s/Sub/Subcomponent/;
</%filter>
</%def>

<%def .sub2>
Subcomp 2
<%filter>
s/Subcomp/Subcomponent/;
</%filter>
</%def>

<%filter>
$_ = lc($_);
</%filter>

EOF
                      expect => <<'EOF',
main component (lowercase)

subcomponent 1


subcomponent 2
EOF
                    );

#------------------------------------------------------------

    $group->add_test( name => 'filter_and_flush',
                      description => 'test that filter still occurs in presence of flush',
                      component => <<'EOF',
hello
% $m->flush_buffer;
goodbye
<%filter>
tr/a-z/A-Z/
</%filter>
EOF
                      expect => <<'EOF',
HELLO
GOODBYE
EOF
                    );

#------------------------------------------------------------

    $group->add_support( path => 'clear_filter_comp',
                         component => <<'EOF',
Bar
% $m->clear_buffer;
Baz
EOF
                       );


#------------------------------------------------------------

    $group->add_test( name => 'clear_in_comp_called_with_filter',
                      description => 'Test that clear_buffer clears _all_ buffers, even inside a filter',
                      component => <<'EOF',
Foo
<& clear_filter_comp &>\
<%filter>
s/^/-/gm;
</%filter>
EOF
                      expect => <<'EOF',
-Baz
EOF
                    );

#------------------------------------------------------------

    $group->add_support( path => 'some_comp',
                         component => <<'EOF',
Some stuff
EOF
                       );


#------------------------------------------------------------

    $group->add_test( name => 'comp_call_in_filter',
                      description => 'Test that calling another component from a filter section works',
                      component => <<'EOF',
Stuff
<%filter>
$_ .= $m->scomp( 'some_comp' );
$_ = lc $_;
</%filter>
EOF
                      expect => <<'EOF',
stuff
some stuff
EOF
                    );

#------------------------------------------------------------

    $group->add_support( path => '/auto_filter_die/dies',
                         component => <<'EOF',
% die "foo death";
EOF
                       );


    $group->add_support( path => '/auto_filter_die/autohandler',
                         component => <<'EOF',
autohandler
% $m->call_next;
EOF
                       );


    $group->add_test( name => 'auto_filter_die/abort_comp_call_in_filter_with_autohandler',
                      description => 'Test that calling another component that dies from a filter section in a component wrapped by an autohandler produces a proper error',
                      component => <<'EOF',
Stuff
<%filter>
$m->comp( 'dies' );
</%filter>
EOF
                      expect_error => qr/foo death/,
                    );

#------------------------------------------------------------

    $group->add_support( path => '/support/abort_in_filter',
                         component => <<'EOF',
Will not be seen
<%filter>
$m->abort;
$_ = lc $_;
</%filter>
EOF
                       );

    $group->add_test( name => 'abort_in_filter',
                      description => 'Test that abort in a filter causes no output',
                      component => <<'EOF',
Before the abort
<& support/abort_in_filter &>
After the abort - not seen
EOF
                      expect => <<'EOF',
Before the abort
EOF
                    );

#------------------------------------------------------------

    $group->add_support( path => '/support/abort_in_shared_with_filter',
                         component => <<'EOF',
<%shared>
$m->abort('dead');
</%shared>

<%filter>
$_ = lc $_;
</%filter>
EOF
                       );

    $group->add_test( name => 'abort_in_shared_with_filter',
                      description => 'Test that abort in a shared block works when component has a filter block',
                      component => <<'EOF',
<% $out %>
<%init>
eval { $m->comp( 'support/abort_in_shared_with_filter' ) };
my $e = $@;

my $out = 'no error';
if ($e)
{
    $out = $m->aborted($e) ? $e->aborted_value : "error: $e";
}
</%init>
EOF
                      expect => <<'EOF',
dead
EOF
                    );

#------------------------------------------------------------

        return $group;
}

