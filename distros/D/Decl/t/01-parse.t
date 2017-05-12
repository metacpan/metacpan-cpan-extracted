#!perl -T

use Test::More tests => 191;
use Data::Dumper;

use Decl qw(-nofilter Decl::Semantics);
use Decl::Parser;
use Decl::Util;
use Iterator::Simple qw(:all);



# --------------------------------------------------------------------------------------
# First set of tests: let's just load the library, with our core semantics, and make
# sure the tags are getting defined during import.
# --------------------------------------------------------------------------------------

#@tags = Decl->known_tags();
#ok (@tags > 0);
#ok (grep { $_ eq 'do'} @tags);


# -------------------------------------------------------------------------------------
# Next, let's set up a simple parser to test the procedural parser API.
# --------------------------------------------------------------------------------------

$p = Decl::Parser->new();
$p->add_tokenizer('WHITESPACE*', '\s+');
$l = $p->lexer("this is a test        string");

@t1 = ();
while ($t = $l->()) {
   push @t1, $t;
}
is (@t1, 5);
@tokens = $p->tokens("this    is a test string");
is_deeply (\@t1, \@tokens);

$p->add_tokenizer('T-word', '^t.*');
@tokens = $p->lexer("this is another  test string");

is (@tokens, 5);
isa_ok ($tokens[0], 'ARRAY');
is (${$tokens[0]}[0], 'T-word');
is (${$tokens[0]}[1], 'this');
is ($tokens[1], 'is');

# -----------------------------------------------------------------------------------------
# Now we exercise the default line parser.
# -----------------------------------------------------------------------------------------
$tree = Decl->new();
$p = $tree->parser('default-line');
isa_ok ($p, "Decl::Parser");

@tokens = $p->lexer ('t (parm1, parm2=on) "label"');
is_deeply (\@tokens, ['t', ['LPAREN', '('], 'parm1', ['COMMA', ','], 'parm2', ['EQUALS', '='], 'on', ['RPAREN', ')'], ['STRING', 'label']]);

@tokens = $p->lexer ('(parm="this is a test") [option1, option2 doubled] \'label\' parser <');
is_deeply (\@tokens, [['LPAREN', '('], 'parm', ['EQUALS', '='], ['STRING', 'this is a test'], ['RPAREN', ')'],
                      ['LBRACK', '['], 'option1', ['COMMA', ','], 'option2', 'doubled', ['RBRACK', ']'],
                      ['STRING', 'label'], 'parser', ['LT', '<']]);
# ----------------------------------------------------------------------------------------
# A quick test of car, cdr, and popcar because we're going to use them in a minute.
# ----------------------------------------------------------------------------------------

$cons = ['a', [['b', 'c'], 'd']];

is (car($cons), 'a');
is (cdr(cdr($cons)), 'd');
is (car(car(cdr($cons))), 'b');

$cons = ['a', ['b', ['c', undef]]];

is (popcar($cons), 'a');
is (popcar($cons), 'b');
is (popcar($cons), 'c');
is (popcar($cons), undef);

sub upfrom {
   my ($m) = @_;
   [$m, sub { upfrom ($m+1); }]
}

$u = [1, sub { upfrom (2); }];

is (popcar($u), 1);
is (popcar($u), 2);
is (popcar($u), 3);
is (popcar($u), 4);
is (popcar($u), 5);
is (popcar($u), 6);
# I think that's clear enough....



# ---------------------------------------------------------------------------------------
# Now a test of tokenstream!
# ---------------------------------------------------------------------------------------

$s = $p->tokenstream ('(parm="this is a test") [option1, option2 doubled] \'label\' parser <');

