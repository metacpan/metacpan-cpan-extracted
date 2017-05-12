#!/usr/bin/perl
use strict;
use Test;
BEGIN { plan tests => 36 }

use HTML::KTemplate;
my ($tpl, $output, $text, @text);


# test process method

$tpl = HTML::KTemplate->new();

$tpl->assign( VARIABLE => 'Variable');

$tpl->process(
	'templates/simple.tpl',
	'templates/simple.tpl',
	'templates/simple.tpl',
);

$tpl->process('templates/simple.tpl');

$output = $tpl->fetch();

ok($$output =~ /^\s*
	(?:
		Text\s*
		Variable\s*
		Text\s*
	){4}
$/x);


# test variables

$tpl = HTML::KTemplate->new();

$tpl->assign({ 'VARIABLE' => 'Testing...'  });

$tpl->assign(
	'_CHAR-TEST-' => 'Testing...', 
	SUBROUTINE => sub { return 'Testing...' },
	SOMETHING => { SOMEWHERE => 'Testing...' },
	ABC => { DEF => { GHI => { JKL => { MNO => 'Testing...' }}}},
);

$tpl->process('templates/variables.tpl');
$output = $tpl->fetch();

ok($$output =~ /^\s*
	(?:Testing...\s*){5}
$/x);


# test begin block as loop statement

$tpl = HTML::KTemplate->new();

$tpl->assign({

	VARIABLE => 'Global',
	OUTER_LOOP => [
		{
			OUTER_YES => 1,
			OUTER_NO => 0,
			VAR => { INNER_LOOP => [0, 'a'] }
		},
		{
			VARIABLE => 'Outer', 
			OUTER_YES => {},
			OUTER_NO => undef,
			VAR => { INNER_LOOP => [[], {}, undef] }
		},
		{
			VARIABLE => 'Outer', 
			OUTER_YES => 'blub',
			VAR => {
				INNER_LOOP => [ 
					{ VARIABLE => 'Inner', INNER_YES => 1, INNER_NO => 0 },  
					{},
				]
			}
		},
	],
});

$tpl->process('templates/loops.tpl');
$output = $tpl->fetch();

ok($$output =~ /^\s*
	Global\s*
		Global\s*
		OUTER_YES\s*
			(?:Global\s*){2}
		Outer\s*
		OUTER_YES\s*
			(?:Outer\s*){3}
		Outer\s*
		OUTER_YES\s*
			Inner\s*
			INNER_YES\s*
			Outer\s*
	Global\s*
$/x);


# test begin block as if statement

$tpl = HTML::KTemplate->new();

$tpl->assign(
	ON_1 => 1,
	ON_2 => 1,
	ON_3 => 'y',
	ON_4 => {},
	OFF_1 => 0,
	OFF_2 => [],
	OFF_3 => undef,
	OFF_4 => '',
);

$tpl->process('templates/if.tpl');
$output = $tpl->fetch();

ok($$output =~ /^\s*
	Text\s*
	(?:On\s*){4}
	Text\s*
$/x);


# test block method

$tpl = HTML::KTemplate->new();

foreach (1..3) {
	$tpl->block('OUTER_LOOP');
	$tpl->assign( VARIABLE => 'Outer' );
		
	foreach (1..4) {
		$tpl->block('OUTER_LOOP.VAR.INNER_LOOP');
		$tpl->assign( VARIABLE => 'Inner' );
	}
}

$tpl->block();
$tpl->assign( VARIABLE => 'Global');

$tpl->process('templates/loops.tpl');
$output = $tpl->fetch();

ok($$output =~ /^\s*
	Global\s*
	(?:
		Outer\s*
		(?:
			Inner\s*
		){4}
	){3}
	Global\s*
$/x);


# test changed tags

$HTML::KTemplate::VAR_START_TAG = '${';
$HTML::KTemplate::VAR_END_TAG   = '}';

