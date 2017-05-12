use strict;
use warnings;

use HTML::Mason::Tests;

my $tests = make_tests();
$tests->run;

sub make_tests
{

    my $group = HTML::Mason::Tests->tests_class->new( name => 'syntax',
                                                      description => 'Basic component syntax tests' );


#------------------------------------------------------------

    $group->add_test( name => 'replace',
                      description => 'tests <% %> tag',
                      component => <<'EOF',
<HTML>
<HEAD>
<TITLE>
Replacement Test
</TITLE>
</HEAD>
<BODY>
<% "Hello World!" %>
</BODY>
</HTML>
EOF
                      expect => <<'EOF',
<HTML>
<HEAD>
<TITLE>
Replacement Test
</TITLE>
</HEAD>
<BODY>
Hello World!
</BODY>
</HTML>
EOF
                    );


#------------------------------------------------------------

        $group->add_test( name => 'percent',
                          description => 'tests %-line syntax',
                          component => <<'EOF',
<HTML>
<HEAD>
<TITLE>
Percent Test
</TITLE>
</HEAD>
<BODY>
% my $message = "Hello World!";
<% $message %>
</BODY>
</HTML>
EOF
                          expect => <<'EOF',
<HTML>
<HEAD>
<TITLE>
Percent Test
</TITLE>
</HEAD>
<BODY>
Hello World!
</BODY>
</HTML>
EOF
                        );

#------------------------------------------------------------

        $group->add_test( name => 'fake_percent',
                          description => 'tests % in text section',
                          component => 'some text, a %, and some text',
                          expect =>    'some text, a %, and some text',
                        );

#------------------------------------------------------------
        $group->add_test( name => 'empty_percents',
                          description => 'tests empty %-lines',
                          component => <<'EOF',
some text,
%
and some more
EOF
                          expect =>    "some text,\nand some more\n",
                        );
#------------------------------------------------------------

        $group->add_test( name => 'empty_percents2',
                          description => 'tests empty %-lines followed by other %-lines',
                          component => <<'EOF',
some text,
%
% $m->print('foo, ');
and some more
EOF
                          expect =>    "some text,\nfoo, and some more\n",
                        );

#------------------------------------------------------------

        $group->add_test( name => 'space_after_method_name',
                          description => 'tests that spaces are allowed after method/subcomp names',
                          component => <<'EOF',
a
<%def foo  >
</%def>
<%method bar   
>
</%method>
b
EOF
                          expect => <<'EOF',
a
b
EOF
                        );

#------------------------------------------------------------

        $group->add_test( name => 'comment_in_attr_flags',
                          description => 'tests that comments are allowed at end of flag/attr lines',
                          component => <<'EOF',
a
<%flags>
inherit => undef # foo bar
</%flags>
<%attr>
a => 1 # a is 1
b => 2 # ya ay
</%attr>
b
EOF
                          expect => <<'EOF',
a
b
EOF
                        );

#------------------------------------------------------------

        $group->add_test( name => 'dash in subcomp named',
                          description => 'tests that dashes are allowed in subcomponent names',
                          component => <<'EOF',
a
<%def has-dashes>
foo
</%def>
b
EOF
                          expect => <<'EOF',
a
b
EOF
                        );

#------------------------------------------------------------

        $group->add_test( name => 'flags_on_one_line',
                          description => 'tests that a flags block can be one line',
                          component => <<'EOF',
a
<%flags>inherit => undef</%flags>
b
EOF
                          expect => <<'EOF',
a
b
EOF
                        );

#------------------------------------------------------------

        $group->add_test( name => 'attr_uc_ending',
                          description => 'tests that an attr ending tag can be upper-case',
                          component => <<'EOF',
<%ATTR>
thing => 1</%ATTR>
thing: <% $m->request_comp->attr('thing') %>
EOF
                          expect => <<'EOF',
thing: 1
EOF
                        );

#------------------------------------------------------------

        $group->add_test( name => 'args_uc_ending',
                          description => 'tests that args ending tag can be mixed case',
                          component => <<'EOF',
<%ARGS>
$a => 1</%ARGS>
a is <% $a %>
b
EOF
                          expect => <<'EOF',
a is 1
b
EOF
                        );

#------------------------------------------------------------

    $group->add_test( name => 'comment_in_call',
                      description => 'make a comp call with a commented line',
                      component => <<'EOF',
<& .foo,
   foo => 1,
#   bar => 2,
 &>
<& .foo,
#   foo => 1,
   bar => 2,
 &>
<%def .foo>foo! args are <% join(", ", %ARGS) %></%def>
EOF
                      expect => <<'EOF',
foo! args are foo, 1
foo! args are bar, 2
EOF
                    );

#------------------------------------------------------------

    $group->add_test( name => 'comment_in_call2',
                      description => 'make a comp call with content with a commented line',
                      component => <<'EOF',
<&| .show_content,
   foo => 1,
#   bar => 2,
 &>\
This is the content\
</&>
<%def .show_content>\
<% $m->content %>\
</%def>
EOF
                      expect => <<'EOF',
This is the content
EOF
                    );

#------------------------------------------------------------

    $group->add_test( name => 'call_starts_with_newline',
                      description => 'make a comp call where the tag starts with a newline',
                      component => <<'EOF',
<&
 .foo,
 x => 1
 &>\
<%def .foo>\
x is <% $ARGS{x} %>
</%def>
EOF
                      expect => <<'EOF',
x is 1
EOF
                    );

#------------------------------------------------------------

    $group->add_test( name => 'cleanup_init',
                      description => 'test that cleanup block has access to variables from init section',
                      component => <<'EOF',
<%init>
my $x = 7;
</%init>
<%cleanup>
$m->print("x is $x");
</%cleanup>
EOF
                      expect => <<'EOF',
x is 7
EOF
                    );

#------------------------------------------------------------

    $group->add_test( name => 'cleanup_perl',
                      description => 'test that cleanup block has access to variables from perl section',
                      component => <<'EOF',
<%perl>
my $x = 7;
</%perl>
<%cleanup>
$m->print("x is $x");
</%cleanup>
EOF
                      expect => <<'EOF',
x is 7
EOF
                    );

#------------------------------------------------------------

    return $group;
}