is_deeply (popcar($s), ['LPAREN', '(']);
is        (popcar($s), 'parm');
is_deeply (popcar($s), ['EQUALS', '=']);
is_deeply (popcar($s), ['STRING', 'this is a test']);
is_deeply (popcar($s), ['RPAREN', ')']);
is_deeply (popcar($s), ['LBRACK', '[']);
is        (popcar($s), 'option1');
is_deeply (popcar($s), ['COMMA', ',']);
is        (popcar($s), 'option2');
is        (popcar($s), 'doubled');
is_deeply (popcar($s), ['RBRACK', ']']);
is_deeply (popcar($s), ['STRING', 'label']);
is        (popcar($s), 'parser');
is_deeply (popcar($s), ['LT', '<']);
is        (popcar($s), undef);

# ---------------------------------------------------------------------------------------
# Final tokenizer check: CODEBLOCK, which is a special tokenizer using Text::Balanced.
# ---------------------------------------------------------------------------------------

$s = $p->tokenstream ('code test {code test {code!} "with a string"} ');

is         (popcar($s), 'code');
is         (popcar($s), 'test');
is_deeply  (popcar($s), ['CODEBLOCK', '{code test {code!} "with a string"}']);
is         (popcar($s), undef);

# ---------------------------------------------------------------------------------------
# 2011-08-01: CODEBLOCK with a \n in it.
# ---------------------------------------------------------------------------------------

$s = $p->tokenstream ('code test {code test {code!} "with a linebreak\n"} ');

is         (popcar($s), 'code');
is         (popcar($s), 'test');
is_deeply  (popcar($s), ['CODEBLOCK', '{code test {code!} "with a linebreak\n"}']);
is         (popcar($s), undef);

# -------------------------------------------------------------------------------------
# Now let's check each of our little parser atoms.
# -------------------------------------------------------------------------------------


# ---------------------------------------
# token and literal
$s = $p->tokenstream ('(( not )))');

$p1 = Decl::Parser::token ('LPAREN');
$p2 = Decl::Parser::literal ('not');
$p3 = Decl::Parser::literal (')');

($token, $s) = $p1->($s);
is_deeply ($token, ['LPAREN', '(']);
is_deeply (car($s), ['LPAREN', '(']);  # Checking that the token stream advances.  'car' looks ahead at the next token.
($token, $s) = $p1->($s);
is_deeply ($token, ['LPAREN', '(']);
is_deeply (car($s), 'not');
($token, $s) = $p2->($s);
is_deeply ($token, ['', 'not']);
is_deeply (car($s), ['RPAREN', ')']);
($token, $s) = $p3->($s);
is_deeply ($token, ['RPAREN', ')']);
is_deeply (car($s), ['RPAREN', ')']);

($token, $ns) = $p1->($s);   # Test non-matching, too.
is ($token, undef);
is ($ns,    undef);

($token, $s) = $p3->($s);    # Stream still OK!
is_deeply ($token, ['RPAREN', ')']);
is_deeply (car($s), ['RPAREN', ')']);

($token, $ns) = $p2->($s);   # Test non-matching in literal.
is ($token, undef);
is ($ns,    undef);



# ---------------------------------------
# concatenation and alternation
$s = $p->tokenstream ('(( not )))');

$p1 = Decl::Parser::token ('LPAREN');
$p2 = Decl::Parser::literal ('not');
$p3 = Decl::Parser::literal (')');

$p4 = Decl::Parser::p_and ($p1, $p1, $p2, $p3, $p3);

($result, $remainder) = $p4->($s);
is_deeply ($result, [['LPAREN', '('], ['LPAREN', '('], ['', 'not'], ['RPAREN', ')'], ['RPAREN', ')']]);

$p5 = Decl::Parser::p_and ($p1, $p1, $p3, $p3);

($result, $remainder) = $p5->($s);
is ($result, undef);
is ($remainder, undef);

$p6 = Decl::Parser::p_or ($p5, $p4);

($result, $remainder) = $p6->($s);
is_deeply ($result, [['LPAREN', '('], ['LPAREN', '('], ['', 'not'], ['RPAREN', ')'], ['RPAREN', ')']]);

