use strict;
use warnings;

use Config;
use HTML::Mason::Tests;
use HTML::Mason::Tools qw(load_pkg);

my $tests = make_tests();
$tests->run;

{ package HTML::Mason::Commands;
  sub _make_interp {
      $tests->_make_interp(@_);
  }}

sub make_tests {
    my $group = HTML::Mason::Tests->tests_class->new( name => 'compiler',
                                                      description => 'compiler and lexer object functionality' );


#------------------------------------------------------------

    $group->add_test( name => 'allowed_globals',
                      description => 'test that undeclared globals cause an error',
                      interp_params => { use_object_files => 0 }, # force it to parse comp each time
                      component => <<'EOF',
<% $global = 1 %>
EOF
                      expect_error => 'Global symbol .* requires explicit package name',
                    );


#------------------------------------------------------------

    $group->add_test( name => 'allowed_globals2',
                      description => 'test that undeclared globals cause an error',
                      pretest_code => sub { undef *HTML::Mason::Commands::global; undef *HTML::Mason::Commands::global },  # repeated to squash a var used only once warning
                      interp_params => { use_object_files => 0 },
                      component => <<'EOF',
<% $global = 1 %>
EOF
                      expect_error => 'Global symbol .* requires explicit package name',
                    );


#------------------------------------------------------------

    $group->add_test( name => 'allowed_globals3',
                      description => 'test that declared globals are allowed',
                      interp_params => { use_object_files => 0, allow_globals => ['$global'] },
                      component => <<'EOF',
<% $global = 1 %>
EOF
                      expect => <<'EOF',
1
EOF
                    );

#------------------------------------------------------------

    $group->add_test( name => 'default_escape_flags',
                      description => 'test that no escaping is done by default',
                      interp_params => { use_object_files => 0 },
                      component => <<'EOF',
Explicitly HTML-escaped: <% $expr |h %><p>
Explicitly HTML-escaped redundantly: <% $expr |hh %><p>
Explicitly URL-escaped: <% $expr |u
%><p>
No flags: <% $expr %><p>
No flags again: <% $expr %><p>
Explicitly not escaped: <% $expr | n%><p>
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

#------------------------------------------------------------

    $group->add_test( name => 'default_escape_flags_new',
                      description => 'test new escape flags',
                      interp_params => { use_object_files => 0 },
                      component => <<'EOF',
Explicitly HTML-escaped: <% $expr | h %><p>
Explicitly HTML-escaped redundantly: <% $expr | h,h %><p>
Explicitly URL-escaped: <% $expr |u
%><p>
No flags: <% $expr %><p>
No flags again: <% $expr %><p>
Explicitly not escaped: <% $expr | n %><p>
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

#------------------------------------------------------------

    $group->add_test( name => 'default_escape_flags_2',
                      description => 'test that turning on default escaping works',
                      interp_params => { use_object_files => 0, default_escape_flags => 'h' },
                      component => <<'EOF',
Explicitly HTML-escaped: <% $expr |h %><p>
Explicitly HTML-escaped redundantly: <% $expr |hh %><p>
Explicitly URL-escaped: <% $expr |un
%><p>
No flags: <% $expr %><p>
No flags again: <% $expr %><p>
Explicitly not escaped: <% $expr | n%><p>
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

#------------------------------------------------------------

    $group->add_test( name => 'default_escape_flags_2_new',
                      description => 'test that turning on default escaping works with new flags',
                      interp_params => { use_object_files => 0,
                                         default_escape_flags => [ 'h' ] },
                      component => <<'EOF',
Explicitly HTML-escaped: <% $expr | h %><p>
Explicitly HTML-escaped redundantly: <% $expr | h , h %><p>
Explicitly URL-escaped: <% $expr | u, n
%><p>
No flags: <% $expr %><p>
No flags again: <% $expr %><p>
Explicitly not escaped: <% $expr | n %><p>
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

#------------------------------------------------------------

    $group->add_test( name => 'setting_escapes',
                      description => 'test setting escapes',
                      component => <<'EOF',
% $m->interp->set_escape( uc => sub { ${$_[0]} = uc ${$_[0]} } );
This will be in <% 'upper case' | uc %>
EOF
                      expect => <<'EOF',
This will be in UPPER CASE
EOF
                    );

#------------------------------------------------------------

    $group->add_test( name => 'invalid_escape_name',
                      description => 'test setting an escape with an invalid name',
                      component => <<'EOF',
% $m->interp->set_escape( 'u c' => sub { uc $_[0] } );
EOF
                      expect_error => qr/Invalid escape name/,
                    );

#------------------------------------------------------------

    $group->add_test( name => 'globals_in_default_package',
                      description => 'tests that components are executed in HTML::Mason::Commands package by default',
                      interp_params => { use_object_files => 0,
                                         allow_globals => ['$packvar'] },
                      component => <<'EOF',
<% $packvar %>
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
                      interp_params => { use_object_files => 0,
                                         allow_globals => ['$packvar'],
                                         in_package => 'HTML::Mason::NewPackage' },
                      component => <<'EOF',
<% $packvar %>
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
                      interp_params => { preamble => 'my $msg = "This is the preamble.\n"; $m->print($msg);
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
                      interp_params => { postamble => 'my $msg = "This is the postamble.\n"; $m->print($msg);
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
                      interp_params => { preprocess => \&brackets_to_lt_gt },
                      component => <<'EOF',
[% 'foo' %]
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
                      interp_params => { postprocess_text => \&uc_alpha },
                      component => <<'EOF',
<% 'foo' %>
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
                      interp_params => { postprocess_text => \&uc_alpha },
                      component => <<'EOF',
<% 'foo' %>
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
                      interp_params => { postprocess_perl => \&make_foo_foofoo },
                      component => <<'EOF',
<% 'foo' %>
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
                      interp_params => { postprocess_perl => \&make_foo_foofoo },
                      component => <<'EOF',
<% 'foo' %>
% $m->print("Make mine foo!\n");
bar
<% "stuff-$var-stuff" %>
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
                      component => <<'EOF',
<% $x %> <% $y %>
<% $z %>
% die "Dead";
<%init>
my ($x, $y, $z) = qw(a b c);
</%init>
EOF
                      expect_error => qr/Dead at .* line 3/,
                    );

#------------------------------------------------------------

    $group->add_test( name => 'line_nums2',
                      description => 'make sure that errors are reported with the correct line numbers',
                      component => <<'EOF',
<% $x %> <% $y %>
<% $z %>\
% die "Dead";
<%init>
my ($x, $y, $z) = qw(a b c);
</%init>
EOF
                      expect_error => qr/Dead at .* line 3/,
                    );

#------------------------------------------------------------

    $group->add_test( name => 'line_nums3',
                      description => 'make sure that errors are reported with the correct line numbers',
                      component => <<'EOF',
<% $x %> <% $y %>
<% $z %>
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

    $group->add_test( name => 'line_nums_with_escaped_newlines',
                      description => 'Check line numbers of error messages after escaped newlines',
                      component => <<'EOF',
1
2
3\
4\
5
% die "Dead";
EOF
                      expect_error => qr/Dead at .* line 6/,
                    );

#------------------------------------------------------------

    $group->add_test( name => 'line_nums_off_by_one',
                      description => 'make sure that line number reporting is not off by one',
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

    $group->add_test( name => 'line_nums_off_2',
                      description => 'make sure that line number reporting is not off (another buggy case)',
                      component => <<'EOF',
<%flags>
    inherit => undef
</%flags>
% die "really #4";
EOF
                      expect_error => qr/really #4 .* line 4/,
                    );

#------------------------------------------------------------

    $group->add_test( name => 'attr_block_zero',
                      description => 'test proper handling of zero in <%attr> block values',
                      component => <<'EOF',
<%attr>
 key => 0
</%attr>
<% $m->current_comp->attr_exists('key') ? 'exists' : 'missing' %>
EOF
                      expect => "exists\n",
                    );

#------------------------------------------------------------

    $group->add_test( name => 'attr_flag_block_comment',
                      description => 'test comment lines in attr and flags blocks',
                      component => <<'EOF',
<%attr>
# this is a comment
  # another comment
 key => 'foo'
# one last comment
</%attr>
<%flags>
# this is a comment
  # another comment
inherit => undef
# one last comment
</%flags>
compiled
EOF
                      expect => 'compiled',
                    );

#------------------------------------------------------------

    $group->add_test( name => 'attr_flag_block_empty',
                      description => 'test empty attr and flags blocks',
                      component => <<'EOF',
<%attr></%attr>
<%flags>
</%flags>
compiled
EOF
                      expect => 'compiled',
                    );

#------------------------------------------------------------

    my $error =
        $] >= 5.006 ? qr/Unterminated <>/ : qr/Bareword "subcomp" not allowed/;

    $group->add_test( name => 'subcomp_parse_error',
                      description => 'A misnamed block at the beginning of a component was throwing the lexer into an infinite loop.  Now it should be compiled into a component with a syntax error.',
                      component => <<'EOF',
<%subcomp .foo>
 <% 5 %>
</%subcomp>
EOF
                      expect_error => $error,
                    );

#------------------------------------------------------------

    $group->add_test( name => 'error_in_args',
                      description => 'Test line number reporting for <%args> block',
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
                      component => <<'EOF',
<% $x %>% $x = 5;
<% $x %>
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
                          component => <<'EOF',
calling SELF:foo - <& SELF:foo &>
<%METHOD foo>bar</%METHOD>
EOF
                          expect => <<'EOF',
calling SELF:foo - bar
EOF
                        );

#------------------------------------------------------------

        $group->add_test( name => 'no_strict',
                          description => 'test turning off strict in a component',
                          interp_params => { use_strict => 0 },
                          component => <<'EOF',
no errors
<%init>
$x = 1;
</%init>
EOF
                          expect => <<'EOF',
no errors
EOF
                        );

#------------------------------------------------------------

        $group->add_test( name => 'no_strict_no_object_files',
                          description =>
                          'test turning off strict in a component when not using object files',
                          interp_params => { use_strict => 0, use_object_files => 0 },
                          component => <<'EOF',
no errors
<%init>
$x = 1;
</%init>
EOF
                          expect => <<'EOF',
no errors
EOF
                        );

#------------------------------------------------------------

        $group->add_test( name => 'weird_case',
                          description => 'test weird parsing case',
                          component => <<'EOF',
<%init()%>
<%args()%>
<%once>
sub init { 'init' }
sub args { 'args' }
</%once>
EOF
                          expect => <<'EOF',
init
args
EOF
                        );


#------------------------------------------------------------

        $group->add_test( name => 'subst_tag_comments',
                          description => 'Make sure comments parse correctly in substitution tags',
                          component => <<'EOF',
<%# Here's a comment
  5 + 5 %>
EOF
                          expect => 10,
                        );

#------------------------------------------------------------

        $group->add_test( name => 'shared_to_init',
                          description => 'Make sure <%init> can see lexicals in <%shared>',
                          component => <<'EOF',
<%init>
 $m->out( $x );
</%init>
<%shared>
 my $x = 7;
</%shared>
EOF
                          expect => 7,
                        );

#------------------------------------------------------------

        $group->add_test( name => 'shared_to_init_global',
                          description => 'Make sure <%init> can see global variables in <%shared>',
                          interp_params => { allow_globals => ['$x'] },
                          component => <<'EOF',
<%init>
 $m->out( $x );
</%init>
<%shared>
 $x = 8;
</%shared>
EOF
                          expect => 8,
                        );

#------------------------------------------------------------

        $group->add_test( name => 'double_pipe_or',
                          description => 'Make sure || works in a substitution',
                          component => <<'EOF',
Should be 1: <% 1 || 2 %>
EOF
                          expect => <<'EOF',
Should be 1: 1
EOF
                        );

#------------------------------------------------------------

        $group->add_test( name => 'double_pipe_or_2',
                          description => 'Make sure || works in a substitution (again)',
                          component => <<'EOF',
<%once>
sub foo { 'foo!' }
sub bar { 'bar!' }
</%once>
<% foo || bar %>
EOF
                          expect => <<'EOF',
foo!
EOF
                        );

#------------------------------------------------------------

        $group->add_test( name => 'flags_regex',
                          description => 'Make sure flags must start with alpha or underscore',
                          component => <<'EOF',
<% 1 | 1 %>
EOF
                          expect => <<'EOF',
1
EOF
                        );

#------------------------------------------------------------

        $group->add_test( name => 'qw_in_perl_lines',
                          description => 'Make sure that Mason that a qw() list stretching across multiple perl-lines works',
                          component => <<'EOF',
% foreach my $foo ( qw( a
%                       b ) ) {
<% $foo %>
% }
EOF
                          expect => <<'EOF',
a
b
EOF
                        );

#------------------------------------------------------------

    $group->add_support( path => '/has_subcomp',
                         component => <<'EOF',
<& .a &>
<%def .a>
A
</%def>
EOF
                       );

    $group->add_support( path => '/no_subcomp',
                         component => <<'EOF',
<%shared>
my $y = 1;
</%shared>
EOF
                       );

    $group->add_test( name => 'subcomp_leak',
                      description => 'Make sure subcomps from one component do not show up in other components',
                      component => <<'EOF',
<%init>
$m->scomp('has_subcomp');
$m->scomp('no_subcomp');

local *FH;
my $obj = $m->fetch_comp('no_subcomp')->object_file;
open FH, "< $obj"
    or die "Cannot read $obj";
my $text = join '', <FH>;
close FH;
</%init>
% if ( $text =~ /subcomponent_\.a/ ) {
Subcomponent leakage!
% } else {
No leak
% }
EOF
                      expect => <<'EOF',
No leak
EOF
                    );

#------------------------------------------------------------

        $group->add_test( name => 'use_source_line_numbers_1',
                          description => 'test presence of line directives when use_source_line_numbers is 1 (default)',
                          component => <<'EOF',
This is line <% __LINE__ %>.
<%doc>

</%doc>
This is line <% __LINE__ %>.
EOF
                          expect => <<'EOF',
This is line 1.
This is line 5.
EOF
                        );

#------------------------------------------------------------

        $group->add_test( name => 'use_source_line_numbers_0',
                          description => 'test absence of line directives when use_source_line_numbers is 1',
                          interp_params => { use_source_line_numbers => 0 },
                          component => <<'EOF',
This line number is <% __LINE__ < 3 ? 'less than 3' : 'not less than 3' %>.
EOF
                          expect => <<'EOF',
This line number is not less than 3.
EOF
                        );

#------------------------------------------------------------

        $group->add_test( name => 'define_args_hash_never',
                          description => 'test setting define_args_hash to never',
                          interp_params => { define_args_hash => 'never' },
                          component => <<'EOF',
% $ARGS{foo} = 1;
no error?
EOF

                          expect_error => qr/Global symbol.*%ARGS/
                        );

#------------------------------------------------------------

        $group->add_test( name => 'define_args_hash_always',
                          description => 'test setting define_args_hash to always',
                          interp_params => { define_args_hash => 'always' },
                          component => <<'EOF',
% eval '$AR' . 'GS{foo} = 1';
<% $@ ? $@ : 'no error' %>
EOF
                          expect => <<'EOF',
no error
EOF
                        );

#------------------------------------------------------------

        $group->add_test( name => 'define_args_hash_auto',
                          description => 'test setting define_args_hash to always',
                          call_args => { bar => 7 },
                          component => <<'EOF',
<%args>
$foo => $ARGS{bar}
</%args>
foo is <% $foo %>
EOF
                          expect => <<'EOF',
foo is 7
EOF
                        );

#------------------------------------------------------------

        $group->add_test( name => 'comment_in_sub',
                          description => 'test a substitution that only contains a comment',
                          component => <<'EOF',
0
<% # a one-line comment %>
1
<%
   # a multiline
  
   # comment
%>
2
<% # a multiline
   # comment %>
3
<% %>
4

EOF
                          expect => <<'EOF',
0

1

2

3

4
EOF
                        );

#------------------------------------------------------------

        $group->add_test( name => 'in_package_shared',
                          description => 'Make sure in_package works with %shared',
                          interp_params => { in_package => 'HTML::Mason::Foo' },
                          component => <<'EOF',
<%shared>
my $foo = 'bar';
</%shared>
Foo: <% $foo %>
EOF
                          expect => <<'EOF',
Foo: bar
EOF
                        );

#------------------------------------------------------------

        $group->add_test( name => 'in_package_m_in_shared',
                          description => 'Make sure $m works with %shared when in_package is set',
                          interp_params => { in_package => 'HTML::Mason::Bar' },
                          component => <<'EOF',
<%shared>
my $dh = $m->dhandler_name;
</%shared>
<% $dh %>
EOF
                          expect => <<'EOF',
dhandler
EOF
                        );

#------------------------------------------------------------

        $group->add_test( name => 'compiler_id_change',
                          description => 'Make sure different compiler params use different object dirs',
                          component => <<'EOF',
<%args>
$count => 0
$compiler_params => {}
$object_id_hash => {}
</%args>

count = <% $count %>

<%perl>
my $object_id = $m->interp->compiler->object_id;
if ($object_id_hash->{$object_id}++) {
    die "object_id '$object_id' has been seen (count = $count)!";
}
if ($count == 0) {
    $compiler_params->{enable_autoflush} = 0;
} elsif ($count == 1) {
    $compiler_params->{default_escape_flags} = 'h';
} elsif ($count == 2) {
    $compiler_params->{use_source_line_numbers} = 0;
} elsif ($count == 3) {
    $compiler_params->{postprocess_text} = sub { my $content = shift; $$content =~ tr/a-z/A-Z/ };
} else {
    return;
}
my $buf;
my $interp = _make_interp(comp_root => $m->interp->comp_root,
                          data_dir => $m->interp->data_dir,
                          out_method => \$buf,
                          %$compiler_params);
$interp->exec($m->current_comp->path, count=>$count+1, compiler_params=>$compiler_params, object_id_hash=>$object_id_hash);
$m->print($buf);
</%perl>
EOF
                          expect => <<'EOF',

count = 0


count = 1


count = 2


count = 3


COUNT = 4
EOF
                        );

#------------------------------------------------------------

        $group->add_test( name => 'no_warnings',
                          description => 'Make sure no warnings are generated for trying to output undef',
                          component => <<'EOF',
% my $x;
x is <% $x %>
EOF
                          expect => <<'EOF',
x is 
EOF
                        );

#------------------------------------------------------------

        $group->add_test( name => 'no_warnings_without_autoflush',
                          description => 'Make sure no warnings are generated for trying to output undef when enable_autoflush is off',
                          interp_params => { enable_autoflush => 0 },
                          component => <<'EOF',
% my $x;
x is <% $x %>
EOF
                          expect => <<'EOF',
x is 
EOF
                          no_warnings => 1,
                        );

#------------------------------------------------------------

        $group->add_test( name => 'no warnings',
                          description => "Make sure that warnings _aren't_ generated for other bad use of uninit",
                          component => <<'EOF',
% my $x;
x is <% $x + 2 %>
EOF
                          expect => <<'EOF',
x is 2
EOF
                        );

#------------------------------------------------------------

        $group->add_test( name => 'warnings_without_autoflush',
                          description => "Make sure that warnings _aren't_ generated for other bad use of uninit when enable_autoflush is off",
                          interp_params => { enable_autoflush => 0 },
                          component => <<'EOF',
% my $x;
x is <% $x + 2 %>
EOF
                          expect => <<'EOF',
x is 2
EOF
                        );

#------------------------------------------------------------

        $group->add_test( name => 'warnings_need_explicit_enabling',
                          description => "Make sure that warnings _are_ generated for other bad use of uninit",
                          component => <<'EOF',
% use warnings;
% my $x;
x is <% $x + 2 %>
EOF
                          expect => <<'EOF',
x is 2
EOF
                          expect_warnings => qr/Use of uninitialized value.+in addition/,
                        );

#------------------------------------------------------------

        $group->add_test( name => 'warnings_need_explicit_enabling_without_autoflush',
                          description => "Make sure that warnings _are_ generated for other bad use of uninit when enable_autoflush is off",
                          interp_params => { enable_autoflush => 0 },
                          component => <<'EOF',
% use warnings;
% my $x;
x is <% $x + 2 %>
EOF
                          expect => <<'EOF',
x is 2
EOF
                          expect_warnings => qr/Use of uninitialized value.+in addition/,
                        );

#------------------------------------------------------------

        $group->add_test( name => 'warnings_do_not_need_explicit_enabling_on_use_warnings',
                          interp_params => { use_warnings => 1 },
                          description => "Make sure that warnings _are_ generated on use_warnings for other bad use of uninit",
                          component => <<'EOF',
% my $x;
use_warnings is <% $x + 2 %>
EOF
                          expect => <<'EOF',
use_warnings is 2
EOF
                          expect_warnings => qr/Use of uninitialized value.+in addition/,
                        );

#------------------------------------------------------------

        $group->add_test( name => 'warnings_do_not_need_explicit_enabling_without_autoflush_on_use_warnings',
                          description => "Make sure that warnings _are_ generated on use_warnings for other bad use of uninit when enable_autoflush is off",
                          interp_params => { enable_autoflush => 0, use_warnings => 1 },
                          component => <<'EOF',
% my $x;
use_warnings is <% $x + 2 %>
EOF
                          expect => <<'EOF',
use_warnings is 2
EOF
                          expect_warnings => qr/Use of uninitialized value.+in addition/,
                        );

#------------------------------------------------------------

        $group->add_test( name => 'unbalanced_content_block_error',
                          description => 'Detect and report unbalanced </&> tags',
                          interp_params => { enable_autoflush => 0 },
                          component => <<'EOF',
</&>
EOF
                          expect_error => qr/content ending tag but no beginning tag/
                        );

#------------------------------------------------------------

        $group->add_test( name => 'unbalanced_content_block_subcomp_error',
                          description => 'Detect and report unbalanced </&> tags in subcomponents',
                          interp_params => { enable_autoflush => 0 },
                          component => <<'EOF',
<%def test>
</&>
</%def>
EOF
                          expect_error => qr/content ending tag but no beginning tag/
                        );

#------------------------------------------------------------

    $group->add_test( name => 'non_stringifying_escape',
                      description => 'stringify after escapes, not before',
                      component => <<'EOF',
% $m->interp->set_escape( blort => sub { ${$_[0]} = ${$_[0]}->[0] if ref ${$_[0]} } );
Works for <% 'strings' | blort %>
Works for <% ['refs']  | blort %>
EOF
                      expect => <<'EOF',
Works for strings
Works for refs
EOF
                    );

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
