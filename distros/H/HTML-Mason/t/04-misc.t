use strict;
use warnings;

use File::Spec;
use HTML::Mason::Tests;

my $tests = make_tests();
$tests->run;

sub make_tests
{
    my $group = HTML::Mason::Tests->tests_class->new( name => 'misc',
                                                      description => 'autohandler and dhandler functionality' );


#------------------------------------------------------------

    $group->add_support( path => '/autohandler_test/autohandler',
                         component => <<'EOF',
<& header &>
Autohandler comp: <% $m->fetch_next->title %>
% my $buf;
% $m->call_next(b=>$a*2);
<& footer &>

<%args>
$a=>5
</%args>
EOF
                       );


#------------------------------------------------------------

    $group->add_support( path => '/autohandler_test/header',
                         component => <<'EOF',
<body bgcolor=<% $bgcolor %>>
<h2>The Site</h2>

<%args>
$bgcolor=>'white'
</%args>
EOF
                       );


#------------------------------------------------------------

    $group->add_support( path => '/autohandler_test/footer',
                         component => <<'EOF',
<hr>
Copyright 1999 Schmoopie Inc.

EOF
                       );


#------------------------------------------------------------

    $group->add_test( name => 'autohandler',
                      path => '/autohandler_test/hello',
                      call_path => '/autohandler_test/hello',
                      description => 'autohandler test',
                      component => <<'EOF',
Hello World!
The answer is <% $b %>.
<%args>
$b
</%args>



EOF
                      expect => <<'EOF',
<body bgcolor=white>
<h2>The Site</h2>


Autohandler comp: /misc/autohandler_test/hello
Hello World!
The answer is 10.



<hr>
Copyright 1999 Schmoopie Inc.



EOF
                    );



#------------------------------------------------------------

    $group->add_support( path => '/dhandler_test/dhandler',
                         component => <<'EOF',
dhandler = <% $m->current_comp->title %>
dhandler arg = <% $m->dhandler_arg %>
EOF
                       );


#------------------------------------------------------------

    $group->add_support( path => '/dhandler_test/subdir/dhandler',
                         component => <<'EOF',
% $m->decline if $m->dhandler_arg eq 'leaf3';
% $m->decline if $m->dhandler_arg eq 'slashes';
% $m->decline if $m->dhandler_arg eq 'buffers';
dhandler = <% $m->current_comp->title %>
dhandler arg = <% $m->dhandler_arg %>
EOF
                       );


#------------------------------------------------------------

    $group->add_support( path => '/dhandler_test/subdir/autohandler',
                         component => <<'EOF',
Header
<% $m->call_next %>
EOF
                       );


#------------------------------------------------------------

    $group->add_support( path => '/dhandler_test/bar/dhandler',
                         component => <<'EOF',
dhandler = <% $m->current_comp->title %>
dhandler arg = <% $m->dhandler_arg %>
EOF
                       );

#------------------------------------------------------------

    $group->add_support( path => '/dhandler_test/buff/dhandler',
                         component => <<'EOF',
Buffer stack size: <% scalar $m->buffer_stack %>
EOF
                       );


#------------------------------------------------------------

    $group->add_test( name => 'dhandler1',
                      description => 'tests dhandler against nonexistent comp',
                      call_path => '/dhandler_test/foo/bar',
                      skip_component => 1,
                      expect => <<'EOF',
dhandler = /misc/dhandler_test/dhandler
dhandler arg = foo/bar

EOF
                    );


#------------------------------------------------------------

    $group->add_test( name => 'dhandler2',
                      description => 'real comp to make sure the real comp is invoked, not the dhandler',
                      path => '/dhandler_test/subdir/leaf',
                      call_path => '/dhandler_test/subdir/leaf',
                      component => <<'EOF',
I'm leaf
EOF
                      expect => <<'EOF',
Header
I'm leaf

EOF
                    );


#------------------------------------------------------------

    $group->add_test( name => 'dhandler3',
                      description => 'real comp declines the request to make sure the dhandler is invoked',
                      path => '/dhandler_test/subdir/leaf2',
                      call_path => '/dhandler_test/subdir/leaf2',
                      component => <<'EOF',
% $m->decline;
I'm leaf2

EOF
                      expect => <<'EOF',
Header
dhandler = /misc/dhandler_test/subdir/dhandler
dhandler arg = leaf2

EOF
                    );


#------------------------------------------------------------

    $group->add_test( name => 'dhandler4',
                      description => 'declines twice to make sure higher level dhandler is called',
                      path => '/dhandler_test/subdir/leaf3',
                      call_path => '/dhandler_test/subdir/leaf3',
                      component => <<'EOF',
% $m->decline;
I'm leaf3
EOF
                      expect => <<'EOF',
dhandler = /misc/dhandler_test/dhandler
dhandler arg = subdir/leaf3

EOF
                    );

#------------------------------------------------------------

    $group->add_test( name => 'dhandler5',
                      description => 'decline with doubled slash (//) in URL path',
                      path => '/dhandler_test/subdir/slashes',
                      call_path => '//dhandler_test//subdir//slashes',
                      component => <<'EOF',
% $m->decline;
I have many slashes!
EOF
                      expect => <<'EOF',
dhandler = /misc/dhandler_test/dhandler
dhandler arg = subdir/slashes

EOF
                    );

#------------------------------------------------------------

    $group->add_test( name => 'dhandler6',
                      description => 'test that a dhandler more than one directory up is found',
                      call_path => '/dhandler_test/bar/baz/quux/not_here',
                      skip_component => 1,
                      expect => <<'EOF',
dhandler = /misc/dhandler_test/bar/dhandler
dhandler arg = baz/quux/not_here

EOF
                    );

#------------------------------------------------------------

    $group->add_test( name => 'accessor_validate',
                      description => 'test accessor parameter validation',
                      component => <<'EOF',
% $m->interp->ignore_warnings_expr([1]);
EOF
                      expect_error => qr/Parameter #1.*to .*? was an 'arrayref'/,
                    );

#------------------------------------------------------------

    $group->add_test( name => 'contained_accessor_validate',
                      description => 'test contained accessor parameter validation',
                      component => <<'EOF',
% $m->interp->autoflush([1]);
EOF
                      expect_error => qr/Parameter #1.*to .*? was an 'arrayref'/,
                    );

#------------------------------------------------------------

    # define /dhandler that sometimes declines. test framework should provide a
    # more supported way to define a top-level component!
    my $updir = File::Spec->updir;
    $group->add_support( path => "$updir/dhandler",
                         component => <<'EOF',
% if ($m->request_args->{decline_from_top}) {
%   $m->decline;
% } else {
top-level dhandler: path = <% $m->current_comp->path %>
% }
EOF
                       );

#------------------------------------------------------------

    $group->add_support( path => '/dhandler',
                         component => <<'EOF',
% $m->decline;
EOF
                       );

#------------------------------------------------------------

    $group->add_test( name => 'top_level_dhandler_handles',
                      description => 'make sure dhandler at /dhandler is called correctly after decline from lower-level dhandler',
                      path      => '/notused',
                      call_path => '/nonexistent',
                      component => <<'EOF',
not ever used
EOF
                      expect => <<'EOF',
top-level dhandler: path = /dhandler
EOF
                    );

#------------------------------------------------------------

    $group->add_test( name => 'top_level_dhandler_declines',
                      description => 'make sure /dhandler decline results in not-found error',
                      path      => '/notused2',
                      call_path => '/nonexistent',
                      call_args => { decline_from_top => 1 },
                      component => <<'EOF',
not ever used
EOF
                      expect_error => qr/could not find component for initial path/,
                    );

#------------------------------------------------------------

    return $group;
}
