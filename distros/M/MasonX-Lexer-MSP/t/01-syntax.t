#!/usr/bin/perl -w

use strict;

use HTML::Mason::Tests;

my $tests = make_tests();
$tests->run;

sub make_tests
{
    my $group = HTML::Mason::Tests->new( name => 'syntax',
					 description => 'Basic component syntax tests' );


#------------------------------------------------------------

    $group->add_support( path => '/support/amper_test',
			 component => <<'EOF',
amper_test.<p>
<% if (%ARGS) { %>\
Arguments:<p>
<%   foreach my $key (sort keys %ARGS) { %>\
<b><%= $key %></b>: <%= $ARGS{$key} %><br>
<%   } %>\
<% } %>\
EOF
		       );


#------------------------------------------------------------

    $group->add_test( name => 'ampersand syntax',
		      description => 'tests all variations of component call path syntax and arg passing',
		      interp_params => { lexer_class => 'MasonX::Lexer::MSP' },
		      component => <<'EOF',
<HTML>
<HEAD>
<TITLE>
amper Test
</TITLE>
</HEAD>
<BODY>
<& support/amper_test &>
<& /syntax/support/amper_test, message=>'Hello World!'  &>
<& support/amper_test, message=>'Hello World!', to=>'Joe' &>
<& "support/amper_test" &>
<% my $dir = "support"; %>\
<% my %args = (a=>17, b=>32); %>\
<& $dir . "/amper_test", %args &>
</BODY>
</HTML>
EOF
		      expect => <<'EOF',
<HTML>
<HEAD>
<TITLE>
amper Test
</TITLE>
</HEAD>
<BODY>
amper_test.<p>

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

</BODY>
</HTML>
EOF
		 );


#------------------------------------------------------------

    $group->add_test( name => 'replace',
		      description => 'tests <%= %> tag',
		      interp_params => { lexer_class => 'MasonX::Lexer::MSP' },
		      component => <<'EOF',
<HTML>
<HEAD>
<TITLE>
Replacement Test
</TITLE>
</HEAD>
<BODY>
<%= "Hello World!" %>
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
			  description => 'tests <% code %> syntax',
		      interp_params => { lexer_class => 'MasonX::Lexer::MSP' },
			  component => <<'EOF',
<HTML>
<HEAD>
<TITLE>
Percent Test
</TITLE>
</HEAD>
<BODY>
<% my $message = "Hello World!"; %>\
<%= $message %>
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
		      interp_params => { lexer_class => 'MasonX::Lexer::MSP' },
			  component => 'some text, a %, and some text',
			  expect =>    'some text, a %, and some text',
			);

#------------------------------------------------------------
	$group->add_test( name => 'empty_percents',
			  description => 'tests empty <% %> tags',
		      interp_params => { lexer_class => 'MasonX::Lexer::MSP' },
			  component => <<'EOF',
some text,
<% %>\
and some more
EOF
			  expect =>    "some text,\nand some more\n",
			);
#------------------------------------------------------------

	$group->add_test( name => 'empty_percents2',
			  description => 'tests empty <% %> tags followed by other <% %> tags',
		      interp_params => { lexer_class => 'MasonX::Lexer::MSP' },
			  component => <<'EOF',
some text,
<% %>\
<% $m->print('foo, '); %>\
and some more
EOF
			  expect =>    "some text,\nfoo, and some more\n",
			);

#------------------------------------------------------------

	$group->add_test( name => 'quiet comment',
			  description => 'tests that quiet comments work',
		      interp_params => { lexer_class => 'MasonX::Lexer::MSP' },
			  component => <<'EOF',
a
<%def isafoo>
<%-- this will not be output --%>foo
</%def>
b
<%-- comment out a bunch of code
<%= 'die' %><% %x = 'y' %><& some-comp, xyzzy &>
--%>
c
<%-- everything except the end --%\> tag is allowed --%>
EOF
			  expect => <<'EOF',
a
b

c

EOF
			);

#------------------------------------------------------------

	$group->add_test( name => 'no perl lines',
			  description => 'tests that perl lines do not work by default',
		      interp_params => { lexer_class => 'MasonX::Lexer::MSP' },
			  component => <<'EOF',
a
<% my $x = 'hi'; %>
b
% $x = 'bye';
c
<%= $x %>
EOF
			  expect => <<'EOF',
a

b
% $x = 'bye';
c
hi
EOF
			);

#------------------------------------------------------------

	$group->add_test( name => 'yes perl lines',
			  description => 'tests that perl lines do work with perl_lines=>1',
			  interp_params => { 
				lexer_class => 'MasonX::Lexer::MSP',
			  	perl_lines => 1 },
			  component => <<'EOF',
a
<% my $x = 'hi'; %>
b
% $x = 'bye';
c
<%= $x %>
EOF
			  expect => <<'EOF',
a

b
c
bye
EOF
			);

#------------------------------------------------------------

    return $group;
}
