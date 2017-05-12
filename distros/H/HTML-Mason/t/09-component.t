use strict;
use warnings;

use HTML::Mason::Tests;

my $tests = make_tests();
$tests->run;

sub make_tests
{
    my $group = HTML::Mason::Tests->tests_class->new( name => 'component',
                                                      description => 'Component object functionality' );


#------------------------------------------------------------

    $group->add_test( name => 'comp_obj',
                      path => 'comp_obj_test/comp_obj',
                      call_path => 'comp_obj_test/comp_obj',
                      description => 'Tests several component object methods',
                      component => <<'EOF',
<%def .subcomp>
% my $adj = 'happy';
I am a <% $adj %> subcomp.
<%args>
$crucial
$useless=>17
</%args>
</%def>

<%method meth>
% my $adj = 'sad';
I am a <% $adj %> method.
<%args>
$crucial
$useless=>17
</%args>
</%method>

% my $anon = $m->interp->make_component(comp_source=>join("\n",'% my $adj = "flummoxed";','I am a <% $adj %> anonymous component.'),name=>'anonymous');

<% '-' x 60 %>

File-based:
<& /shared/display_comp_obj, comp=>$m->current_comp &>

<% '-' x 60 %>

Subcomponent:
<& /shared/display_comp_obj, comp=>$m->fetch_comp('.subcomp')  &>

<% '-' x 60 %>

Method:
<& /shared/display_comp_obj, comp=>$m->fetch_comp('SELF:meth')  &>

<% '-' x 60 %>

Anonymous component:
<& $anon &>
<& $anon &>
<& /shared/display_comp_obj, comp=>$anon &>

<%args>
@animals=>('lions','tigers')
</%args>
EOF
                      expect => <<'EOF',



------------------------------------------------------------

File-based:
Declared args:
@animals=>('lions','tigers')

I am not a subcomponent.
I am not a method.
I am file-based.
My short name is comp_obj.
My directory is /component/comp_obj_test.
I have 1 subcomponent(s).
Including one called .subcomp.
My title is /component/comp_obj_test/comp_obj.

My path is /component/comp_obj_test/comp_obj.
My comp_id is /component/comp_obj_test/comp_obj.


------------------------------------------------------------

Subcomponent:
Declared args:
$crucial
$useless=>17

I am a subcomponent.
I am not a method.
I am not file-based.
My short name is .subcomp.
My parent component is /component/comp_obj_test/comp_obj.
My directory is /component/comp_obj_test.
I have 0 subcomponent(s).
My title is /component/comp_obj_test/comp_obj:.subcomp.

My path is /component/comp_obj_test/comp_obj:.subcomp.
My comp_id is [subcomponent '.subcomp' of /component/comp_obj_test/comp_obj].


------------------------------------------------------------

Method:
Declared args:
$crucial
$useless=>17

I am a subcomponent.
I am a method.
I am not file-based.
My short name is meth.
My parent component is /component/comp_obj_test/comp_obj.
My directory is /component/comp_obj_test.
I have 0 subcomponent(s).
My title is /component/comp_obj_test/comp_obj:meth.

My path is /component/comp_obj_test/comp_obj:meth.
My comp_id is [method 'meth' of /component/comp_obj_test/comp_obj].


------------------------------------------------------------

Anonymous component:
I am a flummoxed anonymous component.
I am a flummoxed anonymous component.
Declared args:

I am not a subcomponent.
I am not a method.
I am not file-based.
My short name is [anon something].
I have 0 subcomponent(s).
My title is [anon something].

My comp_id is [anon something].
EOF
                     );


#------------------------------------------------------------

    $group->add_test( name => 'context',
                      description => 'Tests list/scalar context propogation in comp calls',
                      component => <<'EOF',
Context checking:

List:\
% my $discard = [$m->comp('.subcomp')];


Scalar:\
% scalar $m->comp('.subcomp');


Scalar:\
<& .subcomp &>

<%def .subcomp>
% $m->print( wantarray ? 'array' : 'scalar' );
</%def>
EOF
                      expect => <<'EOF',
Context checking:

List:
array

Scalar:
scalar

Scalar:
scalar

EOF
                    );


#------------------------------------------------------------

    $group->add_test( name => 'scomp',
                      description => 'Test scomp Request method',
                      component => <<'EOF',

% my $text = $m->scomp('.subcomp', 1,2,3);
-----
<% $text %>

<%def .subcomp>
 Hello, you say <% join '', @_ %>.
</%def>
EOF
                      expect => <<'EOF',

-----

 Hello, you say 123.


EOF
                    );


#------------------------------------------------------------

    $group->add_test( name => 'mfu_count',
                      description => 'Test mfu_count component method',
                      component => <<'EOF',
<% $m->current_comp->mfu_count %>
% $m->current_comp->mfu_count(75);
<% $m->current_comp->mfu_count %>
EOF
                      expect => <<'EOF',
1
75
EOF
                    );

#------------------------------------------------------------

    $group->add_test( name => 'store',
                      description => 'Test store parameter to component call',
                      component => <<'EOF',

% my $buffy;
% my $rtn;
% $rtn = $m->comp({store => \$buffy}, '.subcomp', 1,2,3,4);
-----
<% $buffy %>
returned <% $rtn %>

<%def .subcomp>
 Hello, you say <% join '', @_ %>.
% return 'foo';
</%def>
EOF
                      expect => <<'EOF',

-----

 Hello, you say 1234.

returned foo

EOF
                    );

#------------------------------------------------------------

    $group->add_test( name => 'flush_clear',
                      description => 'Flush then clear',
                      component => <<'EOF',
Foo
% $m->flush_buffer;
Bar
% $m->clear_buffer;
Baz
EOF
                      expect => <<'EOF',
Foo
Baz
EOF
                    );

#------------------------------------------------------------

    $group->add_test( name => 'flush_clear_scomp',
                      description => 'Flush then clear inside scomp - flush only affects top buffer',
                      component => <<'EOF',
<%method s>
Foo
% $m->flush_buffer;
Bar
% $m->clear_buffer;
Baz
</%method>
This is me
----------
This is scomp-ed output:
<% $m->scomp('SELF:s') %>
----------
This is me again
EOF
                      expect => <<'EOF',
This is me
----------
This is scomp-ed output:
Baz

----------
This is me again
EOF
                    );

#------------------------------------------------------------

    $group->add_test( name => 'attr_if_exists',
                      description => 'Test attr_if_exists method',
                      component => <<'EOF',
have it: <% $m->base_comp->attr_if_exists('have_it') %>
don't have it: <% defined($m->base_comp->attr_if_exists('don\'t have_it')) ? 'defined' : 'undefined' %>
<%attr>
have_it => 1
</%attr>
EOF
                      expect => <<'EOF',
