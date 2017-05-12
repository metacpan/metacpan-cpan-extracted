use strict;
use warnings;

use File::Basename;
use HTML::Mason::Tests;

my $outside_comp_root_test_file;
my $tests = make_tests();
$tests->run;

sub make_tests
{

    my $group = HTML::Mason::Tests->tests_class->new( name => 'comp-calls',
                                                      description => 'Component call syntax' );
    $outside_comp_root_test_file = dirname($group->comp_root) . "/.outside_comp";

#------------------------------------------------------------

    $group->add_support( path => '/support/amper_test',
                         component => <<'EOF',
amper_test.<p>
% if (%ARGS) {
Arguments:<p>
%   foreach my $key (sort keys %ARGS) {
<b><% $key %></b>: <% $ARGS{$key} %><br>
%   }
% }
EOF
                       );

#------------------------------------------------------------

    $group->add_test( name => 'ampersand',
                      description => 'tests all variations of component call path syntax',
                      component => <<'EOF',
<&support/amper_test&>
<& support/amper_test &>
<&  support/amper_test, &>
<& support/amper_test
&>
<&
support/amper_test &>
<&
support/amper_test
&>
EOF
                      expect => <<'EOF',
amper_test.<p>

amper_test.<p>

amper_test.<p>

amper_test.<p>

amper_test.<p>

amper_test.<p>

EOF
                 );

#------------------------------------------------------------

    $group->add_test( name => 'ampersand_with_args',
                      description => 'tests variations of component calls with arguments',
                      component => <<'EOF',
<& /comp-calls/support/amper_test, message=>'Hello World!'  &>
<& support/amper_test, message=>'Hello World!',
   to=>'Joe' &>
<& "support/amper_test" &>
% my $dir = "support";
% my %args = (a=>17, b=>32);
<& $dir . "/amper_test", %args &>
EOF
                      expect => <<'EOF',
amper_test.<p>
Arguments:<p>
<b>message</b>: Hello World!<br>

amper_test.<p>
Arguments:<p>
<b>message</b>: Hello World!<br>
<b>to</b>: Joe<br>

amper_test.<p>

amper_test.<p>
Arguments:<p>
<b>a</b>: 17<br>
<b>b</b>: 32<br>

EOF
                 );

#------------------------------------------------------------

    $group->add_support( path => '/support/funny_-+=@~~~._name',
                         component => <<'EOF',
foo is <% $ARGS{foo} %>
EOF
                       );

#------------------------------------------------------------

    $group->add_test( name => 'ampersand_with_funny_name',
                      description => 'component with non-alphabetic characters',
                      component => <<'EOF',
<& support/funny_-+=@~~~._name, foo => 5 &>
EOF
                      expect => <<'EOF',
foo is 5
EOF
                 );

#------------------------------------------------------------

    # This only tests for paths passed through Request::fetch_comp,
    # not Interp::load.  Not sure how zealously we want to
    # canonicalize.
    #
    $group->add_test( name => 'canonicalize_paths',
                      description => 'test that various paths are canonicalized to the same component',
                      component => <<'EOF',
<%perl>
my $path1 = '///comp-calls/support//amper_test';
my $comp1 = $m->fetch_comp($path1)
  or die "could not fetch comp1";
my $path2 = './support/./././amper_test';
my $comp2 = $m->fetch_comp($path2)
  or die "could not fetch comp2";
my $path3 = './support/../support/../support/././amper_test';
my $comp3 = $m->fetch_comp($path3)
  or die "could not fetch comp3";
unless ($comp1 == $comp2 && $comp2 == $comp3) {
    die sprintf
        (
         "different component objects for same canonical path:\n  %s (%s -> %s)\n  %s (%s -> %s)\n  %s (%s -> %s)",
         $comp1, $path1, $comp1->path,
         $comp2, $path2, $comp2->path,
         $comp3, $path3, $comp3->path,
         );
}
$m->comp($comp1);
$m->comp($comp2);
$m->comp($comp3);
</%perl>
EOF
                      expect => <<'EOF',
amper_test.<p>
amper_test.<p>
amper_test.<p>
EOF
                 );

#------------------------------------------------------------

    $group->add_test( name => 'fetch_comp_no_arg',
                      description => 'fetch_comp with blank or undefined argument returns undef',
                      component => <<'EOF',
fetch_comp(undef) = <% defined($m->fetch_comp(undef)) ? 'defined' : 'undefined' %>
fetch_comp("") = <% defined($m->fetch_comp("")) ? 'defined' : 'undefined' %>
EOF
                      expect => <<'EOF',
fetch_comp(undef) = undefined
fetch_comp("") = undefined
EOF
                 );

#------------------------------------------------------------

    $group->add_test( name => 'outside_comp_root_prepare',
                      description => 'test that file exists in dist/t for next two tests',
                      pre_code => sub { local *F; open(F, ">$outside_comp_root_test_file"); print F "hi"; },
                      component => "test file '$outside_comp_root_test_file' <% -e '$outside_comp_root_test_file' ? 'exists' : 'does not exist' %>",
                      expect => "test file '$outside_comp_root_test_file' exists",
                 );

#------------------------------------------------------------

    $group->add_test( name => 'outside_comp_root_absolute',
                      description => 'cannot call components outside comp root with absolute path',
                      component => <<'EOF',
<& /../.outside_comp &>
EOF
                      expect_error => qr{could not find component for path '/../.outside_comp'},
                 );

#------------------------------------------------------------

    $group->add_test( name => 'outside_comp_root_relative',
                      description => 'cannot call components outside comp root with relative path',
                      component => <<'EOF',
<& ../../.outside_comp &>
EOF
                      expect_error => qr{could not find component for path '../../.outside_comp'},
                 );

#------------------------------------------------------------

    # put /../ in add_support path to put component right under comp root
    $group->add_support( path => '/../outside_comp_root_from_top',
                         component => <<'EOF',
<& ../.outside_comp &>
EOF
                       );

#------------------------------------------------------------

    $group->add_test( name => 'outside_comp_root_relative_from_top',
                      description => 'cannot call components outside comp root with relative path from component at top of root',
                      component => <<'EOF',
<& /outside_comp_root_from_top &>
EOF
                      expect_error => qr{could not find component for path '../.outside_comp'},
                 );

#------------------------------------------------------------

    $group->add_test( name => 'parent_designator_with_no_parent',
                      description => 'using PARENT from component with no parent',
                      component => <<'EOF',
<%flags>
inherit=>undef
</%flags>

<& PARENT:foo &>
EOF
                      expect_error => qr/PARENT designator used from component with no parent/,
                 );

#------------------------------------------------------------

    $group->add_test( name => 'no_such_method',
                      description => 'calling nonexistent method on existing component',
                      component => <<'EOF',
<& support/amper_test:bar &>
EOF
                      expect_error => qr/no such method 'bar' for component/,
                 );

#------------------------------------------------------------

    $group->add_test( name => 'fetch_comp_no_errors',
                      description => 'fetch_comp should not throw any errors',
                      component => <<'EOF',
% foreach my $path (qw(foo support/amper_test:bar PARENT)) {
<% $m->fetch_comp($path) ? 'defined' : 'undefined' %>
% }
EOF
                      expect => <<'EOF',
undefined
undefined
undefined
EOF
                 );

#------------------------------------------------------------

    $group->add_support( path => '/support/methods',
                         component => <<'EOF',
<%method foo></%method>
EOF
                       );

#------------------------------------------------------------

    $group->add_test( name => 'comp_exists',
                      description => 'test comp_exists with various types of paths',
                      component => <<'EOF',
<%perl>
my @paths = qw(
   support/methods
   support/methods:foo
   support/methods:bar
   .foo
   .bar
   SELF
   SELF:foo
   PARENT
   PARENT:foo
   REQUEST
   REQUEST:foo
);
</%perl>

<%def .foo></%def>

% foreach my $path (@paths) {
<% $path %>: <% $m->comp_exists($path) %>
% }
EOF
                      expect => <<'EOF',


support/methods: 1
support/methods:foo: 1
support/methods:bar: 0
.foo: 1
.bar: 0
SELF: 1
SELF:foo: 0
PARENT: 0
PARENT:foo: 0
REQUEST: 1
REQUEST:foo: 0
EOF
                 );

#------------------------------------------------------------

    $group->add_test( name => 'comp_exists_no_arg',
                      description => 'comp_exists with blank or undefined argument returns 0',
                      component => <<'EOF',
comp_exists(undef) = <% $m->comp_exists(undef) %>
comp_exists("") = <% $m->comp_exists("") %>
EOF
                      expect => <<'EOF',
comp_exists(undef) = 0
comp_exists("") = 0
EOF
                 );

    return $group;
}
