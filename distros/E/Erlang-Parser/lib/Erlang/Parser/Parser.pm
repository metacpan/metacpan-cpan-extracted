####################################################################
#
#    This file was generated using Parse::Yapp version 1.05.
#
#        Don't edit this file, use source file instead.
#
#             ANY CHANGE MADE HERE WILL BE LOST !
#
####################################################################
package Erlang::Parser::Parser;
use vars qw ( @ISA );
use strict;

@ISA= qw ( Parse::Yapp::Driver );
use Parse::Yapp::Driver;

#line 21 "lib/Erlang/Parser/Parser.yp"

    use strict;
    use warnings;

    use Erlang::Parser::Node::Directive;
    use Erlang::Parser::Node::DefList;
    use Erlang::Parser::Node::Def;
    use Erlang::Parser::Node::WhenList;
    use Erlang::Parser::Node::Atom;
    use Erlang::Parser::Node::Integer;
    use Erlang::Parser::Node::BinOp;
    use Erlang::Parser::Node::List;
    use Erlang::Parser::Node::Variable;
    use Erlang::Parser::Node::Tuple;
    use Erlang::Parser::Node::Macro;
    use Erlang::Parser::Node::String;
    use Erlang::Parser::Node::Call;
    use Erlang::Parser::Node::Alt;
    use Erlang::Parser::Node::Try;
    use Erlang::Parser::Node::Literal;
    use Erlang::Parser::Node::FunRef;
    use Erlang::Parser::Node::FunLocal;
    use Erlang::Parser::Node::FunLocalCase;
    use Erlang::Parser::Node::Case;
    use Erlang::Parser::Node::RecordNew;
    use Erlang::Parser::Node::VariableRecordAccess;
    use Erlang::Parser::Node::VariableRecordUpdate;
    use Erlang::Parser::Node::Float;
    use Erlang::Parser::Node::BaseInteger;
    use Erlang::Parser::Node::BinaryExpr;
    use Erlang::Parser::Node::Binary;
    use Erlang::Parser::Node::UnOp;
    use Erlang::Parser::Node::Begin;
    use Erlang::Parser::Node::Comprehension;
    use Erlang::Parser::Node::If;
    use Erlang::Parser::Node::IfExpr;
    use Erlang::Parser::Node::Receive;
    use Erlang::Parser::Node::ReceiveAfter;

    sub new_node {
        my ($kind, %args) = @_;
        "Erlang::Parser::Node::$kind"->new(%args);
    }