have it: 1
don't have it: undefined
EOF
                    );

#------------------------------------------------------------

    $group->add_test( name => 'methods',
                      description => 'Test methods method',
                      component => <<'EOF',
% my $comp = $m->request_comp;
% my $methods = $comp->methods;
% foreach my $name ( sort keys %$methods ) {
<% $name %>
% }
<% $comp->methods('x') ? 'has' : 'does not have' %> x
<% $comp->methods('y') ? 'has' : 'does not have' %> y
<% $comp->methods('z') ? 'has' : 'does not have' %> z
<%method x>
x
</%method>
<%method y>
y
</%method>
EOF
                      expect => <<'EOF',
x
y
has x
has y
does not have z
EOF
                    );

#------------------------------------------------------------

    $group->add_test( name => 'subcomps',
                      description => 'Test subcomps method',
                      component => <<'EOF',
% my $comp = $m->request_comp;
% my $subcomps = $comp->subcomps;
% foreach my $name ( sort keys %$subcomps ) {
<% $name %>
% }
<% $comp->subcomps('x') ? 'has' : 'does not have' %> x
<% $comp->subcomps('y') ? 'has' : 'does not have' %> y
<% $comp->subcomps('z') ? 'has' : 'does not have' %> z
<%def x>
x
</%def>
<%def y>
y
</%def>
EOF
                      expect => <<'EOF',
x
y
has x
has y
does not have z
EOF
                    );

#------------------------------------------------------------

    $group->add_test( name => 'attributes',
                      description => 'Test attributes method',
                      component => <<'EOF',
% my $comp = $m->request_comp;
% my $attrs = $comp->attributes;
% foreach my $name ( sort keys %$attrs ) {
<% $name %>
% }
<%attr>
x => 1
y => 2
</%attr>
EOF
                      expect => <<'EOF',
x
y
EOF
                    );

#------------------------------------------------------------

    $group->add_support( path => 'args_copying_helper',
                         component => <<'EOF',
<%init>
$_[1] = 4;
$b = 5;
$ARGS{'c'} = 6;
</%init>

<%args>
$a
$b
</%args>
EOF
                       );

#------------------------------------------------------------

    $group->add_test( name => 'component_args_copying',
                      description => 'Test that @_ contains aliases, <%args> and %ARGS contain copies after comp',
                      component => <<'EOF',
$a is <% $a %>
$b is <% $b %>
$c is <% $c %>

<%init>;
my $a = 1;
my $b = 2;
my $c = 3;
$m->comp('args_copying_helper', a=>$a, b=>$b, c=>$c);
</%init>
EOF
                      expect => <<'EOF',

$a is 4
$b is 2
$c is 3
EOF
                    );

#------------------------------------------------------------

    $group->add_test( name => 'subrequest_args_copying',
                      description => 'Test that @_ contains aliases, <%args> and %ARGS contain copies after subrequest',
                      component => <<'EOF',
$a is <% $a %>
$b is <% $b %>
$c is <% $c %>

<%init>;
my $a = 1;
my $b = 2;
my $c = 3;
$m->subexec('/component/args_copying_helper', a=>$a, b=>$b, c=>$c);
</%init>
EOF
                      expect => <<'EOF',

$a is 4
$b is 2
$c is 3
EOF
                    );

#------------------------------------------------------------

    $group->add_test( name => 'modification_read_only_arg',
                      description => 'Test that read-only argument cannot be modified through @_',
                      component => <<'EOF',
<%init>;
$m->comp('args_copying_helper', a=>1, b=>2, c=>3);
</%init>
EOF
                      expect_error => 'Modification of a read-only value',
                    );

#------------------------------------------------------------

    return $group;
}

