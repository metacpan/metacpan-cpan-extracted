####################################################################
#
#    This file was generated using Parse::Yapp version 1.05.
#
#        Don't edit this file, use source file instead.
#
#             ANY CHANGE MADE HERE WILL BE LOST !
#
####################################################################
package HOI::typeparser;
use vars qw ( @ISA );
use strict;

@ISA= qw ( Parse::Yapp::Driver );
use Parse::Yapp::Driver;



sub new {
        my($class)=shift;
        ref($class)
    and $class=ref($class);

    my($self)=$class->SUPER::new( yyversion => '1.05',
                                  yystates =>
[
	{#State 0
		ACTIONS => {
			'CONST' => 4,
			'NIL' => 5,
			'IDENT' => 3
		},
		GOTOS => {
			'Type' => 2,
			'Types' => 1
		}
	},
	{#State 1
		ACTIONS => {
			'' => 6
		}
	},
	{#State 2
		ACTIONS => {
			'COMMA' => 7,
			'CONCAT' => 8
		},
		DEFAULT => -1
	},
	{#State 3
		ACTIONS => {
			'STRCONCAT' => 10,
			'LPAREN' => 9
		},
		DEFAULT => -4
	},
	{#State 4
		DEFAULT => -3
	},
	{#State 5
		DEFAULT => -6
	},
	{#State 6
		DEFAULT => 0
	},
	{#State 7
		ACTIONS => {
			'IDENT' => 3,
			'CONST' => 4,
			'NIL' => 5
		},
		GOTOS => {
			'Types' => 11,
			'Type' => 2
		}
	},
	{#State 8
		ACTIONS => {
			'IDENT' => 3,
			'CONST' => 4,
			'NIL' => 5
		},
		GOTOS => {
			'Type' => 12
		}
	},
	{#State 9
		ACTIONS => {
			'IDENT' => 3,
			'CONST' => 4,
			'NIL' => 5
		},
		DEFAULT => -9,
		GOTOS => {
			'Type' => 14,
			'Typelist' => 13
		}
	},
	{#State 10
		ACTIONS => {
			'IDENT' => 15
		}
	},
	{#State 11
		DEFAULT => -2
	},
	{#State 12
		ACTIONS => {
			'CONCAT' => 8
		},
		DEFAULT => -5
	},
	{#State 13
		ACTIONS => {
			'RPAREN' => 16
		}
	},
	{#State 14
		ACTIONS => {
			'CONST' => 4,
			'NIL' => 5,
			'CONCAT' => 8,
			'IDENT' => 3
		},
		DEFAULT => -9,
		GOTOS => {
			'Type' => 14,
			'Typelist' => 17
		}
	},
	{#State 15
		DEFAULT => -8
	},
	{#State 16
		DEFAULT => -7
	},
	{#State 17
		DEFAULT => -10
	}
],
                                  yyrules  =>
[
	[#Rule 0
		 '$start', 2, undef
	],
	[#Rule 1
		 'Types', 1,
sub
#line 12 "typeparser.yp"
{ [ $_[1] ] }
	],
	[#Rule 2
		 'Types', 3,
sub
#line 13 "typeparser.yp"
{ my $sublist = $_[3]; my @list= ($_[1], @$sublist); \@list }
	],
	[#Rule 3
		 'Type', 1,
sub
#line 16 "typeparser.yp"
{ { "kind" => "const", "val" => $_[1] } }
	],
	[#Rule 4
		 'Type', 1,
sub
#line 17 "typeparser.yp"
{ { "kind" => "any", "val" => $_[1] } }
	],
	[#Rule 5
		 'Type', 3,
sub
#line 18 "typeparser.yp"
{ { "kind" => "list", "val" => [ $_[1], $_[3] ] } }
	],
	[#Rule 6
		 'Type', 1,
sub
#line 19 "typeparser.yp"
{ { "kind" => "list", "val" => [] } }
	],
	[#Rule 7
		 'Type', 4,
sub
#line 20 "typeparser.yp"
{ { "kind" => "adt", "val" => [ $_[1], $_[3] ] } }
	],
	[#Rule 8
		 'Type', 3,
sub
#line 21 "typeparser.yp"
{ { "kind" => "strspl", "val" => [ $_[1], $_[3] ] } }
	],
	[#Rule 9
		 'Typelist', 0,
sub
#line 24 "typeparser.yp"
{ [] }
	],
	[#Rule 10
		 'Typelist', 2,
sub
#line 25 "typeparser.yp"
{ my $sublist = $_[2]; my @list= ($_[1], @$sublist); \@list }
	]
],
                                  @_);
    bless($self,$class);
}

#line 28 "typeparser.yp"


1;