sub new {
        my($class)=shift;
        ref($class)
    and $class=ref($class);

    my($self)=$class->SUPER::new( yyversion => '1.05',
                                  yystates =>
[
	{#State 0
		DEFAULT => -1,
		GOTOS => {
			'root' => 1
		}
	},
	{#State 1
		ACTIONS => {
			'SUBTRACT' => 4,
			'ATOM' => 5,
			'' => 6
		},
		GOTOS => {
			'rootstmt' => 2,
			'def' => 3,
			'deflist' => 7
		}
	},
	{#State 2
		DEFAULT => -2
	},
	{#State 3
		DEFAULT => -5
	},
	{#State 4
		ACTIONS => {
			'ATOM' => 8
		}
	},
	{#State 5
		ACTIONS => {
			'LPAREN' => 9
		}
	},
	{#State 6
		DEFAULT => 0
	},
	{#State 7
		ACTIONS => {
			'SEMICOLON' => 10,
			'PERIOD' => 11
		}
	},
	{#State 8
		ACTIONS => {
			'LPAREN' => 12
		}
	},
	{#State 9
		ACTIONS => {
			'KW_BEGIN' => 20,
			'KW_FUN' => 19,
			'LPAREN' => 47,
			'KW_NOT' => 45,
			'ATOM' => 22,
			'VARIABLE' => 21,
			'INTEGER' => 48,
			'OPENBINARY' => 38,
			'TUPLEOPEN' => 42,
			'KW_TRY' => 41,
			'STRING' => 57,
			'ADD' => 32,
			'KW_CATCH' => 56,
			'KW_RECEIVE' => 55,
			'OPENRECORD' => 60,
			'LITERAL' => 34,
			'LISTOPEN' => 59,
			'FLOAT' => 58,
			'KW_IF' => 25,
			'KW_CASE' => 50,
			'KW_BNOT' => 23,
			'MACRO' => 53,
			'SUBTRACT' => 54,
			'BASE_INTEGER' => 27
		},
		DEFAULT => -12,
		GOTOS => {
			'try' => 15,
			'fun' => 14,
			'list' => 39,
			'call' => 37,
			'funlocal' => 13,
			'extcall' => 18,
			'intcall' => 44,
			'if' => 43,
			'binary' => 17,
			'string' => 16,
			'immexpr' => 40,
			'comprehension' => 46,
			'stmtlist' => 26,
			'exprlist' => 24,
			'atom' => 49,
			'newrecord' => 28,
			'unparenexpr' => 52,
			'tuple' => 51,
			'variable' => 31,
			'parenorimm' => 29,
			'macro' => 30,
			'receive' => 61,
			'case' => 36,
			'expr' => 35,
			'parenexpr' => 33
		}
	},
	{#State 10
		ACTIONS => {
			'ATOM' => 5
		},
		GOTOS => {
			'def' => 62
		}
	},
	{#State 11
		DEFAULT => -4
	},
	{#State 12
		ACTIONS => {
			'KW_IF' => 25,
			'KW_CASE' => 50,
			'KW_BNOT' => 23,
			'SUBTRACT' => 54,
			'MACRO' => 53,
			'BASE_INTEGER' => 27,
			'STRING' => 57,
			'ADD' => 32,
			'KW_CATCH' => 56,
			'KW_RECEIVE' => 55,
			'LITERAL' => 34,
			'OPENRECORD' => 60,
			'LISTOPEN' => 59,
			'FLOAT' => 58,
			'OPENBINARY' => 38,
			'TUPLEOPEN' => 42,
			'KW_TRY' => 41,
			'KW_BEGIN' => 20,
			'KW_FUN' => 19,
			'LPAREN' => 47,
			'KW_NOT' => 45,
			'ATOM' => 22,
			'VARIABLE' => 21,
			'INTEGER' => 48
		},
		DEFAULT => -12,
		GOTOS => {
			'comprehension' => 46,
			'intcall' => 44,
			'extcall' => 18,
			'string' => 16,
			'immexpr' => 40,
			'if' => 43,
			'binary' => 17,
			'fun' => 14,
			'try' => 15,
			'list' => 39,
			'funlocal' => 13,
			'call' => 37,
			'expr' => 35,
			'parenexpr' => 33,
			'case' => 36,
			'receive' => 61,
			'variable' => 31,
			'parenorimm' => 29,
			'macro' => 30,
			'unparenexpr' => 52,
			'newrecord' => 28,
			'tuple' => 51,
			'stmtlist' => 26,
			'exprlist' => 63,
			'atom' => 49
		}
	},
	{#State 13
		DEFAULT => -98
	},
	{#State 14
		DEFAULT => -18
	},
	{#State 15
		DEFAULT => -22
	},
	{#State 16
		ACTIONS => {
			'STRING' => 64
		},
		DEFAULT => -69
	},
	{#State 17
		DEFAULT => -19
	},
	{#State 18
		DEFAULT => -85
	},
	{#State 19
		ACTIONS => {
			'LPAREN' => 71,
			'MACRO' => 53,
			'ATOM' => 69,
			'VARIABLE' => 21
		},
		GOTOS => {
			'variable' => 67,
			'atom' => 70,
			'macro' => 68,
			'funlocallist' => 65,
			'funlocalcase' => 66
		}
	},
	{#State 20
		ACTIONS => {
			'KW_NOT' => 45,
			'KW_FUN' => 19,
			'LPAREN' => 47,
			'KW_BEGIN' => 20,
			'INTEGER' => 48,
			'VARIABLE' => 21,
			'ATOM' => 22,
			'OPENBINARY' => 38,
			'KW_TRY' => 41,
			'TUPLEOPEN' => 42,
			'KW_RECEIVE' => 55,
			'KW_CATCH' => 56,
			'ADD' => 32,
			'STRING' => 57,
			'FLOAT' => 58,
			'LISTOPEN' => 59,
			'LITERAL' => 34,
			'OPENRECORD' => 60,
			'KW_BNOT' => 23,
			'KW_CASE' => 50,
			'KW_IF' => 25,
			'BASE_INTEGER' => 27,
			'SUBTRACT' => 54,
			'MACRO' => 53
		},
		DEFAULT => -12,
		GOTOS => {
			'expr' => 35,
			'receive' => 61,
			'case' => 36,
			'parenexpr' => 33,
			'variable' => 31,
			'macro' => 30,
			'parenorimm' => 29,
			'unparenexpr' => 52,
			'newrecord' => 28,
			'tuple' => 51,
			'stmtlist' => 26,
			'atom' => 49,
			'exprlist' => 72,
			'comprehension' => 46,
			'intcall' => 44,
			'extcall' => 18,
			'immexpr' => 40,
			'string' => 16,
			'binary' => 17,
			'if' => 43,
			'fun' => 14,
			'try' => 15,
			'list' => 39,
			'funlocal' => 13,
			'call' => 37
		}
	},
	{#State 21
		DEFAULT => -81
	},
	{#State 22
		DEFAULT => -79
	},
	{#State 23
		ACTIONS => {
			'KW_RECEIVE' => 55,
			'KW_CATCH' => 56,
			'STRING' => 57,
			'ADD' => 32,
			'FLOAT' => 58,
			'LISTOPEN' => 59,
			'OPENRECORD' => 60,
			'LITERAL' => 34,
			'KW_BNOT' => 23,
			'KW_CASE' => 50,
			'KW_IF' => 25,
			'BASE_INTEGER' => 27,
			'MACRO' => 53,
			'SUBTRACT' => 54,
			'KW_NOT' => 45,
			'KW_FUN' => 19,
			'LPAREN' => 47,
			'KW_BEGIN' => 20,
			'VARIABLE' => 21,
			'INTEGER' => 48,
			'ATOM' => 22,
			'OPENBINARY' => 38,
			'KW_TRY' => 41,
			'TUPLEOPEN' => 42
		},
		GOTOS => {
			'atom' => 49,
			'newrecord' => 28,
			'unparenexpr' => 52,
			'tuple' => 51,
			'variable' => 31,
			'parenorimm' => 29,
			'macro' => 30,
			'case' => 36,
			'expr' => 73,
			'parenexpr' => 33,
			'receive' => 61,
			'try' => 15,
			'fun' => 14,
			'funlocal' => 13,
			'call' => 37,
			'list' => 39,
			'extcall' => 18,
			'intcall' => 44,
			'if' => 43,
			'binary' => 17,
			'immexpr' => 40,
			'string' => 16,
			'comprehension' => 46
		}
	},
	{#State 24
		ACTIONS => {
			'RPAREN' => 74
		}
	},
	{#State 25
		ACTIONS => {
			'KW_BEGIN' => 20,
			'LPAREN' => 47,
			'KW_FUN' => 19,
			'KW_NOT' => 45,
			'ATOM' => 22,
			'VARIABLE' => 21,
			'INTEGER' => 48,
			'OPENBINARY' => 38,
			'TUPLEOPEN' => 42,
			'KW_TRY' => 41,
			'STRING' => 57,
			'ADD' => 32,
			'KW_CATCH' => 56,
			'KW_RECEIVE' => 55,
			'LITERAL' => 34,
			'OPENRECORD' => 60,
			'LISTOPEN' => 59,
			'FLOAT' => 58,
			'KW_IF' => 25,
			'KW_CASE' => 50,
			'KW_BNOT' => 23,
			'SUBTRACT' => 54,
			'MACRO' => 53,
			'BASE_INTEGER' => 27
		},
		GOTOS => {
			'comprehension' => 46,
			'ifseq' => 76,
			'immexpr' => 40,
			'string' => 16,
			'if' => 43,
			'binary' => 17,
			'intcall' => 44,
			'extcall' => 18,
			'funlocal' => 13,
			'call' => 37,
			'list' => 39,
			'fun' => 14,
			'try' => 15,
			'case' => 36,
			'expr' => 77,
			'receive' => 61,
			'parenexpr' => 33,
			'macro' => 30,
			'parenorimm' => 29,
			'variable' => 31,
			'ifexpr' => 78,
			'tuple' => 51,
			'iflist' => 75,
			'unparenexpr' => 52,
			'newrecord' => 28,
			'atom' => 49
		}
	},
	{#State 26
		ACTIONS => {
			'COMMA' => 79
		},
		DEFAULT => -13
	},
	{#State 27
		DEFAULT => -67
	},
	{#State 28
		DEFAULT => -75
	},
	{#State 29
		ACTIONS => {
			'LPAREN' => 80,
			'COLON' => 81
		}
	},
	{#State 30
		DEFAULT => -76
	},
	{#State 31
		ACTIONS => {
			'OPENRECORD' => 83
		},
		DEFAULT => -77,
		GOTOS => {
			'newrecord' => 82
		}
	},
	{#State 32
		ACTIONS => {
			'ATOM' => 22,
			'INTEGER' => 48,
			'VARIABLE' => 21,
			'KW_BEGIN' => 20,
			'LPAREN' => 47,
			'KW_FUN' => 19,
			'KW_NOT' => 45,
			'TUPLEOPEN' => 42,
			'KW_TRY' => 41,
			'OPENBINARY' => 38,
			'LITERAL' => 34,
			'OPENRECORD' => 60,
			'LISTOPEN' => 59,
			'FLOAT' => 58,
			'ADD' => 32,
			'STRING' => 57,
			'KW_CATCH' => 56,
			'KW_RECEIVE' => 55,
			'SUBTRACT' => 54,
			'MACRO' => 53,
			'BASE_INTEGER' => 27,
			'KW_IF' => 25,
			'KW_CASE' => 50,
			'KW_BNOT' => 23
		},
		GOTOS => {
			'comprehension' => 46,
			'intcall' => 44,
			'extcall' => 18,
			'immexpr' => 40,
			'string' => 16,
			'binary' => 17,
			'if' => 43,
			'fun' => 14,
			'try' => 15,
			'funlocal' => 13,
			'list' => 39,
			'call' => 37,
			'case' => 36,
			'expr' => 84,
			'parenexpr' => 33,
			'receive' => 61,
			'variable' => 31,
			'parenorimm' => 29,
			'macro' => 30,
			'unparenexpr' => 52,
			'newrecord' => 28,
			'tuple' => 51,
			'atom' => 49
		}
	},
	{#State 33
		ACTIONS => {
			'COLON' => -64,
			'LPAREN' => -64
		},
		DEFAULT => -63
	},
	{#State 34
		DEFAULT => -72
	},
	{#State 35
		ACTIONS => {
			'KW_AND' => 111,
			'KW_BSR' => 112,
			'GTE' => 113,
			'ADD' => 114,
			'LTE' => 100,
			'KW_OR' => 101,
			'NOT_EQUAL' => 103,
			'LISTSUBTRACT' => 104,
			'KW_REM' => 102,
			'KW_ANDALSO' => 105,
			'LARROW' => 106,
			'MULTIPLY' => 107,
			'LDARROW' => 108,
			'KW_BOR' => 109,
			'KW_DIV' => 110,
			'LT' => 94,
			'KW_ORELSE' => 95,
			'SUBTRACT' => 97,
			'SEND' => 96,
			'DIVIDE' => 98,
			'EQUAL' => 99,
			'KW_BXOR' => 85,
			'STRICTLY_EQUAL' => 86,
			'GT' => 89,
			'STRICTLY_NOT_EQUAL' => 87,
			'MATCH' => 88,
			'KW_BAND' => 90,
			'LISTADD' => 91,
			'KW_BSL' => 92,
			'KW_XOR' => 93
		},
		DEFAULT => -14
	},
	{#State 36
		DEFAULT => -17
	},
	{#State 37
		DEFAULT => -60
	},
	{#State 38
		ACTIONS => {
			'STRING' => 57,
			'LPAREN' => 47,
			'LITERAL' => 34,
			'OPENRECORD' => 60,
			'ATOM' => 22,
			'VARIABLE' => 21,
			'INTEGER' => 48,
			'LISTOPEN' => 121,
			'FLOAT' => 58,
			'OPENBINARY' => 122,
			'MACRO' => 53,
			'BASE_INTEGER' => 27,
			'TUPLEOPEN' => 42
		},
		DEFAULT => -109,
		GOTOS => {
			'atom' => 49,
			'list' => 39,
			'binarylist' => 120,
			'newrecord' => 28,
			'tuple' => 51,
			'binary' => 118,
			'binaryexpr' => 117,
			'string' => 16,
			'immexpr' => 123,
			'variable' => 31,
			'optbinarylist' => 119,
			'parenorimm' => 115,
			'macro' => 30,
			'parenexpr' => 116
		}
	},
	{#State 39
		DEFAULT => -73
	},
	{#State 40
		ACTIONS => {
			'LPAREN' => -65,
			'COLON' => -65
		},
		DEFAULT => -16
	},
	{#State 41
		ACTIONS => {
			'OPENBINARY' => 38,
			'TUPLEOPEN' => 42,
			'KW_TRY' => 41,
			'KW_BEGIN' => 20,
			'KW_FUN' => 19,
			'LPAREN' => 47,
			'KW_NOT' => 45,
			'ATOM' => 22,
			'INTEGER' => 48,
			'VARIABLE' => 21,
			'KW_IF' => 25,
			'KW_CASE' => 50,
			'KW_BNOT' => 23,
			'SUBTRACT' => 54,
			'MACRO' => 53,
			'BASE_INTEGER' => 27,
			'ADD' => 32,
			'STRING' => 57,
			'KW_CATCH' => 56,
			'KW_RECEIVE' => 55,
			'LITERAL' => 34,
			'OPENRECORD' => 60,
			'LISTOPEN' => 59,
			'FLOAT' => 58
		},
		DEFAULT => -12,
		GOTOS => {
			'stmtlist' => 26,
			'exprlist' => 124,
			'atom' => 49,
			'unparenexpr' => 52,
			'newrecord' => 28,
			'tuple' => 51,
			'variable' => 31,
			'macro' => 30,
			'parenorimm' => 29,
			'expr' => 35,
			'receive' => 61,
			'case' => 36,
			'parenexpr' => 33,
			'fun' => 14,
			'try' => 15,
			'funlocal' => 13,
			'list' => 39,
			'call' => 37,
			'intcall' => 44,
			'extcall' => 18,
			'immexpr' => 40,
			'string' => 16,
			'if' => 43,
			'binary' => 17,
			'comprehension' => 46
		}
	},
	{#State 42
		ACTIONS => {
			'KW_IF' => 25,
			'KW_CASE' => 50,
			'KW_BNOT' => 23,
			'MACRO' => 53,
			'SUBTRACT' => 54,
			'BASE_INTEGER' => 27,
			'ADD' => 32,
			'STRING' => 57,
			'KW_CATCH' => 56,
			'KW_RECEIVE' => 55,
			'LITERAL' => 34,
			'OPENRECORD' => 60,
			'LISTOPEN' => 59,
			'FLOAT' => 58,
			'OPENBINARY' => 38,
			'TUPLEOPEN' => 42,
			'KW_TRY' => 41,
			'KW_BEGIN' => 20,
			'LPAREN' => 47,
			'KW_FUN' => 19,
			'KW_NOT' => 45,
			'ATOM' => 22,
			'INTEGER' => 48,
			'VARIABLE' => 21
		},
		DEFAULT => -12,
		GOTOS => {
			'comprehension' => 46,
			'if' => 43,
			'binary' => 17,
			'string' => 16,
			'immexpr' => 40,
			'extcall' => 18,
			'intcall' => 44,
			'funlocal' => 13,
			'call' => 37,
			'list' => 39,
			'try' => 15,
			'fun' => 14,
			'receive' => 61,
			'parenexpr' => 33,
			'expr' => 35,
			'case' => 36,
			'parenorimm' => 29,
			'macro' => 30,
			'variable' => 31,
			'tuple' => 51,
			'newrecord' => 28,
			'unparenexpr' => 52,
			'atom' => 49,
			'exprlist' => 125,
			'stmtlist' => 26
		}
	},
	{#State 43
		DEFAULT => -23
	},
	{#State 44
		DEFAULT => -84
	},
	{#State 45
		ACTIONS => {
			'OPENBINARY' => 38,
			'TUPLEOPEN' => 42,
			'KW_TRY' => 41,
			'KW_NOT' => 45,
			'KW_BEGIN' => 20,
			'LPAREN' => 47,
			'KW_FUN' => 19,
			'ATOM' => 22,
			'INTEGER' => 48,
			'VARIABLE' => 21,
			'KW_CASE' => 50,
			'KW_BNOT' => 23,
			'KW_IF' => 25,
			'SUBTRACT' => 54,
			'MACRO' => 53,
			'BASE_INTEGER' => 27,
			'KW_RECEIVE' => 55,
			'ADD' => 32,
			'STRING' => 57,
			'KW_CATCH' => 56,
			'FLOAT' => 58,
			'OPENRECORD' => 60,
			'LITERAL' => 34,
			'LISTOPEN' => 59
		},
		GOTOS => {
			'extcall' => 18,
			'intcall' => 44,
			'if' => 43,
			'binary' => 17,
			'immexpr' => 40,
			'string' => 16,
			'try' => 15,
			'fun' => 14,
			'call' => 37,
			'funlocal' => 13,
			'list' => 39,
			'comprehension' => 46,
			'newrecord' => 28,
			'unparenexpr' => 52,
			'tuple' => 51,
			'atom' => 49,
			'case' => 36,
			'expr' => 126,
			'parenexpr' => 33,
			'receive' => 61,
			'variable' => 31,
			'macro' => 30,
			'parenorimm' => 29
		}
	},
	{#State 46
		DEFAULT => -21
	},
	{#State 47
		ACTIONS => {
			'ATOM' => 22,
			'VARIABLE' => 21,
			'INTEGER' => 48,
			'KW_BEGIN' => 20,
			'KW_FUN' => 19,
			'LPAREN' => 47,
			'KW_NOT' => 45,
			'TUPLEOPEN' => 42,
			'KW_TRY' => 41,
			'OPENBINARY' => 38,
			'LITERAL' => 34,
			'OPENRECORD' => 60,
			'LISTOPEN' => 59,
			'FLOAT' => 58,
			'ADD' => 32,
			'STRING' => 57,
			'KW_CATCH' => 56,
			'KW_RECEIVE' => 55,
			'MACRO' => 53,
			'SUBTRACT' => 54,
			'BASE_INTEGER' => 27,
			'KW_IF' => 25,
			'KW_CASE' => 50,
			'KW_BNOT' => 23
		},
		GOTOS => {
			'comprehension' => 46,
			'immexpr' => 40,
			'string' => 16,
			'binary' => 17,
			'if' => 43,
			'intcall' => 44,
			'extcall' => 18,
			'funlocal' => 13,
			'list' => 39,
			'call' => 37,
			'fun' => 14,
			'try' => 15,
			'case' => 36,
			'expr' => 127,
			'receive' => 61,
			'parenexpr' => 33,
			'macro' => 30,
			'parenorimm' => 29,
			'variable' => 31,
			'tuple' => 51,
			'unparenexpr' => 52,
			'newrecord' => 28,
			'atom' => 49
		}
	},
	{#State 48
		DEFAULT => -68
	},
	{#State 49
		DEFAULT => -78
	},
	{#State 50
		ACTIONS => {
			'FLOAT' => 58,
			'OPENRECORD' => 60,
			'LITERAL' => 34,
			'LISTOPEN' => 59,
			'KW_RECEIVE' => 55,
			'ADD' => 32,
			'STRING' => 57,
			'KW_CATCH' => 56,
			'MACRO' => 53,
			'SUBTRACT' => 54,
			'BASE_INTEGER' => 27,
			'KW_CASE' => 50,
			'KW_BNOT' => 23,
			'KW_IF' => 25,
			'ATOM' => 22,
			'INTEGER' => 48,
			'VARIABLE' => 21,
			'KW_NOT' => 45,
			'KW_BEGIN' => 20,
			'LPAREN' => 47,
			'KW_FUN' => 19,
			'TUPLEOPEN' => 42,
			'KW_TRY' => 41,
			'OPENBINARY' => 38
		},
		GOTOS => {
			'comprehension' => 46,
			'immexpr' => 40,
			'string' => 16,
			'binary' => 17,
			'if' => 43,
			'intcall' => 44,
			'extcall' => 18,
			'call' => 37,
			'funlocal' => 13,
			'list' => 39,
			'fun' => 14,
			'try' => 15,
			'case' => 36,
			'expr' => 128,
			'receive' => 61,
			'parenexpr' => 33,
			'parenorimm' => 29,
			'macro' => 30,
			'variable' => 31,
			'tuple' => 51,
			'unparenexpr' => 52,
			'newrecord' => 28,
			'atom' => 49
		}
	},
	{#State 51
		DEFAULT => -74
	},
	{#State 52
		DEFAULT => -62
	},
	{#State 53
		DEFAULT => -80
	},
	{#State 54
		ACTIONS => {
			'KW_TRY' => 41,
			'TUPLEOPEN' => 42,
			'OPENBINARY' => 38,
			'VARIABLE' => 21,
			'INTEGER' => 48,
			'ATOM' => 22,
			'KW_NOT' => 45,
			'KW_FUN' => 19,
			'LPAREN' => 47,
			'KW_BEGIN' => 20,
			'BASE_INTEGER' => 27,
			'MACRO' => 53,
			'SUBTRACT' => 54,
			'KW_BNOT' => 23,
			'KW_CASE' => 50,
			'KW_IF' => 25,
			'FLOAT' => 58,
			'LISTOPEN' => 59,
			'LITERAL' => 34,
			'OPENRECORD' => 60,
			'KW_RECEIVE' => 55,
			'KW_CATCH' => 56,
			'STRING' => 57,
			'ADD' => 32
		},
		GOTOS => {
			'receive' => 61,
			'parenexpr' => 33,
			'case' => 36,
			'expr' => 129,
			'parenorimm' => 29,
			'macro' => 30,
			'variable' => 31,
			'tuple' => 51,
			'newrecord' => 28,
			'unparenexpr' => 52,
			'atom' => 49,
			'comprehension' => 46,
			'if' => 43,
			'binary' => 17,
			'immexpr' => 40,
			'string' => 16,
			'extcall' => 18,
			'intcall' => 44,
			'call' => 37,
			'funlocal' => 13,
			'list' => 39,
			'try' => 15,
			'fun' => 14
		}
	},
	{#State 55
		ACTIONS => {
			'TUPLEOPEN' => 42,
			'KW_TRY' => 41,
			'OPENBINARY' => 38,
			'ATOM' => 22,
			'VARIABLE' => 21,
			'INTEGER' => 48,
			'KW_NOT' => 45,
			'KW_BEGIN' => 20,
			'KW_FUN' => 19,
			'LPAREN' => 47,
			'SUBTRACT' => 54,
			'MACRO' => 53,
			'BASE_INTEGER' => 27,
			'KW_CASE' => 50,
			'KW_BNOT' => 23,
			'KW_IF' => 25,
			'FLOAT' => 58,
			'OPENRECORD' => 60,
			'LITERAL' => 34,
			'LISTOPEN' => 59,
			'KW_RECEIVE' => 55,
			'STRING' => 57,
			'ADD' => 32,
			'KW_CATCH' => 56
		},
		GOTOS => {
			'comprehension' => 46,
			'alt' => 130,
			'call' => 37,
			'funlocal' => 13,
			'list' => 39,
			'try' => 15,
			'fun' => 14,
			'binary' => 17,
			'if' => 43,
			'immexpr' => 40,
			'string' => 16,
			'extcall' => 18,
			'intcall' => 44,
			'macro' => 30,
			'parenorimm' => 29,
			'variable' => 31,
			'expr' => 132,
			'receive' => 61,
			'parenexpr' => 33,
			'case' => 36,
			'altlist' => 131,
			'atom' => 49,
			'tuple' => 51,
			'newrecord' => 28,
			'unparenexpr' => 52
		}
	},
	{#State 56
		ACTIONS => {
			'KW_IF' => 25,
			'KW_BNOT' => 23,
			'KW_CASE' => 50,
			'BASE_INTEGER' => 27,
			'SUBTRACT' => 54,
			'MACRO' => 53,
			'KW_CATCH' => 56,
			'STRING' => 57,
			'ADD' => 32,
			'KW_RECEIVE' => 55,
			'LISTOPEN' => 59,
			'OPENRECORD' => 60,
			'LITERAL' => 34,
			'FLOAT' => 58,
			'OPENBINARY' => 38,
			'KW_TRY' => 41,
			'TUPLEOPEN' => 42,
			'KW_FUN' => 19,
			'LPAREN' => 47,
			'KW_BEGIN' => 20,
			'KW_NOT' => 45,
			'INTEGER' => 48,
			'VARIABLE' => 21,
			'ATOM' => 22
		},
		GOTOS => {
			'comprehension' => 46,
			'extcall' => 18,
			'intcall' => 44,
			'binary' => 17,
			'if' => 43,
			'immexpr' => 40,
			'string' => 16,
			'try' => 15,
			'fun' => 14,
			'call' => 37,
			'funlocal' => 13,
			'list' => 39,
			'receive' => 61,
			'case' => 36,
			'parenexpr' => 33,
			'expr' => 133,
			'variable' => 31,
			'parenorimm' => 29,
			'macro' => 30,
			'newrecord' => 28,
			'unparenexpr' => 52,
			'tuple' => 51,
			'atom' => 49
		}
	},
	{#State 57
		DEFAULT => -82
	},
	{#State 58
		DEFAULT => -66
	},
	{#State 59
		ACTIONS => {
			'LPAREN' => 47,
			'KW_FUN' => 19,
			'KW_BEGIN' => 20,
			'KW_NOT' => 45,
			'INTEGER' => 48,
			'VARIABLE' => 21,
			'ATOM' => 22,
			'OPENBINARY' => 38,
			'KW_TRY' => 41,
			'TUPLEOPEN' => 42,
			'KW_CATCH' => 56,
			'STRING' => 57,
			'ADD' => 32,
			'KW_RECEIVE' => 55,
			'LISTOPEN' => 59,
			'LITERAL' => 34,
			'OPENRECORD' => 60,
			'FLOAT' => 58,
			'KW_IF' => 25,
			'KW_BNOT' => 23,
			'KW_CASE' => 50,
			'BASE_INTEGER' => 27,
			'SUBTRACT' => 54,
			'MACRO' => 53
		},
		DEFAULT => -12,
		GOTOS => {
			'comprehension' => 46,
			'fun' => 14,
			'try' => 15,
			'call' => 37,
			'funlocal' => 13,
			'list' => 39,
			'intcall' => 44,
			'extcall' => 18,
			'immexpr' => 40,
			'string' => 16,
			'binary' => 17,
			'if' => 43,
			'variable' => 31,
			'macro' => 30,
			'parenorimm' => 29,
			'receive' => 61,
			'expr' => 135,
			'parenexpr' => 33,
			'case' => 36,
			'stmtlist' => 26,
			'exprlist' => 134,
			'atom' => 49,
			'unparenexpr' => 52,
			'newrecord' => 28,
			'tuple' => 51
		}
	},
	{#State 60
		ACTIONS => {
			'ATOM' => 22
		},
		GOTOS => {
			'atom' => 136
		}
	},
	{#State 61
		DEFAULT => -20
	},
	{#State 62
		DEFAULT => -6
	},
	{#State 63
		ACTIONS => {
			'RPAREN' => 137
		}
	},
	{#State 64
		DEFAULT => -83
	},
	{#State 65
		ACTIONS => {
			'KW_END' => 139,
			'SEMICOLON' => 138
		}
	},
	{#State 66
		DEFAULT => -104
	},
	{#State 67
		ACTIONS => {
			'COLON' => 140
		}
	},
	{#State 68
		ACTIONS => {
			'COLON' => 141
		}
	},
	{#State 69
		ACTIONS => {
			'DIVIDE' => 142
		},
		DEFAULT => -79
	},
	{#State 70
		ACTIONS => {
			'COLON' => 143
		}
	},
	{#State 71
		ACTIONS => {
			'KW_NOT' => 45,
			'KW_BEGIN' => 20,
			'KW_FUN' => 19,
			'LPAREN' => 47,
			'ATOM' => 22,
			'INTEGER' => 48,
			'VARIABLE' => 21,
			'OPENBINARY' => 38,
			'TUPLEOPEN' => 42,
			'KW_TRY' => 41,
			'KW_RECEIVE' => 55,
			'ADD' => 32,
			'STRING' => 57,
			'KW_CATCH' => 56,
			'FLOAT' => 58,
			'OPENRECORD' => 60,
			'LITERAL' => 34,
			'LISTOPEN' => 59,
			'KW_CASE' => 50,
			'KW_BNOT' => 23,
			'KW_IF' => 25,
			'SUBTRACT' => 54,
			'MACRO' => 53,
			'BASE_INTEGER' => 27
		},
		DEFAULT => -12,
		GOTOS => {
			'comprehension' => 46,
			'fun' => 14,
			'try' => 15,
			'call' => 37,
			'funlocal' => 13,
			'list' => 39,
			'intcall' => 44,
			'extcall' => 18,
			'immexpr' => 40,
			'string' => 16,
			'binary' => 17,
			'if' => 43,
			'variable' => 31,
			'macro' => 30,
			'parenorimm' => 29,
			'case' => 36,
			'expr' => 35,
			'parenexpr' => 33,
			'receive' => 61,
			'stmtlist' => 26,
			'atom' => 49,
			'exprlist' => 144,
			'unparenexpr' => 52,
			'newrecord' => 28,
			'tuple' => 51
		}
	},
	{#State 72
		ACTIONS => {
			'KW_END' => 145
		}
	},
	{#State 73
		DEFAULT => -55
	},
	{#State 74
		ACTIONS => {
			'KW_WHEN' => 147
		},
		DEFAULT => -8,
		GOTOS => {
			'whenlist' => 146
		}
	},
	{#State 75
		ACTIONS => {
			'SEMICOLON' => 148,
			'KW_END' => 149
		}
	},
	{#State 76
		ACTIONS => {
			'RARROW' => 150,
			'COMMA' => 151
		}
	},
	{#State 77
		ACTIONS => {
			'ADD' => 114,
			'KW_AND' => 111,
			'KW_BSR' => 112,
			'GTE' => 113,
			'MULTIPLY' => 107,
			'LDARROW' => 108,
			'KW_BOR' => 109,
			'KW_DIV' => 110,
			'LTE' => 100,
			'KW_OR' => 101,
			'LISTSUBTRACT' => 104,
			'NOT_EQUAL' => 103,
			'KW_REM' => 102,
			'KW_ANDALSO' => 105,
			'LARROW' => 106,
			'DIVIDE' => 98,
			'EQUAL' => 99,
			'LT' => 94,
			'KW_ORELSE' => 95,
			'SEND' => 96,
			'SUBTRACT' => 97,
			'KW_BSL' => 92,
			'KW_XOR' => 93,
			'KW_BXOR' => 85,
			'STRICTLY_EQUAL' => 86,
			'MATCH' => 88,
			'GT' => 89,
			'STRICTLY_NOT_EQUAL' => 87,
			'KW_BAND' => 90,
			'LISTADD' => 91
		},
		DEFAULT => -139
	},
	{#State 78
		DEFAULT => -136
	},
	{#State 79
		ACTIONS => {
			'KW_BEGIN' => 20,
			'LPAREN' => 47,
			'KW_FUN' => 19,
			'KW_NOT' => 45,
			'ATOM' => 22,
			'INTEGER' => 48,
			'VARIABLE' => 21,
			'OPENBINARY' => 38,
			'TUPLEOPEN' => 42,
			'KW_TRY' => 41,
			'STRING' => 57,
			'ADD' => 32,
			'KW_CATCH' => 56,
			'KW_RECEIVE' => 55,
			'OPENRECORD' => 60,
			'LITERAL' => 34,
			'LISTOPEN' => 59,
			'FLOAT' => 58,
			'KW_IF' => 25,
			'KW_CASE' => 50,
			'KW_BNOT' => 23,
			'SUBTRACT' => 54,
			'MACRO' => 53,
			'BASE_INTEGER' => 27
		},
		GOTOS => {
			'funlocal' => 13,
			'call' => 37,
			'list' => 39,
			'fun' => 14,
			'try' => 15,
			'immexpr' => 40,
			'string' => 16,
			'binary' => 17,
			'if' => 43,
			'intcall' => 44,
			'extcall' => 18,
			'comprehension' => 46,
			'atom' => 49,
			'tuple' => 51,
			'unparenexpr' => 52,
			'newrecord' => 28,
			'macro' => 30,
			'parenorimm' => 29,
			'variable' => 31,
			'case' => 36,
			'parenexpr' => 33,
			'expr' => 152,
			'receive' => 61
		}
	},
	{#State 80
		ACTIONS => {
			'OPENBINARY' => 38,
			'TUPLEOPEN' => 42,
			'KW_TRY' => 41,
			'KW_BEGIN' => 20,
			'LPAREN' => 47,
			'KW_FUN' => 19,
			'KW_NOT' => 45,
			'ATOM' => 22,
			'INTEGER' => 48,
			'VARIABLE' => 21,
			'KW_IF' => 25,
			'KW_CASE' => 50,
			'KW_BNOT' => 23,
			'SUBTRACT' => 54,
			'MACRO' => 53,
			'BASE_INTEGER' => 27,
			'ADD' => 32,
			'STRING' => 57,
			'KW_CATCH' => 56,
			'KW_RECEIVE' => 55,
			'LITERAL' => 34,
			'OPENRECORD' => 60,
			'LISTOPEN' => 59,
			'FLOAT' => 58
		},
		DEFAULT => -12,
		GOTOS => {
			'fun' => 14,
			'try' => 15,
			'funlocal' => 13,
			'call' => 37,
			'list' => 39,
			'intcall' => 44,
			'extcall' => 18,
			'string' => 16,
			'immexpr' => 40,
			'if' => 43,
			'binary' => 17,
			'comprehension' => 46,
			'stmtlist' => 26,
			'exprlist' => 153,
			'atom' => 49,
			'unparenexpr' => 52,
			'newrecord' => 28,
			'tuple' => 51,
			'variable' => 31,
			'parenorimm' => 29,
			'macro' => 30,
			'parenexpr' => 33,
			'expr' => 35,
			'case' => 36,
			'receive' => 61
		}
	},
	{#State 81
		ACTIONS => {
			'FLOAT' => 58,
			'INTEGER' => 48,
			'LISTOPEN' => 121,
			'VARIABLE' => 21,
			'OPENRECORD' => 60,
			'LITERAL' => 34,
			'ATOM' => 22,
			'LPAREN' => 47,
			'STRING' => 57,
			'TUPLEOPEN' => 42,
			'BASE_INTEGER' => 27,
			'MACRO' => 53
		},
		GOTOS => {
			'parenorimm' => 154,
			'macro' => 30,
			'variable' => 31,
			'parenexpr' => 116,
			'list' => 39,
			'atom' => 49,
			'immexpr' => 123,
			'string' => 16,
			'tuple' => 51,
			'intcall' => 155,
			'newrecord' => 28
		}
	},
	{#State 82
		DEFAULT => -71
	},
	{#State 83
		ACTIONS => {
			'ATOM' => 22
		},
		GOTOS => {
			'atom' => 156
		}
	},
	{#State 84
		DEFAULT => -54
	},
	{#State 85
		ACTIONS => {
			'ATOM' => 22,
			'INTEGER' => 48,
			'VARIABLE' => 21,
			'KW_NOT' => 45,
			'KW_BEGIN' => 20,
			'LPAREN' => 47,
			'KW_FUN' => 19,
			'TUPLEOPEN' => 42,
			'KW_TRY' => 41,
			'OPENBINARY' => 38,
			'FLOAT' => 58,
			'LITERAL' => 34,
			'OPENRECORD' => 60,
			'LISTOPEN' => 59,
			'KW_RECEIVE' => 55,
			'STRING' => 57,
			'ADD' => 32,
			'KW_CATCH' => 56,
			'MACRO' => 53,
			'SUBTRACT' => 54,
			'BASE_INTEGER' => 27,
			'KW_CASE' => 50,
			'KW_BNOT' => 23,
			'KW_IF' => 25
		},
		GOTOS => {
			'binary' => 17,
			'if' => 43,
			'immexpr' => 40,
			'string' => 16,
			'extcall' => 18,
			'intcall' => 44,
			'call' => 37,
			'funlocal' => 13,
			'list' => 39,
			'try' => 15,
			'fun' => 14,
			'comprehension' => 46,
			'tuple' => 51,
			'newrecord' => 28,
			'unparenexpr' => 52,
			'atom' => 49,
			'receive' => 61,
			'expr' => 157,
			'parenexpr' => 33,
			'case' => 36,
			'parenorimm' => 29,
			'macro' => 30,
			'variable' => 31
		}
	},
	{#State 86
		ACTIONS => {
			'VARIABLE' => 21,
			'INTEGER' => 48,
			'ATOM' => 22,
			'KW_FUN' => 19,
			'LPAREN' => 47,
			'KW_BEGIN' => 20,
			'KW_NOT' => 45,
			'KW_TRY' => 41,
			'TUPLEOPEN' => 42,
			'OPENBINARY' => 38,
			'LISTOPEN' => 59,
			'OPENRECORD' => 60,
			'LITERAL' => 34,
			'FLOAT' => 58,
			'KW_CATCH' => 56,
			'STRING' => 57,
			'ADD' => 32,
			'KW_RECEIVE' => 55,
			'BASE_INTEGER' => 27,
			'SUBTRACT' => 54,
			'MACRO' => 53,
			'KW_IF' => 25,
			'KW_BNOT' => 23,
			'KW_CASE' => 50
		},
		GOTOS => {
			'variable' => 31,
			'macro' => 30,
			'parenorimm' => 29,
			'expr' => 158,
			'receive' => 61,
			'parenexpr' => 33,
			'case' => 36,
			'atom' => 49,
			'newrecord' => 28,
			'unparenexpr' => 52,
			'tuple' => 51,
			'comprehension' => 46,
			'try' => 15,
			'fun' => 14,
			'funlocal' => 13,
			'call' => 37,
			'list' => 39,
			'extcall' => 18,
			'intcall' => 44,
			'binary' => 17,
			'if' => 43,
			'string' => 16,
			'immexpr' => 40
		}
	},
	{#State 87
		ACTIONS => {
			'FLOAT' => 58,
			'LISTOPEN' => 59,
			'LITERAL' => 34,
			'OPENRECORD' => 60,
			'KW_RECEIVE' => 55,
			'KW_CATCH' => 56,
			'ADD' => 32,
			'STRING' => 57,
			'BASE_INTEGER' => 27,
			'MACRO' => 53,
			'SUBTRACT' => 54,
			'KW_BNOT' => 23,
			'KW_CASE' => 50,
			'KW_IF' => 25,
			'VARIABLE' => 21,
			'INTEGER' => 48,
			'ATOM' => 22,
			'KW_NOT' => 45,
			'KW_FUN' => 19,
			'LPAREN' => 47,
			'KW_BEGIN' => 20,
			'KW_TRY' => 41,
			'TUPLEOPEN' => 42,
			'OPENBINARY' => 38
		},
		GOTOS => {
			'binary' => 17,
			'if' => 43,
			'immexpr' => 40,
			'string' => 16,
			'extcall' => 18,
			'intcall' => 44,
			'list' => 39,
			'funlocal' => 13,
			'call' => 37,
			'try' => 15,
			'fun' => 14,
			'comprehension' => 46,
			'tuple' => 51,
			'newrecord' => 28,
			'unparenexpr' => 52,
			'atom' => 49,
			'expr' => 159,
			'receive' => 61,
			'parenexpr' => 33,
			'case' => 36,
			'macro' => 30,
			'parenorimm' => 29,
			'variable' => 31
		}
	},
	{#State 88
		ACTIONS => {
			'KW_RECEIVE' => 55,
			'KW_CATCH' => 56,
			'ADD' => 32,
			'STRING' => 57,
			'FLOAT' => 58,
			'LISTOPEN' => 59,
			'OPENRECORD' => 60,
			'LITERAL' => 34,
			'KW_BNOT' => 23,
			'KW_CASE' => 50,
			'KW_IF' => 25,
			'BASE_INTEGER' => 27,
			'SUBTRACT' => 54,
			'MACRO' => 53,
			'KW_NOT' => 45,
			'LPAREN' => 47,
			'KW_FUN' => 19,
			'KW_BEGIN' => 20,
			'INTEGER' => 48,
			'VARIABLE' => 21,
			'ATOM' => 22,
			'OPENBINARY' => 38,
			'KW_TRY' => 41,
			'TUPLEOPEN' => 42
		},
		GOTOS => {
			'parenexpr' => 33,
			'expr' => 160,
			'case' => 36,
			'receive' => 61,
			'parenorimm' => 29,
			'macro' => 30,
			'variable' => 31,
			'tuple' => 51,
			'newrecord' => 28,
			'unparenexpr' => 52,
			'atom' => 49,
			'comprehension' => 46,
			'binary' => 17,
			'if' => 43,
			'string' => 16,
			'immexpr' => 40,
			'extcall' => 18,
			'intcall' => 44,
			'list' => 39,
			'funlocal' => 13,
			'call' => 37,
			'try' => 15,
			'fun' => 14
		}
	},
	{#State 89
		ACTIONS => {
			'KW_CATCH' => 56,
			'ADD' => 32,
			'STRING' => 57,
			'KW_RECEIVE' => 55,
			'LISTOPEN' => 59,
			'LITERAL' => 34,
			'OPENRECORD' => 60,
			'FLOAT' => 58,
			'KW_IF' => 25,
			'KW_BNOT' => 23,
			'KW_CASE' => 50,
			'BASE_INTEGER' => 27,
			'MACRO' => 53,
			'SUBTRACT' => 54,
			'LPAREN' => 47,
			'KW_FUN' => 19,
			'KW_BEGIN' => 20,
			'KW_NOT' => 45,
			'VARIABLE' => 21,
			'INTEGER' => 48,
			'ATOM' => 22,
			'OPENBINARY' => 38,
			'KW_TRY' => 41,
			'TUPLEOPEN' => 42
		},
		GOTOS => {
			'unparenexpr' => 52,
			'newrecord' => 28,
			'tuple' => 51,
			'atom' => 49,
			'parenexpr' => 33,
			'case' => 36,
			'receive' => 61,
			'expr' => 161,
			'variable' => 31,
			'parenorimm' => 29,
			'macro' => 30,
			'intcall' => 44,
			'extcall' => 18,
			'string' => 16,
			'immexpr' => 40,
			'binary' => 17,
			'if' => 43,
			'fun' => 14,
			'try' => 15,
			'call' => 37,
			'funlocal' => 13,
			'list' => 39,
			'comprehension' => 46
		}
	},
	{#State 90
		ACTIONS => {
			'STRING' => 57,
			'ADD' => 32,
			'KW_CATCH' => 56,
			'KW_RECEIVE' => 55,
			'LITERAL' => 34,
			'OPENRECORD' => 60,
			'LISTOPEN' => 59,
			'FLOAT' => 58,
			'KW_IF' => 25,
			'KW_CASE' => 50,
			'KW_BNOT' => 23,
			'MACRO' => 53,
			'SUBTRACT' => 54,
			'BASE_INTEGER' => 27,
			'KW_BEGIN' => 20,
			'LPAREN' => 47,
			'KW_FUN' => 19,
			'KW_NOT' => 45,
			'ATOM' => 22,
			'VARIABLE' => 21,
			'INTEGER' => 48,
			'OPENBINARY' => 38,
			'TUPLEOPEN' => 42,
			'KW_TRY' => 41
		},
		GOTOS => {
			'case' => 36,
			'expr' => 162,
			'receive' => 61,
			'parenexpr' => 33,
			'variable' => 31,
			'macro' => 30,
			'parenorimm' => 29,
			'newrecord' => 28,
			'unparenexpr' => 52,
			'tuple' => 51,
			'atom' => 49,
			'comprehension' => 46,
			'extcall' => 18,
			'intcall' => 44,
			'if' => 43,
			'binary' => 17,
			'string' => 16,
			'immexpr' => 40,
			'try' => 15,
			'fun' => 14,
			'list' => 39,
			'funlocal' => 13,
			'call' => 37
		}
	},
	{#State 91
		ACTIONS => {
			'FLOAT' => 58,
			'LISTOPEN' => 59,
			'LITERAL' => 34,
			'OPENRECORD' => 60,
			'KW_RECEIVE' => 55,
			'KW_CATCH' => 56,
			'STRING' => 57,
			'ADD' => 32,
			'BASE_INTEGER' => 27,
			'SUBTRACT' => 54,
			'MACRO' => 53,
			'KW_BNOT' => 23,
			'KW_CASE' => 50,
			'KW_IF' => 25,
			'VARIABLE' => 21,
			'INTEGER' => 48,
			'ATOM' => 22,
			'KW_NOT' => 45,
			'KW_FUN' => 19,
			'LPAREN' => 47,
			'KW_BEGIN' => 20,
			'KW_TRY' => 41,
			'TUPLEOPEN' => 42,
			'OPENBINARY' => 38
		},
		GOTOS => {
			'try' => 15,
			'fun' => 14,
			'funlocal' => 13,
			'list' => 39,
			'call' => 37,
			'extcall' => 18,
			'intcall' => 44,
			'binary' => 17,
			'if' => 43,
			'immexpr' => 40,
			'string' => 16,
			'comprehension' => 46,
			'atom' => 49,
			'newrecord' => 28,
			'unparenexpr' => 52,
			'tuple' => 51,
			'variable' => 31,
			'parenorimm' => 29,
			'macro' => 30,
			'expr' => 163,
			'case' => 36,
			'receive' => 61,
			'parenexpr' => 33
		}
	},
	{#State 92
		ACTIONS => {
			'KW_RECEIVE' => 55,
			'STRING' => 57,
			'ADD' => 32,
			'KW_CATCH' => 56,
			'FLOAT' => 58,
			'OPENRECORD' => 60,
			'LITERAL' => 34,
			'LISTOPEN' => 59,
			'KW_CASE' => 50,
			'KW_BNOT' => 23,
			'KW_IF' => 25,
			'SUBTRACT' => 54,
			'MACRO' => 53,
			'BASE_INTEGER' => 27,
			'KW_NOT' => 45,
			'KW_BEGIN' => 20,
			'LPAREN' => 47,
			'KW_FUN' => 19,
			'ATOM' => 22,
			'INTEGER' => 48,
			'VARIABLE' => 21,
			'OPENBINARY' => 38,
			'TUPLEOPEN' => 42,
			'KW_TRY' => 41
		},
		GOTOS => {
			'atom' => 49,
			'newrecord' => 28,
			'unparenexpr' => 52,
			'tuple' => 51,
			'variable' => 31,
			'parenorimm' => 29,
			'macro' => 30,
			'parenexpr' => 33,
			'expr' => 164,
			'case' => 36,
			'receive' => 61,
			'try' => 15,
			'fun' => 14,
			'funlocal' => 13,
			'list' => 39,
			'call' => 37,
			'extcall' => 18,
			'intcall' => 44,
			'if' => 43,
			'binary' => 17,
			'string' => 16,
			'immexpr' => 40,
			'comprehension' => 46
		}
	},
	{#State 93
		ACTIONS => {
			'KW_IF' => 25,
			'KW_BNOT' => 23,
			'KW_CASE' => 50,
			'BASE_INTEGER' => 27,
			'MACRO' => 53,
			'SUBTRACT' => 54,
			'KW_CATCH' => 56,
			'ADD' => 32,
			'STRING' => 57,
			'KW_RECEIVE' => 55,
			'LISTOPEN' => 59,
			'LITERAL' => 34,
			'OPENRECORD' => 60,
			'FLOAT' => 58,
			'OPENBINARY' => 38,
			'KW_TRY' => 41,
			'TUPLEOPEN' => 42,
			'LPAREN' => 47,
			'KW_FUN' => 19,
			'KW_BEGIN' => 20,
			'KW_NOT' => 45,
			'VARIABLE' => 21,
			'INTEGER' => 48,
			'ATOM' => 22
		},
		GOTOS => {
			'immexpr' => 40,
			'string' => 16,
			'if' => 43,
			'binary' => 17,
			'intcall' => 44,
			'extcall' => 18,
			'call' => 37,
			'funlocal' => 13,
			'list' => 39,
			'fun' => 14,
			'try' => 15,
			'comprehension' => 46,
			'tuple' => 51,
			'unparenexpr' => 52,
			'newrecord' => 28,
			'atom' => 49,
			'expr' => 165,
			'case' => 36,
			'parenexpr' => 33,
			'receive' => 61,
			'macro' => 30,
			'parenorimm' => 29,
			'variable' => 31
		}
	},
	{#State 94
		ACTIONS => {
			'KW_IF' => 25,
			'KW_CASE' => 50,
			'KW_BNOT' => 23,
			'MACRO' => 53,
			'SUBTRACT' => 54,
			'BASE_INTEGER' => 27,
			'ADD' => 32,
			'STRING' => 57,
			'KW_CATCH' => 56,
			'KW_RECEIVE' => 55,
			'LITERAL' => 34,
			'OPENRECORD' => 60,
			'LISTOPEN' => 59,
			'FLOAT' => 58,
			'OPENBINARY' => 38,
			'TUPLEOPEN' => 42,
			'KW_TRY' => 41,
			'KW_BEGIN' => 20,
			'LPAREN' => 47,
			'KW_FUN' => 19,
			'KW_NOT' => 45,
			'ATOM' => 22,
			'INTEGER' => 48,
			'VARIABLE' => 21
		},
		GOTOS => {
			'list' => 39,
			'funlocal' => 13,
			'call' => 37,
			'try' => 15,
			'fun' => 14,
			'binary' => 17,
			'if' => 43,
			'string' => 16,
			'immexpr' => 40,
			'extcall' => 18,
			'intcall' => 44,
			'comprehension' => 46,
			'atom' => 49,
			'tuple' => 51,
			'newrecord' => 28,
			'unparenexpr' => 52,
			'parenorimm' => 29,
			'macro' => 30,
			'variable' => 31,
			'parenexpr' => 33,
			'receive' => 61,
			'case' => 36,
			'expr' => 166
		}
	},
	{#State 95
		ACTIONS => {
			'KW_NOT' => 45,
			'KW_BEGIN' => 20,
			'KW_FUN' => 19,
			'LPAREN' => 47,
			'ATOM' => 22,
			'INTEGER' => 48,
			'VARIABLE' => 21,
			'OPENBINARY' => 38,
			'TUPLEOPEN' => 42,
			'KW_TRY' => 41,
			'KW_RECEIVE' => 55,
			'STRING' => 57,
			'ADD' => 32,
			'KW_CATCH' => 56,
			'FLOAT' => 58,
			'LITERAL' => 34,
			'OPENRECORD' => 60,
			'LISTOPEN' => 59,
			'KW_CASE' => 50,
			'KW_BNOT' => 23,
			'KW_IF' => 25,
			'MACRO' => 53,
			'SUBTRACT' => 54,
			'BASE_INTEGER' => 27
		},
		GOTOS => {
			'string' => 16,
			'immexpr' => 40,
			'if' => 43,
			'binary' => 17,
			'intcall' => 44,
			'extcall' => 18,
			'list' => 39,
			'call' => 37,
			'funlocal' => 13,
			'fun' => 14,
			'try' => 15,
			'comprehension' => 46,
			'tuple' => 51,
			'unparenexpr' => 52,
			'newrecord' => 28,
			'atom' => 49,
			'receive' => 61,
			'case' => 36,
			'expr' => 167,
			'parenexpr' => 33,
			'macro' => 30,
			'parenorimm' => 29,
			'variable' => 31
		}
	},
	{#State 96
		ACTIONS => {
			'ADD' => 32,
			'STRING' => 57,
			'KW_CATCH' => 56,
			'KW_RECEIVE' => 55,
			'LITERAL' => 34,
			'OPENRECORD' => 60,
			'LISTOPEN' => 59,
			'FLOAT' => 58,
			'KW_IF' => 25,
			'KW_CASE' => 50,
			'KW_BNOT' => 23,
			'SUBTRACT' => 54,
			'MACRO' => 53,
			'BASE_INTEGER' => 27,
			'KW_BEGIN' => 20,
			'LPAREN' => 47,
			'KW_FUN' => 19,
			'KW_NOT' => 45,
			'ATOM' => 22,
			'INTEGER' => 48,
			'VARIABLE' => 21,
			'OPENBINARY' => 38,
			'TUPLEOPEN' => 42,
			'KW_TRY' => 41
		},
		GOTOS => {
			'macro' => 30,
			'parenorimm' => 29,
			'variable' => 31,
			'expr' => 168,
			'receive' => 61,
			'parenexpr' => 33,
			'case' => 36,
			'atom' => 49,
			'tuple' => 51,
			'newrecord' => 28,
			'unparenexpr' => 52,
			'comprehension' => 46,
			'list' => 39,
			'funlocal' => 13,
			'call' => 37,
			'try' => 15,
			'fun' => 14,
			'binary' => 17,
			'if' => 43,
			'immexpr' => 40,
			'string' => 16,
			'extcall' => 18,
			'intcall' => 44
		}
	},
	{#State 97
		ACTIONS => {
			'ATOM' => 22,
			'INTEGER' => 48,
			'VARIABLE' => 21,
			'KW_BEGIN' => 20,
			'LPAREN' => 47,
			'KW_FUN' => 19,
			'KW_NOT' => 45,
			'TUPLEOPEN' => 42,
			'KW_TRY' => 41,
			'OPENBINARY' => 38,
			'OPENRECORD' => 60,
			'LITERAL' => 34,
			'LISTOPEN' => 59,
			'FLOAT' => 58,
			'ADD' => 32,
			'STRING' => 57,
			'KW_CATCH' => 56,
			'KW_RECEIVE' => 55,
			'MACRO' => 53,
			'SUBTRACT' => 54,
			'BASE_INTEGER' => 27,
			'KW_IF' => 25,
			'KW_CASE' => 50,
			'KW_BNOT' => 23
		},
		GOTOS => {
			'comprehension' => 46,
			'try' => 15,
			'fun' => 14,
			'call' => 37,
			'list' => 39,
			'funlocal' => 13,
			'extcall' => 18,
			'intcall' => 44,
			'if' => 43,
			'binary' => 17,
			'string' => 16,
			'immexpr' => 40,
			'variable' => 31,
			'macro' => 30,
			'parenorimm' => 29,
			'receive' => 61,
			'case' => 36,
			'expr' => 169,
			'parenexpr' => 33,
			'atom' => 49,
			'newrecord' => 28,
			'unparenexpr' => 52,
			'tuple' => 51
		}
	},
	{#State 98
		ACTIONS => {
			'BASE_INTEGER' => 27,
			'SUBTRACT' => 54,
			'MACRO' => 53,
			'KW_IF' => 25,
			'KW_BNOT' => 23,
			'KW_CASE' => 50,
			'LISTOPEN' => 59,
			'LITERAL' => 34,
			'OPENRECORD' => 60,
			'FLOAT' => 58,
			'KW_CATCH' => 56,
			'STRING' => 57,
			'ADD' => 32,
			'KW_RECEIVE' => 55,
			'KW_TRY' => 41,
			'TUPLEOPEN' => 42,
			'OPENBINARY' => 38,
			'INTEGER' => 48,
			'VARIABLE' => 21,
			'ATOM' => 22,
			'KW_FUN' => 19,
			'LPAREN' => 47,
			'KW_BEGIN' => 20,
			'KW_NOT' => 45
		},
		GOTOS => {
			'comprehension' => 46,
			'funlocal' => 13,
			'list' => 39,
			'call' => 37,
			'try' => 15,
			'fun' => 14,
			'binary' => 17,
			'if' => 43,
			'string' => 16,
			'immexpr' => 40,
			'extcall' => 18,
			'intcall' => 44,
			'macro' => 30,
			'parenorimm' => 29,
			'variable' => 31,
			'receive' => 61,
			'case' => 36,
			'expr' => 170,
			'parenexpr' => 33,
			'atom' => 49,
			'tuple' => 51,
			'newrecord' => 28,
			'unparenexpr' => 52
		}
	},
	{#State 99
		ACTIONS => {
			'KW_NOT' => 45,
			'KW_BEGIN' => 20,
			'LPAREN' => 47,
			'KW_FUN' => 19,
			'ATOM' => 22,
			'INTEGER' => 48,
			'VARIABLE' => 21,
			'OPENBINARY' => 38,
			'TUPLEOPEN' => 42,
			'KW_TRY' => 41,
			'KW_RECEIVE' => 55,
			'ADD' => 32,
			'STRING' => 57,
			'KW_CATCH' => 56,
			'FLOAT' => 58,
			'LITERAL' => 34,
			'OPENRECORD' => 60,
			'LISTOPEN' => 59,
			'KW_CASE' => 50,
			'KW_BNOT' => 23,
			'KW_IF' => 25,
			'SUBTRACT' => 54,
			'MACRO' => 53,
			'BASE_INTEGER' => 27
		},
		GOTOS => {
			'macro' => 30,
			'parenorimm' => 29,
			'variable' => 31,
			'parenexpr' => 33,
			'receive' => 61,
			'expr' => 171,
			'case' => 36,
			'atom' => 49,
			'tuple' => 51,
			'unparenexpr' => 52,
			'newrecord' => 28,
			'comprehension' => 46,
			'call' => 37,
			'funlocal' => 13,
			'list' => 39,
			'fun' => 14,
			'try' => 15,
			'string' => 16,
			'immexpr' => 40,
			'if' => 43,
			'binary' => 17,
			'intcall' => 44,
			'extcall' => 18
		}
	},
	{#State 100
		ACTIONS => {
			'BASE_INTEGER' => 27,
			'MACRO' => 53,
			'SUBTRACT' => 54,
			'KW_BNOT' => 23,
			'KW_CASE' => 50,
			'KW_IF' => 25,
			'FLOAT' => 58,
			'LISTOPEN' => 59,
			'LITERAL' => 34,
			'OPENRECORD' => 60,
			'KW_RECEIVE' => 55,
			'KW_CATCH' => 56,
			'ADD' => 32,
			'STRING' => 57,
			'KW_TRY' => 41,
			'TUPLEOPEN' => 42,
			'OPENBINARY' => 38,
			'VARIABLE' => 21,
			'INTEGER' => 48,
			'ATOM' => 22,
			'KW_NOT' => 45,
			'LPAREN' => 47,
			'KW_FUN' => 19,
			'KW_BEGIN' => 20
		},
		GOTOS => {
			'variable' => 31,
			'macro' => 30,
			'parenorimm' => 29,
			'expr' => 172,
			'case' => 36,
			'receive' => 61,
			'parenexpr' => 33,
			'atom' => 49,
			'newrecord' => 28,
			'unparenexpr' => 52,
			'tuple' => 51,
			'comprehension' => 46,
			'try' => 15,
			'fun' => 14,
			'funlocal' => 13,
			'list' => 39,
			'call' => 37,
			'extcall' => 18,
			'intcall' => 44,
			'binary' => 17,
			'if' => 43,
			'immexpr' => 40,
			'string' => 16
		}
	},
	{#State 101
		ACTIONS => {
			'OPENBINARY' => 38,
			'KW_TRY' => 41,
			'TUPLEOPEN' => 42,
			'KW_FUN' => 19,
			'LPAREN' => 47,
			'KW_BEGIN' => 20,
			'KW_NOT' => 45,
			'INTEGER' => 48,
			'VARIABLE' => 21,
			'ATOM' => 22,
			'KW_IF' => 25,
			'KW_BNOT' => 23,
			'KW_CASE' => 50,
			'BASE_INTEGER' => 27,
			'SUBTRACT' => 54,
			'MACRO' => 53,
			'KW_CATCH' => 56,
			'STRING' => 57,
			'ADD' => 32,
			'KW_RECEIVE' => 55,
			'LISTOPEN' => 59,
			'OPENRECORD' => 60,
			'LITERAL' => 34,
			'FLOAT' => 58
		},
		GOTOS => {
			'comprehension' => 46,
			'extcall' => 18,
			'intcall' => 44,
			'binary' => 17,
			'if' => 43,
			'immexpr' => 40,
			'string' => 16,
			'try' => 15,
			'fun' => 14,
			'call' => 37,
			'list' => 39,
			'funlocal' => 13,
			'expr' => 173,
			'case' => 36,
			'parenexpr' => 33,
			'receive' => 61,
			'variable' => 31,
			'macro' => 30,
			'parenorimm' => 29,
			'newrecord' => 28,
			'unparenexpr' => 52,
			'tuple' => 51,
			'atom' => 49
		}
	},
	{#State 102
		ACTIONS => {
			'FLOAT' => 58,
			'LISTOPEN' => 59,
			'LITERAL' => 34,
			'OPENRECORD' => 60,
			'KW_RECEIVE' => 55,
			'KW_CATCH' => 56,
			'ADD' => 32,
			'STRING' => 57,
			'BASE_INTEGER' => 27,
			'SUBTRACT' => 54,
			'MACRO' => 53,
			'KW_BNOT' => 23,
			'KW_CASE' => 50,
			'KW_IF' => 25,
			'INTEGER' => 48,
			'VARIABLE' => 21,
			'ATOM' => 22,
			'KW_NOT' => 45,
			'KW_FUN' => 19,
			'LPAREN' => 47,
			'KW_BEGIN' => 20,
			'KW_TRY' => 41,
			'TUPLEOPEN' => 42,
			'OPENBINARY' => 38
		},
		GOTOS => {
			'atom' => 49,
			'unparenexpr' => 52,
			'newrecord' => 28,
			'tuple' => 51,
			'variable' => 31,
			'parenorimm' => 29,
			'macro' => 30,
			'receive' => 61,
			'expr' => 174,
			'parenexpr' => 33,
			'case' => 36,
			'fun' => 14,
			'try' => 15,
			'list' => 39,
			'funlocal' => 13,
			'call' => 37,
			'intcall' => 44,
			'extcall' => 18,
			'immexpr' => 40,
			'string' => 16,
			'if' => 43,
			'binary' => 17,
			'comprehension' => 46
		}
	},
	{#State 103
		ACTIONS => {
			'KW_NOT' => 45,
			'LPAREN' => 47,
			'KW_FUN' => 19,
			'KW_BEGIN' => 20,
			'VARIABLE' => 21,
			'INTEGER' => 48,
			'ATOM' => 22,
			'OPENBINARY' => 38,
			'KW_TRY' => 41,
			'TUPLEOPEN' => 42,
			'KW_RECEIVE' => 55,
			'KW_CATCH' => 56,
			'ADD' => 32,
			'STRING' => 57,
			'FLOAT' => 58,
			'LISTOPEN' => 59,
			'OPENRECORD' => 60,
			'LITERAL' => 34,
			'KW_BNOT' => 23,
			'KW_CASE' => 50,
			'KW_IF' => 25,
			'BASE_INTEGER' => 27,
			'SUBTRACT' => 54,
			'MACRO' => 53
		},
		GOTOS => {
			'extcall' => 18,
			'intcall' => 44,
			'binary' => 17,
			'if' => 43,
			'immexpr' => 40,
			'string' => 16,
			'try' => 15,
			'fun' => 14,
			'list' => 39,
			'funlocal' => 13,
			'call' => 37,
			'comprehension' => 46,
			'newrecord' => 28,
			'unparenexpr' => 52,
			'tuple' => 51,
			'atom' => 49,
			'receive' => 61,
			'case' => 36,
			'parenexpr' => 33,
			'expr' => 175,
			'variable' => 31,
			'macro' => 30,
			'parenorimm' => 29
		}
	},
	{#State 104
		ACTIONS => {
			'SUBTRACT' => 54,
			'MACRO' => 53,
			'BASE_INTEGER' => 27,
			'KW_CASE' => 50,
			'KW_BNOT' => 23,
			'KW_IF' => 25,
			'FLOAT' => 58,
			'LITERAL' => 34,
			'OPENRECORD' => 60,
			'LISTOPEN' => 59,
			'KW_RECEIVE' => 55,
			'STRING' => 57,
			'ADD' => 32,
			'KW_CATCH' => 56,
			'TUPLEOPEN' => 42,
			'KW_TRY' => 41,
			'OPENBINARY' => 38,
			'ATOM' => 22,
			'VARIABLE' => 21,
			'INTEGER' => 48,
			'KW_NOT' => 45,
			'KW_BEGIN' => 20,
			'LPAREN' => 47,
			'KW_FUN' => 19
		},
		GOTOS => {
			'comprehension' => 46,
			'extcall' => 18,
			'intcall' => 44,
			'if' => 43,
			'binary' => 17,
			'string' => 16,
			'immexpr' => 40,
			'try' => 15,
			'fun' => 14,
			'call' => 37,
			'funlocal' => 13,
			'list' => 39,
			'expr' => 176,
			'case' => 36,
			'parenexpr' => 33,
			'receive' => 61,
			'variable' => 31,
			'parenorimm' => 29,
			'macro' => 30,
			'newrecord' => 28,
			'unparenexpr' => 52,
			'tuple' => 51,
			'atom' => 49
		}
	},
	{#State 105
		ACTIONS => {
			'KW_BNOT' => 23,
			'KW_CASE' => 50,
			'KW_IF' => 25,
			'BASE_INTEGER' => 27,
			'SUBTRACT' => 54,
			'MACRO' => 53,
			'KW_RECEIVE' => 55,
			'KW_CATCH' => 56,
			'STRING' => 57,
			'ADD' => 32,
			'FLOAT' => 58,
			'LISTOPEN' => 59,
			'OPENRECORD' => 60,
			'LITERAL' => 34,
			'OPENBINARY' => 38,
			'KW_TRY' => 41,
			'TUPLEOPEN' => 42,
			'KW_NOT' => 45,
			'KW_FUN' => 19,
			'LPAREN' => 47,
			'KW_BEGIN' => 20,
			'VARIABLE' => 21,
			'INTEGER' => 48,
			'ATOM' => 22
		},
		GOTOS => {
			'comprehension' => 46,
			'list' => 39,
			'funlocal' => 13,
			'call' => 37,
			'fun' => 14,
			'try' => 15,
			'string' => 16,
			'immexpr' => 40,
			'binary' => 17,
			'if' => 43,
			'intcall' => 44,
			'extcall' => 18,
			'parenorimm' => 29,
			'macro' => 30,
			'variable' => 31,
			'case' => 36,
			'parenexpr' => 33,
			'expr' => 177,
			'receive' => 61,
			'atom' => 49,
			'tuple' => 51,
			'unparenexpr' => 52,
			'newrecord' => 28
		}
	},
	{#State 106
		ACTIONS => {
			'BASE_INTEGER' => 27,
			'MACRO' => 53,
			'SUBTRACT' => 54,
			'KW_IF' => 25,
			'KW_BNOT' => 23,
			'KW_CASE' => 50,
			'LISTOPEN' => 59,
			'LITERAL' => 34,
			'OPENRECORD' => 60,
			'FLOAT' => 58,
			'KW_CATCH' => 56,
			'ADD' => 32,
			'STRING' => 57,
			'KW_RECEIVE' => 55,
			'KW_TRY' => 41,
			'TUPLEOPEN' => 42,
			'OPENBINARY' => 38,
			'VARIABLE' => 21,
			'INTEGER' => 48,
			'ATOM' => 22,
			'LPAREN' => 47,
			'KW_FUN' => 19,
			'KW_BEGIN' => 20,
			'KW_NOT' => 45
		},
		GOTOS => {
			'list' => 39,
			'funlocal' => 13,
			'call' => 37,
			'try' => 15,
			'fun' => 14,
			'binary' => 17,
			'if' => 43,
			'immexpr' => 40,
			'string' => 16,
			'extcall' => 18,
			'intcall' => 44,
			'comprehension' => 46,
			'atom' => 49,
			'tuple' => 51,
			'newrecord' => 28,
			'unparenexpr' => 52,
			'parenorimm' => 29,
			'macro' => 30,
			'variable' => 31,
			'expr' => 178,
			'receive' => 61,
			'case' => 36,
			'parenexpr' => 33
		}
	},
	{#State 107
		ACTIONS => {
			'OPENBINARY' => 38,
			'TUPLEOPEN' => 42,
			'KW_TRY' => 41,
			'KW_NOT' => 45,
			'KW_BEGIN' => 20,
			'LPAREN' => 47,
			'KW_FUN' => 19,
			'ATOM' => 22,
			'VARIABLE' => 21,
			'INTEGER' => 48,
			'KW_CASE' => 50,
			'KW_BNOT' => 23,
			'KW_IF' => 25,
			'MACRO' => 53,
			'SUBTRACT' => 54,
			'BASE_INTEGER' => 27,
			'KW_RECEIVE' => 55,
			'STRING' => 57,
			'ADD' => 32,
			'KW_CATCH' => 56,
			'FLOAT' => 58,
			'OPENRECORD' => 60,
			'LITERAL' => 34,
			'LISTOPEN' => 59
		},
		GOTOS => {
			'tuple' => 51,
			'newrecord' => 28,
			'unparenexpr' => 52,
			'atom' => 49,
			'parenexpr' => 33,
			'case' => 36,
			'expr' => 179,
			'receive' => 61,
			'parenorimm' => 29,
			'macro' => 30,
			'variable' => 31,
			'if' => 43,
			'binary' => 17,
			'immexpr' => 40,
			'string' => 16,
			'extcall' => 18,
			'intcall' => 44,
			'funlocal' => 13,
			'call' => 37,
			'list' => 39,
			'try' => 15,
			'fun' => 14,
			'comprehension' => 46
		}
	},
	{#State 108
		ACTIONS => {
			'OPENBINARY' => 38,
			'KW_TRY' => 41,
			'TUPLEOPEN' => 42,
			'KW_FUN' => 19,
			'LPAREN' => 47,
			'KW_BEGIN' => 20,
			'KW_NOT' => 45,
			'VARIABLE' => 21,
			'INTEGER' => 48,
			'ATOM' => 22,
			'KW_IF' => 25,
			'KW_BNOT' => 23,
			'KW_CASE' => 50,
			'BASE_INTEGER' => 27,
			'MACRO' => 53,
			'SUBTRACT' => 54,
			'KW_CATCH' => 56,
			'STRING' => 57,
			'ADD' => 32,
			'KW_RECEIVE' => 55,
			'LISTOPEN' => 59,
			'OPENRECORD' => 60,
			'LITERAL' => 34,
			'FLOAT' => 58
		},
		GOTOS => {
			'parenexpr' => 33,
			'expr' => 180,
			'receive' => 61,
			'case' => 36,
			'parenorimm' => 29,
			'macro' => 30,
			'variable' => 31,
			'tuple' => 51,
			'unparenexpr' => 52,
			'newrecord' => 28,
			'atom' => 49,
			'comprehension' => 46,
			'string' => 16,
			'immexpr' => 40,
			'if' => 43,
			'binary' => 17,
			'intcall' => 44,
			'extcall' => 18,
			'call' => 37,
			'funlocal' => 13,
			'list' => 39,
			'fun' => 14,
			'try' => 15
		}
	},
	{#State 109
		ACTIONS => {
			'OPENBINARY' => 38,
			'KW_TRY' => 41,
			'TUPLEOPEN' => 42,
			'KW_NOT' => 45,
			'LPAREN' => 47,
			'KW_FUN' => 19,
			'KW_BEGIN' => 20,
			'INTEGER' => 48,
			'VARIABLE' => 21,
			'ATOM' => 22,
			'KW_BNOT' => 23,
			'KW_CASE' => 50,
			'KW_IF' => 25,
			'BASE_INTEGER' => 27,
			'MACRO' => 53,
			'SUBTRACT' => 54,
			'KW_RECEIVE' => 55,
			'KW_CATCH' => 56,
			'ADD' => 32,
			'STRING' => 57,
			'FLOAT' => 58,
			'LISTOPEN' => 59,
			'OPENRECORD' => 60,
			'LITERAL' => 34
		},
		GOTOS => {
			'expr' => 181,
			'receive' => 61,
			'case' => 36,
			'parenexpr' => 33,
			'macro' => 30,
			'parenorimm' => 29,
			'variable' => 31,
			'tuple' => 51,
			'unparenexpr' => 52,
			'newrecord' => 28,
			'atom' => 49,
			'comprehension' => 46,
			'string' => 16,
			'immexpr' => 40,
			'binary' => 17,
			'if' => 43,
			'intcall' => 44,
			'extcall' => 18,
			'list' => 39,
			'call' => 37,
			'funlocal' => 13,
			'fun' => 14,
			'try' => 15
		}
	},
	{#State 110
		ACTIONS => {
			'SUBTRACT' => 54,
			'MACRO' => 53,
			'BASE_INTEGER' => 27,
			'KW_CASE' => 50,
			'KW_BNOT' => 23,
			'KW_IF' => 25,
			'FLOAT' => 58,
			'OPENRECORD' => 60,
			'LITERAL' => 34,
			'LISTOPEN' => 59,
			'KW_RECEIVE' => 55,
			'ADD' => 32,
			'STRING' => 57,
			'KW_CATCH' => 56,
			'TUPLEOPEN' => 42,
			'KW_TRY' => 41,
			'OPENBINARY' => 38,
			'ATOM' => 22,
			'VARIABLE' => 21,
			'INTEGER' => 48,
			'KW_NOT' => 45,
			'KW_BEGIN' => 20,
			'LPAREN' => 47,
			'KW_FUN' => 19
		},
		GOTOS => {
			'fun' => 14,
			'try' => 15,
			'call' => 37,
			'list' => 39,
			'funlocal' => 13,
			'intcall' => 44,
			'extcall' => 18,
			'immexpr' => 40,
			'string' => 16,
			'binary' => 17,
			'if' => 43,
			'comprehension' => 46,
			'atom' => 49,
			'unparenexpr' => 52,
			'newrecord' => 28,
			'tuple' => 51,
			'variable' => 31,
			'parenorimm' => 29,
			'macro' => 30,
			'receive' => 61,
			'case' => 36,
			'expr' => 182,
			'parenexpr' => 33
		}
	},
	{#State 111
		ACTIONS => {
			'INTEGER' => 48,
			'VARIABLE' => 21,
			'ATOM' => 22,
			'KW_FUN' => 19,
			'LPAREN' => 47,
			'KW_BEGIN' => 20,
			'KW_NOT' => 45,
			'KW_TRY' => 41,
			'TUPLEOPEN' => 42,
			'OPENBINARY' => 38,
			'LISTOPEN' => 59,
			'OPENRECORD' => 60,
			'LITERAL' => 34,
			'FLOAT' => 58,
			'KW_CATCH' => 56,
			'ADD' => 32,
			'STRING' => 57,
			'KW_RECEIVE' => 55,
			'BASE_INTEGER' => 27,
			'SUBTRACT' => 54,
			'MACRO' => 53,
			'KW_IF' => 25,
			'KW_BNOT' => 23,
			'KW_CASE' => 50
		},
		GOTOS => {
			'expr' => 183,
			'receive' => 61,
			'case' => 36,
			'parenexpr' => 33,
			'macro' => 30,
			'parenorimm' => 29,
			'variable' => 31,
			'tuple' => 51,
			'unparenexpr' => 52,
			'newrecord' => 28,
			'atom' => 49,
			'comprehension' => 46,
			'immexpr' => 40,
			'string' => 16,
			'if' => 43,
			'binary' => 17,
			'intcall' => 44,
			'extcall' => 18,
			'call' => 37,
			'list' => 39,
			'funlocal' => 13,
			'fun' => 14,
			'try' => 15
		}
	},
	{#State 112
		ACTIONS => {
			'BASE_INTEGER' => 27,
			'MACRO' => 53,
			'SUBTRACT' => 54,
			'KW_BNOT' => 23,
			'KW_CASE' => 50,
			'KW_IF' => 25,
			'FLOAT' => 58,
			'LISTOPEN' => 59,
			'OPENRECORD' => 60,
			'LITERAL' => 34,
			'KW_RECEIVE' => 55,
			'KW_CATCH' => 56,
			'STRING' => 57,
			'ADD' => 32,
			'KW_TRY' => 41,
			'TUPLEOPEN' => 42,
			'OPENBINARY' => 38,
			'VARIABLE' => 21,
			'INTEGER' => 48,
			'ATOM' => 22,
			'KW_NOT' => 45,
			'KW_FUN' => 19,
			'LPAREN' => 47,
			'KW_BEGIN' => 20
		},
		GOTOS => {
			'parenorimm' => 29,
			'macro' => 30,
			'variable' => 31,
			'receive' => 61,
			'expr' => 184,
			'case' => 36,
			'parenexpr' => 33,
			'atom' => 49,
			'tuple' => 51,
			'unparenexpr' => 52,
			'newrecord' => 28,
			'comprehension' => 46,
			'call' => 37,
			'funlocal' => 13,
			'list' => 39,
			'fun' => 14,
			'try' => 15,
			'string' => 16,
			'immexpr' => 40,
			'binary' => 17,
			'if' => 43,
			'intcall' => 44,
			'extcall' => 18
		}
	},
	{#State 113
		ACTIONS => {
			'TUPLEOPEN' => 42,
			'KW_TRY' => 41,
			'OPENBINARY' => 38,
			'ATOM' => 22,
			'VARIABLE' => 21,
			'INTEGER' => 48,
			'KW_NOT' => 45,
			'KW_BEGIN' => 20,
			'KW_FUN' => 19,
			'LPAREN' => 47,
			'SUBTRACT' => 54,
			'MACRO' => 53,
			'BASE_INTEGER' => 27,
			'KW_CASE' => 50,
			'KW_BNOT' => 23,
			'KW_IF' => 25,
			'FLOAT' => 58,
			'OPENRECORD' => 60,
			'LITERAL' => 34,
			'LISTOPEN' => 59,
			'KW_RECEIVE' => 55,
			'ADD' => 32,
			'STRING' => 57,
			'KW_CATCH' => 56
		},
		GOTOS => {
			'atom' => 49,
			'unparenexpr' => 52,
			'newrecord' => 28,
			'tuple' => 51,
			'variable' => 31,
			'macro' => 30,
			'parenorimm' => 29,
			'expr' => 185,
			'case' => 36,
			'receive' => 61,
			'parenexpr' => 33,
			'fun' => 14,
			'try' => 15,
			'funlocal' => 13,
			'list' => 39,
			'call' => 37,
			'intcall' => 44,
			'extcall' => 18,
			'string' => 16,
			'immexpr' => 40,
			'binary' => 17,
			'if' => 43,
			'comprehension' => 46
		}
	},
	{#State 114
		ACTIONS => {
			'KW_NOT' => 45,
			'KW_FUN' => 19,
			'LPAREN' => 47,
			'KW_BEGIN' => 20,
			'VARIABLE' => 21,
			'INTEGER' => 48,
			'ATOM' => 22,
			'OPENBINARY' => 38,
			'KW_TRY' => 41,
			'TUPLEOPEN' => 42,
			'KW_RECEIVE' => 55,
			'KW_CATCH' => 56,
			'ADD' => 32,
			'STRING' => 57,
			'FLOAT' => 58,
			'LISTOPEN' => 59,
			'OPENRECORD' => 60,
			'LITERAL' => 34,
			'KW_BNOT' => 23,
			'KW_CASE' => 50,
			'KW_IF' => 25,
			'BASE_INTEGER' => 27,
			'SUBTRACT' => 54,
			'MACRO' => 53
		},
		GOTOS => {
			'comprehension' => 46,
			'list' => 39,
			'call' => 37,
			'funlocal' => 13,
			'try' => 15,
			'fun' => 14,
			'if' => 43,
			'binary' => 17,
			'string' => 16,
			'immexpr' => 40,
			'extcall' => 18,
			'intcall' => 44,
			'parenorimm' => 29,
			'macro' => 30,
			'variable' => 31,
			'receive' => 61,
			'case' => 36,
			'parenexpr' => 33,
			'expr' => 186,
			'atom' => 49,
			'tuple' => 51,
			'newrecord' => 28,
			'unparenexpr' => 52
		}
	},
	{#State 115
		ACTIONS => {
			'COLON' => 188
		},
		DEFAULT => -114,
		GOTOS => {
			'optbinarysize' => 187
		}
	},
	{#State 116
		DEFAULT => -64
	},
	{#State 117
		DEFAULT => -111
	},
	{#State 118
		ACTIONS => {
			'COMPREHENSION' => 189
		}
	},
	{#State 119
		ACTIONS => {
			'CLOSEBINARY' => 190
		}
	},
	{#State 120
		ACTIONS => {
			'COMMA' => 191
		},
		DEFAULT => -110
	},
	{#State 121
		ACTIONS => {
			'KW_IF' => 25,
			'KW_CASE' => 50,
			'KW_BNOT' => 23,
			'MACRO' => 53,
			'SUBTRACT' => 54,
			'BASE_INTEGER' => 27,
			'ADD' => 32,
			'STRING' => 57,
			'KW_CATCH' => 56,
			'KW_RECEIVE' => 55,
			'LITERAL' => 34,
			'OPENRECORD' => 60,
			'LISTOPEN' => 59,
			'FLOAT' => 58,
			'OPENBINARY' => 38,
			'TUPLEOPEN' => 42,
			'KW_TRY' => 41,
			'KW_BEGIN' => 20,
			'KW_FUN' => 19,
			'LPAREN' => 47,
			'KW_NOT' => 45,
			'ATOM' => 22,
			'INTEGER' => 48,
			'VARIABLE' => 21
		},
		DEFAULT => -12,
		GOTOS => {
			'immexpr' => 40,
			'string' => 16,
			'binary' => 17,
			'if' => 43,
			'intcall' => 44,
			'extcall' => 18,
			'list' => 39,
			'call' => 37,
			'funlocal' => 13,
			'fun' => 14,
			'try' => 15,
			'comprehension' => 46,
			'tuple' => 51,
			'unparenexpr' => 52,
			'newrecord' => 28,
			'exprlist' => 134,
			'atom' => 49,
			'stmtlist' => 26,
			'case' => 36,
			'receive' => 61,
			'expr' => 35,
			'parenexpr' => 33,
			'macro' => 30,
			'parenorimm' => 29,
			'variable' => 31
		}
	},
	{#State 122
		ACTIONS => {
			'BASE_INTEGER' => 27,
			'MACRO' => 53,
			'TUPLEOPEN' => 42,
			'LPAREN' => 47,
			'STRING' => 57,
			'VARIABLE' => 21,
			'INTEGER' => 48,
			'LISTOPEN' => 121,
			'ATOM' => 22,
			'LITERAL' => 34,
			'OPENRECORD' => 60,
			'FLOAT' => 58
		},
		DEFAULT => -109,
		GOTOS => {
			'immexpr' => 123,
			'string' => 16,
			'binaryexpr' => 117,
			'tuple' => 51,
			'binarylist' => 120,
			'newrecord' => 28,
			'list' => 39,
			'atom' => 49,
			'parenexpr' => 116,
			'macro' => 30,
			'parenorimm' => 115,
			'variable' => 31,
			'optbinarylist' => 119
		}
	},
	{#State 123
		DEFAULT => -65
	},
	{#State 124
		ACTIONS => {
			'KW_OF' => 193
		},
		DEFAULT => -124,
		GOTOS => {
			'opttryof' => 192
		}
	},
	{#State 125
		ACTIONS => {
			'TUPLECLOSE' => 194
		}
	},
	{#State 126
		DEFAULT => -56
	},
	{#State 127
		ACTIONS => {
			'RPAREN' => 195,
			'MULTIPLY' => 107,
			'LDARROW' => 108,
			'KW_BSL' => 92,
			'KW_DIV' => 110,
			'KW_XOR' => 93,
			'KW_BOR' => 109,
			'LTE' => 100,
			'STRICTLY_EQUAL' => 86,
			'KW_BXOR' => 85,
			'KW_OR' => 101,
			'KW_BAND' => 90,
			'NOT_EQUAL' => 103,
			'LISTSUBTRACT' => 104,
			'KW_REM' => 102,
			'GT' => 89,
			'STRICTLY_NOT_EQUAL' => 87,
			'MATCH' => 88,
			'LARROW' => 106,
			'LISTADD' => 91,
			'KW_ANDALSO' => 105,
			'ADD' => 114,
			'DIVIDE' => 98,
			'EQUAL' => 99,
			'KW_AND' => 111,
			'LT' => 94,
			'KW_ORELSE' => 95,
			'KW_BSR' => 112,
			'SUBTRACT' => 97,
			'SEND' => 96,
			'GTE' => 113
		}
	},
	{#State 128
		ACTIONS => {
			'LT' => 94,
			'KW_AND' => 111,
			'KW_ORELSE' => 95,
			'KW_BSR' => 112,
			'SEND' => 96,
			'SUBTRACT' => 97,
			'GTE' => 113,
			'ADD' => 114,
			'DIVIDE' => 98,
			'EQUAL' => 99,
			'STRICTLY_EQUAL' => 86,
			'LTE' => 100,
			'KW_BXOR' => 85,
			'KW_OR' => 101,
			'KW_BAND' => 90,
			'KW_REM' => 102,
			'LISTSUBTRACT' => 104,
			'NOT_EQUAL' => 103,
			'STRICTLY_NOT_EQUAL' => 87,
			'GT' => 89,
			'MATCH' => 88,
			'LISTADD' => 91,
			'LARROW' => 106,
			'KW_ANDALSO' => 105,
			'MULTIPLY' => 107,
			'LDARROW' => 108,
			'KW_BSL' => 92,
			'KW_XOR' => 93,
			'KW_DIV' => 110,
			'KW_OF' => 196,
			'KW_BOR' => 109
		}
	},
	{#State 129
		DEFAULT => -53
	},
	{#State 130
		DEFAULT => -95
	},
	{#State 131
		ACTIONS => {
			'SEMICOLON' => 199,
			'KW_AFTER' => 198
		},
		DEFAULT => -121,
		GOTOS => {
			'after' => 197
		}
	},
	{#State 132
		ACTIONS => {
			'KW_AND' => 111,
			'KW_BSR' => 112,
			'GTE' => 113,
			'ADD' => 114,
			'LTE' => 100,
			'KW_OR' => 101,
			'LISTSUBTRACT' => 104,
			'NOT_EQUAL' => 103,
			'KW_REM' => 102,
			'KW_ANDALSO' => 105,
			'LARROW' => 106,
			'MULTIPLY' => 107,
			'LDARROW' => 108,
			'KW_BOR' => 109,
			'KW_DIV' => 110,
			'LT' => 94,
			'KW_ORELSE' => 95,
			'SEND' => 96,
			'SUBTRACT' => 97,
			'DIVIDE' => 98,
			'EQUAL' => 99,
			'KW_BXOR' => 85,
			'STRICTLY_EQUAL' => 86,
			'MATCH' => 88,
			'GT' => 89,
			'STRICTLY_NOT_EQUAL' => 87,
			'KW_BAND' => 90,
			'LISTADD' => 91,
			'KW_WHEN' => 147,
			'KW_BSL' => 92,
			'KW_XOR' => 93
		},
		DEFAULT => -8,
		GOTOS => {
			'whenlist' => 200
		}
	},
	{#State 133
		ACTIONS => {
			'LTE' => 100,
			'KW_OR' => 101,
			'LISTSUBTRACT' => 104,
			'NOT_EQUAL' => 103,
			'KW_REM' => 102,
			'KW_ANDALSO' => 105,
			'LARROW' => 106,
			'MULTIPLY' => 107,
			'LDARROW' => 108,
			'KW_BOR' => 109,
			'KW_DIV' => 110,
			'KW_AND' => 111,
			'KW_BSR' => 112,
			'GTE' => 113,
			'ADD' => 114,
			'KW_BXOR' => 85,
			'STRICTLY_EQUAL' => 86,
			'GT' => 89,
			'STRICTLY_NOT_EQUAL' => 87,
			'MATCH' => 88,
			'KW_BAND' => 90,
			'LISTADD' => 91,
			'KW_BSL' => 92,
			'KW_XOR' => 93,
			'LT' => 94,
			'KW_ORELSE' => 95,
			'SUBTRACT' => 97,
			'SEND' => 96,
			'DIVIDE' => 98,
			'EQUAL' => 99
		},
		DEFAULT => -57
	},
	{#State 134
		ACTIONS => {
			'PIPE' => 201
		},
		DEFAULT => -89,
		GOTOS => {
			'listcdr' => 202
		}
	},
	{#State 135
		ACTIONS => {
			'MULTIPLY' => 107,
			'KW_DIV' => 110,
			'KW_BOR' => 109,
			'LDARROW' => 108,
			'KW_OR' => 101,
			'LTE' => 100,
			'LARROW' => 106,
			'KW_ANDALSO' => 105,
			'LISTSUBTRACT' => 104,
			'NOT_EQUAL' => 103,
			'KW_REM' => 102,
			'ADD' => 114,
			'KW_AND' => 111,
			'GTE' => 113,
			'KW_BSR' => 112,
			'KW_XOR' => 93,
			'KW_BSL' => 92,
			'STRICTLY_EQUAL' => 86,
			'KW_BXOR' => 85,
			'LISTADD' => 91,
			'KW_BAND' => 90,
			'MATCH' => 88,
			'STRICTLY_NOT_EQUAL' => 87,
			'GT' => 89,
			'EQUAL' => 99,
			'COMPREHENSION' => 203,
			'DIVIDE' => 98,
			'LT' => 94,
			'SUBTRACT' => 97,
			'SEND' => 96,
			'KW_ORELSE' => 95
		},
		DEFAULT => -14
	},
	{#State 136
		ACTIONS => {
			'TUPLEOPEN' => 204
		}
	},
	{#State 137
		ACTIONS => {
			'PERIOD' => 205
		}
	},
	{#State 138
		ACTIONS => {
			'LPAREN' => 71
		},
		GOTOS => {
			'funlocalcase' => 206
		}
	},
	{#State 139
		DEFAULT => -103
	},
	{#State 140
		ACTIONS => {
			'ATOM' => 207
		}
	},
	{#State 141
		ACTIONS => {
			'ATOM' => 208
		}
	},
	{#State 142
		ACTIONS => {
			'INTEGER' => 209
		}
	},
	{#State 143
		ACTIONS => {
			'ATOM' => 210
		}
	},
	{#State 144
		ACTIONS => {
			'RPAREN' => 211
		}
	},
	{#State 145
		DEFAULT => -24
	},
	{#State 146
		ACTIONS => {
			'RARROW' => 212,
			'SEMICOLON' => 213,
			'COMMA' => 214
		}
	},
	{#State 147
		ACTIONS => {
			'TUPLEOPEN' => 42,
			'KW_TRY' => 41,
			'OPENBINARY' => 38,
			'ATOM' => 22,
			'INTEGER' => 48,
			'VARIABLE' => 21,
			'KW_NOT' => 45,
			'KW_BEGIN' => 20,
			'KW_FUN' => 19,
			'LPAREN' => 47,
			'SUBTRACT' => 54,
			'MACRO' => 53,
			'BASE_INTEGER' => 27,
			'KW_CASE' => 50,
			'KW_BNOT' => 23,
			'KW_IF' => 25,
			'FLOAT' => 58,
			'OPENRECORD' => 60,
			'LITERAL' => 34,
			'LISTOPEN' => 59,
			'KW_RECEIVE' => 55,
			'ADD' => 32,
			'STRING' => 57,
			'KW_CATCH' => 56
		},
		GOTOS => {
			'comprehension' => 46,
			'list' => 39,
			'funlocal' => 13,
			'call' => 37,
			'fun' => 14,
			'try' => 15,
			'immexpr' => 40,
			'string' => 16,
			'binary' => 17,
			'if' => 43,
			'intcall' => 44,
			'extcall' => 18,
			'parenorimm' => 29,
			'macro' => 30,
			'variable' => 31,
			'parenexpr' => 33,
			'case' => 36,
			'receive' => 61,
			'expr' => 215,
			'atom' => 49,
			'tuple' => 51,
			'unparenexpr' => 52,
			'newrecord' => 28
		}
	},
	{#State 148
		ACTIONS => {
			'KW_CASE' => 50,
			'KW_BNOT' => 23,
			'KW_IF' => 25,
			'SUBTRACT' => 54,
			'MACRO' => 53,
			'BASE_INTEGER' => 27,
			'KW_RECEIVE' => 55,
			'ADD' => 32,
			'STRING' => 57,
			'KW_CATCH' => 56,
			'FLOAT' => 58,
			'LITERAL' => 34,
			'OPENRECORD' => 60,
			'LISTOPEN' => 59,
			'OPENBINARY' => 38,
			'TUPLEOPEN' => 42,
			'KW_TRY' => 41,
			'KW_NOT' => 45,
			'KW_BEGIN' => 20,
			'KW_FUN' => 19,
			'LPAREN' => 47,
			'ATOM' => 22,
			'VARIABLE' => 21,
			'INTEGER' => 48
		},
		GOTOS => {
			'comprehension' => 46,
			'if' => 43,
			'binary' => 17,
			'ifseq' => 76,
			'immexpr' => 40,
			'string' => 16,
			'extcall' => 18,
			'intcall' => 44,
			'list' => 39,
			'call' => 37,
			'funlocal' => 13,
			'try' => 15,
			'fun' => 14,
			'receive' => 61,
			'case' => 36,
			'expr' => 77,
			'parenexpr' => 33,
			'macro' => 30,
			'parenorimm' => 29,
			'variable' => 31,
			'tuple' => 51,
			'ifexpr' => 216,
			'newrecord' => 28,
			'unparenexpr' => 52,
			'atom' => 49
		}
	},
	{#State 149
		DEFAULT => -135
	},
	{#State 150
		ACTIONS => {
			'KW_IF' => 25,
			'KW_BNOT' => 23,
			'KW_CASE' => 50,
			'BASE_INTEGER' => 27,
			'MACRO' => 53,
			'SUBTRACT' => 54,
			'KW_CATCH' => 56,
			'ADD' => 32,
			'STRING' => 57,
			'KW_RECEIVE' => 55,
			'LISTOPEN' => 59,
			'LITERAL' => 34,
			'OPENRECORD' => 60,
			'FLOAT' => 58,
			'OPENBINARY' => 38,
			'KW_TRY' => 41,
			'TUPLEOPEN' => 42,
			'LPAREN' => 47,
			'KW_FUN' => 19,
			'KW_BEGIN' => 20,
			'KW_NOT' => 45,
			'INTEGER' => 48,
			'VARIABLE' => 21,
			'ATOM' => 22
		},
		GOTOS => {
			'comprehension' => 46,
			'extcall' => 18,
			'intcall' => 44,
			'binary' => 17,
			'if' => 43,
			'immexpr' => 40,
			'string' => 16,
			'try' => 15,
			'fun' => 14,
			'call' => 37,
			'list' => 39,
			'funlocal' => 13,
			'receive' => 61,
			'expr' => 35,
			'parenexpr' => 33,
			'case' => 36,
			'variable' => 31,
			'parenorimm' => 29,
			'macro' => 30,
			'newrecord' => 28,
			'unparenexpr' => 52,
			'tuple' => 51,
			'stmtlist' => 217,
			'atom' => 49
		}
	},
	{#State 151
		ACTIONS => {
			'FLOAT' => 58,
			'LISTOPEN' => 59,
			'LITERAL' => 34,
			'OPENRECORD' => 60,
			'KW_RECEIVE' => 55,
			'KW_CATCH' => 56,
			'STRING' => 57,
			'ADD' => 32,
			'BASE_INTEGER' => 27,
			'SUBTRACT' => 54,
			'MACRO' => 53,
			'KW_BNOT' => 23,
			'KW_CASE' => 50,
			'KW_IF' => 25,
			'VARIABLE' => 21,
			'INTEGER' => 48,
			'ATOM' => 22,
			'KW_NOT' => 45,
			'KW_FUN' => 19,
			'LPAREN' => 47,
			'KW_BEGIN' => 20,
			'KW_TRY' => 41,
			'TUPLEOPEN' => 42,
			'OPENBINARY' => 38
		},
		GOTOS => {
			'binary' => 17,
			'if' => 43,
			'immexpr' => 40,
			'string' => 16,
			'extcall' => 18,
			'intcall' => 44,
			'call' => 37,
			'funlocal' => 13,
			'list' => 39,
			'try' => 15,
			'fun' => 14,
			'comprehension' => 46,
			'tuple' => 51,
			'newrecord' => 28,
			'unparenexpr' => 52,
			'atom' => 49,
			'expr' => 218,
			'case' => 36,
			'parenexpr' => 33,
			'receive' => 61,
			'parenorimm' => 29,
			'macro' => 30,
			'variable' => 31
		}
	},
	{#State 152
		ACTIONS => {
			'LISTADD' => 91,
			'KW_BAND' => 90,
			'MATCH' => 88,
			'STRICTLY_NOT_EQUAL' => 87,
			'GT' => 89,
			'STRICTLY_EQUAL' => 86,
			'KW_BXOR' => 85,
			'KW_XOR' => 93,
			'KW_BSL' => 92,
			'SEND' => 96,
			'SUBTRACT' => 97,
			'KW_ORELSE' => 95,
			'LT' => 94,
			'EQUAL' => 99,
			'DIVIDE' => 98,
			'LARROW' => 106,
			'KW_ANDALSO' => 105,
			'KW_REM' => 102,
			'NOT_EQUAL' => 103,
			'LISTSUBTRACT' => 104,
			'KW_OR' => 101,
			'LTE' => 100,
			'KW_DIV' => 110,
			'KW_BOR' => 109,
			'LDARROW' => 108,
			'MULTIPLY' => 107,
			'GTE' => 113,
			'KW_BSR' => 112,
			'KW_AND' => 111,
			'ADD' => 114
		},
		DEFAULT => -15
	},
	{#State 153
		ACTIONS => {
			'RPAREN' => 219
		}
	},
	{#State 154
		ACTIONS => {
			'LPAREN' => 80
		}
	},
	{#State 155
		DEFAULT => -87
	},
	{#State 156
		ACTIONS => {
			'TUPLEOPEN' => 204
		},
		DEFAULT => -70
	},
	{#State 157
		ACTIONS => {
			'KW_BAND' => 90,
			'DIVIDE' => 98,
			'KW_REM' => 102,
			'KW_DIV' => 110,
			'MULTIPLY' => 107,
			'KW_AND' => 111
		},
		DEFAULT => -46
	},
	{#State 158
		ACTIONS => {
			'ADD' => 114,
			'GTE' => undef,
			'KW_BSR' => 112,
			'KW_AND' => 111,
			'KW_BOR' => 109,
			'KW_DIV' => 110,
			'MULTIPLY' => 107,
			'NOT_EQUAL' => undef,
			'KW_REM' => 102,
			'LISTSUBTRACT' => 104,
			'KW_OR' => 101,
			'LTE' => undef,
			'EQUAL' => undef,
			'DIVIDE' => 98,
			'SUBTRACT' => 97,
			'LT' => undef,
			'KW_XOR' => 93,
			'KW_BSL' => 92,
			'LISTADD' => 91,
			'GT' => undef,
			'STRICTLY_NOT_EQUAL' => undef,
			'KW_BAND' => 90,
			'KW_BXOR' => 85,
			'STRICTLY_EQUAL' => undef
		},
		DEFAULT => -39
	},
	{#State 159
		ACTIONS => {
			'MULTIPLY' => 107,
			'KW_DIV' => 110,
			'KW_BOR' => 109,
			'LTE' => undef,
			'KW_OR' => 101,
			'NOT_EQUAL' => undef,
			'LISTSUBTRACT' => 104,
			'KW_REM' => 102,
			'ADD' => 114,
			'KW_AND' => 111,
			'KW_BSR' => 112,
			'GTE' => undef,
			'KW_BSL' => 92,
			'KW_XOR' => 93,
			'STRICTLY_EQUAL' => undef,
			'KW_BXOR' => 85,
			'KW_BAND' => 90,
			'STRICTLY_NOT_EQUAL' => undef,
			'GT' => undef,
			'LISTADD' => 91,
			'DIVIDE' => 98,
			'EQUAL' => undef,
			'LT' => undef,
			'SUBTRACT' => 97
		},
		DEFAULT => -40
	},
	{#State 160
		ACTIONS => {
			'EQUAL' => 99,
			'DIVIDE' => 98,
			'LT' => 94,
			'SUBTRACT' => 97,
			'SEND' => 96,
			'KW_ORELSE' => 95,
			'KW_XOR' => 93,
			'KW_BSL' => 92,
			'KW_BXOR' => 85,
			'STRICTLY_EQUAL' => 86,
			'LISTADD' => 91,
			'STRICTLY_NOT_EQUAL' => 87,
			'GT' => 89,
			'MATCH' => 88,
			'KW_BAND' => 90,
			'ADD' => 114,
			'KW_AND' => 111,
			'GTE' => 113,
			'KW_BSR' => 112,
			'MULTIPLY' => 107,
			'KW_BOR' => 109,
			'KW_DIV' => 110,
			'KW_OR' => 101,
			'LTE' => 100,
			'KW_ANDALSO' => 105,
			'LISTSUBTRACT' => 104,
			'KW_REM' => 102,
			'NOT_EQUAL' => 103
		},
		DEFAULT => -35
	},
	{#State 161
		ACTIONS => {
			'KW_BSL' => 92,
			'KW_XOR' => 93,
			'STRICTLY_EQUAL' => undef,
			'KW_BXOR' => 85,
			'KW_BAND' => 90,
			'GT' => undef,
			'STRICTLY_NOT_EQUAL' => undef,
			'LISTADD' => 91,
			'DIVIDE' => 98,
			'EQUAL' => undef,
			'LT' => undef,
			'SUBTRACT' => 97,
			'MULTIPLY' => 107,
			'KW_DIV' => 110,
			'KW_BOR' => 109,
			'LTE' => undef,
			'KW_OR' => 101,
			'NOT_EQUAL' => undef,
			'LISTSUBTRACT' => 104,
			'KW_REM' => 102,
			'ADD' => 114,
			'KW_AND' => 111,
			'KW_BSR' => 112,
			'GTE' => undef
		},
		DEFAULT => -28
	},
	{#State 162
		DEFAULT => -45
	},
	{#State 163
		ACTIONS => {
			'KW_BSL' => 92,
			'KW_XOR' => 93,
			'KW_BAND' => 90,
			'LISTADD' => 91,
			'KW_BXOR' => 85,
			'DIVIDE' => 98,
			'SUBTRACT' => 97,
			'KW_DIV' => 110,
			'KW_BOR' => 109,
			'MULTIPLY' => 107,
			'KW_REM' => 102,
			'LISTSUBTRACT' => 104,
			'KW_OR' => 101,
			'ADD' => 114,
			'KW_BSR' => 112,
			'KW_AND' => 111
		},
		DEFAULT => -36
	},
	{#State 164
		ACTIONS => {
			'KW_BAND' => 90,
			'DIVIDE' => 98,
			'MULTIPLY' => 107,
			'KW_DIV' => 110,
			'KW_REM' => 102,
			'KW_AND' => 111
		},
		DEFAULT => -42
	},
	{#State 165
		ACTIONS => {
			'KW_AND' => 111,
			'KW_DIV' => 110,
			'MULTIPLY' => 107,
			'KW_REM' => 102,
			'DIVIDE' => 98,
			'KW_BAND' => 90
		},
		DEFAULT => -47
	},
	{#State 166
		ACTIONS => {
			'MULTIPLY' => 107,
			'KW_DIV' => 110,
			'KW_BOR' => 109,
			'LTE' => undef,
			'KW_OR' => 101,
			'LISTSUBTRACT' => 104,
			'NOT_EQUAL' => undef,
			'KW_REM' => 102,
			'ADD' => 114,
			'KW_AND' => 111,
			'KW_BSR' => 112,
			'GTE' => undef,
			'KW_BSL' => 92,
			'KW_XOR' => 93,
			'STRICTLY_EQUAL' => undef,
			'KW_BXOR' => 85,
			'KW_BAND' => 90,
			'STRICTLY_NOT_EQUAL' => undef,
			'GT' => undef,
			'LISTADD' => 91,
			'DIVIDE' => 98,
			'EQUAL' => undef,
			'LT' => undef,
			'SUBTRACT' => 97
		},
		DEFAULT => -26
	},
	{#State 167
		ACTIONS => {
			'GT' => 89,
			'STRICTLY_NOT_EQUAL' => 87,
			'KW_BAND' => 90,
			'LISTADD' => 91,
			'KW_BXOR' => 85,
			'STRICTLY_EQUAL' => 86,
			'KW_BSL' => 92,
			'KW_XOR' => 93,
			'SUBTRACT' => 97,
			'LT' => 94,
			'DIVIDE' => 98,
			'EQUAL' => 99,
			'LISTSUBTRACT' => 104,
			'KW_REM' => 102,
			'NOT_EQUAL' => 103,
			'KW_ANDALSO' => 105,
			'LTE' => 100,
			'KW_OR' => 101,
			'KW_BOR' => 109,
			'KW_DIV' => 110,
			'MULTIPLY' => 107,
			'KW_BSR' => 112,
			'GTE' => 113,
			'KW_AND' => 111,
			'ADD' => 114
		},
		DEFAULT => -50
	},
	{#State 168
		ACTIONS => {
			'SUBTRACT' => 97,
			'SEND' => 96,
			'KW_ORELSE' => 95,
			'LT' => 94,
			'EQUAL' => 99,
			'DIVIDE' => 98,
			'LISTADD' => 91,
			'STRICTLY_NOT_EQUAL' => 87,
			'GT' => 89,
			'MATCH' => 88,
			'KW_BAND' => 90,
			'KW_BXOR' => 85,
			'STRICTLY_EQUAL' => 86,
			'KW_XOR' => 93,
			'KW_BSL' => 92,
			'GTE' => 113,
			'KW_BSR' => 112,
			'KW_AND' => 111,
			'ADD' => 114,
			'KW_ANDALSO' => 105,
			'KW_REM' => 102,
			'LISTSUBTRACT' => 104,
			'NOT_EQUAL' => 103,
			'KW_OR' => 101,
			'LTE' => 100,
			'KW_BOR' => 109,
			'KW_DIV' => 110,
			'MULTIPLY' => 107
		},
		DEFAULT => -25
	},
	{#State 169
		ACTIONS => {
			'DIVIDE' => 98,
			'KW_BAND' => 90,
			'KW_AND' => 111,
			'MULTIPLY' => 107,
			'KW_DIV' => 110,
			'KW_REM' => 102
		},
		DEFAULT => -34
	},
	{#State 170
		DEFAULT => -30
	},
	{#State 171
		ACTIONS => {
			'DIVIDE' => 98,
			'EQUAL' => undef,
			'LT' => undef,
			'SUBTRACT' => 97,
			'KW_BSL' => 92,
			'KW_XOR' => 93,
			'STRICTLY_EQUAL' => undef,
			'KW_BXOR' => 85,
			'KW_BAND' => 90,
			'GT' => undef,
			'STRICTLY_NOT_EQUAL' => undef,
			'LISTADD' => 91,
			'ADD' => 114,
			'KW_AND' => 111,
			'KW_BSR' => 112,
			'GTE' => undef,
			'MULTIPLY' => 107,
			'KW_DIV' => 110,
			'KW_BOR' => 109,
			'LTE' => undef,
			'KW_OR' => 101,
			'KW_REM' => 102,
			'NOT_EQUAL' => undef,
			'LISTSUBTRACT' => 104
		},
		DEFAULT => -38
	},
	{#State 172
		ACTIONS => {
			'KW_REM' => 102,
			'NOT_EQUAL' => undef,
			'LISTSUBTRACT' => 104,
			'LTE' => undef,
			'KW_OR' => 101,
			'KW_DIV' => 110,
			'KW_BOR' => 109,
			'MULTIPLY' => 107,
			'KW_BSR' => 112,
			'GTE' => undef,
			'KW_AND' => 111,
			'ADD' => 114,
			'KW_BAND' => 90,
			'GT' => undef,
			'STRICTLY_NOT_EQUAL' => undef,
			'LISTADD' => 91,
			'STRICTLY_EQUAL' => undef,
			'KW_BXOR' => 85,
			'KW_BSL' => 92,
			'KW_XOR' => 93,
			'SUBTRACT' => 97,
			'LT' => undef,
			'DIVIDE' => 98,
			'EQUAL' => undef
		},
		DEFAULT => -27
	},
	{#State 173
		ACTIONS => {
			'KW_REM' => 102,
			'KW_DIV' => 110,
			'MULTIPLY' => 107,
			'KW_AND' => 111,
			'KW_BAND' => 90,
			'DIVIDE' => 98
		},
		DEFAULT => -52
	},
	{#State 174
		DEFAULT => -48
	},
	{#State 175
		ACTIONS => {
			'KW_DIV' => 110,
			'KW_BOR' => 109,
			'MULTIPLY' => 107,
			'LISTSUBTRACT' => 104,
			'NOT_EQUAL' => undef,
			'KW_REM' => 102,
			'LTE' => undef,
			'KW_OR' => 101,
			'ADD' => 114,
			'KW_BSR' => 112,
			'GTE' => undef,
			'KW_AND' => 111,
			'KW_BSL' => 92,
			'KW_XOR' => 93,
			'KW_BAND' => 90,
			'STRICTLY_NOT_EQUAL' => undef,
			'GT' => undef,
			'LISTADD' => 91,
			'STRICTLY_EQUAL' => undef,
			'KW_BXOR' => 85,
			'DIVIDE' => 98,
			'EQUAL' => undef,
			'SUBTRACT' => 97,
			'LT' => undef
		},
		DEFAULT => -41
	},
	{#State 176
		ACTIONS => {
			'DIVIDE' => 98,
			'SUBTRACT' => 97,
			'KW_XOR' => 93,
			'KW_BSL' => 92,
			'KW_BXOR' => 85,
			'LISTADD' => 91,
			'KW_BAND' => 90,
			'ADD' => 114,
			'KW_AND' => 111,
			'KW_BSR' => 112,
			'MULTIPLY' => 107,
			'KW_BOR' => 109,
			'KW_DIV' => 110,
			'KW_OR' => 101,
			'LISTSUBTRACT' => 104,
			'KW_REM' => 102
		},
		DEFAULT => -37
	},
	{#State 177
		ACTIONS => {
			'KW_BSL' => 92,
			'KW_XOR' => 93,
			'STRICTLY_EQUAL' => 86,
			'KW_BXOR' => 85,
			'KW_BAND' => 90,
			'STRICTLY_NOT_EQUAL' => 87,
			'GT' => 89,
			'LISTADD' => 91,
			'DIVIDE' => 98,
			'EQUAL' => 99,
			'LT' => 94,
			'SUBTRACT' => 97,
			'MULTIPLY' => 107,
			'KW_DIV' => 110,
			'KW_BOR' => 109,
			'LTE' => 100,
			'KW_OR' => 101,
			'KW_REM' => 102,
			'LISTSUBTRACT' => 104,
			'NOT_EQUAL' => 103,
			'ADD' => 114,
			'KW_AND' => 111,
			'KW_BSR' => 112,
			'GTE' => 113
		},
		DEFAULT => -49
	},
	{#State 178
		ACTIONS => {
			'ADD' => 114,
			'KW_AND' => 111,
			'GTE' => 113,
			'KW_BSR' => 112,
			'MULTIPLY' => 107,
			'KW_DIV' => 110,
			'KW_BOR' => 109,
			'LDARROW' => undef,
			'KW_OR' => 101,
			'LTE' => 100,
			'LARROW' => undef,
			'KW_ANDALSO' => 105,
			'KW_REM' => 102,
			'LISTSUBTRACT' => 104,
			'NOT_EQUAL' => 103,
			'EQUAL' => 99,
			'DIVIDE' => 98,
			'LT' => 94,
			'SEND' => 96,
			'SUBTRACT' => 97,
			'KW_ORELSE' => 95,
			'KW_XOR' => 93,
			'KW_BSL' => 92,
			'STRICTLY_EQUAL' => 86,
			'KW_BXOR' => 85,
			'LISTADD' => 91,
			'KW_BAND' => 90,
			'GT' => 89,
			'STRICTLY_NOT_EQUAL' => 87,
			'MATCH' => 88
		},
		DEFAULT => -58
	},
	{#State 179
		DEFAULT => -32
	},
	{#State 180
		ACTIONS => {
			'STRICTLY_NOT_EQUAL' => 87,
			'GT' => 89,
			'MATCH' => 88,
			'KW_BAND' => 90,
			'LISTADD' => 91,
			'KW_BXOR' => 85,
			'STRICTLY_EQUAL' => 86,
			'KW_BSL' => 92,
			'KW_XOR' => 93,
			'KW_ORELSE' => 95,
			'SEND' => 96,
			'SUBTRACT' => 97,
			'LT' => 94,
			'DIVIDE' => 98,
			'EQUAL' => 99,
			'KW_REM' => 102,
			'LISTSUBTRACT' => 104,
			'NOT_EQUAL' => 103,
			'KW_ANDALSO' => 105,
			'LARROW' => undef,
			'LTE' => 100,
			'KW_OR' => 101,
			'LDARROW' => undef,
			'KW_BOR' => 109,
			'KW_DIV' => 110,
			'MULTIPLY' => 107,
			'KW_BSR' => 112,
			'GTE' => 113,
			'KW_AND' => 111,
			'ADD' => 114
		},
		DEFAULT => -59
	},
	{#State 181
		ACTIONS => {
			'KW_BAND' => 90,
			'DIVIDE' => 98,
			'KW_REM' => 102,
			'MULTIPLY' => 107,
			'KW_DIV' => 110,
			'KW_AND' => 111
		},
		DEFAULT => -44
	},
	{#State 182
		DEFAULT => -31
	},
	{#State 183
		DEFAULT => -51
	},
	{#State 184
		ACTIONS => {
			'DIVIDE' => 98,
			'KW_BAND' => 90,
			'KW_AND' => 111,
			'KW_DIV' => 110,
			'MULTIPLY' => 107,
			'KW_REM' => 102
		},
		DEFAULT => -43
	},
	{#State 185
		ACTIONS => {
			'SUBTRACT' => 97,
			'LT' => undef,
			'EQUAL' => undef,
			'DIVIDE' => 98,
			'LISTADD' => 91,
			'STRICTLY_NOT_EQUAL' => undef,
			'GT' => undef,
			'KW_BAND' => 90,
			'KW_BXOR' => 85,
			'STRICTLY_EQUAL' => undef,
			'KW_XOR' => 93,
			'KW_BSL' => 92,
			'GTE' => undef,
			'KW_BSR' => 112,
			'KW_AND' => 111,
			'ADD' => 114,
			'KW_REM' => 102,
			'NOT_EQUAL' => undef,
			'LISTSUBTRACT' => 104,
			'KW_OR' => 101,
			'LTE' => undef,
			'KW_BOR' => 109,
			'KW_DIV' => 110,
			'MULTIPLY' => 107
		},
		DEFAULT => -29
	},
	{#State 186
		ACTIONS => {
			'KW_BAND' => 90,
			'DIVIDE' => 98,
			'MULTIPLY' => 107,
			'KW_DIV' => 110,
			'KW_REM' => 102,
			'KW_AND' => 111
		},
		DEFAULT => -33
	},
	{#State 187
		ACTIONS => {
			'DIVIDE' => 220
		},
		DEFAULT => -116,
		GOTOS => {
			'optbinaryqualifier' => 221
		}
	},
	{#State 188
		ACTIONS => {
			'FLOAT' => 58,
			'VARIABLE' => 21,
			'INTEGER' => 48,
			'LISTOPEN' => 121,
			'LITERAL' => 34,
			'ATOM' => 22,
			'OPENRECORD' => 60,
			'STRING' => 57,
			'TUPLEOPEN' => 42,
			'BASE_INTEGER' => 27,
			'MACRO' => 53
		},
		GOTOS => {
			'atom' => 49,
			'list' => 39,
			'newrecord' => 28,
			'tuple' => 51,
			'string' => 16,
			'immexpr' => 222,
			'variable' => 31,
			'macro' => 30
		}
	},
	{#State 189
		ACTIONS => {
			'KW_BNOT' => 23,
			'KW_CASE' => 50,
			'KW_IF' => 25,
			'BASE_INTEGER' => 27,
			'MACRO' => 53,
			'SUBTRACT' => 54,
			'KW_RECEIVE' => 55,
			'KW_CATCH' => 56,
			'ADD' => 32,
			'STRING' => 57,
			'FLOAT' => 58,
			'LISTOPEN' => 59,
			'LITERAL' => 34,
			'OPENRECORD' => 60,
			'OPENBINARY' => 38,
			'KW_TRY' => 41,
			'TUPLEOPEN' => 42,
			'KW_NOT' => 45,
			'KW_FUN' => 19,
			'LPAREN' => 47,
			'KW_BEGIN' => 20,
			'INTEGER' => 48,
			'VARIABLE' => 21,
			'ATOM' => 22
		},
		DEFAULT => -12,
		GOTOS => {
			'comprehension' => 46,
			'fun' => 14,
			'try' => 15,
			'list' => 39,
			'funlocal' => 13,
			'call' => 37,
			'intcall' => 44,
			'extcall' => 18,
			'immexpr' => 40,
			'string' => 16,
			'binary' => 17,
			'if' => 43,
			'variable' => 31,
			'parenorimm' => 29,
			'macro' => 30,
			'case' => 36,
			'receive' => 61,
			'expr' => 35,
			'parenexpr' => 33,
			'stmtlist' => 26,
			'atom' => 49,
			'exprlist' => 223,
			'unparenexpr' => 52,
			'newrecord' => 28,
			'tuple' => 51
		}
	},
	{#State 190
		DEFAULT => -108
	},
	{#State 191
		ACTIONS => {
			'BASE_INTEGER' => 27,
			'MACRO' => 53,
			'TUPLEOPEN' => 42,
			'INTEGER' => 48,
			'VARIABLE' => 21,
			'LISTOPEN' => 121,
			'OPENRECORD' => 60,
			'ATOM' => 22,
			'LITERAL' => 34,
			'FLOAT' => 58,
			'LPAREN' => 47,
			'STRING' => 57
		},
		GOTOS => {
			'newrecord' => 28,
			'binaryexpr' => 224,
			'tuple' => 51,
			'immexpr' => 123,
			'string' => 16,
			'atom' => 49,
			'list' => 39,
			'parenexpr' => 116,
			'variable' => 31,
			'parenorimm' => 115,
			'macro' => 30
		}
	},
	{#State 192
		ACTIONS => {
			'KW_CATCH' => 225
		},
		DEFAULT => -126,
		GOTOS => {
			'opttrycatch' => 226
		}
	},
	{#State 193
		ACTIONS => {
			'KW_RECEIVE' => 55,
			'STRING' => 57,
			'ADD' => 32,
			'KW_CATCH' => 56,
			'FLOAT' => 58,
			'OPENRECORD' => 60,
			'LITERAL' => 34,
			'LISTOPEN' => 59,
			'KW_CASE' => 50,
			'KW_BNOT' => 23,
			'KW_IF' => 25,
			'MACRO' => 53,
			'SUBTRACT' => 54,
			'BASE_INTEGER' => 27,
			'KW_NOT' => 45,
			'KW_BEGIN' => 20,
			'KW_FUN' => 19,
			'LPAREN' => 47,
			'ATOM' => 22,
			'INTEGER' => 48,
			'VARIABLE' => 21,
			'OPENBINARY' => 38,
			'TUPLEOPEN' => 42,
			'KW_TRY' => 41
		},
		GOTOS => {
			'tuple' => 51,
			'unparenexpr' => 52,
			'newrecord' => 28,
			'altlist' => 227,
			'atom' => 49,
			'case' => 36,
			'receive' => 61,
			'parenexpr' => 33,
			'expr' => 132,
			'parenorimm' => 29,
			'macro' => 30,
			'variable' => 31,
			'string' => 16,
			'immexpr' => 40,
			'if' => 43,
			'binary' => 17,
			'intcall' => 44,
			'extcall' => 18,
			'list' => 39,
			'call' => 37,
			'funlocal' => 13,
			'fun' => 14,
			'try' => 15,
			'alt' => 130,
			'comprehension' => 46
		}
	},
	{#State 194
		DEFAULT => -93
	},
	{#State 195
		DEFAULT => -61
	},
	{#State 196
		ACTIONS => {
			'KW_NOT' => 45,
			'KW_BEGIN' => 20,
			'KW_FUN' => 19,
			'LPAREN' => 47,
			'ATOM' => 22,
			'INTEGER' => 48,
			'VARIABLE' => 21,
			'OPENBINARY' => 38,
			'TUPLEOPEN' => 42,
			'KW_TRY' => 41,
			'KW_RECEIVE' => 55,
			'STRING' => 57,
			'ADD' => 32,
			'KW_CATCH' => 56,
			'FLOAT' => 58,
			'OPENRECORD' => 60,
			'LITERAL' => 34,
			'LISTOPEN' => 59,
			'KW_CASE' => 50,
			'KW_BNOT' => 23,
			'KW_IF' => 25,
			'SUBTRACT' => 54,
			'MACRO' => 53,
			'BASE_INTEGER' => 27
		},
		GOTOS => {
			'tuple' => 51,
			'unparenexpr' => 52,
			'newrecord' => 28,
			'atom' => 49,
			'altlist' => 228,
			'receive' => 61,
			'parenexpr' => 33,
			'case' => 36,
			'expr' => 132,
			'parenorimm' => 29,
			'macro' => 30,
			'variable' => 31,
			'string' => 16,
			'immexpr' => 40,
			'if' => 43,
			'binary' => 17,
			'intcall' => 44,
			'extcall' => 18,
			'funlocal' => 13,
			'list' => 39,
			'call' => 37,
			'fun' => 14,
			'try' => 15,
			'alt' => 130,
			'comprehension' => 46
		}
	},
	{#State 197
		ACTIONS => {
			'KW_END' => 229
		}
	},
	{#State 198
		ACTIONS => {
			'KW_RECEIVE' => 55,
			'ADD' => 32,
			'STRING' => 57,
			'KW_CATCH' => 56,
			'FLOAT' => 58,
			'OPENRECORD' => 60,
			'LITERAL' => 34,
			'LISTOPEN' => 59,
			'KW_CASE' => 50,
			'KW_BNOT' => 23,
			'KW_IF' => 25,
			'MACRO' => 53,
			'SUBTRACT' => 54,
			'BASE_INTEGER' => 27,
			'KW_NOT' => 45,
			'KW_BEGIN' => 20,
			'LPAREN' => 47,
			'KW_FUN' => 19,
			'ATOM' => 22,
			'VARIABLE' => 21,
			'INTEGER' => 48,
			'OPENBINARY' => 38,
			'TUPLEOPEN' => 42,
			'KW_TRY' => 41
		},
		GOTOS => {
			'macro' => 30,
			'parenorimm' => 29,
			'variable' => 31,
			'case' => 36,
			'receive' => 61,
			'expr' => 230,
			'parenexpr' => 33,
			'atom' => 49,
			'tuple' => 51,
			'unparenexpr' => 52,
			'newrecord' => 28,
			'comprehension' => 46,
			'call' => 37,
			'funlocal' => 13,
			'list' => 39,
			'fun' => 14,
			'try' => 15,
			'immexpr' => 40,
			'string' => 16,
			'binary' => 17,
			'if' => 43,
			'intcall' => 44,
			'extcall' => 18
		}
	},
	{#State 199
		ACTIONS => {
			'BASE_INTEGER' => 27,
			'MACRO' => 53,
			'SUBTRACT' => 54,
			'KW_BNOT' => 23,
			'KW_CASE' => 50,
			'KW_IF' => 25,
			'FLOAT' => 58,
			'LISTOPEN' => 59,
			'OPENRECORD' => 60,
			'LITERAL' => 34,
			'KW_RECEIVE' => 55,
			'KW_CATCH' => 56,
			'ADD' => 32,
			'STRING' => 57,
			'KW_TRY' => 41,
			'TUPLEOPEN' => 42,
			'OPENBINARY' => 38,
			'VARIABLE' => 21,
			'INTEGER' => 48,
			'ATOM' => 22,
			'KW_NOT' => 45,
			'KW_FUN' => 19,
			'LPAREN' => 47,
			'KW_BEGIN' => 20
		},
		GOTOS => {
			'fun' => 14,
			'try' => 15,
			'funlocal' => 13,
			'call' => 37,
			'list' => 39,
			'intcall' => 44,
			'extcall' => 18,
			'string' => 16,
			'immexpr' => 40,
			'if' => 43,
			'binary' => 17,
			'comprehension' => 46,
			'alt' => 231,
			'atom' => 49,
			'unparenexpr' => 52,
			'newrecord' => 28,
			'tuple' => 51,
			'variable' => 31,
			'macro' => 30,
			'parenorimm' => 29,
			'case' => 36,
			'expr' => 132,
			'receive' => 61,
			'parenexpr' => 33
		}
	},
	{#State 200
		ACTIONS => {
			'COMMA' => 214,
			'SEMICOLON' => 213,
			'RARROW' => 232
		}
	},
	{#State 201
		ACTIONS => {
			'KW_RECEIVE' => 55,
			'KW_CATCH' => 56,
			'ADD' => 32,
			'STRING' => 57,
			'FLOAT' => 58,
			'LISTOPEN' => 59,
			'LITERAL' => 34,
			'OPENRECORD' => 60,
			'KW_BNOT' => 23,
			'KW_CASE' => 50,
			'KW_IF' => 25,
			'BASE_INTEGER' => 27,
			'SUBTRACT' => 54,
			'MACRO' => 53,
			'KW_NOT' => 45,
			'KW_FUN' => 19,
			'LPAREN' => 47,
			'KW_BEGIN' => 20,
			'VARIABLE' => 21,
			'INTEGER' => 48,
			'ATOM' => 22,
			'OPENBINARY' => 38,
			'KW_TRY' => 41,
			'TUPLEOPEN' => 42
		},
		GOTOS => {
			'comprehension' => 46,
			'try' => 15,
			'fun' => 14,
			'funlocal' => 13,
			'list' => 39,
			'call' => 37,
			'extcall' => 18,
			'intcall' => 44,
			'binary' => 17,
			'if' => 43,
			'string' => 16,
			'immexpr' => 40,
			'variable' => 31,
			'macro' => 30,
			'parenorimm' => 29,
			'parenexpr' => 33,
			'expr' => 233,
			'case' => 36,
			'receive' => 61,
			'atom' => 49,
			'newrecord' => 28,
			'unparenexpr' => 52,
			'tuple' => 51
		}
	},
	{#State 202
		ACTIONS => {
			'LISTCLOSE' => 234
		}
	},
	{#State 203
		ACTIONS => {
			'LPAREN' => 47,
			'KW_FUN' => 19,
			'KW_BEGIN' => 20,
			'KW_NOT' => 45,
			'VARIABLE' => 21,
			'INTEGER' => 48,
			'ATOM' => 22,
			'OPENBINARY' => 38,
			'KW_TRY' => 41,
			'TUPLEOPEN' => 42,
			'KW_CATCH' => 56,
			'STRING' => 57,
			'ADD' => 32,
			'KW_RECEIVE' => 55,
			'LISTOPEN' => 59,
			'LITERAL' => 34,
			'OPENRECORD' => 60,
			'FLOAT' => 58,
			'KW_IF' => 25,
			'KW_BNOT' => 23,
			'KW_CASE' => 50,
			'BASE_INTEGER' => 27,
			'SUBTRACT' => 54,
			'MACRO' => 53
		},
		DEFAULT => -12,
		GOTOS => {
			'variable' => 31,
			'macro' => 30,
			'parenorimm' => 29,
			'expr' => 35,
			'case' => 36,
			'receive' => 61,
			'parenexpr' => 33,
			'stmtlist' => 26,
			'exprlist' => 235,
			'atom' => 49,
			'unparenexpr' => 52,
			'newrecord' => 28,
			'tuple' => 51,
			'comprehension' => 46,
			'fun' => 14,
			'try' => 15,
			'list' => 39,
			'funlocal' => 13,
			'call' => 37,
			'intcall' => 44,
			'extcall' => 18,
			'string' => 16,
			'immexpr' => 40,
			'binary' => 17,
			'if' => 43
		}
	},
	{#State 204
		ACTIONS => {
			'KW_TRY' => 41,
			'TUPLEOPEN' => 42,
			'OPENBINARY' => 38,
			'VARIABLE' => 21,
			'INTEGER' => 48,
			'ATOM' => 22,
			'KW_NOT' => 45,
			'LPAREN' => 47,
			'KW_FUN' => 19,
			'KW_BEGIN' => 20,
			'BASE_INTEGER' => 27,
			'MACRO' => 53,
			'SUBTRACT' => 54,
			'KW_BNOT' => 23,
			'KW_CASE' => 50,
			'KW_IF' => 25,
			'FLOAT' => 58,
			'LISTOPEN' => 59,
			'LITERAL' => 34,
			'OPENRECORD' => 60,
			'KW_RECEIVE' => 55,
			'KW_CATCH' => 56,
			'ADD' => 32,
			'STRING' => 57
		},
		DEFAULT => -12,
		GOTOS => {
			'try' => 15,
			'fun' => 14,
			'funlocal' => 13,
			'list' => 39,
			'call' => 37,
			'extcall' => 18,
			'intcall' => 44,
			'if' => 43,
			'binary' => 17,
			'string' => 16,
			'immexpr' => 40,
			'comprehension' => 46,
			'stmtlist' => 26,
			'atom' => 49,
			'exprlist' => 236,
			'newrecord' => 28,
			'unparenexpr' => 52,
			'tuple' => 51,
			'variable' => 31,
			'macro' => 30,
			'parenorimm' => 29,
			'case' => 36,
			'receive' => 61,
			'expr' => 35,
			'parenexpr' => 33
		}
	},
	{#State 205
		DEFAULT => -3
	},
	{#State 206
		DEFAULT => -105
	},
	{#State 207
		ACTIONS => {
			'DIVIDE' => 237
		}
	},
	{#State 208
		ACTIONS => {
			'DIVIDE' => 238
		}
	},
	{#State 209
		DEFAULT => -102
	},
	{#State 210
		ACTIONS => {
			'DIVIDE' => 239
		}
	},
	{#State 211
		ACTIONS => {
			'KW_WHEN' => 147
		},
		DEFAULT => -8,
		GOTOS => {
			'whenlist' => 240
		}
	},
	{#State 212
		ACTIONS => {
			'OPENBINARY' => 38,
			'KW_TRY' => 41,
			'TUPLEOPEN' => 42,
			'KW_FUN' => 19,
			'LPAREN' => 47,
			'KW_BEGIN' => 20,
			'KW_NOT' => 45,
			'INTEGER' => 48,
			'VARIABLE' => 21,
			'ATOM' => 22,
			'KW_IF' => 25,
			'KW_BNOT' => 23,
			'KW_CASE' => 50,
			'BASE_INTEGER' => 27,
			'MACRO' => 53,
			'SUBTRACT' => 54,
			'KW_CATCH' => 56,
			'ADD' => 32,
			'STRING' => 57,
			'KW_RECEIVE' => 55,
			'LISTOPEN' => 59,
			'OPENRECORD' => 60,
			'LITERAL' => 34,
			'FLOAT' => 58
		},
		GOTOS => {
			'case' => 36,
			'receive' => 61,
			'parenexpr' => 33,
			'expr' => 35,
			'variable' => 31,
			'macro' => 30,
			'parenorimm' => 29,
			'newrecord' => 28,
			'unparenexpr' => 52,
			'tuple' => 51,
			'stmtlist' => 241,
			'atom' => 49,
			'comprehension' => 46,
			'extcall' => 18,
			'intcall' => 44,
			'binary' => 17,
			'if' => 43,
			'string' => 16,
			'immexpr' => 40,
			'try' => 15,
			'fun' => 14,
			'list' => 39,
			'funlocal' => 13,
			'call' => 37
		}
	},
	{#State 213
		ACTIONS => {
			'FLOAT' => 58,
			'LISTOPEN' => 59,
			'LITERAL' => 34,
			'OPENRECORD' => 60,
			'KW_RECEIVE' => 55,
			'KW_CATCH' => 56,
			'ADD' => 32,
			'STRING' => 57,
			'BASE_INTEGER' => 27,
			'SUBTRACT' => 54,
			'MACRO' => 53,
			'KW_BNOT' => 23,
			'KW_CASE' => 50,
			'KW_IF' => 25,
			'INTEGER' => 48,
			'VARIABLE' => 21,
			'ATOM' => 22,
			'KW_NOT' => 45,
			'KW_FUN' => 19,
			'LPAREN' => 47,
			'KW_BEGIN' => 20,
			'KW_TRY' => 41,
			'TUPLEOPEN' => 42,
			'OPENBINARY' => 38
		},
		GOTOS => {
			'receive' => 61,
			'case' => 36,
			'expr' => 242,
			'parenexpr' => 33,
			'variable' => 31,
			'macro' => 30,
			'parenorimm' => 29,
			'newrecord' => 28,
			'unparenexpr' => 52,
			'tuple' => 51,
			'atom' => 49,
			'comprehension' => 46,
			'extcall' => 18,
			'intcall' => 44,
			'binary' => 17,
			'if' => 43,
			'immexpr' => 40,
			'string' => 16,
			'try' => 15,
			'fun' => 14,
			'funlocal' => 13,
			'list' => 39,
			'call' => 37
		}
	},
	{#State 214
		ACTIONS => {
			'INTEGER' => 48,
			'VARIABLE' => 21,
			'ATOM' => 22,
			'KW_NOT' => 45,
			'KW_FUN' => 19,
			'LPAREN' => 47,
			'KW_BEGIN' => 20,
			'KW_TRY' => 41,
			'TUPLEOPEN' => 42,
			'OPENBINARY' => 38,
			'FLOAT' => 58,
			'LISTOPEN' => 59,
			'OPENRECORD' => 60,
			'LITERAL' => 34,
			'KW_RECEIVE' => 55,
			'KW_CATCH' => 56,
			'STRING' => 57,
			'ADD' => 32,
			'BASE_INTEGER' => 27,
			'SUBTRACT' => 54,
			'MACRO' => 53,
			'KW_BNOT' => 23,
			'KW_CASE' => 50,
			'KW_IF' => 25
		},
		GOTOS => {
			'comprehension' => 46,
			'extcall' => 18,
			'intcall' => 44,
			'binary' => 17,
			'if' => 43,
			'immexpr' => 40,
			'string' => 16,
			'try' => 15,
			'fun' => 14,
			'call' => 37,
			'list' => 39,
			'funlocal' => 13,
			'receive' => 61,
			'parenexpr' => 33,
			'expr' => 243,
			'case' => 36,
			'variable' => 31,
			'macro' => 30,
			'parenorimm' => 29,
			'newrecord' => 28,
			'unparenexpr' => 52,
			'tuple' => 51,
			'atom' => 49
		}
	},
	{#State 215
		ACTIONS => {
			'KW_BXOR' => 85,
			'STRICTLY_EQUAL' => 86,
			'GT' => 89,
			'STRICTLY_NOT_EQUAL' => 87,
			'MATCH' => 88,
			'KW_BAND' => 90,
			'LISTADD' => 91,
			'KW_BSL' => 92,
			'KW_XOR' => 93,
			'LT' => 94,
			'KW_ORELSE' => 95,
			'SUBTRACT' => 97,
			'SEND' => 96,
			'DIVIDE' => 98,
			'EQUAL' => 99,
			'LTE' => 100,
			'KW_OR' => 101,
			'LISTSUBTRACT' => 104,
			'KW_REM' => 102,
			'NOT_EQUAL' => 103,
			'KW_ANDALSO' => 105,
			'LARROW' => 106,
			'MULTIPLY' => 107,
			'LDARROW' => 108,
			'KW_BOR' => 109,
			'KW_DIV' => 110,
			'KW_AND' => 111,
			'KW_BSR' => 112,
			'GTE' => 113,
			'ADD' => 114
		},
		DEFAULT => -9
	},
	{#State 216
		DEFAULT => -137
	},
	{#State 217
		ACTIONS => {
			'COMMA' => 79
		},
		DEFAULT => -138
	},
	{#State 218
		ACTIONS => {
			'KW_XOR' => 93,
			'KW_BSL' => 92,
			'LISTADD' => 91,
			'KW_BAND' => 90,
			'GT' => 89,
			'STRICTLY_NOT_EQUAL' => 87,
			'MATCH' => 88,
			'STRICTLY_EQUAL' => 86,
			'KW_BXOR' => 85,
			'EQUAL' => 99,
			'DIVIDE' => 98,
			'SEND' => 96,
			'SUBTRACT' => 97,
			'KW_ORELSE' => 95,
			'LT' => 94,
			'KW_DIV' => 110,
			'KW_BOR' => 109,
			'LDARROW' => 108,
			'MULTIPLY' => 107,
			'LARROW' => 106,
			'KW_ANDALSO' => 105,
			'KW_REM' => 102,
			'NOT_EQUAL' => 103,
			'LISTSUBTRACT' => 104,
			'KW_OR' => 101,
			'LTE' => 100,
			'ADD' => 114,
			'GTE' => 113,
			'KW_BSR' => 112,
			'KW_AND' => 111
		},
		DEFAULT => -140
	},
	{#State 219
		DEFAULT => -86
	},
	{#State 220
		ACTIONS => {
			'ATOM' => 245
		},
		GOTOS => {
			'binaryqualifier' => 244
		}
	},
	{#State 221
		DEFAULT => -113
	},
	{#State 222
		DEFAULT => -115
	},
	{#State 223
		ACTIONS => {
			'CLOSEBINARY' => 246
		}
	},
	{#State 224
		DEFAULT => -112
	},
	{#State 225
		ACTIONS => {
			'OPENBINARY' => 38,
			'TUPLEOPEN' => 42,
			'KW_TRY' => 41,
			'KW_NOT' => 45,
			'KW_BEGIN' => 20,
			'LPAREN' => 47,
			'KW_FUN' => 19,
			'ATOM' => 250,
			'VARIABLE' => 249,
			'INTEGER' => 48,
			'KW_CASE' => 50,
			'KW_BNOT' => 23,
			'KW_IF' => 25,
			'SUBTRACT' => 54,
			'MACRO' => 53,
			'BASE_INTEGER' => 27,
			'KW_RECEIVE' => 55,
			'STRING' => 57,
			'ADD' => 32,
			'KW_CATCH' => 56,
			'FLOAT' => 58,
			'OPENRECORD' => 60,
			'LITERAL' => 34,
			'LISTOPEN' => 59
		},
		GOTOS => {
			'expr' => 251,
			'case' => 36,
			'parenexpr' => 33,
			'receive' => 61,
			'catchalt' => 248,
			'variable' => 31,
			'parenorimm' => 29,
			'macro' => 30,
			'unparenexpr' => 52,
			'newrecord' => 28,
			'tuple' => 51,
			'atom' => 49,
			'comprehension' => 46,
			'intcall' => 44,
			'extcall' => 18,
			'immexpr' => 40,
			'string' => 16,
			'catchaltlist' => 247,
			'binary' => 17,
			'if' => 43,
			'fun' => 14,
			'try' => 15,
			'call' => 37,
			'list' => 39,
			'funlocal' => 13
		}
	},
	{#State 226
		ACTIONS => {
			'KW_AFTER' => 253
		},
		DEFAULT => -128,
		GOTOS => {
			'opttryafter' => 252
		}
	},
	{#State 227
		ACTIONS => {
			'SEMICOLON' => 199
		},
		DEFAULT => -125
	},
	{#State 228
		ACTIONS => {
			'KW_END' => 254,
			'SEMICOLON' => 199
		}
	},
	{#State 229
		DEFAULT => -120
	},
	{#State 230
		ACTIONS => {
			'RARROW' => 255,
			'MULTIPLY' => 107,
			'KW_XOR' => 93,
			'KW_DIV' => 110,
			'KW_BOR' => 109,
			'KW_BSL' => 92,
			'LDARROW' => 108,
			'KW_OR' => 101,
			'STRICTLY_EQUAL' => 86,
			'LTE' => 100,
			'KW_BXOR' => 85,
			'LARROW' => 106,
			'LISTADD' => 91,
			'KW_ANDALSO' => 105,
			'KW_BAND' => 90,
			'KW_REM' => 102,
			'NOT_EQUAL' => 103,
			'LISTSUBTRACT' => 104,
			'GT' => 89,
			'MATCH' => 88,
			'STRICTLY_NOT_EQUAL' => 87,
			'ADD' => 114,
			'EQUAL' => 99,
			'DIVIDE' => 98,
			'LT' => 94,
			'KW_AND' => 111,
			'SUBTRACT' => 97,
			'SEND' => 96,
			'GTE' => 113,
			'KW_ORELSE' => 95,
			'KW_BSR' => 112
		}
	},
	{#State 231
		DEFAULT => -96
	},
	{#State 232
		ACTIONS => {
			'FLOAT' => 58,
			'LISTOPEN' => 59,
			'LITERAL' => 34,
			'OPENRECORD' => 60,
			'KW_RECEIVE' => 55,
			'KW_CATCH' => 56,
			'ADD' => 32,
			'STRING' => 57,
			'BASE_INTEGER' => 27,
			'MACRO' => 53,
			'SUBTRACT' => 54,
			'KW_BNOT' => 23,
			'KW_CASE' => 50,
			'KW_IF' => 25,
			'VARIABLE' => 21,
			'INTEGER' => 48,
			'ATOM' => 22,
			'KW_NOT' => 45,
			'LPAREN' => 47,
			'KW_FUN' => 19,
			'KW_BEGIN' => 20,
			'KW_TRY' => 41,
			'TUPLEOPEN' => 42,
			'OPENBINARY' => 38
		},
		GOTOS => {
			'atom' => 49,
			'stmtlist' => 256,
			'tuple' => 51,
			'newrecord' => 28,
			'unparenexpr' => 52,
			'parenorimm' => 29,
			'macro' => 30,
			'variable' => 31,
			'case' => 36,
			'receive' => 61,
			'parenexpr' => 33,
			'expr' => 35,
			'funlocal' => 13,
			'list' => 39,
			'call' => 37,
			'try' => 15,
			'fun' => 14,
			'binary' => 17,
			'if' => 43,
			'immexpr' => 40,
			'string' => 16,
			'extcall' => 18,
			'intcall' => 44,
			'comprehension' => 46
		}
	},
	{#State 233
		ACTIONS => {
			'KW_ANDALSO' => 105,
			'LARROW' => 106,
			'KW_REM' => 102,
			'LISTSUBTRACT' => 104,
			'NOT_EQUAL' => 103,
			'KW_OR' => 101,
			'LTE' => 100,
			'KW_BOR' => 109,
			'KW_DIV' => 110,
			'LDARROW' => 108,
			'MULTIPLY' => 107,
			'GTE' => 113,
			'KW_BSR' => 112,
			'KW_AND' => 111,
			'ADD' => 114,
			'LISTADD' => 91,
			'MATCH' => 88,
			'GT' => 89,
			'STRICTLY_NOT_EQUAL' => 87,
			'KW_BAND' => 90,
			'KW_BXOR' => 85,
			'STRICTLY_EQUAL' => 86,
			'KW_XOR' => 93,
			'KW_BSL' => 92,
			'SEND' => 96,
			'SUBTRACT' => 97,
			'KW_ORELSE' => 95,
			'LT' => 94,
			'EQUAL' => 99,
			'DIVIDE' => 98
		},
		DEFAULT => -90
	},
	{#State 234
		DEFAULT => -88
	},
	{#State 235
		ACTIONS => {
			'LISTCLOSE' => 257
		}
	},
	{#State 236
		ACTIONS => {
			'TUPLECLOSE' => 258
		}
	},
	{#State 237
		ACTIONS => {
			'INTEGER' => 259
		}
	},
	{#State 238
		ACTIONS => {
			'INTEGER' => 260
		}
	},
	{#State 239
		ACTIONS => {
			'INTEGER' => 261
		}
	},
	{#State 240
		ACTIONS => {
			'COMMA' => 214,
			'SEMICOLON' => 213,
			'RARROW' => 262
		}
	},
	{#State 241
		ACTIONS => {
			'COMMA' => 79
		},
		DEFAULT => -7
	},
	{#State 242
		ACTIONS => {
			'KW_ANDALSO' => 105,
			'LARROW' => 106,
			'LISTSUBTRACT' => 104,
			'NOT_EQUAL' => 103,
			'KW_REM' => 102,
			'KW_OR' => 101,
			'LTE' => 100,
			'KW_BOR' => 109,
			'KW_DIV' => 110,
			'LDARROW' => 108,
			'MULTIPLY' => 107,
			'GTE' => 113,
			'KW_BSR' => 112,
			'KW_AND' => 111,
			'ADD' => 114,
			'LISTADD' => 91,
			'MATCH' => 88,
			'STRICTLY_NOT_EQUAL' => 87,
			'GT' => 89,
			'KW_BAND' => 90,
			'KW_BXOR' => 85,
			'STRICTLY_EQUAL' => 86,
			'KW_XOR' => 93,
			'KW_BSL' => 92,
			'SUBTRACT' => 97,
			'SEND' => 96,
			'KW_ORELSE' => 95,
			'LT' => 94,
			'EQUAL' => 99,
			'DIVIDE' => 98
		},
		DEFAULT => -11
	},
	{#State 243
		ACTIONS => {
			'ADD' => 114,
			'GTE' => 113,
			'KW_BSR' => 112,
			'KW_AND' => 111,
			'KW_BOR' => 109,
			'KW_DIV' => 110,
			'LDARROW' => 108,
			'MULTIPLY' => 107,
			'KW_ANDALSO' => 105,
			'LARROW' => 106,
			'KW_REM' => 102,
			'NOT_EQUAL' => 103,
			'LISTSUBTRACT' => 104,
			'KW_OR' => 101,
			'LTE' => 100,
			'EQUAL' => 99,
			'DIVIDE' => 98,
			'SEND' => 96,
			'SUBTRACT' => 97,
			'KW_ORELSE' => 95,
			'LT' => 94,
			'KW_XOR' => 93,
			'KW_BSL' => 92,
			'LISTADD' => 91,
			'GT' => 89,
			'MATCH' => 88,
			'STRICTLY_NOT_EQUAL' => 87,
			'KW_BAND' => 90,
			'KW_BXOR' => 85,
			'STRICTLY_EQUAL' => 86
		},
		DEFAULT => -10
	},
	{#State 244
		ACTIONS => {
			'SUBTRACT' => 263
		},
		DEFAULT => -117
	},
	{#State 245
		DEFAULT => -118
	},
	{#State 246
		DEFAULT => -92
	},
	{#State 247
		ACTIONS => {
			'SEMICOLON' => 264
		},
		DEFAULT => -127
	},
	{#State 248
		DEFAULT => -130
	},
	{#State 249
		ACTIONS => {
			'COLON' => 265
		},
		DEFAULT => -81
	},
	{#State 250
		ACTIONS => {
			'COLON' => 266
		},
		DEFAULT => -79
	},
	{#State 251
		ACTIONS => {
			'KW_ORELSE' => 95,
			'SUBTRACT' => 97,
			'SEND' => 96,
			'LT' => 94,
			'DIVIDE' => 98,
			'EQUAL' => 99,
			'KW_BAND' => 90,
			'GT' => 89,
			'STRICTLY_NOT_EQUAL' => 87,
			'MATCH' => 88,
			'LISTADD' => 91,
			'STRICTLY_EQUAL' => 86,
			'KW_BXOR' => 85,
			'KW_BSL' => 92,
			'KW_XOR' => 93,
			'KW_WHEN' => 147,
			'KW_BSR' => 112,
			'GTE' => 113,
			'KW_AND' => 111,
			'ADD' => 114,
			'KW_REM' => 102,
			'NOT_EQUAL' => 103,
			'LISTSUBTRACT' => 104,
			'LARROW' => 106,
			'KW_ANDALSO' => 105,
			'LTE' => 100,
			'KW_OR' => 101,
			'LDARROW' => 108,
			'KW_DIV' => 110,
			'KW_BOR' => 109,
			'MULTIPLY' => 107
		},
		DEFAULT => -8,
		GOTOS => {
			'whenlist' => 267
		}
	},
	{#State 252
		ACTIONS => {
			'KW_END' => 268
		}
	},
	{#State 253
		ACTIONS => {
			'KW_BEGIN' => 20,
			'KW_FUN' => 19,
			'LPAREN' => 47,
			'KW_NOT' => 45,
			'ATOM' => 22,
			'INTEGER' => 48,
			'VARIABLE' => 21,
			'OPENBINARY' => 38,
			'TUPLEOPEN' => 42,
			'KW_TRY' => 41,
			'ADD' => 32,
			'STRING' => 57,
			'KW_CATCH' => 56,
			'KW_RECEIVE' => 55,
			'OPENRECORD' => 60,
			'LITERAL' => 34,
			'LISTOPEN' => 59,
			'FLOAT' => 58,
			'KW_IF' => 25,
			'KW_CASE' => 50,
			'KW_BNOT' => 23,
			'SUBTRACT' => 54,
			'MACRO' => 53,
			'BASE_INTEGER' => 27
		},
		DEFAULT => -12,
		GOTOS => {
			'try' => 15,
			'fun' => 14,
			'list' => 39,
			'call' => 37,
			'funlocal' => 13,
			'extcall' => 18,
			'intcall' => 44,
			'if' => 43,
			'binary' => 17,
			'immexpr' => 40,
			'string' => 16,
			'comprehension' => 46,
			'stmtlist' => 26,
			'atom' => 49,
			'exprlist' => 269,
			'newrecord' => 28,
			'unparenexpr' => 52,
			'tuple' => 51,
			'variable' => 31,
			'parenorimm' => 29,
			'macro' => 30,
			'expr' => 35,
			'receive' => 61,
			'case' => 36,
			'parenexpr' => 33
		}
	},
	{#State 254
		DEFAULT => -94
	},
	{#State 255
		ACTIONS => {
			'VARIABLE' => 21,
			'INTEGER' => 48,
			'ATOM' => 22,
			'LPAREN' => 47,
			'KW_FUN' => 19,
			'KW_BEGIN' => 20,
			'KW_NOT' => 45,
			'KW_TRY' => 41,
			'TUPLEOPEN' => 42,
			'OPENBINARY' => 38,
			'LISTOPEN' => 59,
			'OPENRECORD' => 60,
			'LITERAL' => 34,
			'FLOAT' => 58,
			'KW_CATCH' => 56,
			'STRING' => 57,
			'ADD' => 32,
			'KW_RECEIVE' => 55,
			'BASE_INTEGER' => 27,
			'SUBTRACT' => 54,
			'MACRO' => 53,
			'KW_IF' => 25,
			'KW_BNOT' => 23,
			'KW_CASE' => 50
		},
		GOTOS => {
			'atom' => 49,
			'stmtlist' => 270,
			'tuple' => 51,
			'unparenexpr' => 52,
			'newrecord' => 28,
			'macro' => 30,
			'parenorimm' => 29,
			'variable' => 31,
			'case' => 36,
			'parenexpr' => 33,
			'expr' => 35,
			'receive' => 61,
			'funlocal' => 13,
			'call' => 37,
			'list' => 39,
			'fun' => 14,
			'try' => 15,
			'immexpr' => 40,
			'string' => 16,
			'binary' => 17,
			'if' => 43,
			'intcall' => 44,
			'extcall' => 18,
			'comprehension' => 46
		}
	},
	{#State 256
		ACTIONS => {
			'COMMA' => 79
		},
		DEFAULT => -97
	},
	{#State 257
		DEFAULT => -91
	},
	{#State 258
		DEFAULT => -107
	},
	{#State 259
		DEFAULT => -101
	},
	{#State 260
		DEFAULT => -100
	},
	{#State 261
		DEFAULT => -99
	},
	{#State 262
		ACTIONS => {
			'KW_RECEIVE' => 55,
			'STRING' => 57,
			'ADD' => 32,
			'KW_CATCH' => 56,
			'FLOAT' => 58,
			'LITERAL' => 34,
			'OPENRECORD' => 60,
			'LISTOPEN' => 59,
			'KW_CASE' => 50,
			'KW_BNOT' => 23,
			'KW_IF' => 25,
			'MACRO' => 53,
			'SUBTRACT' => 54,
			'BASE_INTEGER' => 27,
			'KW_NOT' => 45,
			'KW_BEGIN' => 20,
			'KW_FUN' => 19,
			'LPAREN' => 47,
			'ATOM' => 22,
			'VARIABLE' => 21,
			'INTEGER' => 48,
			'OPENBINARY' => 38,
			'TUPLEOPEN' => 42,
			'KW_TRY' => 41
		},
		GOTOS => {
			'tuple' => 51,
			'unparenexpr' => 52,
			'newrecord' => 28,
			'atom' => 49,
			'stmtlist' => 271,
			'case' => 36,
			'receive' => 61,
			'expr' => 35,
			'parenexpr' => 33,
			'macro' => 30,
			'parenorimm' => 29,
			'variable' => 31,
			'string' => 16,
			'immexpr' => 40,
			'binary' => 17,
			'if' => 43,
			'intcall' => 44,
			'extcall' => 18,
			'call' => 37,
			'funlocal' => 13,
			'list' => 39,
			'fun' => 14,
			'try' => 15,
			'comprehension' => 46
		}
	},
	{#State 263
		ACTIONS => {
			'ATOM' => 272
		}
	},
	{#State 264
		ACTIONS => {
			'SUBTRACT' => 54,
			'MACRO' => 53,
			'BASE_INTEGER' => 27,
			'KW_IF' => 25,
			'KW_CASE' => 50,
			'KW_BNOT' => 23,
			'LITERAL' => 34,
			'OPENRECORD' => 60,
			'LISTOPEN' => 59,
			'FLOAT' => 58,
			'STRING' => 57,
			'ADD' => 32,
			'KW_CATCH' => 56,
			'KW_RECEIVE' => 55,
			'TUPLEOPEN' => 42,
			'KW_TRY' => 41,
			'OPENBINARY' => 38,
			'ATOM' => 250,
			'VARIABLE' => 249,
			'INTEGER' => 48,
			'KW_BEGIN' => 20,
			'KW_FUN' => 19,
			'LPAREN' => 47,
			'KW_NOT' => 45
		},
		GOTOS => {
			'tuple' => 51,
			'unparenexpr' => 52,
			'newrecord' => 28,
			'atom' => 49,
			'catchalt' => 273,
			'expr' => 251,
			'receive' => 61,
			'parenexpr' => 33,
			'case' => 36,
			'macro' => 30,
			'parenorimm' => 29,
			'variable' => 31,
			'string' => 16,
			'immexpr' => 40,
			'if' => 43,
			'binary' => 17,
			'intcall' => 44,
			'extcall' => 18,
			'call' => 37,
			'funlocal' => 13,
			'list' => 39,
			'fun' => 14,
			'try' => 15,
			'comprehension' => 46
		}
	},
	{#State 265
		ACTIONS => {
			'OPENBINARY' => 38,
			'KW_TRY' => 41,
			'TUPLEOPEN' => 42,
			'KW_NOT' => 45,
			'LPAREN' => 47,
			'KW_FUN' => 19,
			'KW_BEGIN' => 20,
			'INTEGER' => 48,
			'VARIABLE' => 21,
			'ATOM' => 22,
			'KW_BNOT' => 23,
			'KW_CASE' => 50,
			'KW_IF' => 25,
			'BASE_INTEGER' => 27,
			'SUBTRACT' => 54,
			'MACRO' => 53,
			'KW_RECEIVE' => 55,
			'KW_CATCH' => 56,
			'ADD' => 32,
			'STRING' => 57,
			'FLOAT' => 58,
			'LISTOPEN' => 59,
			'LITERAL' => 34,
			'OPENRECORD' => 60
		},
		GOTOS => {
			'receive' => 61,
			'case' => 36,
			'parenexpr' => 33,
			'expr' => 274,
			'variable' => 31,
			'parenorimm' => 29,
			'macro' => 30,
			'newrecord' => 28,
			'unparenexpr' => 52,
			'tuple' => 51,
			'atom' => 49,
			'comprehension' => 46,
			'extcall' => 18,
			'intcall' => 44,
			'if' => 43,
			'binary' => 17,
			'string' => 16,
			'immexpr' => 40,
			'try' => 15,
			'fun' => 14,
			'list' => 39,
			'funlocal' => 13,
			'call' => 37
		}
	},
	{#State 266
		ACTIONS => {
			'OPENBINARY' => 38,
			'KW_TRY' => 41,
			'TUPLEOPEN' => 42,
			'KW_NOT' => 45,
			'KW_FUN' => 19,
			'LPAREN' => 47,
			'KW_BEGIN' => 20,
			'VARIABLE' => 21,
			'INTEGER' => 48,
			'ATOM' => 22,
			'KW_BNOT' => 23,
			'KW_CASE' => 50,
			'KW_IF' => 25,
			'BASE_INTEGER' => 27,
			'SUBTRACT' => 54,
			'MACRO' => 53,
			'KW_RECEIVE' => 55,
			'KW_CATCH' => 56,
			'STRING' => 57,
			'ADD' => 32,
			'FLOAT' => 58,
			'LISTOPEN' => 59,
			'LITERAL' => 34,
			'OPENRECORD' => 60
		},
		GOTOS => {
			'atom' => 49,
			'newrecord' => 28,
			'unparenexpr' => 52,
			'tuple' => 51,
			'variable' => 31,
			'parenorimm' => 29,
			'macro' => 30,
			'case' => 36,
			'receive' => 61,
			'expr' => 275,
			'parenexpr' => 33,
			'try' => 15,
			'fun' => 14,
			'funlocal' => 13,
			'list' => 39,
			'call' => 37,
			'extcall' => 18,
			'intcall' => 44,
			'if' => 43,
			'binary' => 17,
			'string' => 16,
			'immexpr' => 40,
			'comprehension' => 46
		}
	},
	{#State 267
		ACTIONS => {
			'RARROW' => 276,
			'COMMA' => 214,
			'SEMICOLON' => 213
		}
	},
	{#State 268
		DEFAULT => -123
	},
	{#State 269
		DEFAULT => -129
	},
	{#State 270
		ACTIONS => {
			'COMMA' => 79
		},
		DEFAULT => -122
	},
	{#State 271
		ACTIONS => {
			'COMMA' => 79
		},
		DEFAULT => -106
	},
	{#State 272
		DEFAULT => -119
	},
	{#State 273
		DEFAULT => -131
	},
	{#State 274
		ACTIONS => {
			'ADD' => 114,
			'KW_AND' => 111,
			'GTE' => 113,
			'KW_BSR' => 112,
			'MULTIPLY' => 107,
			'KW_BOR' => 109,
			'KW_DIV' => 110,
			'LDARROW' => 108,
			'KW_OR' => 101,
			'LTE' => 100,
			'KW_ANDALSO' => 105,
			'LARROW' => 106,
			'LISTSUBTRACT' => 104,
			'KW_REM' => 102,
			'NOT_EQUAL' => 103,
			'EQUAL' => 99,
			'DIVIDE' => 98,
			'LT' => 94,
			'SUBTRACT' => 97,
			'SEND' => 96,
			'KW_ORELSE' => 95,
			'KW_WHEN' => 147,
			'KW_XOR' => 93,
			'KW_BSL' => 92,
			'KW_BXOR' => 85,
			'STRICTLY_EQUAL' => 86,
			'LISTADD' => 91,
			'GT' => 89,
			'STRICTLY_NOT_EQUAL' => 87,
			'MATCH' => 88,
			'KW_BAND' => 90
		},
		DEFAULT => -8,
		GOTOS => {
			'whenlist' => 277
		}
	},
	{#State 275
		ACTIONS => {
			'KW_BOR' => 109,
			'KW_DIV' => 110,
			'LDARROW' => 108,
			'MULTIPLY' => 107,
			'KW_ANDALSO' => 105,
			'LARROW' => 106,
			'KW_REM' => 102,
			'NOT_EQUAL' => 103,
			'LISTSUBTRACT' => 104,
			'KW_OR' => 101,
			'LTE' => 100,
			'ADD' => 114,
			'GTE' => 113,
			'KW_BSR' => 112,
			'KW_AND' => 111,
			'KW_XOR' => 93,
			'KW_BSL' => 92,
			'KW_WHEN' => 147,
			'LISTADD' => 91,
			'GT' => 89,
			'MATCH' => 88,
			'STRICTLY_NOT_EQUAL' => 87,
			'KW_BAND' => 90,
			'KW_BXOR' => 85,
			'STRICTLY_EQUAL' => 86,
			'EQUAL' => 99,
			'DIVIDE' => 98,
			'SUBTRACT' => 97,
			'SEND' => 96,
			'KW_ORELSE' => 95,
			'LT' => 94
		},
		DEFAULT => -8,
		GOTOS => {
			'whenlist' => 278
		}
	},
	{#State 276
		ACTIONS => {
			'KW_FUN' => 19,
			'LPAREN' => 47,
			'KW_BEGIN' => 20,
			'KW_NOT' => 45,
			'VARIABLE' => 21,
			'INTEGER' => 48,
			'ATOM' => 22,
			'OPENBINARY' => 38,
			'KW_TRY' => 41,
			'TUPLEOPEN' => 42,
			'KW_CATCH' => 56,
			'STRING' => 57,
			'ADD' => 32,
			'KW_RECEIVE' => 55,
			'LISTOPEN' => 59,
			'OPENRECORD' => 60,
			'LITERAL' => 34,
			'FLOAT' => 58,
			'KW_IF' => 25,
			'KW_BNOT' => 23,
			'KW_CASE' => 50,
			'BASE_INTEGER' => 27,
			'SUBTRACT' => 54,
			'MACRO' => 53
		},
		GOTOS => {
			'stmtlist' => 279,
			'atom' => 49,
			'unparenexpr' => 52,
			'newrecord' => 28,
			'tuple' => 51,
			'variable' => 31,
			'parenorimm' => 29,
			'macro' => 30,
			'expr' => 35,
			'case' => 36,
			'receive' => 61,
			'parenexpr' => 33,
			'fun' => 14,
			'try' => 15,
			'call' => 37,
			'list' => 39,
			'funlocal' => 13,
			'intcall' => 44,
			'extcall' => 18,
			'immexpr' => 40,
			'string' => 16,
			'binary' => 17,
			'if' => 43,
			'comprehension' => 46
		}
	},
	{#State 277
		ACTIONS => {
			'RARROW' => 280,
			'SEMICOLON' => 213,
			'COMMA' => 214
		}
	},
	{#State 278
		ACTIONS => {
			'RARROW' => 281,
			'SEMICOLON' => 213,
			'COMMA' => 214
		}
	},
	{#State 279
		ACTIONS => {
			'COMMA' => 79
		},
		DEFAULT => -134
	},
	{#State 280
		ACTIONS => {
			'MACRO' => 53,
			'SUBTRACT' => 54,
			'BASE_INTEGER' => 27,
			'KW_IF' => 25,
			'KW_CASE' => 50,
			'KW_BNOT' => 23,
			'LITERAL' => 34,
			'OPENRECORD' => 60,
			'LISTOPEN' => 59,
			'FLOAT' => 58,
			'ADD' => 32,
			'STRING' => 57,
			'KW_CATCH' => 56,
			'KW_RECEIVE' => 55,
			'TUPLEOPEN' => 42,
			'KW_TRY' => 41,
			'OPENBINARY' => 38,
			'ATOM' => 22,
			'VARIABLE' => 21,
			'INTEGER' => 48,
			'KW_BEGIN' => 20,
			'LPAREN' => 47,
			'KW_FUN' => 19,
			'KW_NOT' => 45
		},
		GOTOS => {
			'comprehension' => 46,
			'funlocal' => 13,
			'call' => 37,
			'list' => 39,
			'fun' => 14,
			'try' => 15,
			'string' => 16,
			'immexpr' => 40,
			'if' => 43,
			'binary' => 17,
			'intcall' => 44,
			'extcall' => 18,
			'macro' => 30,
			'parenorimm' => 29,
			'variable' => 31,
			'case' => 36,
			'receive' => 61,
			'parenexpr' => 33,
			'expr' => 35,
			'atom' => 49,
			'stmtlist' => 282,
			'tuple' => 51,
			'unparenexpr' => 52,
			'newrecord' => 28
		}
	},
	{#State 281
		ACTIONS => {
			'VARIABLE' => 21,
			'INTEGER' => 48,
			'ATOM' => 22,
			'KW_FUN' => 19,
			'LPAREN' => 47,
			'KW_BEGIN' => 20,
			'KW_NOT' => 45,
			'KW_TRY' => 41,
			'TUPLEOPEN' => 42,
			'OPENBINARY' => 38,
			'LISTOPEN' => 59,
			'OPENRECORD' => 60,
			'LITERAL' => 34,
			'FLOAT' => 58,
			'KW_CATCH' => 56,
			'ADD' => 32,
			'STRING' => 57,
			'KW_RECEIVE' => 55,
			'BASE_INTEGER' => 27,
			'MACRO' => 53,
			'SUBTRACT' => 54,
			'KW_IF' => 25,
			'KW_BNOT' => 23,
			'KW_CASE' => 50
		},
		GOTOS => {
			'receive' => 61,
			'expr' => 35,
			'case' => 36,
			'parenexpr' => 33,
			'parenorimm' => 29,
			'macro' => 30,
			'variable' => 31,
			'tuple' => 51,
			'unparenexpr' => 52,
			'newrecord' => 28,
			'atom' => 49,
			'stmtlist' => 283,
			'comprehension' => 46,
			'immexpr' => 40,
			'string' => 16,
			'binary' => 17,
			'if' => 43,
			'intcall' => 44,
			'extcall' => 18,
			'call' => 37,
			'list' => 39,
			'funlocal' => 13,
			'fun' => 14,
			'try' => 15
		}
	},
	{#State 282
		ACTIONS => {
			'COMMA' => 79
		},
		DEFAULT => -133
	},
	{#State 283
		ACTIONS => {
			'COMMA' => 79
		},
		DEFAULT => -132
	}
],
                                  yyrules  =>
[
	[#Rule 0
		 '$start', 2, undef
	],
	[#Rule 1
		 'root', 0,
sub
#line 72 "lib/Erlang/Parser/Parser.yp"
{ [] }
	],
	[#Rule 2
		 'root', 2,
sub
#line 73 "lib/Erlang/Parser/Parser.yp"
{ [@{$_[1]}, $_[2]] }
	],
	[#Rule 3
		 'rootstmt', 6,
sub
#line 77 "lib/Erlang/Parser/Parser.yp"
{ new_node 'Directive', directive => $_[2], args => $_[4] }
	],
	[#Rule 4
		 'rootstmt', 2,
sub
#line 78 "lib/Erlang/Parser/Parser.yp"
{ $_[1] }
	],
	[#Rule 5
		 'deflist', 1,
sub
#line 82 "lib/Erlang/Parser/Parser.yp"
{ new_node('DefList')->_append($_[1]) }
	],
	[#Rule 6
		 'deflist', 3,
sub
#line 83 "lib/Erlang/Parser/Parser.yp"
{ $_[1]->_append($_[3]) }
	],
	[#Rule 7
		 'def', 7,
sub
#line 87 "lib/Erlang/Parser/Parser.yp"
{ new_node 'Def', def => $_[1], args => $_[3], whens => $_[5]->_group, stmts => $_[7] }
	],
	[#Rule 8
		 'whenlist', 0,
sub
#line 91 "lib/Erlang/Parser/Parser.yp"
{ new_node 'WhenList' }
	],
	[#Rule 9
		 'whenlist', 2,
sub
#line 92 "lib/Erlang/Parser/Parser.yp"
{ new_node('WhenList')->_append($_[2]) }
	],
	[#Rule 10
		 'whenlist', 3,
sub
#line 94 "lib/Erlang/Parser/Parser.yp"
{ $_[1]->_append($_[3]) }
	],
	[#Rule 11
		 'whenlist', 3,
sub
#line 95 "lib/Erlang/Parser/Parser.yp"
{ $_[1]->_group->_append($_[3]) }
	],
	[#Rule 12
		 'exprlist', 0,
sub
#line 100 "lib/Erlang/Parser/Parser.yp"
{ [] }
	],
	[#Rule 13
		 'exprlist', 1,
sub
#line 101 "lib/Erlang/Parser/Parser.yp"
{ $_[1] }
	],
	[#Rule 14
		 'stmtlist', 1,
sub
#line 105 "lib/Erlang/Parser/Parser.yp"
{ [$_[1]] }
	],
	[#Rule 15
		 'stmtlist', 3,
sub
#line 106 "lib/Erlang/Parser/Parser.yp"
{ [@{$_[1]}, $_[3]] }
	],
	[#Rule 16
		 'unparenexpr', 1, undef
	],
	[#Rule 17
		 'unparenexpr', 1, undef
	],
	[#Rule 18
		 'unparenexpr', 1, undef
	],
	[#Rule 19
		 'unparenexpr', 1, undef
	],
	[#Rule 20
		 'unparenexpr', 1, undef
	],
	[#Rule 21
		 'unparenexpr', 1, undef
	],
	[#Rule 22
		 'unparenexpr', 1, undef
	],
	[#Rule 23
		 'unparenexpr', 1, undef
	],
	[#Rule 24
		 'unparenexpr', 3,
sub
#line 118 "lib/Erlang/Parser/Parser.yp"
{ new_node 'Begin', exprs => $_[2] }
	],
	[#Rule 25
		 'unparenexpr', 3,
sub
#line 119 "lib/Erlang/Parser/Parser.yp"
{ new_node 'BinOp', op => '!',       a => $_[1], b => $_[3] }
	],
	[#Rule 26
		 'unparenexpr', 3,
sub
#line 120 "lib/Erlang/Parser/Parser.yp"
{ new_node 'BinOp', op => '<',       a => $_[1], b => $_[3] }
	],
	[#Rule 27
		 'unparenexpr', 3,
sub
#line 121 "lib/Erlang/Parser/Parser.yp"
{ new_node 'BinOp', op => '=<',      a => $_[1], b => $_[3] }
	],
	[#Rule 28
		 'unparenexpr', 3,
sub
#line 122 "lib/Erlang/Parser/Parser.yp"
{ new_node 'BinOp', op => '>',       a => $_[1], b => $_[3] }
	],
	[#Rule 29
		 'unparenexpr', 3,
sub
#line 123 "lib/Erlang/Parser/Parser.yp"
{ new_node 'BinOp', op => '>=',      a => $_[1], b => $_[3] }
	],
	[#Rule 30
		 'unparenexpr', 3,
sub
#line 124 "lib/Erlang/Parser/Parser.yp"
{ new_node 'BinOp', op => '/',       a => $_[1], b => $_[3] }
	],
	[#Rule 31
		 'unparenexpr', 3,
sub
#line 125 "lib/Erlang/Parser/Parser.yp"
{ new_node 'BinOp', op => 'div',     a => $_[1], b => $_[3] }
	],
	[#Rule 32
		 'unparenexpr', 3,
sub
#line 126 "lib/Erlang/Parser/Parser.yp"
{ new_node 'BinOp', op => '*',       a => $_[1], b => $_[3] }
	],
	[#Rule 33
		 'unparenexpr', 3,
sub
#line 127 "lib/Erlang/Parser/Parser.yp"
{ new_node 'BinOp', op => '+',       a => $_[1], b => $_[3] }
	],
	[#Rule 34
		 'unparenexpr', 3,
sub
#line 128 "lib/Erlang/Parser/Parser.yp"
{ new_node 'BinOp', op => '-',       a => $_[1], b => $_[3] }
	],
	[#Rule 35
		 'unparenexpr', 3,
sub
#line 129 "lib/Erlang/Parser/Parser.yp"
{ new_node 'BinOp', op => '=',       a => $_[1], b => $_[3] }
	],
	[#Rule 36
		 'unparenexpr', 3,
sub
#line 130 "lib/Erlang/Parser/Parser.yp"
{ new_node 'BinOp', op => '++',      a => $_[1], b => $_[3] }
	],
	[#Rule 37
		 'unparenexpr', 3,
sub
#line 131 "lib/Erlang/Parser/Parser.yp"
{ new_node 'BinOp', op => '--',      a => $_[1], b => $_[3] }
	],
	[#Rule 38
		 'unparenexpr', 3,
sub
#line 132 "lib/Erlang/Parser/Parser.yp"
{ new_node 'BinOp', op => '==',      a => $_[1], b => $_[3] }
	],
	[#Rule 39
		 'unparenexpr', 3,
sub
#line 133 "lib/Erlang/Parser/Parser.yp"
{ new_node 'BinOp', op => '=:=',     a => $_[1], b => $_[3] }
	],
	[#Rule 40
		 'unparenexpr', 3,
sub
#line 134 "lib/Erlang/Parser/Parser.yp"
{ new_node 'BinOp', op => '=/=',     a => $_[1], b => $_[3] }
	],
	[#Rule 41
		 'unparenexpr', 3,
sub
#line 135 "lib/Erlang/Parser/Parser.yp"
{ new_node 'BinOp', op => '/=',      a => $_[1], b => $_[3] }
	],
	[#Rule 42
		 'unparenexpr', 3,
sub
#line 136 "lib/Erlang/Parser/Parser.yp"
{ new_node 'BinOp', op => 'bsl',     a => $_[1], b => $_[3] }
	],
	[#Rule 43
		 'unparenexpr', 3,
sub
#line 137 "lib/Erlang/Parser/Parser.yp"
{ new_node 'BinOp', op => 'bsr',     a => $_[1], b => $_[3] }
	],
	[#Rule 44
		 'unparenexpr', 3,
sub
#line 138 "lib/Erlang/Parser/Parser.yp"
{ new_node 'BinOp', op => 'bor',     a => $_[1], b => $_[3] }
	],
	[#Rule 45
		 'unparenexpr', 3,
sub
#line 139 "lib/Erlang/Parser/Parser.yp"
{ new_node 'BinOp', op => 'band',    a => $_[1], b => $_[3] }
	],
	[#Rule 46
		 'unparenexpr', 3,
sub
#line 140 "lib/Erlang/Parser/Parser.yp"
{ new_node 'BinOp', op => 'bxor',    a => $_[1], b => $_[3] }
	],
	[#Rule 47
		 'unparenexpr', 3,
sub
#line 141 "lib/Erlang/Parser/Parser.yp"
{ new_node 'BinOp', op => 'xor',     a => $_[1], b => $_[3] }
	],
	[#Rule 48
		 'unparenexpr', 3,
sub
#line 142 "lib/Erlang/Parser/Parser.yp"
{ new_node 'BinOp', op => 'rem',     a => $_[1], b => $_[3] }
	],
	[#Rule 49
		 'unparenexpr', 3,
sub
#line 143 "lib/Erlang/Parser/Parser.yp"
{ new_node 'BinOp', op => 'andalso', a => $_[1], b => $_[3] }
	],
	[#Rule 50
		 'unparenexpr', 3,
sub
#line 144 "lib/Erlang/Parser/Parser.yp"
{ new_node 'BinOp', op => 'orelse',  a => $_[1], b => $_[3] }
	],
	[#Rule 51
		 'unparenexpr', 3,
sub
#line 145 "lib/Erlang/Parser/Parser.yp"
{ new_node 'BinOp', op => 'and',     a => $_[1], b => $_[3] }
	],
	[#Rule 52
		 'unparenexpr', 3,
sub
#line 146 "lib/Erlang/Parser/Parser.yp"
{ new_node 'BinOp', op => 'or',      a => $_[1], b => $_[3] }
	],
	[#Rule 53
		 'unparenexpr', 2,
sub
#line 147 "lib/Erlang/Parser/Parser.yp"
{ new_node 'UnOp',  op => '-',       a => $_[2] }
	],
	[#Rule 54
		 'unparenexpr', 2,
sub
#line 148 "lib/Erlang/Parser/Parser.yp"
{ new_node 'UnOp',  op => '+',       a => $_[2] }
	],
	[#Rule 55
		 'unparenexpr', 2,
sub
#line 149 "lib/Erlang/Parser/Parser.yp"
{ new_node 'UnOp',  op => 'bnot',    a => $_[2] }
	],
	[#Rule 56
		 'unparenexpr', 2,
sub
#line 150 "lib/Erlang/Parser/Parser.yp"
{ new_node 'UnOp',  op => 'not',     a => $_[2] }
	],
	[#Rule 57
		 'unparenexpr', 2,
sub
#line 151 "lib/Erlang/Parser/Parser.yp"
{ new_node 'UnOp',  op => 'catch',   a => $_[2] }
	],
	[#Rule 58
		 'unparenexpr', 3,
sub
#line 154 "lib/Erlang/Parser/Parser.yp"
{ new_node 'BinOp', op => '<-', a => $_[1], b => $_[3] }
	],
	[#Rule 59
		 'unparenexpr', 3,
sub
#line 155 "lib/Erlang/Parser/Parser.yp"
{ new_node 'BinOp', op => '<=', a => $_[1], b => $_[3] }
	],
	[#Rule 60
		 'unparenexpr', 1, undef
	],
	[#Rule 61
		 'parenexpr', 3,
sub
#line 161 "lib/Erlang/Parser/Parser.yp"
{ $_[2] }
	],
	[#Rule 62
		 'expr', 1, undef
	],
	[#Rule 63
		 'expr', 1, undef
	],
	[#Rule 64
		 'parenorimm', 1, undef
	],
	[#Rule 65
		 'parenorimm', 1, undef
	],
	[#Rule 66
		 'immexpr', 1,
sub
#line 175 "lib/Erlang/Parser/Parser.yp"
{ new_node 'Float', float => $_[1] }
	],
	[#Rule 67
		 'immexpr', 1,
sub
#line 176 "lib/Erlang/Parser/Parser.yp"
{ new_node 'BaseInteger', baseinteger => $_[1] }
	],
	[#Rule 68
		 'immexpr', 1,
sub
#line 177 "lib/Erlang/Parser/Parser.yp"
{ new_node 'Integer', int => $_[1] }
	],
	[#Rule 69
		 'immexpr', 1, undef
	],
	[#Rule 70
		 'immexpr', 3,
sub
#line 179 "lib/Erlang/Parser/Parser.yp"
{ new_node 'VariableRecordAccess', variable => $_[1], record => $_[3] }
	],
	[#Rule 71
		 'immexpr', 2,
sub
#line 180 "lib/Erlang/Parser/Parser.yp"
{ new_node 'VariableRecordUpdate', variable => $_[1], update => $_[2] }
	],
	[#Rule 72
		 'immexpr', 1,
sub
#line 181 "lib/Erlang/Parser/Parser.yp"
{ new_node 'Literal', literal => substr($_[1], 1) }
	],
	[#Rule 73
		 'immexpr', 1, undef
	],
	[#Rule 74
		 'immexpr', 1, undef
	],
	[#Rule 75
		 'immexpr', 1, undef
	],
	[#Rule 76
		 'immexpr', 1, undef
	],
	[#Rule 77
		 'immexpr', 1, undef
	],
	[#Rule 78
		 'immexpr', 1, undef
	],
	[#Rule 79
		 'atom', 1,
sub
#line 191 "lib/Erlang/Parser/Parser.yp"
{ new_node 'Atom', atom => $_[1] }
	],
	[#Rule 80
		 'macro', 1,
sub
#line 195 "lib/Erlang/Parser/Parser.yp"
{ new_node 'Macro', macro => substr($_[1], 1) }
	],
	[#Rule 81
		 'variable', 1,
sub
#line 199 "lib/Erlang/Parser/Parser.yp"
{ new_node 'Variable', variable => $_[1] }
	],
	[#Rule 82
		 'string', 1,
sub
#line 203 "lib/Erlang/Parser/Parser.yp"
{ new_node 'String', string => $_[1] }
	],
	[#Rule 83
		 'string', 2,
sub
#line 204 "lib/Erlang/Parser/Parser.yp"
{ $_[1]->_append($_[2]) }
	],
	[#Rule 84
		 'call', 1, undef
	],
	[#Rule 85
		 'call', 1, undef
	],
	[#Rule 86
		 'intcall', 4,
sub
#line 213 "lib/Erlang/Parser/Parser.yp"
{ new_node 'Call', function => $_[1], args => $_[3] }
	],
	[#Rule 87
		 'extcall', 3,
sub
#line 217 "lib/Erlang/Parser/Parser.yp"
{ $_[3]->module($_[1]); $_[3] }
	],
	[#Rule 88
		 'list', 4,
sub
#line 221 "lib/Erlang/Parser/Parser.yp"
{ new_node 'List', elems => $_[2], cdr => $_[3] }
	],
	[#Rule 89
		 'listcdr', 0,
sub
#line 226 "lib/Erlang/Parser/Parser.yp"
{ undef }
	],
	[#Rule 90
		 'listcdr', 2,
sub
#line 227 "lib/Erlang/Parser/Parser.yp"
{ $_[2] }
	],
	[#Rule 91
		 'comprehension', 5,
sub
#line 231 "lib/Erlang/Parser/Parser.yp"
{ new_node 'Comprehension', output => $_[2], generators => $_[4] }
	],
	[#Rule 92
		 'comprehension', 5,
sub
#line 232 "lib/Erlang/Parser/Parser.yp"
{ new_node 'Comprehension', output => $_[2], generators => $_[4], binary => 1 }
	],
	[#Rule 93
		 'tuple', 3,
sub
#line 236 "lib/Erlang/Parser/Parser.yp"
{ new_node 'Tuple', elems => $_[2] }
	],
	[#Rule 94
		 'case', 5,
sub
#line 240 "lib/Erlang/Parser/Parser.yp"
{ new_node 'Case', of => $_[2], alts => $_[4] }
	],
	[#Rule 95
		 'altlist', 1,
sub
#line 244 "lib/Erlang/Parser/Parser.yp"
{ [$_[1]] }
	],
	[#Rule 96
		 'altlist', 3,
sub
#line 245 "lib/Erlang/Parser/Parser.yp"
{ [@{$_[1]}, $_[3]] }
	],
	[#Rule 97
		 'alt', 4,
sub
#line 249 "lib/Erlang/Parser/Parser.yp"
{ new_node 'Alt', expr => $_[1], whens => $_[2]->_group, stmts => $_[4] }
	],
	[#Rule 98
		 'fun', 1, undef
	],
	[#Rule 99
		 'fun', 6,
sub
#line 254 "lib/Erlang/Parser/Parser.yp"
{ new_node 'FunRef', module => $_[2], function => $_[4], arity => $_[6] }
	],
	[#Rule 100
		 'fun', 6,
sub
#line 255 "lib/Erlang/Parser/Parser.yp"
{ new_node 'FunRef', module => $_[2], function => $_[4], arity => $_[6] }
	],
	[#Rule 101
		 'fun', 6,
sub
#line 256 "lib/Erlang/Parser/Parser.yp"
{ new_node 'FunRef', module => $_[2], function => $_[4], arity => $_[6] }
	],
	[#Rule 102
		 'fun', 4,
sub
#line 257 "lib/Erlang/Parser/Parser.yp"
{ new_node 'FunRef', function => $_[2], arity => $_[4] }
	],
	[#Rule 103
		 'funlocal', 3,
sub
#line 261 "lib/Erlang/Parser/Parser.yp"
{ new_node 'FunLocal', cases => $_[2] }
	],
	[#Rule 104
		 'funlocallist', 1,
sub
#line 266 "lib/Erlang/Parser/Parser.yp"
{ [$_[1]] }
	],
	[#Rule 105
		 'funlocallist', 3,
sub
#line 267 "lib/Erlang/Parser/Parser.yp"
{ [@{$_[1]}, $_[3]] }
	],
	[#Rule 106
		 'funlocalcase', 6,
sub
#line 271 "lib/Erlang/Parser/Parser.yp"
{ new_node 'FunLocalCase', args => $_[2], whens => $_[4]->_group, stmts => $_[6] }
	],
	[#Rule 107
		 'newrecord', 5,
sub
#line 275 "lib/Erlang/Parser/Parser.yp"
{ new_node 'RecordNew', record => $_[2], exprs => $_[4] }
	],
	[#Rule 108
		 'binary', 3,
sub
#line 279 "lib/Erlang/Parser/Parser.yp"
{ new_node 'Binary', bexprs => $_[2] }
	],
	[#Rule 109
		 'optbinarylist', 0,
sub
#line 284 "lib/Erlang/Parser/Parser.yp"
{ [] }
	],
	[#Rule 110
		 'optbinarylist', 1, undef
	],
	[#Rule 111
		 'binarylist', 1,
sub
#line 289 "lib/Erlang/Parser/Parser.yp"
{ [$_[1]] }
	],
	[#Rule 112
		 'binarylist', 3,
sub
#line 290 "lib/Erlang/Parser/Parser.yp"
{ [@{$_[1]}, $_[3]] }
	],
	[#Rule 113
		 'binaryexpr', 3,
sub
#line 294 "lib/Erlang/Parser/Parser.yp"
{ new_node 'BinaryExpr', output => $_[1], size => $_[2], qualifier => $_[3] }
	],
	[#Rule 114
		 'optbinarysize', 0,
sub
#line 299 "lib/Erlang/Parser/Parser.yp"
{ undef }
	],
	[#Rule 115
		 'optbinarysize', 2,
sub
#line 300 "lib/Erlang/Parser/Parser.yp"
{ $_[2] }
	],
	[#Rule 116
		 'optbinaryqualifier', 0,
sub
#line 304 "lib/Erlang/Parser/Parser.yp"
{ undef }
	],
	[#Rule 117
		 'optbinaryqualifier', 2,
sub
#line 305 "lib/Erlang/Parser/Parser.yp"
{ $_[2] }
	],
	[#Rule 118
		 'binaryqualifier', 1, undef
	],
	[#Rule 119
		 'binaryqualifier', 3,
sub
#line 310 "lib/Erlang/Parser/Parser.yp"
{ "$_[1]-$_[3]" }
	],
	[#Rule 120
		 'receive', 4,
sub
#line 314 "lib/Erlang/Parser/Parser.yp"
{ new_node 'Receive', alts => $_[2], aft => $_[3] }
	],
	[#Rule 121
		 'after', 0,
sub
#line 319 "lib/Erlang/Parser/Parser.yp"
{ undef }
	],
	[#Rule 122
		 'after', 4,
sub
#line 320 "lib/Erlang/Parser/Parser.yp"
{ new_node 'ReceiveAfter', time => $_[2], stmts => $_[4] }
	],
	[#Rule 123
		 'try', 6,
sub
#line 324 "lib/Erlang/Parser/Parser.yp"
{ new_node 'Try', exprs => $_[2], of => $_[3], catch => $_[4], aft => $_[5] }
	],
	[#Rule 124
		 'opttryof', 0,
sub
#line 329 "lib/Erlang/Parser/Parser.yp"
{ undef }
	],
	[#Rule 125
		 'opttryof', 2,
sub
#line 330 "lib/Erlang/Parser/Parser.yp"
{ $_[2] }
	],
	[#Rule 126
		 'opttrycatch', 0,
sub
#line 334 "lib/Erlang/Parser/Parser.yp"
{ undef }
	],
	[#Rule 127
		 'opttrycatch', 2,
sub
#line 335 "lib/Erlang/Parser/Parser.yp"
{ $_[2] }
	],
	[#Rule 128
		 'opttryafter', 0,
sub
#line 339 "lib/Erlang/Parser/Parser.yp"
{ undef }
	],
	[#Rule 129
		 'opttryafter', 2,
sub
#line 340 "lib/Erlang/Parser/Parser.yp"
{ $_[2] }
	],
	[#Rule 130
		 'catchaltlist', 1,
sub
#line 344 "lib/Erlang/Parser/Parser.yp"
{ [$_[1]] }
	],
	[#Rule 131
		 'catchaltlist', 3,
sub
#line 345 "lib/Erlang/Parser/Parser.yp"
{ [@{$_[1]}, $_[3]] }
	],
	[#Rule 132
		 'catchalt', 6,
sub
#line 349 "lib/Erlang/Parser/Parser.yp"
{ new_node 'Alt', catch => 1, class => $_[1], expr => $_[3], whens => $_[4]->_group, stmts => $_[6] }
	],
	[#Rule 133
		 'catchalt', 6,
sub
#line 350 "lib/Erlang/Parser/Parser.yp"
{ new_node 'Alt', catch => 1, class => $_[1], expr => $_[3], whens => $_[4]->_group, stmts => $_[6] }
	],
	[#Rule 134
		 'catchalt', 4,
sub
#line 351 "lib/Erlang/Parser/Parser.yp"
{ new_node 'Alt', catch => 1, expr => $_[1], whens => $_[2]->_group, stmts => $_[4] }
	],
	[#Rule 135
		 'if', 3,
sub
#line 355 "lib/Erlang/Parser/Parser.yp"
{ new_node 'If', cases => $_[2] }
	],
	[#Rule 136
		 'iflist', 1,
sub
#line 359 "lib/Erlang/Parser/Parser.yp"
{ [$_[1]] }
	],
	[#Rule 137
		 'iflist', 3,
sub
#line 360 "lib/Erlang/Parser/Parser.yp"
{ [@{$_[1]}, $_[3]] }
	],
	[#Rule 138
		 'ifexpr', 3,
sub
#line 364 "lib/Erlang/Parser/Parser.yp"
{ new_node 'IfExpr', seq => $_[1], stmts => $_[3] }
	],
	[#Rule 139
		 'ifseq', 1,
sub
#line 368 "lib/Erlang/Parser/Parser.yp"
{ [$_[1]] }
	],
	[#Rule 140
		 'ifseq', 3,
sub
#line 369 "lib/Erlang/Parser/Parser.yp"
{ [@{$_[1]}, $_[3]] }
	]
],
                                  @_);
    bless($self,$class);
}

#line 371 "lib/Erlang/Parser/Parser.yp"


=over 4

=item C<new>

Creates a new parser object. See L<Parse::Yapp> for more information.

=item C<new_node>

Helper function used to create new nodes.

    # These are identical.
    my $n1 = new_node('X', @y);
    my $n2 = Erlang::Parser::Node::X->new(@y);

=cut

1;

# vim: set sw=4 ts=4 et filetype=perl:

1;