$HTML::KTemplate::BLOCK_START_TAG = '<<<';
$HTML::KTemplate::BLOCK_END_TAG   = '>>>';

$HTML::KTemplate::INCLUDE_START_TAG = '###';
$HTML::KTemplate::INCLUDE_END_TAG   = '###';

$tpl = HTML::KTemplate->new();

$tpl->assign(VARIABLE => 'Variable');

foreach (1 .. 4) {
	$tpl->block('LOOP');
	$tpl->assign(VARIABLE => $_);
}

$tpl->process('templates/tags.tpl');
$output = $tpl->fetch();

$HTML::KTemplate::VAR_START_TAG = '[%';
$HTML::KTemplate::VAR_END_TAG   = '%]';

$HTML::KTemplate::BLOCK_START_TAG = '<!--';
$HTML::KTemplate::BLOCK_END_TAG   = '-->';

$HTML::KTemplate::INCLUDE_START_TAG = '<!--';
$HTML::KTemplate::INCLUDE_END_TAG   = '-->';

ok($$output =~ /^\s*
	Variable\s*
	1\s*2\s*3\s*4\s*
	Text\s*
	\[%\sVARIABLE\s%\]\s*
	Text\s*
$/x);


# test root variable

$HTML::KTemplate::ROOT = 'templates';
$tpl = HTML::KTemplate->new();

$tpl->assign( VARIABLE => 'Variable' );

$tpl->process('simple.tpl');
$output = $tpl->fetch();

$HTML::KTemplate::ROOT = undef;

ok($$output =~ /^\s*
	Text\s*
	Variable\s*
	Text\s*
$/x);


# test root option

$HTML::KTemplate::ROOT = 'wrong/path';
$tpl = HTML::KTemplate->new('templates');

$tpl->assign( VARIABLE => 'Variable' );

$tpl->process('simple.tpl');
$output = $tpl->fetch();

$HTML::KTemplate::ROOT = undef;

ok($$output =~ /^\s*
	Text\s*
	Variable\s*
	Text\s*
$/x);


# test root option

$HTML::KTemplate::ROOT = 'wrong/path';
$tpl = HTML::KTemplate->new(root => 'templates');

$tpl->assign( VARIABLE => 'Variable' );

$tpl->process('simple.tpl');
$output = $tpl->fetch();

$HTML::KTemplate::ROOT = undef;

ok($$output =~ /^\s*
	Text\s*
	Variable\s*
	Text\s*
$/x);


# test clear_vars method clears variables

$tpl = HTML::KTemplate->new();

$tpl->assign( VARIABLE => 'Variable' );
$tpl->clear_vars();

$tpl->process('templates/simple.tpl');
$output = $tpl->fetch();

ok($$output =~ /^\s*
	Text\s*
	Text\s*
$/x);


# test clear_vars method clears block reference

$tpl = HTML::KTemplate->new();

$tpl->block('SUB.TEST.BLOCK');
$tpl->clear_vars();

$tpl->assign( VARIABLE => 'Testing...' );

$tpl->process('templates/block.tpl');
$output = $tpl->fetch();

ok($$output =~ /^\s*$/x);


# test clear_out method

$tpl = HTML::KTemplate->new();

$tpl->assign( VARIABLE => 'Variable' );

$tpl->process('templates/simple.tpl');
$tpl->clear_out();
$output = $tpl->fetch();

ok($$output =~ /^$/x);


# test include

$tpl = HTML::KTemplate->new();

$tpl->assign( VARIABLE => 'Variable' );

$tpl->process('templates/include.tpl');
$output = $tpl->fetch();

ok($$output =~ /^\s*
	(?:
		Text\s*
		Variable\s*
		Text\s*
	){6}
$/x);


# test recursive includes

$tpl = HTML::KTemplate->new();

eval { $tpl->process('templates/recursive.tpl') };
ok($@ =~ /recursive includes/i);


# test strict with vars

$tpl = HTML::KTemplate->new('strict' => 1);