# ---------------------------------------
# general non-token word and end-of-input
$p7 = Decl::Parser::p_and ($p1, $p1, \&Decl::Parser::word, $p3, $p3, $p3, \&Decl::Parser::end_of_input);
($result, $remainder) = $p7->($s);
is_deeply ($result, [['LPAREN', '('], ['LPAREN', '('], ['', 'not'], ['RPAREN', ')'], ['RPAREN', ')'], ['RPAREN', ')']]);

$p8 = Decl::Parser::p_and ($p1, $p1, \&Decl::Parser::word, $p3, $p3, \&Decl::Parser::end_of_input);
($result, $remainder) = $p8->($s);
is ($result, undef);

# -------------------------------------------------
# star!

$p9 = Decl::Parser::series($p1);
$p10 = Decl::Parser::p_and (Decl::Parser::series($p1), \&Decl::Parser::word, Decl::Parser::series($p3), \&Decl::Parser::end_of_input);
($result, $remainder) = $p9->($s);
is_deeply ($result, [['LPAREN', '('], ['LPAREN', '(']]);
($result, $remainder) = $p10->($s);
is_deeply ($result, [['LPAREN', '('], ['LPAREN', '('], ['', 'not'], ['RPAREN', ')'], ['RPAREN', ')'], ['RPAREN', ')']]);

@values = map { cdr $_ } @$result;
is_deeply (\@values, ['(', '(', 'not', ')', ')', ')']);
@types = map { car $_ } @$result;
is_deeply (\@types,  ['LPAREN', 'LPAREN', '', 'RPAREN', 'RPAREN', 'RPAREN']);

# -------------------------------------------------
# optional!

$p11 = Decl::Parser::p_and (Decl::Parser::series($p1), \&Decl::Parser::word, Decl::Parser::optional(\&Decl::Parser::word), Decl::Parser::series($p3), \&Decl::Parser::end_of_input);

($result, $remainder) = $p11->($s);
is_deeply ($result, [['LPAREN', '('], ['LPAREN', '('], ['', 'not'], ['RPAREN', ')'], ['RPAREN', ')'], ['RPAREN', ')']]);

# --------------------------------------------------------------------------------
# Now we're ready to build a parser by rule.
# --------------------------------------------------------------------------------

$ps10 = "p_and(series(token(['LPAREN']), \\&word, series(literal(')'))), \\&end_of_input)";
$p12 = $p->make_component ('test', $ps10);
($result, $remainder) = $p12->($s);
is($result, undef);

$ps11 = "p_and(series(token(['LPAREN'])), \\&word, series(literal(')')), \\&end_of_input)";
$p13 = $p->make_component ('', $ps11);
($result, $remainder) = $p13->($s);
is_deeply ($result, [['LPAREN', '('], ['LPAREN', '('], ['', 'not'], ['RPAREN', ')'], ['RPAREN', ')'], ['RPAREN', ')']]);

$p14 = $p->make_component ('test', $ps11);
($result, $remainder) = $p14->($s);
is_deeply ($result, ['test', [['LPAREN', '('], ['LPAREN', '('], ['', 'not'], ['RPAREN', ')'], ['RPAREN', ')'], ['RPAREN', ')']]]);

$s2 = $p->tokenstream ('one, two, three, four');
$p15 = $p->make_component ('', "list_of(\\&word)");
($result, $remainder) = $p15->($s2);
is_deeply ($result, [['', 'one'], ['', 'two'], ['', 'three'], ['', 'four']]);
$p15 = $p->make_component ('', "list_of(\\&word, 'COMMA')");
($result, $remainder) = $p15->($s2);
is_deeply ($result, [['', 'one'], ['COMMA', ','], ['', 'two'], ['COMMA', ','], ['', 'three'], ['COMMA', ','], ['', 'four']]);
$p15 = $p->make_component ('', "list_of(\\&word, 'COMMA*')");
($result, $remainder) = $p15->($s2);
is_deeply ($result, [['', 'one'], ['', 'two'], ['', 'three'], ['', 'four']]);

