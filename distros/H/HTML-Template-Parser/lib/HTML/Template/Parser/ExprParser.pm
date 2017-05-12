package HTML::Template::Parser::ExprParser;

use strict;
use warnings;

use base qw(Class::Accessor::Fast);
__PACKAGE__->mk_accessors(qw());

use Parse::RecDescent;

sub parse {
    my($self, $expr) = @_;

    $self->_get_parser_instance->expr($expr);
}

my $_instance;

sub _get_parser_instance {
    return $_instance if $_instance;
    $::RD_ERRORS=1;
    $::RD_WARN=1;
    $::RD_HINT=1;
#    $::RD_TRACE=1; # @@@
    return $_instance = Parse::RecDescent->new(<<'END;');
{
  use strict;
  use warnings;

  sub unexpand {
    if(@_ == 1 and ref($_[0]) eq 'ARRAY'){
      return $_[0];
    }

    my $right = pop;
    my $op = pop;
    [ 'op', $op, unexpand(@_), $right ];
  }
}

expr: xxx_op

xxx_op:		or_sym_op
or_sym_op:	<leftop: and_sym_op OR_SYM  and_sym_op >	{ unexpand(@{$item[1]}); }
and_sym_op:	<leftop: not_sym_op AND_SYM not_sym_op >	{ unexpand(@{$item[1]}); }
not_sym_op: NOT_SYM or_op								{ [ 'op', $item[1], $item[2] ] }
		| or_op
or_op:		<leftop: and_op     OR      and_op >		{ unexpand(@{$item[1]}); }
and_op:		<leftop: comp_op    AND     comp_op >		{ unexpand(@{$item[1]}); }
comp_op:	<leftop: sum_op     COMP    sum_op >		{ unexpand(@{$item[1]}); }
sum_op:		<leftop: prod_op    SUM     prod_op >		{ unexpand(@{$item[1]}); }
prod_op:	<leftop: match_op   PROD    match_op >		{ unexpand(@{$item[1]}); }
match_op:	not_op MATCH REGEXP							{ [ 'op', $item[2], $item[1], $item[3] ] }
		| not_op
not_op:	(NOT|NOT_SYM) term										{ [ 'op', $item[1], $item[2] ] }
		| term

NOT:		'!'
MATCH:		'=~'
PROD:		'*' | '/' | '%'
SUM:		'+' | '-'
COMP:		/>=?|<=?|!=|==|le|ge|eq|ne|lt|gt/
AND:		'&&'
OR:			'||'
NOT_SYM:	/not(?!\w)/
AND_SYM:	/and(?!\w)/
OR_SYM:		/or(?!\w)/

term:
	function
	| '(' xxx_op ')' { $item[2] }
	| NUMBER
	| STRING
	| VARIABLE

function: NAME '(' expr(s? /,/) ')' { [ 'function', $item[1], @{$item[3]} ] }

REGEXP:		m!/[^/]*/i?!		{ [ 'regexp', $item[1] ] }
NUMBER:		/[+-]?\d+(\.\d+)?/			{ [ 'number', $item[1]+0 ]; }
STRING:		/"([^\"]*)"/		{ [ 'string', $1, ]; }
STRING:		/'([^\']*)'/		{ [ 'string', $1, ]; }
VARIABLE:	/[_a-z][_a-z0-9]*/i { [ 'variable', $item[1] ] }
VARIABLE:	/\$?{([^}]+)}/		{ [ 'variable', $1 ] }
NAME:		/[_a-z][_a-z0-9]*/i { [ 'name', $item[1] ] }
END;
}

1;