eval { $tpl->process('templates/simple.tpl') };
ok($@ =~ /no value found for variable/i);


# test strict with disabled includes

$tpl = HTML::KTemplate->new('strict' => 1, 'no_includes' => 1);

eval { $tpl->process('templates/include.tpl') };
ok($@ =~ /include blocks are disabled/i);


# test changed tags again

$HTML::KTemplate::VAR_START_TAG = '${';
$HTML::KTemplate::VAR_END_TAG   = '}';

$HTML::KTemplate::BLOCK_START_TAG = '###';
$HTML::KTemplate::BLOCK_END_TAG   = '###';

$HTML::KTemplate::INCLUDE_START_TAG = '###';
$HTML::KTemplate::INCLUDE_END_TAG   = '###';

$tpl = HTML::KTemplate->new();

$tpl->assign(VARIABLE => 'Variable');

foreach (1 .. 4) {
	$tpl->block('LOOP');
	$tpl->assign(VARIABLE => $_);
}

$tpl->process('templates/tags.tpl');
$tpl->clear_out();

$HTML::KTemplate::VAR_START_TAG = '${';
$HTML::KTemplate::VAR_END_TAG   = '}';

$HTML::KTemplate::BLOCK_START_TAG = '<<<';
$HTML::KTemplate::BLOCK_END_TAG   = '>>>';

$HTML::KTemplate::INCLUDE_START_TAG = '<<<';
$HTML::KTemplate::INCLUDE_END_TAG   = '>>>';

$tpl->process('templates/tags.tpl');
$output = $tpl->fetch();

$HTML::KTemplate::VAR_START_TAG = '[%';
$HTML::KTemplate::VAR_END_TAG   = '%]';

$HTML::KTemplate::BLOCK_START_TAG = '<!--';
$HTML::KTemplate::BLOCK_END_TAG   = '-->';

$HTML::KTemplate::INCLUDE_START_TAG = '<!--';
$HTML::KTemplate::INCLUDE_END_TAG   = '-->';

ok($$output =~ /^\s*
	Variable\s*
	1\s*2\s*3\s*4\s*
	# skip testing include
/x);


# test fetch method really works

$tpl = HTML::KTemplate->new();

$tpl->assign( VARIABLE => 'Variable 1' );
$tpl->process('templates/simple.tpl');
$output = $tpl->fetch();

$tpl->clear();

$tpl->assign( VARIABLE => 'Variable 2' );
$tpl->process('templates/simple.tpl');

ok($$output =~ /^\s*
	Text\s*
	Variable\s1\s*
	Text\s*
$/x && ${$tpl->fetch()} =~ /^\s*
	Text\s*
	Variable\s2\s*
	Text\s*
$/x);


# test loop context variables

$tpl = HTML::KTemplate->new('loop_vars' => 1);

foreach (1 .. 5) {
	$tpl->block('LOOP_1');
	
	foreach (1 .. 2) {
		$tpl->block('LOOP_1.LOOP_2');
	}
	
}

$tpl->process('templates/context.tpl');
$output = $tpl->fetch();

ok($$output =~ /^\s*
	First\s*
		First\s*
		Last\s*
	(?:Inner\s*
		First\s*
		Last\s* ){3}
	Last\s*
		First\s*
		Last\s*
$/x);


# test if block

$tpl = HTML::KTemplate->new();

$tpl->assign(
	ON_1 => 1,
	ON_2 => 1,
	ON_3 => 'y',
	ON_4 => {},
	ON_5 => [],
	OFF_1 => 0,
	OFF_2 => undef,
	OFF_3 => '',
);

$tpl->process('templates/if2.tpl');
$output = $tpl->fetch();

ok($$output =~ /^\s*
	Text\s*
	(?:On\s*){5}
	Text\s*
$/x);


# test loop block

$tpl = HTML::KTemplate->new();