# ------------------------------------------------------------------------------------
# OK, single-rule parsers work like they should.  Now let's grab selected parts of
# the default line parser to make sure that machinery is working OK.
# ------------------------------------------------------------------------------------

$p15 = $p->get_parser('value');
$s = $p->tokenstream('"this is a string" ()');
($result, $remainder) = $p15->($s);
is_deeply ($result, ['value', ['STRING', 'this is a string']]);

$p16 = $p->get_parser('parm');
$s = $p->tokenstream('wer="this is a string!" ...');
($result, $remainder) = $p16->($s);
is_deeply ($result, ['parm', ['parmval', [['', 'wer'], ['value', ['STRING', 'this is a string!']]]]]);
($result, $remainder) = $p16->($p->tokenstream ('wer=stuff'));
is_deeply ($result, ['parm', ['parmval', [['', 'wer'], ['value', ['', 'stuff']]]]]);
($result, $remainder) = $p16->($p->tokenstream ('wer wer)('));
is_deeply ($result, ['parm', [['', 'wer'], ['', 'wer']]]);

$p17 = $p->get_parser('parmlist');
$s = $p->tokenstream ('(wer, thing=value, thing2="string value", wer bog)');
($result, $remainder) = $p17->($s);
is_deeply ($result, ['parmlist', [['parm',    [['', 'wer']]],
                                  ['parm',    ['parmval', [['', 'thing'], ['value', ['', 'value']]]]],
                                  ['parm',    ['parmval', [['', 'thing2'], ['value', ['STRING', 'string value']]]]],
                                  ['parm',    [['', 'wer'], ['', 'bog']]]]]);

# By Jove, I think we've got it!

# -------------------------------------------------------------------------------------------------
# Final exercise of the default line parser at the rule level, now that we've verified that the
# thing actually works.
# -------------------------------------------------------------------------------------------------

$p18 = $p->get_parser('line');
($result, $remainder) = $p18->($p->tokenstream ('t (parm1 = "parameter") [option = option, blargh] "Here is a label" perl < { test code }'));
is_deeply ($result, ['line', [['name', [['', 't']]],
                              ['parmlist', [['parm', ['parmval', [['', 'parm1'], ['value', ['STRING', 'parameter']]]]]]],
                              ['optionlist', [['parm', ['parmval', [['', 'option'], ['value', ['', 'option']]]]],
                                              ['parm', [['', 'blargh']]]]],
                              ['label', ['STRING', 'Here is a label']],
                              ['parser', [['', 'perl']]],
                              ['code', ['CODEBLOCK', '{ test code }']]]]);
($result, $remainder) = $p18->($p->tokenstream ('"label!"'));
is_deeply ($result, ['line', [['label', ['STRING', 'label!']]]]);

# ------------------------------------------------------------------------------------------------
# One level up, we have "parse", which takes the built parser's first rule, and applies it to
# an input that may or may not be a tokenstream already.  The remainder of the stream is
# discarded, if any.  (Your first rule is presumed to have an \&end_of_input at the end of it.)
# Better error handling (than the present lack thereof) would be a boon.  Not sure how to handle it.
# ------------------------------------------------------------------------------------------------

$result = $p->parse ('t_t (parm1 = "parameter") [option = option, blargh] "Here is a label"');
is_deeply ($result, ['line', [['name', [['', 't_t']]],
                              ['parmlist', [['parm', ['parmval', [['', 'parm1'], ['value', ['STRING', 'parameter']]]]]]],
                              ['optionlist', [['parm', ['parmval', [['', 'option'], ['value', ['', 'option']]]]],
                                              ['parm', [['', 'blargh']]]]],
                              ['label', ['STRING', 'Here is a label']]]]);

$result = $p->parse ('t "Here is a label" extraneous input');
is_deeply ($result, undef);  # See how unsatisfying that is?

$result = $p->parse ('');
is_deeply ($result, ['line', []]);

