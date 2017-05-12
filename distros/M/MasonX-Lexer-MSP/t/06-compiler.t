#!/usr/bin/perl -w

use strict;

use Config;
use HTML::Mason::Tests;
use HTML::Mason::Tools qw(load_pkg);

my $tests = make_tests();
$tests->run;

sub make_tests {
    my $group = HTML::Mason::Tests->new( name => 'compiler',
					 description => 'compiler and lexer object functionality' );


#------------------------------------------------------------

    $group->add_test( name => 'allowed_globals',
		      description => 'test that undeclared globals cause an error',
		      interp_params => { 
			lexer_class => 'MasonX::Lexer::MSP',
			use_object_files => 0 }, # force it to parse comp each time
		      component => <<'EOF',
<%= $global = 1 %>
EOF
		      expect_error => 'Global symbol .* requires explicit package name',
		    );


#------------------------------------------------------------

    $group->add_test( name => 'allowed_globals',
		      description => 'test that undeclared globals cause an error',
		      pretest_code => sub { undef *HTML::Mason::Commands::global; undef *HTML::Mason::Commands::global },  # repeated to squash a var used only once warning
		      interp_params => { 
			lexer_class => 'MasonX::Lexer::MSP',
			use_object_files => 0 },
		      component => <<'EOF',
<%= $global = 1 %>
EOF
		      expect_error => 'Global symbol .* requires explicit package name',
		    );


#------------------------------------------------------------

    $group->add_test( name => 'allowed_globals',
		      description => 'test that declared globals are allowed',
		      interp_params => { 
			lexer_class => 'MasonX::Lexer::MSP',
			use_object_files => 0 ,
		        allow_globals => ['$global'] },
		      component => <<'EOF',
<%= $global = 1 %>
EOF
		      expect => <<'EOF',
1
EOF
		    );

#------------------------------------------------------------

    if ( load_pkg('HTML::Entities') && $HTML::Mason::VERSION >= 1.14)
    {
        $group->add_test( name => 'default_escape_flags',
                          description => 'test that no escaping is done by default',
		      interp_params => { 
			lexer_class => 'MasonX::Lexer::MSP',
			use_object_files => 0 },
                          component => <<'EOF',
Explicitly HTML-escaped: <%= $expr |h %><p>
Explicitly HTML-escaped redundantly: <%= $expr |hh %><p>
Explicitly URL-escaped: <%= $expr |u
%><p>
No flags: <%= $expr %><p>
No flags again: <%= $expr | %><p>
Explicitly not escaped: <%= $expr | n%><p>
<%init>
my $expr = "<b><i>Hello there</i></b>.";
</%init>
EOF
                          expect => <<'EOF',
Explicitly HTML-escaped: &lt;b&gt;&lt;i&gt;Hello there&lt;/i&gt;&lt;/b&gt;.<p>
Explicitly HTML-escaped redundantly: &lt;b&gt;&lt;i&gt;Hello there&lt;/i&gt;&lt;/b&gt;.<p>
Explicitly URL-escaped: %3Cb%3E%3Ci%3EHello%20there%3C%2Fi%3E%3C%2Fb%3E.<p>
No flags: <b><i>Hello there</i></b>.<p>
No flags again: <b><i>Hello there</i></b>.<p>
Explicitly not escaped: <b><i>Hello there</i></b>.<p>
EOF
                        );
    }

#------------------------------------------------------------

    if ( load_pkg('HTML::Entities') && $HTML::Mason::VERSION >= 1.14)
    {
        $group->add_test( name => 'default_escape_flags_2',
                          description => 'test that turning on default escaping works',
		      interp_params => { 
			lexer_class => 'MasonX::Lexer::MSP',
			use_object_files => 0 ,
                        default_escape_flags => 'h' },
                          component => <<'EOF',
Explicitly HTML-escaped: <%= $expr |h %><p>
Explicitly HTML-escaped redundantly: <%= $expr |hh %><p>
Explicitly URL-escaped: <%= $expr |un
%><p>
No flags: <%= $expr %><p>
No flags again: <%= $expr | %><p>
Explicitly not escaped: <%= $expr | n%><p>
<%init>
my $expr = "<b><i>Hello there</i></b>.";
</%init>
EOF
                          expect => <<'EOF',
Explicitly HTML-escaped: &lt;b&gt;&lt;i&gt;Hello there&lt;/i&gt;&lt;/b&gt;.<p>
Explicitly HTML-escaped redundantly: &lt;b&gt;&lt;i&gt;Hello there&lt;/i&gt;&lt;/b&gt;.<p>
Explicitly URL-escaped: %3Cb%3E%3Ci%3EHello%20there%3C%2Fi%3E%3C%2Fb%3E.<p>
No flags: &lt;b&gt;&lt;i&gt;Hello there&lt;/i&gt;&lt;/b&gt;.<p>
No flags again: &lt;b&gt;&lt;i&gt;Hello there&lt;/i&gt;&lt;/b&gt;.<p>
Explicitly not escaped: <b><i>Hello there</i></b>.<p>
EOF
                        );
    }


#------------------------------------------------------------

    $group->add_test( name => 'globals_in_default_package',
		      description => 'tests that components are executed in HTML::Mason::Commands package by default',
		      interp_params => { 
			lexer_class => 'MasonX::Lexer::MSP',
			use_object_files => 0 ,
		        allow_globals => ['$packvar'] },
		      component => <<'EOF',
<%= $packvar %>
<%init>
$HTML::Mason::Commands::packvar = 'commands';
$HTML::Mason::NewPackage::packvar = 'newpackage';
</%init>
EOF
		      expect => <<'EOF',
commands
EOF
		    );


#------------------------------------------------------------

    $group->add_test( name => 'globals_in_different_package',
		      description => 'tests in_package compiler parameter',
		      interp_params => { 
			lexer_class => 'MasonX::Lexer::MSP',
			use_object_files => 0 ,
		        allow_globals => ['$packvar'],
			in_package => 'HTML::Mason::NewPackage' },
		      component => <<'EOF',
<%= $packvar %>
<%init>
$HTML::Mason::Commands::packvar = 'commands';
$HTML::Mason::NewPackage::packvar = 'newpackage';
</%init>
EOF
		      expect => <<'EOF',
newpackage
EOF
		    );


#------------------------------------------------------------

    $group->add_test( name => 'preamble',
		      description => 'tests preamble compiler parameter',
		      interp_params => { 
			lexer_class => 'MasonX::Lexer::MSP',
		        preamble => 'my $msg = "This is the preamble.\n"; $m->print($msg);
'},
		      component => <<'EOF',
This is the body.
EOF
		      expect => <<'EOF',
This is the preamble.
This is the body.
EOF
		    );


#------------------------------------------------------------

    $group->add_test( name => 'postamble',
		      description => 'tests postamble compiler parameter',
		      interp_params => { 
			lexer_class => 'MasonX::Lexer::MSP',
		        postamble => 'my $msg = "This is the postamble.\n"; $m->print($msg);
'},
		      component => <<'EOF',
This is the body.
EOF
		      expect => <<'EOF',
This is the body.
This is the postamble.
EOF
		    );


#------------------------------------------------------------

    $group->add_test( name => 'preprocess',
		      description => 'test preprocess compiler parameter',
		      interp_params => { 
			lexer_class => 'MasonX::Lexer::MSP',
		        preprocess => \&brackets_to_lt_gt },
		      component => <<'EOF',
[%= 'foo' %]
bar
EOF
		      expect => <<'EOF',
foo
bar
EOF
		    );


#------------------------------------------------------------

    $group->add_test( name => 'postprocess_text1',
		      description => 'test postprocess compiler parameter (alpha blocks)',
		      interp_params => { 
			lexer_class => 'MasonX::Lexer::MSP',
		        postprocess_text => \&uc_alpha },
		      component => <<'EOF',
<%= 'foo' %>
bar
EOF
		      expect => <<'EOF',
foo
BAR
EOF
		    );


#------------------------------------------------------------
    $group->add_test( name => 'postprocess_text2',
		      description => 'test postprocess compiler parameter (alpha blocks)',
		      interp_params => { 
			lexer_class => 'MasonX::Lexer::MSP',
		        postprocess_text => \&uc_alpha },
		      component => <<'EOF',
<%= 'foo' %>
<%text>bar</%text>
EOF
		      expect => <<'EOF',
foo
BAR
EOF
		    );


#------------------------------------------------------------

    $group->add_test( name => 'postprocess_perl1',
		      description => 'test postprocess compiler parameter (perl blocks)',
		      interp_params => { 
			lexer_class => 'MasonX::Lexer::MSP',
		        postprocess_perl => \&make_foo_foofoo },
		      component => <<'EOF',
<%= 'foo' %>
bar
EOF
		      expect => <<'EOF',
foofoo
bar
EOF
		    );

#------------------------------------------------------------

    $group->add_test( name => 'postprocess_perl2',
		      description => 'test postprocess compiler parameter (perl blocks)',
		      interp_params => { 
			lexer_class => 'MasonX::Lexer::MSP',
		        postprocess_perl => \&make_foo_foofoo },
		      component => <<'EOF',
<%= 'foo' %>
<% $m->print("Make mine foo!\n"); %>\
bar
<%= "stuff-$var-stuff" %>
<%init>
 my $var = 'foo';
</%init>
EOF
		      expect => <<'EOF',
foofoo
Make mine foofoo!
bar
stuff-foofoo-stuff
EOF
		    );




#------------------------------------------------------------
    $group->add_test( name => 'bad_var_name',
		      description => 'test that invalid Perl variable names are caught',
		      interp_params => { lexer_class => 'MasonX::Lexer::MSP' },
		      component => <<'EOF',
<%args>
$foo
$8teen
%bar
</%args>
Never get here
EOF
		      expect_error => qr{Invalid <%args> section line},
		    );

#------------------------------------------------------------
    $group->add_test( name => 'whitespace_near_args',
		      description => 'test that whitespace is allowed before </%args>',
		      interp_params => { lexer_class => 'MasonX::Lexer::MSP' },
		      call_args => [qw(foo foo)],
		      component => <<'EOF',
  <%args>
   $foo
  </%args>
EOF
		      expect => "  \n",
		    );

#------------------------------------------------------------

    $group->add_test( name => 'line_nums',
		      description => 'make sure that errors are reported with the correct line numbers',
		      interp_params => { lexer_class => 'MasonX::Lexer::MSP' },
		      component => <<'EOF',
<%= $x %> <%= $y %>
<%= $z %>
<% die "Dead"; %>\
<%init>
my ($x, $y, $z) = qw(a b c);
</%init>
EOF
		      expect_error => qr/Dead at .* line 3/,
		    );

#------------------------------------------------------------

    $group->add_test( name => 'line_nums2',
		      description => 'make sure that errors are reported with the correct line numbers',
		      interp_params => { lexer_class => 'MasonX::Lexer::MSP' },
		      component => <<'EOF',
<%= $x %> <%= $y %>
<%= $z %>\
<% die "Dead"; %>\
<%init>
my ($x, $y, $z) = qw(a b c);
</%init>
EOF
		      expect_error => qr/Dead at .* line 3/,
		    );

#------------------------------------------------------------

    $group->add_test( name => 'line_nums3',
		      description => 'make sure that errors are reported with the correct line numbers',
		      interp_params => { lexer_class => 'MasonX::Lexer::MSP' },
		      component => <<'EOF',
<%= $x %> <%= $y %>
<%= $z %>
<%init>
my ($x, $y, $z) = qw(a b c);
die "Dead";
</%init>
EOF
		      expect_error => qr/Dead at .* line 5/,
		    );

#------------------------------------------------------------

    $group->add_test( name => 'line_nums4',
		      description => 'make sure that errors are reported with the correct line numbers in <%once> blocks',
		      interp_params => { lexer_class => 'MasonX::Lexer::MSP' },
		      component => <<'EOF',
1
2
3
<%ONCE>
$x = 1;
</%ONCE>
EOF
		      expect_error => qr/Global symbol .* at .* line 5/,
		    );

#------------------------------------------------------------

    $group->add_test( name => 'line_nums_off_by_one',
		      description => 'make sure that line number reporting is not off by one',
		      interp_params => { lexer_class => 'MasonX::Lexer::MSP' },
		      component => <<'EOF',
1
2
3
<%once>#4
my $x = 1; #5
</%once>6
7
<%args>#8
$foo#9
@bar#10
</%args>11
<%init>#12
#13
#14
#15
$y; #16
</%init>
EOF
		      expect_error => qr/Global symbol .* at .* line 16/,
		    );

#------------------------------------------------------------

    $group->add_test( name => 'attr_block_zero',
		      description => 'test proper handling of zero in <%attr> block values',
		      interp_params => { lexer_class => 'MasonX::Lexer::MSP' },
		      component => <<'EOF',
<%attr>
 key => 0
</%attr>
<%= $m->current_comp->attr_exists('key') ? 'exists' : 'missing' %>
EOF
		      expect => "exists\n",
		    );

#------------------------------------------------------------

    $group->add_test( name => 'error_in_args',
		      description => 'Test line number reporting for <%args> block',
		      interp_params => { lexer_class => 'MasonX::Lexer::MSP' },
		      component => <<'EOF',
lalalal
<%args>
$foo => this should break
</%args>
EOF
		      expect_error => qr/Bareword "break".*error_in_args line 3/,
		    );

#------------------------------------------------------------

    $group->add_test( name => 'block_end_without_nl',
		      description => 'Test that a block can end without a newline before it',
		      interp_params => { lexer_class => 'MasonX::Lexer::MSP' },
		      component => <<'EOF',
no newlines<%args>$foo => 1</%args><%attr>foo => 1</%attr><%flags>inherit => undef</%flags>
EOF
		      expect => <<'EOF',
no newlines
EOF
		    );

#------------------------------------------------------------

    $group->add_test( name => 'more_block_variations',
		      description => 'Test various mixture of whitespace with blocks',
		      interp_params => { lexer_class => 'MasonX::Lexer::MSP' },
		      component => <<'EOF',
various
<%args>
 $foo => 1</%args>
<%attr>
  foo => 1</%attr>
<%args>$bar => 1
</%args>
<%attr>bar => 1
</%attr>
<%args>
 $quux => 1</%args>
<%attr>
  quux => 1</%attr>
<%args>  $baz => 1
</%args>
<%attr>  baz => 1
</%attr>
EOF
		      expect => <<'EOF',
various
EOF
		    );

#------------------------------------------------------------

    $group->add_test( name => 'percent_at_end',
		      description => 'Make sure that percent signs are only considered perl lines when at the beginning of the line',
		      interp_params => { lexer_class => 'MasonX::Lexer::MSP' },
		      component => <<'EOF',
<%= $x %>% $x = 5;
<%= $x %>
<%init>
my $x = 10;
</%init>
EOF
		      expect => <<'EOF',
10% $x = 5;
10
EOF
		    );

#------------------------------------------------------------

    $group->add_test( name => 'nameless_method',
		      description => 'Check for appropriate error message when there is a method or def block without a name',
		      interp_params => { lexer_class => 'MasonX::Lexer::MSP' },
		      component => <<'EOF',
<%method>
foo
</%method>
EOF
		      expect_error => qr/method block without a name at .*/
		    );

#------------------------------------------------------------

    $group->add_test( name => 'invalid_method_name',
		      description => 'Check for appropriate error message when there is a method with an invalid name',
		      interp_params => { lexer_class => 'MasonX::Lexer::MSP' },
		      component => <<'EOF',
<%method   >
foo
</%method>
EOF
		      expect_error => qr/Invalid method name:.*/
		    );

#------------------------------------------------------------

	$group->add_test( name => 'uc_method',
			  description => 'make sure that <%METHOD ...> is allowed',
		      interp_params => { lexer_class => 'MasonX::Lexer::MSP' },
			  component => <<'EOF',
calling SELF:foo - <& SELF:foo &>
<%METHOD foo>bar</%METHOD>
EOF
                          expect => <<'EOF',
calling SELF:foo - bar
EOF
                        );

#------------------------------------------------------------

    if ($HTML::Mason::VERSION >= 1.14) {
        $group->add_test( name => 'multiple_user_escapes',
                          description => 'test that comma works with user escapes',
                          interp_params => { lexer_class => 'MasonX::Lexer::MSP',
                                             escape_flags => {
						one => sub { ${$_[0]} =~ s/1/2/; },
						two => sub { ${$_[0]} =~ s/2/3/; },
						},
					    },
                          component => <<'EOF',
<%= 1 %>
<%= 1 |one%>
<%= 1 |one,two%>
<%= 1 |two,one%>
EOF
                          expect => <<'EOF',
1
2
3
2
EOF
                        );
    }

#------------------------------------------------------------

    return $group;
}

# preprocessing the component
sub brackets_to_lt_gt
{
    my $comp = shift;
    ${ $comp } =~ s/\[\%(.*?)\%\]/<\%$1\%>/g;
}

# postprocessing alpha/perl code
sub uc_alpha
{
    ${ $_[0] } = uc ${ $_[0] };
}

sub make_foo_foofoo
{
    ${ $_[0] } =~ s/foo/foofoo/ig;
}