$tpl->assign({

	VARIABLE => 'Global',
	OUTER_LOOP => [
		{
			OUTER_NO_1 => 1,
			OUTER_NO_2 => 0,
			VAR => { INNER_LOOP => [0, 'a'] }
		},
		{
			VARIABLE => 'Outer', 
			OUTER_YES => {},
			OUTER_NO => undef,
			VAR => { INNER_LOOP => [[], {}, undef] }
		},
		{
			VARIABLE => 'Outer', 
			OUTER_YES => 'blub',
			VAR => {
				INNER_LOOP => [ 
					{ VARIABLE => 'Inner', INNER_NO_1 => 1, INNER_NO_2 => 0 },  
					{},
				]
			}
		},
	],
});

$tpl->process('templates/loops2.tpl');
$output = $tpl->fetch();

ok($$output =~ /^\s*
	Global\s*
		Global\s*
			(?:Global\s*){2}
		Outer\s*
			(?:Outer\s*){3}
		Outer\s*
			Inner\s*
			Outer\s*
	Global\s*
$/x);


# test unless block

$tpl = HTML::KTemplate->new();

$tpl->assign(
	OFF_1 => 1,
	OFF_2 => 1,
	OFF_3 => 'y',
	OFF_4 => {},
	OFF_5 => [],
	ON_1 => 0,
	ON_2 => undef,
	ON_3 => '',
);

$tpl->process('templates/unless.tpl');
$output = $tpl->fetch();

ok($$output =~ /^\s*
	(?:On\s*){3}
$/x);


# test else block

$tpl = HTML::KTemplate->new();

$tpl->assign(
	OFF_LOOP => [],
	OFF_COND => 0,
	ON_COND  => 1,
);

$tpl->process('templates/else.tpl');
$output = $tpl->fetch();

ok($$output =~ /^\s*
	Text\s*
	(?:On\s*){4}
	Text\s*
$/x);


# test chomp

$tpl = HTML::KTemplate->new();

$tpl->assign(
	ON => 1
);

$HTML::KTemplate::CHOMP = 1; # just to be sure
$tpl->process('templates/chomp.tpl');

$output = $tpl->fetch();

ok($$output =~ /^ {4}Text Text\r?\n\r?\nText\r?\n\r?\n\r?\n Text \r?\n\r?\n\r?\nText\r?\n\r?\nText Text Text\r?\n\r?\nTextTEXTText\r?\n\r?\nText TEXT Text\r?\n\r?\nText TEXT Text\r?\n\r?\nText Text {1,}$/);


# test template syntax

$tpl = HTML::KTemplate->new();

$tpl->assign(
	ON => 1,
	OFF => 0,
	ARRAY => [1],
);

$tpl->process('templates/syntax.tpl');
$output = $tpl->fetch();

ok($$output =~ /^\s*
	(?:On\s*){18}
$/x);


# test including template from var

$tpl = HTML::KTemplate->new( include_vars => 1 );

$tpl->assign(
	VARIABLE => 'templates/simple.tpl',
	SOME => { VARIABLE => 'templates/simple.tpl' },
);

$tpl->process('templates/include2.tpl');
$output = $tpl->fetch();

ok($$output =~ /^\s*
	(?:
	Text\s*
	templates\/simple\.tpl\s*
	Text\s*
	){2}
$/x);


# test block method accepts array

$tpl = HTML::KTemplate->new();

$tpl->block('SUB' => 'TEST.BLOCK');
$tpl->assign(VARIABLE => 'Testing...');

$tpl->process('templates/block.tpl');
$output = $tpl->fetch();

ok($$output =~ /^\s*Testing...\s*$/x);


# test parse vars option

$tpl = HTML::KTemplate->new(parse_vars => 1);

$tpl->assign(
	VARIABLE => 'Test [% TEST %] Test',
	TEST => 'Test [% BLUB %] Test',
	BLUB => 'Blub',
);

$tpl->process('templates/simple.tpl');
$output = $tpl->fetch();

ok($$output =~ /^\s*
	Text\s*
	Test\s*Test\s*
	Blub\s*
	Test\s*Test\s*
	Text\s*
$/x);