$result = $p->parse('t { # A line with a bracket');
is_deeply ($result, ['line', [['name', [['', 't']]], ['bracket', ['BRACKET', '{ # A line with a bracket']]]]);

$result = $p->parse('t # comment here');
is_deeply ($result, ['line', [['name', [['', 't']]], ['comment', ['COMMENT', '# comment here']]]]);



# -------------------------------------------------------------------------------------
# Final step in the default line parser: configuring a Decl::Node based
# on the final action defined.  (Whew!)
# -------------------------------------------------------------------------------------

$node = Decl::Node->new();
$p->execute ($node, 't (parm1 = "parameter") [option = option, blargh] "Here is a label" perl < { test code }');

is ($node->name(), 't');
is ($node->{parameters}->{parm1}, 'parameter');
is ($node->{options}->{option}, 'option');
is ($node->{options}->{blargh}, 'yes');
is ($node->label(), 'Here is a label');
is ($node->parser(), 'perl');
is ($node->code(), '{ test code }');

$node = Decl::Node->new('tag t (3) "This is a shorter test"');
$p->execute ($node);

is ($node->name(), 't');
is ($node->{parmlist}->[0], 3);
is ($node->label(), 'This is a shorter test');


# --------------------------------------------------------------------------------------
# Test the default body parser.
# --------------------------------------------------------------------------------------

# ---------------------------------------------------------------------------------------
# Now let's test the default body parser; we're doing some new stuff here.
# Tokenizer first.  Note the distinction between blank lines and those with whitespace only...
# ---------------------------------------------------------------------------------------

$p = $tree->parser('default-body');
isa_ok ($p, "Decl::Parser");
$s = $p->tokenstream (<<EOF);

# Here is a comment.

testing name (id=OK, something) [1, 2] "Label" {
   body text
   second line
}


  

EOF

is         (popcar($s), '# Here is a comment.');
is_deeply  (popcar($s), ['BLANKLINE', "\n\n"]);
is         (popcar($s), 'testing name (id=OK, something) [1, 2] "Label" {');
is         (popcar($s), '   body text');
is         (popcar($s), '   second line');
is         (popcar($s), '}');
is_deeply  (popcar($s), ['BLANKLINE', "\n\n\n"]);
is         (popcar($s), '  ');
is_deeply  (popcar($s), ['BLANKLINE', "\n\n"]);
is         (popcar($s), undef);

# ---------------------------------------------------------------------------------------
# 2011-08-06: Same thing, but with some escaped newlines.  Somewhere, this is getting me.
# ---------------------------------------------------------------------------------------

$p = $tree->parser('default-body');
isa_ok ($p, "Decl::Parser");
$s = $p->tokenstream (<<'EOF');

# Here is a comment.

testing name (id=OK, something) [1, 2] "Label\n" {
   body "This has a newline in it.\n\n";
   second line
}


  

EOF

is         (popcar($s), '# Here is a comment.');
is_deeply  (popcar($s), ['BLANKLINE', "\n\n"]);
is         (popcar($s), 'testing name (id=OK, something) [1, 2] "Label\n" {');
is         (popcar($s), '   body "This has a newline in it.\n\n";');
is         (popcar($s), '   second line');
is         (popcar($s), '}');
is_deeply  (popcar($s), ['BLANKLINE', "\n\n\n"]);
is         (popcar($s), '  ');
is_deeply  (popcar($s), ['BLANKLINE', "\n\n"]);
is         (popcar($s), undef);

# -------------------------------------------------------------------------------------
# Now the raw parser.
# -------------------------------------------------------------------------------------

$result = $p->parse (<<EOF);

# Here is a comment.

testing name (id=OK, something) [1, 2] "Label" {
   body text
   second line
}


  

EOF

is_deeply ($result, ['body', [['', '# Here is a comment.'], ['BLANKLINE', "\n\n"], ['', 'testing name (id=OK, something) [1, 2] "Label" {'],
                              ['', '   body text'], ['', '   second line'], ['', '}'], ['BLANKLINE', "\n\n\n"], ['', '  '], ['BLANKLINE', "\n\n"]]]);
                              

