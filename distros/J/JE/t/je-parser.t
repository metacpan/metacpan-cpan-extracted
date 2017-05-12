#!perl  -T

use Test::More tests => 14;
use strict;



#--------------------------------------------------------------------#
# Tests 1-2: See if the modules load

BEGIN { use_ok 'JE::Parser' }
BEGIN { use_ok 'JE'         }

#--------------------------------------------------------------------#
# Tests 3-4: Object creation

my $je = new JE;
isa_ok $je, 'JE';

my $p = new JE::Parser $je;
isa_ok $p, 'JE::Parser';

#--------------------------------------------------------------------#
# Tests 5-8: delete_statements and the first of the examples

$p->delete_statement('for','while','do','-function');

is $p->eval('1+2+3'), 6, '$p->parse after mangling the parser';
$p->parse('for(;;);');
ok $@, 'deletion of "for" statement type makes "for" a syntax error';
$p->parse('while(true){}');
ok $@, 'deletion of "while" statement type makes "while" a syntax error';
$p->parse('do{}while();');
ok $@, 'deletion of "do" statement type makes "do" a syntax error';

#--------------------------------------------------------------------#
# Test 9: return value of parse

isa_ok $p->parse('1+2+3'), 'JE::Code', 'return value of parse';

#--------------------------------------------------------------------#
# Tests 10-11: statement_list

is_deeply $je->new_parser-> statement_list,
	[qw/-function block empty if while with for switch try labelled
	     var do continue break return throw expr/],
	'default statement type list';
is_deeply $p-> statement_list,
	[qw/block empty if with switch try labelled
	     var continue break return throw expr/],
	'modified statement type list';

#--------------------------------------------------------------------#
# Tests 12-14: JS's 'eval' should respect the custom parser

$p->eval('eval("for(;;);")');
ok $@, 'deletion of "for" statement type makes eval("for") a syntax error';
$p->eval('eval("while(true){}")');
ok $@, 'deleting "while" statement type makes eval("while") a SyntaxError';
$p->eval('eval("do{}while();")');
ok $@, 'deletion of "do" statement type makes eval("do") a syntax error';


#--------------------------------------------------------------------#
# Tests 15-?: Test add_statement once the API's figured out