# test creating block with assign method

$tpl = HTML::KTemplate->new();

$tpl->assign(VARIABLE => 'Global');
$tpl->assign('SUB.TEST.BLOCK',
	VARIABLE => 'Test',
);

$tpl->assign(VARIABLE => 'Error');

$tpl->process('templates/block.tpl');
$output = $tpl->fetch();

ok($$output =~ /^\s*Test\s*$/x);


# test process method accepts scalar ref

$tpl = HTML::KTemplate->new();

$tpl->assign(VARIABLE => 'Test');

$text = 'Test [% VARIABLE %] Test';

$tpl->process(\$text);
$output = $tpl->fetch();

$text = undef;

ok($$output =~ /^\s*(Test\s*){3}$/x);


# test process method accepts array ref

$tpl = HTML::KTemplate->new();

$tpl->assign(VARIABLE => 'Test');

@text = ('Test', '[% VARIABLE %]', 'Test');

$tpl->process(\@text);
$output = $tpl->fetch();

@text = ();

ok($$output =~ /^\s*(Test\s*){3}$/x);


# test process method accepts file handle ref

$tpl = HTML::KTemplate->new();

$tpl->assign(VARIABLE => 'Test');

open (FH, '<templates/simple.tpl') ||  die "Can't open file simple.tpl: $!";

$tpl->process(\*FH);
$output = $tpl->fetch();

close (FH);

ok($$output =~ /^\s*Text\s*Test\s*Text\s*$/x);


# test process method accepts file handle

$tpl = HTML::KTemplate->new();

$tpl->assign(VARIABLE => 'Test');

open (FH, '<templates/simple.tpl') ||  die "Can't open file simple.tpl: $!";

$tpl->process(*FH);
$output = $tpl->fetch();

close (FH);

ok($$output =~ /^\s*Text\s*Test\s*Text\s*$/x);


# test process method does not change scalar ref

$tpl = HTML::KTemplate->new();

$tpl->assign(VARIABLE => 'Test');

$text = 'Test [% VARIABLE %] Test';

$tpl->process(\$text);

ok($text eq 'Test [% VARIABLE %] Test');

$text = undef;


# test changed tags inside of vars

$HTML::KTemplate::VAR_START_TAG = '${';
$HTML::KTemplate::VAR_END_TAG   = '}';

$HTML::KTemplate::BLOCK_START_TAG = '<<<';
$HTML::KTemplate::BLOCK_END_TAG   = '>>>';

$HTML::KTemplate::INCLUDE_START_TAG = '###';
$HTML::KTemplate::INCLUDE_END_TAG   = '###';

$tpl = HTML::KTemplate->new(parse_vars => 1);

$tpl->assign(
	VARIABLE => '${VARIABLE_VALUE}',
	VARIABLE_VALUE => 'Variable',
);

$tpl->process('templates/tags.tpl');
$output = $tpl->fetch();

$HTML::KTemplate::VAR_START_TAG = '[%';
$HTML::KTemplate::VAR_END_TAG   = '%]';

$HTML::KTemplate::BLOCK_START_TAG = '<!--';
$HTML::KTemplate::BLOCK_END_TAG   = '-->';

$HTML::KTemplate::INCLUDE_START_TAG = '<!--';
$HTML::KTemplate::INCLUDE_END_TAG   = '-->';

ok($$output =~ /^\s*
	Variable\s*
	Text\s*
	\[%\sVARIABLE\s%\]\s*
	Text\s*
$/x);


# test assigned undefined variables are not skipped

$tpl = HTML::KTemplate->new();

$tpl->assign(
	SUB => { 
		VARIABLE => 'variable not used',
		TEST => { BLOCK => [ { SUB => { VARIABLE => undef } } ] },
	},
);

$tpl->process('templates/block.tpl');
$output = $tpl->fetch();

ok($$output =~ /^\s*$/x);


