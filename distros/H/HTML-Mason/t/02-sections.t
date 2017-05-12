use strict;
use warnings;

use HTML::Mason::Tests;

my $tests = make_tests();
$tests->run;

sub make_tests
{
    my $group = HTML::Mason::Tests->tests_class->new( name => 'sections',
                                                      description => 'Tests various <%foo></%foo> sections' );


#------------------------------------------------------------

    $group->add_support( path => '/support/args_test',
                         component => <<'EOF',
<% $message %>\
<%args>
$message
</%args>
EOF
                       );

#------------------------------------------------------------

    $group->add_support( path => '/support/perl_args_test',
                         component => <<'EOF',
a: <% $a %>
b: <% join(",",@b) %>
c: <% join(",",map("$_=$c{$_}",sort(keys(%c)))) %>
d: <% $d %>
e: <% join(",",@e) %>
f: <% join(",",map("$_=$f{$_}",sort(keys(%f)))) %>

<%args>
$a       
@b       # a comment
%c
$d=>5    # another comment
@e=>('foo','baz')
%f=>(joe=>1,bob=>2)
</%args>
EOF
                       );


#------------------------------------------------------------

    $group->add_test( name => 'args',
                      description => 'tests <%args> block',
                      component => <<'EOF',
<HTML>
<HEAD>
<TITLE>
args Test
</TITLE>
</HEAD>
<BODY>
<& support/args_test, message => 'Hello World!' &>
</BODY>
</HTML>
EOF
                      expect => <<'EOF',
<HTML>
<HEAD>
<TITLE>
args Test
</TITLE>
</HEAD>
<BODY>
Hello World!
</BODY>
</HTML>
EOF
                    );


#------------------------------------------------------------

    $group->add_test( name => 'attr',
                      description => 'tests <%attr> block',
                      component => <<'EOF',
<HTML>
<HEAD>
<TITLE>
attr Test
</TITLE>
</HEAD>
<BODY>
foo
<% $m->current_comp->attr('foo') %>
<% $m->current_comp->attr('bar')->[1] %>
<% $m->current_comp->attr('baz')->{b} %>
</BODY>
</HTML>
<%attr>
foo => 'a'
bar => [1, 3]
baz => { a => 1, b => 2 }
</%attr>
EOF
                      expect => <<'EOF',
<HTML>
<HEAD>
<TITLE>
attr Test
</TITLE>
</HEAD>
<BODY>
foo
a
3
2
</BODY>
</HTML>
EOF
                    );


#------------------------------------------------------------

    $group->add_test( name => 'def',
                      description => 'tests <%def> block',
                      component => <<'EOF',
<%def intro>
% my $comp = $m->current_comp;
Hello!<br>
My name is <% $comp->name %>. Full name <% $comp->title %>.<br>
I was created by <% $comp->owner->path %>.<br>
<& .link, site=>'masonhq', label=>'Mason' &>
</%def>

<& intro &><hr>
<& .link, site=>'apache', label=>'Apache Foundation' &><br>
<& .link, site=>'yahoo' &><br>
<& .link, site=>'excite' &>
<%def .link>
--> <a href="http://www.<% $site %>.com"><% $label %></a>
<%args>
$site
$label=>ucfirst($site)
</%args>
</%def>
EOF
                      expect => <<'EOF',


Hello!<br>
My name is intro. Full name /sections/def:intro.<br>
I was created by /sections/def.<br>

--> <a href="http://www.masonhq.com">Mason</a>

<hr>

--> <a href="http://www.apache.com">Apache Foundation</a>
<br>

--> <a href="http://www.yahoo.com">Yahoo</a>
<br>

--> <a href="http://www.excite.com">Excite</a>
EOF
                    );

#------------------------------------------------------------

    $group->add_test( name => 'doc',
                      description => 'tests <%doc> section',
                      component => <<'EOF',
<HTML>
<HEAD>
<TITLE>
doc Test
</TITLE>
</HEAD>
<BODY>
Hello World!
</BODY>
</HTML>

<%doc>
This is an HTML::Mason documentation section.

Right?
</%doc>
EOF
                      expect => <<'EOF',
<HTML>
<HEAD>
<TITLE>
doc Test
</TITLE>
</HEAD>
<BODY>
Hello World!
</BODY>
</HTML>

EOF
                    );

#------------------------------------------------------------

    $group->add_test( name => 'filter',
                      description => 'tests <%filter> section',
                      component => <<'EOF',
<HTML>
<HEAD>
<TITLE>
filter Test
</TITLE>
</HEAD>
<BODY>
!dlorW olleH
</BODY>
</HTML>

<%filter>
s/\!dlorW olleH/Hello World!/;
</%filter>
EOF
                      expect => <<'EOF',
<HTML>
<HEAD>
<TITLE>
filter Test
</TITLE>
</HEAD>
<BODY>
Hello World!
</BODY>
</HTML>

EOF
                    );

#------------------------------------------------------------

    $group->add_test( name => 'flags',
                      description => 'tests <%flags> section',
                      component => <<'EOF',
<HTML>
<HEAD>
<TITLE>
flags Test
</TITLE>
</HEAD>
<BODY>
foo
</BODY>
</HTML>
<%flags>
inherit=>undef   # an inherit flag
</%flags>
EOF
                      expect => <<'EOF',
<HTML>
<HEAD>
<TITLE>
flags Test
</TITLE>
</HEAD>
<BODY>
foo
</BODY>
</HTML>
EOF
                    );

#------------------------------------------------------------

    $group->add_test( name => 'init',
                      description => 'tests <%init> section',
                      component => <<'EOF',
<HTML>
<HEAD>
<TITLE>
init Test
</TITLE>
</HEAD>
<BODY>
<% $message %>
</BODY>
</HTML>

<%init>
my $message = "Hello World!";
</%init>
EOF
                      expect => <<'EOF',
<HTML>
<HEAD>
<TITLE>
init Test
</TITLE>
</HEAD>
<BODY>
Hello World!
</BODY>
</HTML>

EOF
                    );

#------------------------------------------------------------

    $group->add_test( name => 'method',
                      description => 'tests <%method> section',
                      component => <<'EOF',
<HTML>
<HEAD>
<TITLE>
method Test
</TITLE>
</HEAD>
<BODY>
% $m->current_comp->call_method('foo','y'=>2);
% my $out = $m->current_comp->scall_method('bar',qw(a b c));
<% uc($out) %>
</BODY>
</HTML>
<%method foo>
% my $sum = $y + $y;
<% $y %> + <% $y %> = <% $sum %>.
<%ARGS>
$y
</%ARGS>
</%method>
<%method bar>
The second method. Arguments are <% join(",",@_) %>.
</%method>
EOF
                      expect => <<'EOF',
<HTML>
<HEAD>
<TITLE>
method Test
</TITLE>
</HEAD>
<BODY>

2 + 2 = 4.

THE SECOND METHOD. ARGUMENTS ARE A,B,C.

</BODY>
</HTML>
EOF
                    );

#------------------------------------------------------------

    $group->add_test( name => 'once',
                      description => 'tests <%once> block',
                      component => <<'EOF',
<HTML>
<HEAD>
<TITLE>
once Test
</TITLE>
</HEAD>
<BODY>
<% $message %>
</BODY>
</HTML>

<%once>
my $message = "Hello World";
</%once>

<%INIT>
$message .= "!";
</%INIT>
EOF
                      expect => <<'EOF',
<HTML>
<HEAD>
<TITLE>
once Test
</TITLE>
</HEAD>
<BODY>
Hello World!
</BODY>
</HTML>


EOF
                    );

#------------------------------------------------------------

    $group->add_test( name => 'perl',
                      description => 'test <%perl> sections and makes sure block names are case-insensitive',
                      component => <<'EOF',
<HTML>
<HEAD>
<TITLE>
perl Test
</TITLE>
</HEAD>
<BODY>
<%perl>
my $message = "Hello";
</%PERL>
<%Perl>
$message .= " World!";
</%perl>
<% $message %>
<%perl>
$message = "How are you?";
</%perL>
<% $message %>
</BODY>
</HTML>
EOF
                      expect => <<'EOF',
<HTML>
<HEAD>
<TITLE>
perl Test
</TITLE>
</HEAD>
<BODY>
Hello World!
How are you?
</BODY>
</HTML>
EOF
                    );

#------------------------------------------------------------

=pod

    $group->add_test( name => 'perl_args',
                      description => 'tests old <%perl_args> block',
                      component => <<'EOF',
<& support/perl_args_test, a=>'fargo', b=>[17,82,16], c=>{britain=>3, spain=>1} &>

EOF
                      expect => <<'EOF',
a: fargo
b: 17,82,16
c: britain=3,spain=1
d: 5
e: foo,baz
f: bob=2,joe=1



EOF
                    );

=cut

#------------------------------------------------------------

    # Carp in 5.6.0 is broken so just skip it
    unless ($] == 5.006)
    {
        $group->add_test( name => 'omitted_args',
                          description => 'tests error message when expect args are not passed',
                          component => '<& support/perl_args_test, b=>[17,82,16], c=>{britain=>3, spain=>1} &>',
                          expect_error => qr{no value sent for required parameter 'a'},
                        );
    }

