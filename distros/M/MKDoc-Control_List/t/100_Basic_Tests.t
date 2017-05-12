package main;
use strict;
use warnings;
use Test::More qw /no_plan/;
use lib qw (../lib lib);
use MKDoc::Control_List;

my $data = <<EOF;
CONDITION true	1
CONDITION false	0

RET_VALUE foo	"foo"
RET_VALUE bar	"bar"

RULE foo bar	WHEN true false
RULE bar foo	WHEN false true
RULE bar bar	WHEN false false
RULE foo foo	WHEN true true false
RULE foo foo	WHEN true true
EOF


my $cl = new MKDoc::Control_List ( data => $data );
ok ($cl, 'new()');

ok ($cl->_build_code_condition ('CONDITION true "true"'), 'condition compile #1');
ok ($cl->_build_code_condition (' CONDITION true "true"'), 'condition compile #2');
ok (!$cl->_build_code_condition (' CONDITIONE true "true"'), 'condition compile #3');
ok ($cl->_build_code_ret_value ('RET_VALUE true "true"'), 'ret_value compile #1');
ok ($cl->_build_code_ret_value (' RET_VALUE true "true"'), 'ret_value compile #2');
ok (!$cl->_build_code_ret_value (' RET_VALUEE true "true"'), 'ret_value compile #3');
ok ($cl->_build_code_rule ('RULE foo bar WHEN baz buz'), 'rule_when');

my ($one, $two) = $cl->process();
is ($one, 'foo');
is ($two, 'foo');