# An error case.

$result = $p->parse (<<EOF);

   toolbar
      tool league (xpm)  { ^do ("show league"); }
         "66 50 218 2",
         "   c #2C1F16",
         ".  c #2D2116",
         "X  c #332516",
         "o  c #3F2715",
         "O  c #362816",
        
      tool teams    { ^do ("show teams"); }

EOF
#diag Dumper($result);
#die;


# --------------------------------------------------------------------------------------
# OK, let's just do a basic parser test with something that *won't* activate any of
# our semantic classes, and make sure the basic node parser works.
# --------------------------------------------------------------------------------------
$tree = Decl->new(<<EOF);

# Here is a comment.

test1 name (id=OK, something, value="quoted spaces", cols="2.64in 1.13in 1.28in 0.91in") [1, 2, 4, 3] "Label" {
   body text
   second line
}

test2 t "another label" # commented, no bracket
   body text
   second line

   third!

EOF

is ($tree->tag, '*root');
isa_ok ($tree, 'Decl');

is_deeply ($tree->sketch, ['*root', [['test1', []], ['test2', [['body', []], ['second', []], ['third', []]]]]]); # 2011-03-13: third!->third due to flag
$test = $tree->find ('test1');
isa_ok ($test, 'Decl::Node');
is ($test->name, 'name');
is ($test->parameter('id'), 'OK');
ok ($test->parameter('something'));
is ($test->parameter('value'), 'quoted spaces');  # 2010-11-18 - forgot spaces?
is ($test->parameter('cols'),  '2.64in 1.13in 1.28in 0.91in'); # 2010-11-18 - ...
@options = $test->optionlist;
is_deeply (\@options, ['1', '2', '4', '3']);
is ($test->option_n(3), 4);
is ($test->option_n(2), 2);
is ($test->parameter_n(2), 'something');
is ($test->parameter_n(1), 'id');
is ($test->label, 'Label');
ok ($test->bracket);

ok ($test->body);
like ($test->body, qr/body text/);

$test2 = $tree->find('test2');
ok (not $test2->bracket);
is ($test2->comment, '# commented, no bracket');

$body = $test2->find('body');
isa_ok ($body, 'Decl::Node');
is ($body->name, 'text');
is ($body->nodes, undef);

$tree->load (<<EOF);
 ! second_item "thing here"
 !
 ! third "another"
EOF
 
$second = $tree->find('second_item');
isa_ok ($test, 'Decl::Node');
is ($second->label, 'thing here');
$third = $tree->find('third');
isa_ok ($test, 'Decl::Node');
is ($third->label, 'another');

$tree = Decl->new(<<EOF);

frame (x=50, y=50, xsize=500, ysize=400) "Wx::Declarative menu demo"
   menubar
 
   on quit { ^Close(1); }
   on about
      messagebox (OK, INFORMATION) "About"
         The menu demo shows you how menus are set up.

EOF

is_deeply($tree->sketch, ['*root', [['frame', [['menubar', []], ['on', []], ['on', [['messagebox', [['The', []]]]]]]]]]);

$tree = Decl->new(<<EOF);

frame (x=50, y=50, xsize=500, ysize=400) "Wx::Declarative menu demo"
   menubar
 
   on quit { ^Close(1); }
 
   on about
      messagebox (OK, INFORMATION) "About"
         The menu demo shows you how menus are set up.

EOF

$on = $tree->first('on');
is ($on->body, '');


# Another error case.

$tree = Decl->new (<<EOF);

dialog (x=50, y=50, xsize=500, ysize=400) "Wx::Declarative tutorial"
   field script (size=100, x=20, y=20) "run me"
   button run (x=130, y=20) "Run" {
     
      ^messagebox ($^script);
   }
   