#------------------------------------------------------------

    $group->add_test( name => 'overridden_args',
                      description => 'tests overriding of default args values',
                      component => <<'EOF',
<& support/perl_args_test, a=>'fargo', b=>[17,82,16], c=>{britain=>3, spain=>1}, d=>103, e=>['a','b','c'], f=>{ralph=>15, sue=>37} &>
EOF
                      expect => <<'EOF',
a: fargo
b: 17,82,16
c: britain=3,spain=1
d: 103
e: a,b,c
f: ralph=15,sue=37


EOF
                    );

#------------------------------------------------------------

=pod

    $group->add_test( name => 'perl_doc',
                      description => 'tests old <%perl_doc> section',
                      component => <<'EOF',
<HTML>
<HEAD>
<TITLE>
perl_doc Test
</TITLE>
</HEAD>
<BODY>
Hello World!
</BODY>
</HTML>

<%perl_doc>
This is an HTML::Mason documentation section.

Right?
</%perl_doc>
EOF
                      expect => <<'EOF',
<HTML>
<HEAD>
<TITLE>
perl_doc Test
</TITLE>
</HEAD>
<BODY>
Hello World!
</BODY>
</HTML>

EOF
                    );

#------------------------------------------------------------

    $group->add_test( name => 'perl_init',
                      description => 'tests old <%perl_init> section',
                      component => <<'EOF',
<HTML>
<HEAD>
<TITLE>
perl_init Test
</TITLE>
</HEAD>
<BODY>
<% $message %>
</BODY>
</HTML>

<%perl_init>
my $message = "Hello World!";
</%perl_init>
EOF
                      expect => <<'EOF',
<HTML>
<HEAD>
<TITLE>
perl_init Test
</TITLE>
</HEAD>
<BODY>
Hello World!
</BODY>
</HTML>

EOF
                    );

