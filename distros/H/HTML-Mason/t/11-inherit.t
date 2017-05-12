use strict;
use warnings;

use HTML::Mason::Tests;

my $tests = make_tests();
$tests->run;

sub make_tests
{
    my $group = HTML::Mason::Tests->tests_class->new( name => 'inherit',
                                                      description => 'Test inheritance' );


#------------------------------------------------------------

    $group->add_support( path => 'autohandler',
                         component => <<'EOF',
<%method m1>m1 from level 1</%method>
<%method m12>m12 from level 1</%method>
<%method m13>m13 from level 1</%method>
<%method m123>m123 from level 1</%method>

<%attr>
a1=>'a1 from level 1'
a12=>'a12 from level 1'
a13=>'a13 from level 1'
a123=>'a123 from level 1'
</%attr>

<& { base_comp => $m->base_comp }, 'variants' &>

% $m->call_next;

EOF
                       );


#------------------------------------------------------------

    $group->add_support( path => 'report_parent',
                         component => <<'EOF',
% my $comp = $m->callers(1);
My name is <% $comp->path %> and <% $comp->parent ? "my parent is ".$comp->parent->path : "I have no parent" %>.
EOF
                       );


#------------------------------------------------------------

    $group->add_support( path => 'variants',
                         component => <<'EOF',
% my @variants = qw(1 2 3 12 13 23 123);

Methods (called from <% $m->callers(1)->title %>)
% foreach my $v (@variants) {
%   if ($self->method_exists("m$v")) {
m<% $v %>: <& "SELF:m$v" &>
%   } else {
m<% $v %>: does not exist
%   }
% }

Attributes (referenced from <% $m->callers(1)->title %>)
% foreach my $v (@variants) {
%   if ($self->attr_exists("a$v")) {
a<% $v %>: <% $self->attr("a$v") %>
%   } else {
a<% $v %>: does not exist
%   }
% }

<%init>
my $self = $m->base_comp;
</%init>
EOF
                       );


#------------------------------------------------------------

    $group->add_support( path => 'subdir/call_next_helper',
                         component => <<'EOF',
<%init>
# Making sure we can call_next from a helper component
$m->call_next;
</%init>
EOF
                       );
#------------------------------------------------------------

    $group->add_support( path => 'subdir/autohandler',
                         component => <<'EOF',
<%method m2>m2 from level 2</%method>
<%method m12>m12 from level 2</%method>
<%method m23>m23 from level 2</%method>
<%method m123>m123 from level 2</%method>

<%attr>
a2=>'a2 from level 2'
a12=>'a12 from level 2'
a23=>'a23 from level 2'
a123=>'a123 from level 2'
</%attr>

<& { base_comp => $m->base_comp }, '../variants' &>

<& call_next_helper &>

<%init>
my $self = $m->base_comp;
</%init>
EOF
                       );


#------------------------------------------------------------

    $group->add_test( name => 'bypass',
                      description => 'test inheritance that skips one autohandler',
                      path => 'subdir/bypass',
                      call_path => 'subdir/bypass',
                      component => <<'EOF',
<%method m3>m3 from level 3</%method>
<%method m13>m13 from level 3</%method>
<%method m23>m23 from level 3</%method>
<%method m123>m123 from level 3</%method>

<%attr>
a3=>'a3 from level 3'
a13=>'a13 from level 3'
a23=>'a23 from level 3'
a123=>'a123 from level 3'
</%attr>

<& { base_comp => $m->base_comp }, '../variants' &>
<& ../report_parent &>

<%flags>
inherit=>'../autohandler'
</%flags>
EOF
                      expect => <<'EOF',



Methods (called from /inherit/autohandler)
m1: m1 from level 1
m2: does not exist
m3: m3 from level 3
m12: m12 from level 1
m13: m13 from level 3
m23: m23 from level 3
m123: m123 from level 3

Attributes (referenced from /inherit/autohandler)
a1: a1 from level 1
a2: does not exist
a3: a3 from level 3
a12: a12 from level 1
a13: a13 from level 3
a23: a23 from level 3
a123: a123 from level 3






Methods (called from /inherit/subdir/bypass)
m1: m1 from level 1
m2: does not exist
m3: m3 from level 3
m12: m12 from level 1
m13: m13 from level 3
m23: m23 from level 3
m123: m123 from level 3

Attributes (referenced from /inherit/subdir/bypass)
a1: a1 from level 1
a2: does not exist
a3: a3 from level 3
a12: a12 from level 1
a13: a13 from level 3
a23: a23 from level 3
a123: a123 from level 3


My name is /inherit/subdir/bypass and my parent is /inherit/autohandler.




EOF
                    );


#------------------------------------------------------------

    $group->add_test( name => 'ignore',
                      description => 'turning off inheritance',
                      path => 'subdir/ignore',
                      call_path => 'subdir/ignore',
                      component => <<'EOF',
<%method m3>m3 from level 3</%method>
<%method m13>m13 from level 3</%method>
<%method m23>m23 from level 3</%method>
<%method m123>m123 from level 3</%method>

<%attr>
a3=>'a3 from level 3'
a13=>'a13 from level 3'
a23=>'a23 from level 3'
a123=>'a123 from level 3'
</%attr>

%# base_comp currently does not change when a comp ref is used
% my $variants = $m->fetch_comp('../variants'); 
<& $variants &>

<& ../report_parent &>

<%flags>
inherit=>undef
</%flags>
EOF
                      expect => <<'EOF',



Methods (called from /inherit/subdir/ignore)
m1: does not exist
m2: does not exist
m3: m3 from level 3
m12: does not exist
m13: m13 from level 3
m23: m23 from level 3
m123: m123 from level 3

Attributes (referenced from /inherit/subdir/ignore)
a1: does not exist
a2: does not exist
a3: a3 from level 3
a12: does not exist
a13: a13 from level 3
a23: a23 from level 3
a123: a123 from level 3



My name is /inherit/subdir/ignore and I have no parent.


EOF
                    );


#------------------------------------------------------------

    $group->add_test( name => 'normal',
                      description => 'normal inheritance path',
                      path => 'subdir/normal',
                      call_path => 'subdir/normal',
                      component => <<'EOF',
<%method m3>m3 from level 3</%method>
<%method m13>m13 from level 3</%method>
<%method m23>m23 from level 3</%method>
<%method m123>m123 from level 3</%method>

<%attr>
a3=>'a3 from level 3'
a13=>'a13 from level 3'
a23=>'a23 from level 3'
a123=>'a123 from level 3'
</%attr>

<& { base_comp => $m->base_comp }, '../variants' &>
<& ../report_parent &>
EOF
                      expect => <<'EOF',



Methods (called from /inherit/autohandler)
m1: m1 from level 1
m2: m2 from level 2
m3: m3 from level 3
m12: m12 from level 2
m13: m13 from level 3
m23: m23 from level 3
m123: m123 from level 3

Attributes (referenced from /inherit/autohandler)
a1: a1 from level 1
a2: a2 from level 2
a3: a3 from level 3
a12: a12 from level 2
a13: a13 from level 3
a23: a23 from level 3
a123: a123 from level 3






Methods (called from /inherit/subdir/autohandler)
m1: m1 from level 1
m2: m2 from level 2
m3: m3 from level 3
m12: m12 from level 2
m13: m13 from level 3
m23: m23 from level 3
m123: m123 from level 3

Attributes (referenced from /inherit/subdir/autohandler)
a1: a1 from level 1
a2: a2 from level 2
a3: a3 from level 3
a12: a12 from level 2
a13: a13 from level 3
a23: a23 from level 3
a123: a123 from level 3






Methods (called from /inherit/subdir/normal)
m1: m1 from level 1
m2: m2 from level 2
m3: m3 from level 3
m12: m12 from level 2
m13: m13 from level 3
m23: m23 from level 3
m123: m123 from level 3

Attributes (referenced from /inherit/subdir/normal)
a1: a1 from level 1
a2: a2 from level 2
a3: a3 from level 3
a12: a12 from level 2
a13: a13 from level 3
a23: a23 from level 3
a123: a123 from level 3


My name is /inherit/subdir/normal and my parent is /inherit/subdir/autohandler.





EOF
                    );

#------------------------------------------------------------

    $group->add_support( path => '/base/autohandler',
                         component => <<'EOF',
<%flags>
inherit => undef
</%flags>
<%attr>
a => 'base autohandler'
</%attr>
<%method x>
This is X in base autohandler
attribute A is <% $m->base_comp->attr('a') %>
<& SELF:x &>
<& .util &>
</%method>
<%method y>
This is method Y in base autohandler
base_comp is <% $m->base_comp->name %>
</%method>
<%def .util>
This is subcomponent .util
base_comp is <% $m->base_comp->name %>
<& SELF:y &>
</%def>
% $m->call_next;
EOF
                       );

#------------------------------------------------------------

    $group->add_support( path => '/util/autohandler',
                         component => <<'EOF',
<%flags>
inherit => undef
</%flags>
<%attr>
a => 'util autohandler'
</%attr>
<%method x>
This is X in util autohandler
attribute A is <% $m->base_comp->attr('a') %>
<& SELF:x , why => 'infinite loop if PARENT does not work ' &>
</%method>
<%method exec>
This is autohandler:exec
exec was really called for <% $m->base_comp->name %>
attribute A is <% $m->base_comp->attr('a') %>
<& SELF:x &>
</%method>
% $m->call_next;
EOF
                       );

#------------------------------------------------------------

    $group->add_support( path => '/util/util',
                         component => <<'EOF',
<%method x>
This is method X in UTIL
</%method>
<%attr>
a => 'util'
</%attr>
This is UTIL
attribute A is <% $m->base_comp->attr('a') %>
<& SELF:x &>
<& PARENT:x &>
EOF
                       );

#------------------------------------------------------------

    $group->add_test(   name => 'base_comp',
                        path => '/base/base',
                        call_path => '/base/base',
                        description => 'base_comp test',
                        component => <<'EOF',
<%method x>
This is method X in BASE
</%method>
<%attr>
a => 'base'
</%attr>
This is BASE
attribute A is <% $m->base_comp->attr('a') %>
<& SELF:x &>
<& ../util/util &>
<& PARENT:x &>
EOF
                      expect => <<'EOF',
This is BASE
attribute A is base

This is method X in BASE

This is UTIL
attribute A is util

This is method X in UTIL


This is X in util autohandler
attribute A is util

This is method X in UTIL




This is X in base autohandler
attribute A is base

This is method X in BASE


This is subcomponent .util
base_comp is base

This is method Y in base autohandler
base_comp is base
EOF
                       );

#------------------------------------------------------------

    $group->add_test(   name => 'base_comp_method',
                        path => '/base/meth',
                        call_path => '/base/meth',
                        description => 'base_comp method inheritance test',
                        component => <<'EOF',
<%method x>
This is method X in METH
</%method>
<%attr>
a => 'meth'
</%attr>
This is METH
attribute A is <% $m->base_comp->attr('a') %>
<& SELF:x &>
<& ../util/util:exec &>
EOF
                      expect => <<'EOF',
This is METH
attribute A is meth

This is method X in METH


This is autohandler:exec
exec was really called for util
attribute A is util

This is method X in UTIL
EOF
                       );

#------------------------------------------------------------

    $group->add_support( path => '/base2/autohandler',
                         component => <<'EOF',
<%flags>
inherit => undef
</%flags>
This is autohandler A
<& sub/sibling &>
% $m->call_next;
EOF
                       );

#------------------------------------------------------------

    $group->add_support( path => '/base2/sub/autohandler',
                         component => <<'EOF',
This is autohandler B
<& SELF:m &>
% $m->call_next;
EOF
                       );

#------------------------------------------------------------

    $group->add_support( path => '/base2/sub/sibling',
                         component => <<'EOF',
This is SIBLING
<& PARENT &>
<%method m>
This is method M in SIBLING
</%method>
EOF
                       );

#------------------------------------------------------------

    $group->add_test(   name => 'double_parent',
                        path => '/base2/sub/child',
                        call_path => '/base2/sub/child',
                        description => 'test that parent does not confuse children',
                        component => <<'EOF',
This is CHILD
<%method m>
This is method M in CHILD
</%method>
EOF
                      expect => <<'EOF',
This is autohandler A
This is SIBLING
This is autohandler B

This is method M in SIBLING

This is CHILD


This is autohandler B

This is method M in CHILD

This is CHILD



EOF
                       );

#------------------------------------------------------------

    $group->add_test(   name => 'subcomponent',
                        path => '/base2/subcomp',
                        call_path => '/base2/subcomp',
                        description => 'test subcomponents',
                        component => <<'EOF',
<%flags>
inherit => undef
</%flags>
<%def .sub>
This is a subcomponent
<& SELF:x &>
</%def>
<%method x>
This is method X
</%method>
This is the component
<& .sub &>
EOF
                      expect => <<'EOF',
This is the component

This is a subcomponent

This is method X

EOF
                       );

#------------------------------------------------------------

    $group->add_support( path => '/base3/autohandler',
                         component => <<'EOF',
<%flags>
inherit => undef
</%flags>
<%method x>
This is X in base autohandler
</%method>
<& .foo &>
<%def .foo>
% $m->call_next;
</%def>
EOF
                       );

#------------------------------------------------------------

    # Remarks: this used to work in older versions of Mason.  It's not
    # *quite* surprising that it fails, because the call to <& .foo &>
    # is a "normal" call and thus changes base_comp.  But since .foo
    # can't actually function usefully as a base_comp (as far as I
    # know), it would be possible to not change base_comp while
    # calling subcomponents.  Currently base_comp changes to the
    # autohandler in this situation, which seems odd.
    #
    # Current workaround is <& {base_comp => $m->request_comp}, $m->fetch_next, $m->caller_args(1) &>
    #
    #   -Ken

    $group->add_test(   name => 'call_next_in_def',
                        path => '/base3/call_next_in_def',
                        call_path => '/base3/call_next_in_def',
                        description => 'Test call_next() inside a subcomponent',
                        component => <<'EOF',
<%method x>
This is method X in BASE
</%method>
This is BASE
base_comp is <% $m->base_comp->name %>
<& SELF:x &>
EOF
                      expect => <<'EOF',

This is BASE
base_comp is call_next_in_def

This is method X in BASE
EOF
                       );

#------------------------------------------------------------

    $group->add_support( path => '/subcompbase/parent',
                         component => <<'EOF',
<& _foo &>

<%def _foo>
<& SELF:bar &>
</%def>

<%method bar>
This is parent's bar.
</%method>

<%flags>
inherit => undef
</%flags>
EOF
                       );

#------------------------------------------------------------

    $group->add_test(   name => 'subcomponent_inheritance',
                        path => '/subcompbase/child',
                        call_path => '/subcompbase/child',
                        description => 'test base_comp with subcomponents',
                        component => <<'EOF',
<%flags>
inherit => 'parent'
</%flags>

<%method bar>
This is child's bar.
</%method>
EOF
                      expect => <<'EOF',


This is child's bar.
EOF
                       );

#------------------------------------------------------------

    $group->add_support( path => '/request_test/autohandler',
                         component => <<'EOF',
<& SELF:x &>\
<& REQUEST:x &>\
next\
% $m->call_next;
<%method x>
x in autohandler
</%method>
<%flags>
inherit => undef
</%flags>
EOF
                       );

    $group->add_support( path => '/request_test/other_comp',
                         component => <<'EOF',
<& REQUEST:x &>\
<& SELF:x &>\
<%method x>x in other comp
</%method>
<%flags>
inherit => undef
</%flags>
EOF
                       );

    $group->add_test( name => 'request_tests',
                      path => '/request_test/request_test',
                      call_path => '/request_test/request_test',
                      description => 'Test that REQUEST: works',
                      component => <<'EOF',
<& PARENT:x &>\
<& other_comp &>\
<%method x>x in requested comp
</%method>
EOF
                      expect => <<'EOF',
x in requested comp
x in requested comp
next
x in autohandler
x in requested comp
x in other comp
EOF
                    );

#------------------------------------------------------------

    return $group;
}