EOF
$button = $tree->first('button');
$m = $button->first('^messagebox'); # Don't laugh - this was an error due to the indentation of the blank line.
is ($m, undef);
# $d = $button->describe;
# TODO: like ($button->describe, qr/\$\^/); -- there's something funky in the parser itself, I think.



# ------------------------------------------------------------------------------------------------
# Now let's load a tree that *will* engage some of our core semantic classes (I'm being vague
# because I expect the number of core semantic classes to grow), and make sure they're getting
# parsed correctly.  One will be POD, to ensure that wants_sublines works.
# ------------------------------------------------------------------------------------------------

$tree = Decl->new();

$tree->load (<<'EOF');


pod head1 "THIS IS A TEST"
   Here is some POD code.
   
      Some of it is indented.
      
   Even blank lines should get picked up.
   
do "This is some random code" {
   my $something = 2;
   print "$something\n";
}

EOF

is_deeply ($tree->sketch, ['*root', [['pod', []], ['do', []]]]);
$pod = $tree->find("pod");
isa_ok ($pod, 'Decl::Node');
isa_ok ($pod, 'Decl::Semantics::POD');

$code = $tree->find('do');
isa_ok ($code, 'Decl::Node');
isa_ok ($code, 'Decl::Semantics::Code');

is ($tree->root, $tree);
is ($code->root, $tree);
is ($pod->root, $tree);

$pod_text = $pod->extract;
@pod_lines = split /\n/, $pod_text;
is (@pod_lines, 9);    # 6 lines as above, plus the header and one blank line after it, plus the =cut.

# -----------------
# Onwards!  Testing the locator parser.
# -----------------

$p = $tree->parser('locator');
isa_ok ($p, "Decl::Parser");
$s = $p->tokenstream ("tag.tag2[name].tag3(4)/tag4[label='this is a label']:tag5[label=~'this']");

is         (popcar($s), 'tag');
is_deeply  (popcar($s), ['SEPARATOR', "."]);
is         (popcar($s), 'tag2');
is_deeply  (popcar($s), ['LBRACK', "["]);
is         (popcar($s), 'name');
is_deeply  (popcar($s), ['RBRACK', "]"]);
is_deeply  (popcar($s), ['SEPARATOR', "."]);
is         (popcar($s), 'tag3');
is_deeply  (popcar($s), ['LPAREN', "("]);
is         (popcar($s), '4');
is_deeply  (popcar($s), ['RPAREN', ")"]);
is_deeply  (popcar($s), ['SEPARATOR', '/']);
is         (popcar($s), 'tag4');
is_deeply  (popcar($s), ['LBRACK', "["]);
is         (popcar($s), 'label');
is_deeply  (popcar($s), ['EQUALS', '=']);
is_deeply  (popcar($s), ['STRING', 'this is a label']);
is_deeply  (popcar($s), ['RBRACK', "]"]);
is_deeply  (popcar($s), ['SEPARATOR', ':']);
is         (popcar($s), 'tag5');
is_deeply  (popcar($s), ['LBRACK', "["]);
is         (popcar($s), 'label');
is_deeply  (popcar($s), ['MATCHES', '=~']);
is_deeply  (popcar($s), ['STRING', 'this']);
is_deeply  (popcar($s), ['RBRACK', "]"]);
is         (popcar($s), undef);

$parse = $p->execute ("tag.tag2[name].tag2a[name1 name2]:tag3(4)/tag4[label='this is a label']:tag5[label=~'this']");
is_deeply ($parse, ['tag', ['tag2', 'name'], ['tag2a', 'name1', 'name2'], [tag3, ['o', '4']], ['tag4', ['a', 'label', 'this is a label']],
                           ['tag5', ['m', 'label', 'this']]]);
                           
                           
$parse = $tree->parse_using("tag.tag2[name]", "locator");
is_deeply ($parse, ['tag', ['tag2', 'name']]);

$parse = $tree->parse_using ("tag", "really-improbable-name-that-isn't-a-parser");
is ($parse, undef);  # Just checking.