=cut

#------------------------------------------------------------

    $group->add_test( name => 'shared',
                      description => 'tests <%shared> section',
                      component => <<'EOF',
<%def .main>
Hello <% $name %>.

% $m->current_comp->owner->call_method('foo');
% $m->current_comp->owner->call_method('bar');
<& .baz &>
</%def>

<%method foo>
This is the foo method, <% $name %>.
</%method>
<%method bar>
This is the bar method, <% $name %>.
</%method>
<%def .baz>
This is the baz subcomponent, <% $name %>.
</%def>

<& .main &>

% $name = 'Mary';
<& .main &>

<%shared>
my $name = 'Joe';
</%shared>
EOF
                      expect => <<'EOF',



Hello Joe.


This is the foo method, Joe.

This is the bar method, Joe.

This is the baz subcomponent, Joe.




Hello Mary.


This is the foo method, Mary.

This is the bar method, Mary.

This is the baz subcomponent, Mary.



EOF
                    );

#------------------------------------------------------------

    $group->add_test( name => 'text',
                      description => 'tests <%text> section',
                      component => <<'EOF',
<%text>
%
<%once>
<%init>
<%doc>
<%args>
</%text>
EOF
                      expect => <<'EOF',

%
<%once>
<%init>
<%doc>
<%args>
EOF
                    );

#------------------------------------------------------------

    $group->add_test( name => 'multiple',
                      description => 'tests repeated blocks of the same type',
                      component => <<'EOF',
<%attr>
name=>'Joe'
</%attr>
<%init>
my $var1 = "Foo!";
</%init>
<%filter>
tr/a-z/A-Z/
</%filter>
var1 = <% $var1 %>
var2 = <% $var2 %>
Name = <% $m->current_comp->attr('name') %>
Color = <% $m->current_comp->attr('color') %>
<%filter>
s/\!/\?/g
</%filter>
<%init>
my $var2 = "Bar!";
</%init>
<%attr>
color=>'Blue'
</%attr>
EOF
                      expect => <<'EOF',
VAR1 = FOO?
VAR2 = BAR?
NAME = JOE
COLOR = BLUE
EOF
                    );

#------------------------------------------------------------

    return $group;
}
