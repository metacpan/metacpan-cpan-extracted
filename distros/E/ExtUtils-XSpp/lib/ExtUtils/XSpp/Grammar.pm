####################################################################
#
#    This file was generated using Parse::Yapp version 1.21.
#
#        Don't edit this file, use source file instead.
#
#             ANY CHANGE MADE HERE WILL BE LOST !
#
####################################################################
package ExtUtils::XSpp::Grammar;
use vars qw ( @ISA );
use strict;

@ISA= qw ( ExtUtils::XSpp::Grammar::YappDriver );
#Included Parse/Yapp/Driver.pm file----------------------------------------
{
#
# Module ExtUtils::XSpp::Grammar::YappDriver
#
# This module is part of the Parse::Yapp package available on your
# nearest CPAN
#
# Any use of this module in a standalone parser make the included
# text under the same copyright as the Parse::Yapp module itself.
#
# This notice should remain unchanged.
#
# Copyright © 1998, 1999, 2000, 2001, Francois Desarmenien.
# Copyright © 2017 William N. Braswell, Jr.
# (see the pod text in Parse::Yapp module for use and distribution rights)
#

package ExtUtils::XSpp::Grammar::YappDriver;

require 5.004;

use strict;

use vars qw ( $VERSION $COMPATIBLE $FILENAME );

# CORRELATION #py001: $VERSION must be changed in both Parse::Yapp & ExtUtils::XSpp::Grammar::YappDriver
$VERSION = '1.21';
$COMPATIBLE = '0.07';
$FILENAME=__FILE__;

use Carp;

#Known parameters, all starting with YY (leading YY will be discarded)
my(%params)=(YYLEX => 'CODE', 'YYERROR' => 'CODE', YYVERSION => '',
			 YYRULES => 'ARRAY', YYSTATES => 'ARRAY', YYDEBUG => '');
#Mandatory parameters
my(@params)=('LEX','RULES','STATES');

sub new {
    my($class)=shift;
	my($errst,$nberr,$token,$value,$check,$dotpos);
    my($self)={ ERROR => \&_Error,
				ERRST => \$errst,
                NBERR => \$nberr,
				TOKEN => \$token,
				VALUE => \$value,
				DOTPOS => \$dotpos,
				STACK => [],
				DEBUG => 0,
				CHECK => \$check };

	_CheckParams( [], \%params, \@_, $self );

		exists($$self{VERSION})
	and	$$self{VERSION} < $COMPATIBLE
	and	croak "Yapp driver version $VERSION ".
			  "incompatible with version $$self{VERSION}:\n".
			  "Please recompile parser module.";

        ref($class)
    and $class=ref($class);

    bless($self,$class);
}

sub YYParse {
    my($self)=shift;
    my($retval);

	_CheckParams( \@params, \%params, \@_, $self );

	if($$self{DEBUG}) {
		_DBLoad();
		$retval = eval '$self->_DBParse()';#Do not create stab entry on compile
        $@ and die $@;
	}
	else {
		$retval = $self->_Parse();
	}
    $retval
}

sub YYData {
	my($self)=shift;

		exists($$self{USER})
	or	$$self{USER}={};

	$$self{USER};
	
}

sub YYErrok {
	my($self)=shift;

	${$$self{ERRST}}=0;
    undef;
}

sub YYNberr {
	my($self)=shift;

	${$$self{NBERR}};
}

sub YYRecovering {
	my($self)=shift;

	${$$self{ERRST}} != 0;
}

sub YYAbort {
	my($self)=shift;

	${$$self{CHECK}}='ABORT';
    undef;
}

sub YYAccept {
	my($self)=shift;

	${$$self{CHECK}}='ACCEPT';
    undef;
}

sub YYError {
	my($self)=shift;

	${$$self{CHECK}}='ERROR';
    undef;
}

sub YYSemval {
	my($self)=shift;
	my($index)= $_[0] - ${$$self{DOTPOS}} - 1;

		$index < 0
	and	-$index <= @{$$self{STACK}}
	and	return $$self{STACK}[$index][1];

	undef;	#Invalid index
}

sub YYCurtok {
	my($self)=shift;

        @_
    and ${$$self{TOKEN}}=$_[0];
    ${$$self{TOKEN}};
}

sub YYCurval {
	my($self)=shift;

        @_
    and ${$$self{VALUE}}=$_[0];
    ${$$self{VALUE}};
}

sub YYExpect {
    my($self)=shift;

    keys %{$self->{STATES}[$self->{STACK}[-1][0]]{ACTIONS}}
}

sub YYLexer {
    my($self)=shift;

	$$self{LEX};
}


#################
# Private stuff #
#################


sub _CheckParams {
	my($mandatory,$checklist,$inarray,$outhash)=@_;
	my($prm,$value);
	my($prmlst)={};

	while(($prm,$value)=splice(@$inarray,0,2)) {
        $prm=uc($prm);
			exists($$checklist{$prm})
		or	croak("Unknow parameter '$prm'");
			ref($value) eq $$checklist{$prm}
		or	croak("Invalid value for parameter '$prm'");
        $prm=unpack('@2A*',$prm);
		$$outhash{$prm}=$value;
	}
	for (@$mandatory) {
			exists($$outhash{$_})
		or	croak("Missing mandatory parameter '".lc($_)."'");
	}
}

sub _Error {
	print "Parse error.\n";
}

sub _DBLoad {
	{
		no strict 'refs';

			exists(${__PACKAGE__.'::'}{_DBParse})#Already loaded ?
		and	return;
	}
	my($fname)=__FILE__;
	my(@drv);
	open(DRV,"<$fname") or die "Report this as a BUG: Cannot open $fname";
	while(<DRV>) {
                	/^\s*sub\s+_Parse\s*{\s*$/ .. /^\s*}\s*#\s*_Parse\s*$/
        	and     do {
                	s/^#DBG>//;
                	push(@drv,$_);
        	}
	}
	close(DRV);

	$drv[0]=~s/_P/_DBP/;
	eval join('',@drv);
}

#Note that for loading debugging version of the driver,
#this file will be parsed from 'sub _Parse' up to '}#_Parse' inclusive.
#So, DO NOT remove comment at end of sub !!!
sub _Parse {
    my($self)=shift;

	my($rules,$states,$lex,$error)
     = @$self{ 'RULES', 'STATES', 'LEX', 'ERROR' };
	my($errstatus,$nberror,$token,$value,$stack,$check,$dotpos)
     = @$self{ 'ERRST', 'NBERR', 'TOKEN', 'VALUE', 'STACK', 'CHECK', 'DOTPOS' };

#DBG>	my($debug)=$$self{DEBUG};
#DBG>	my($dbgerror)=0;

#DBG>	my($ShowCurToken) = sub {
#DBG>		my($tok)='>';
#DBG>		for (split('',$$token)) {
#DBG>			$tok.=		(ord($_) < 32 or ord($_) > 126)
#DBG>					?	sprintf('<%02X>',ord($_))
#DBG>					:	$_;
#DBG>		}
#DBG>		$tok.='<';
#DBG>	};

	$$errstatus=0;
	$$nberror=0;
	($$token,$$value)=(undef,undef);
	@$stack=( [ 0, undef ] );
	$$check='';

    while(1) {
        my($actions,$act,$stateno);

        $stateno=$$stack[-1][0];
        $actions=$$states[$stateno];

#DBG>	print STDERR ('-' x 40),"\n";
#DBG>		$debug & 0x2
#DBG>	and	print STDERR "In state $stateno:\n";
#DBG>		$debug & 0x08
#DBG>	and	print STDERR "Stack:[".
#DBG>					 join(',',map { $$_[0] } @$stack).
#DBG>					 "]\n";


        if  (exists($$actions{ACTIONS})) {

				defined($$token)
            or	do {
				($$token,$$value)=&$lex($self);
#DBG>				$debug & 0x01
#DBG>			and	print STDERR "Need token. Got ".&$ShowCurToken."\n";
			};

            $act=   exists($$actions{ACTIONS}{$$token})
                    ?   $$actions{ACTIONS}{$$token}
                    :   exists($$actions{DEFAULT})
                        ?   $$actions{DEFAULT}
                        :   undef;
        }
        else {
            $act=$$actions{DEFAULT};
#DBG>			$debug & 0x01
#DBG>		and	print STDERR "Don't need token.\n";
        }

            defined($act)
        and do {

                $act > 0
            and do {        #shift

#DBG>				$debug & 0x04
#DBG>			and	print STDERR "Shift and go to state $act.\n";

					$$errstatus
				and	do {
					--$$errstatus;

#DBG>					$debug & 0x10
#DBG>				and	$dbgerror
#DBG>				and	$$errstatus == 0
#DBG>				and	do {
#DBG>					print STDERR "**End of Error recovery.\n";
#DBG>					$dbgerror=0;
#DBG>				};
				};


                push(@$stack,[ $act, $$value ]);

					$$token ne ''	#Don't eat the eof
				and	$$token=$$value=undef;
                next;
            };

            #reduce
            my($lhs,$len,$code,@sempar,$semval);
            ($lhs,$len,$code)=@{$$rules[-$act]};

#DBG>			$debug & 0x04
#DBG>		and	$act
#DBG>		and	print STDERR "Reduce using rule ".-$act." ($lhs,$len): ";

                $act
            or  $self->YYAccept();

            $$dotpos=$len;

                unpack('A1',$lhs) eq '@'    #In line rule
            and do {
                    $lhs =~ /^\@[0-9]+\-([0-9]+)$/
                or  die "In line rule name '$lhs' ill formed: ".
                        "report it as a BUG.\n";
                $$dotpos = $1;
            };

            @sempar =       $$dotpos
                        ?   map { $$_[1] } @$stack[ -$$dotpos .. -1 ]
                        :   ();

            $semval = $code ? &$code( $self, @sempar )
                            : @sempar ? $sempar[0] : undef;

            splice(@$stack,-$len,$len);

                $$check eq 'ACCEPT'
            and do {

#DBG>			$debug & 0x04
#DBG>		and	print STDERR "Accept.\n";

				return($semval);
			};

                $$check eq 'ABORT'
            and	do {

#DBG>			$debug & 0x04
#DBG>		and	print STDERR "Abort.\n";

				return(undef);

			};

#DBG>			$debug & 0x04
#DBG>		and	print STDERR "Back to state $$stack[-1][0], then ";

                $$check eq 'ERROR'
            or  do {
#DBG>				$debug & 0x04
#DBG>			and	print STDERR 
#DBG>				    "go to state $$states[$$stack[-1][0]]{GOTOS}{$lhs}.\n";

#DBG>				$debug & 0x10
#DBG>			and	$dbgerror
#DBG>			and	$$errstatus == 0
#DBG>			and	do {
#DBG>				print STDERR "**End of Error recovery.\n";
#DBG>				$dbgerror=0;
#DBG>			};

			    push(@$stack,
                     [ $$states[$$stack[-1][0]]{GOTOS}{$lhs}, $semval ]);
                $$check='';
                next;
            };

#DBG>			$debug & 0x04
#DBG>		and	print STDERR "Forced Error recovery.\n";

            $$check='';

        };

        #Error
            $$errstatus
        or   do {

            $$errstatus = 1;
            &$error($self);
                $$errstatus # if 0, then YYErrok has been called
            or  next;       # so continue parsing

#DBG>			$debug & 0x10
#DBG>		and	do {
#DBG>			print STDERR "**Entering Error recovery.\n";
#DBG>			++$dbgerror;
#DBG>		};

            ++$$nberror;

        };

			$$errstatus == 3	#The next token is not valid: discard it
		and	do {
				$$token eq ''	# End of input: no hope
			and	do {
#DBG>				$debug & 0x10
#DBG>			and	print STDERR "**At eof: aborting.\n";
				return(undef);
			};

#DBG>			$debug & 0x10
#DBG>		and	print STDERR "**Dicard invalid token ".&$ShowCurToken.".\n";

			$$token=$$value=undef;
		};

        $$errstatus=3;

		while(	  @$stack
			  and (		not exists($$states[$$stack[-1][0]]{ACTIONS})
			        or  not exists($$states[$$stack[-1][0]]{ACTIONS}{error})
					or	$$states[$$stack[-1][0]]{ACTIONS}{error} <= 0)) {

#DBG>			$debug & 0x10
#DBG>		and	print STDERR "**Pop state $$stack[-1][0].\n";

			pop(@$stack);
		}

			@$stack
		or	do {

#DBG>			$debug & 0x10
#DBG>		and	print STDERR "**No state left on stack: aborting.\n";

			return(undef);
		};

		#shift the error token

#DBG>			$debug & 0x10
#DBG>		and	print STDERR "**Shift \$error token and go to state ".
#DBG>						 $$states[$$stack[-1][0]]{ACTIONS}{error}.
#DBG>						 ".\n";

		push(@$stack, [ $$states[$$stack[-1][0]]{ACTIONS}{error}, undef ]);

    }

    #never reached
	croak("Error in driver logic. Please, report it as a BUG");

}#_Parse
#DO NOT remove comment

1;

}
#End of include--------------------------------------------------




sub new {
        my($class)=shift;
        ref($class)
    and $class=ref($class);

    my($self)=$class->SUPER::new( yyversion => '1.21',
                                  yystates =>
[
	{#State 0
		ACTIONS => {
			"enum" => 4,
			'p_include' => 19,
			'COMMENT' => 20,
			'p_typemap' => 47,
			'p_name' => 34,
			"class" => 32,
			'RAW_CODE' => 3,
			'p_exceptionmap' => 17,
			'p__type' => 14,
			'p_file' => 1,
			'PREPROCESSOR' => 27,
			"void" => 29,
			"const" => 24,
			"char" => 13,
			"short" => 42,
			"int" => 54,
			'OPSPECIAL' => 40,
			'p_package' => 7,
			'p_module' => 51,
			'ID' => 6,
			'p_loadplugin' => 49,
			"unsigned" => 50,
			'p_any' => 48,
			"long" => 37
		},
		GOTOS => {
			'basic_type' => 52,
			'typemap' => 23,
			'perc_include' => 22,
			'decorate_class' => 21,
			'perc_name' => 53,
			'class' => 45,
			'directive' => 44,
			'perc_loadplugin' => 43,
			'type' => 12,
			'raw' => 18,
			'class_name' => 46,
			'perc_module' => 16,
			'type_name' => 15,
			'nconsttype' => 38,
			'function_decl' => 39,
			'special_block' => 5,
			'class_decl' => 11,
			'template' => 41,
			'perc_package' => 10,
			'perc_file' => 9,
			'function' => 8,
			'exceptionmap' => 30,
			'top_list' => 26,
			'_top' => 28,
			'looks_like_function' => 25,
			'enum' => 36,
			'special_block_start' => 35,
			'perc_any' => 33,
			'looks_like_renamed_function' => 31,
			'top' => 2
		}
	},
	{#State 1
		ACTIONS => {
			'OPCURLY' => 55
		}
	},
	{#State 2
		DEFAULT => -1
	},
	{#State 3
		DEFAULT => -26
	},
	{#State 4
		ACTIONS => {
			'OPCURLY' => 57,
			'ID' => 56
		}
	},
	{#State 5
		DEFAULT => -29
	},
	{#State 6
		ACTIONS => {
			'DCOLON' => 59
		},
		DEFAULT => -147,
		GOTOS => {
			'class_suffix' => 58
		}
	},
	{#State 7
		ACTIONS => {
			'OPCURLY' => 60
		}
	},
	{#State 8
		DEFAULT => -9
	},
	{#State 9
		ACTIONS => {
			'SEMICOLON' => 61
		}
	},
	{#State 10
		ACTIONS => {
			'SEMICOLON' => 62
		}
	},
	{#State 11
		ACTIONS => {
			'SEMICOLON' => 63
		}
	},
	{#State 12
		ACTIONS => {
			'ID' => 64
		}
	},
	{#State 13
		DEFAULT => -138
	},
	{#State 14
		ACTIONS => {
			'OPCURLY' => 65
		}
	},
	{#State 15
		DEFAULT => -131
	},
	{#State 16
		ACTIONS => {
			'SEMICOLON' => 66
		}
	},
	{#State 17
		ACTIONS => {
			'OPCURLY' => 67
		}
	},
	{#State 18
		DEFAULT => -5
	},
	{#State 19
		ACTIONS => {
			'OPCURLY' => 68
		}
	},
	{#State 20
		DEFAULT => -27
	},
	{#State 21
		ACTIONS => {
			'SEMICOLON' => 69
		}
	},
	{#State 22
		ACTIONS => {
			'SEMICOLON' => 70
		}
	},
	{#State 23
		DEFAULT => -16
	},
	{#State 24
		ACTIONS => {
			'ID' => 6,
			"char" => 13,
			"long" => 37,
			"void" => 29,
			"unsigned" => 50,
			"int" => 54,
			"short" => 42
		},
		GOTOS => {
			'type_name' => 15,
			'nconsttype' => 71,
			'class_name' => 46,
			'basic_type' => 52,
			'template' => 41
		}
	},
	{#State 25
		DEFAULT => -86
	},
	{#State 26
		ACTIONS => {
			'p_package' => 7,
			'ID' => 6,
			"long" => 37,
			"short" => 42,
			'OPSPECIAL' => 40,
			'p_file' => 1,
			"void" => 29,
			'PREPROCESSOR' => 27,
			"const" => 24,
			"enum" => 4,
			'p_name' => 34,
			"class" => 32,
			'RAW_CODE' => 3,
			'' => 73,
			'p_module' => 51,
			"unsigned" => 50,
			'p_loadplugin' => 49,
			'p_any' => 48,
			"int" => 54,
			"char" => 13,
			'COMMENT' => 20,
			'p_include' => 19,
			'p_typemap' => 47,
			'p_exceptionmap' => 17
		},
		GOTOS => {
			'_top' => 28,
			'looks_like_function' => 25,
			'exceptionmap' => 30,
			'perc_any' => 33,
			'top' => 72,
			'looks_like_renamed_function' => 31,
			'enum' => 36,
			'special_block_start' => 35,
			'special_block' => 5,
			'nconsttype' => 38,
			'function_decl' => 39,
			'perc_file' => 9,
			'function' => 8,
			'template' => 41,
			'class_decl' => 11,
			'perc_package' => 10,
			'type' => 12,
			'class' => 45,
			'perc_loadplugin' => 43,
			'directive' => 44,
			'class_name' => 46,
			'type_name' => 15,
			'perc_module' => 16,
			'raw' => 18,
			'perc_include' => 22,
			'decorate_class' => 21,
			'typemap' => 23,
			'basic_type' => 52,
			'perc_name' => 53
		}
	},
	{#State 27
		DEFAULT => -28
	},
	{#State 28
		DEFAULT => -4
	},
	{#State 29
		DEFAULT => -135
	},
	{#State 30
		DEFAULT => -17
	},
	{#State 31
		DEFAULT => -95,
		GOTOS => {
			'function_metadata' => 74
		}
	},
	{#State 32
		ACTIONS => {
			'ID' => 6
		},
		GOTOS => {
			'class_name' => 75
		}
	},
	{#State 33
		ACTIONS => {
			'SEMICOLON' => 76
		}
	},
	{#State 34
		ACTIONS => {
			'OPCURLY' => 77
		}
	},
	{#State 35
		ACTIONS => {
			'CLSPECIAL' => 81,
			'line' => 78
		},
		GOTOS => {
			'special_block_end' => 79,
			'lines' => 80
		}
	},
	{#State 36
		DEFAULT => -8
	},
	{#State 37
		ACTIONS => {
			"int" => 82
		},
		DEFAULT => -140
	},
	{#State 38
		ACTIONS => {
			'STAR' => 84,
			'AMP' => 83
		},
		DEFAULT => -128
	},
	{#State 39
		ACTIONS => {
			'SEMICOLON' => 85
		}
	},
	{#State 40
		DEFAULT => -184
	},
	{#State 41
		DEFAULT => -132
	},
	{#State 42
		ACTIONS => {
			"int" => 86
		},
		DEFAULT => -141
	},
	{#State 43
		ACTIONS => {
			'SEMICOLON' => 87
		}
	},
	{#State 44
		DEFAULT => -7
	},
	{#State 45
		DEFAULT => -6
	},
	{#State 46
		ACTIONS => {
			'OPANG' => 88
		},
		DEFAULT => -133
	},
	{#State 47
		ACTIONS => {
			'OPCURLY' => 89
		}
	},
	{#State 48
		ACTIONS => {
			'OPCURLY' => 90,
			'OPSPECIAL' => 40
		},
		DEFAULT => -122,
		GOTOS => {
			'special_block_start' => 35,
			'special_block' => 91
		}
	},
	{#State 49
		ACTIONS => {
			'OPCURLY' => 92
		}
	},
	{#State 50
		ACTIONS => {
			"char" => 13,
			"long" => 37,
			"int" => 54,
			"short" => 42
		},
		DEFAULT => -136,
		GOTOS => {
			'basic_type' => 93
		}
	},
	{#State 51
		ACTIONS => {
			'OPCURLY' => 94
		}
	},
	{#State 52
		DEFAULT => -134
	},
	{#State 53
		ACTIONS => {
			"short" => 42,
			"int" => 54,
			"class" => 32,
			'ID' => 6,
			"unsigned" => 50,
			"void" => 29,
			"const" => 24,
			"long" => 37,
			"char" => 13
		},
		GOTOS => {
			'basic_type' => 52,
			'class_decl' => 96,
			'template' => 41,
			'type' => 12,
			'type_name' => 15,
			'class_name' => 46,
			'nconsttype' => 38,
			'looks_like_function' => 95
		}
	},
	{#State 54
		DEFAULT => -139
	},
	{#State 55
		ACTIONS => {
			'ID' => 98,
			'DASH' => 97
		},
		GOTOS => {
			'file_name' => 99
		}
	},
	{#State 56
		ACTIONS => {
			'OPCURLY' => 100
		}
	},
	{#State 57
		DEFAULT => -32,
		GOTOS => {
			'enum_element_list' => 101
		}
	},
	{#State 58
		ACTIONS => {
			'DCOLON' => 102
		},
		DEFAULT => -148
	},
	{#State 59
		ACTIONS => {
			'ID' => 103
		}
	},
	{#State 60
		ACTIONS => {
			'ID' => 6
		},
		GOTOS => {
			'class_name' => 104
		}
	},
	{#State 61
		DEFAULT => -12
	},
	{#State 62
		DEFAULT => -11
	},
	{#State 63
		DEFAULT => -38
	},
	{#State 64
		ACTIONS => {
			'OPPAR' => 105
		}
	},
	{#State 65
		ACTIONS => {
			"short" => 42,
			"int" => 54,
			'ID' => 6,
			"unsigned" => 50,
			"void" => 29,
			"long" => 37,
			"char" => 13,
			"const" => 24
		},
		GOTOS => {
			'type' => 106,
			'type_name' => 15,
			'class_name' => 46,
			'nconsttype' => 38,
			'basic_type' => 52,
			'template' => 41
		}
	},
	{#State 66
		DEFAULT => -10
	},
	{#State 67
		ACTIONS => {
			'ID' => 107
		}
	},
	{#State 68
		ACTIONS => {
			'ID' => 98,
			'DASH' => 97
		},
		GOTOS => {
			'file_name' => 108
		}
	},
	{#State 69
		DEFAULT => -39
	},
	{#State 70
		DEFAULT => -14
	},
	{#State 71
		ACTIONS => {
			'STAR' => 84,
			'AMP' => 83
		},
		DEFAULT => -127
	},
	{#State 72
		DEFAULT => -2
	},
	{#State 73
		DEFAULT => 0
	},
	{#State 74
		ACTIONS => {
			'p_catch' => 112,
			'p_postcall' => 113,
			'p_any' => 48,
			'p_alias' => 118,
			'p_cleanup' => 116,
			'p_code' => 120
		},
		DEFAULT => -88,
		GOTOS => {
			'perc_cleanup' => 111,
			'perc_postcall' => 110,
			'perc_catch' => 115,
			'perc_any' => 114,
			'_function_metadata' => 119,
			'perc_alias' => 117,
			'perc_code' => 109
		}
	},
	{#State 75
		ACTIONS => {
			'COLON' => 121
		},
		DEFAULT => -47,
		GOTOS => {
			'base_classes' => 122
		}
	},
	{#State 76
		DEFAULT => -15
	},
	{#State 77
		ACTIONS => {
			'ID' => 6
		},
		GOTOS => {
			'class_name' => 123
		}
	},
	{#State 78
		DEFAULT => -186
	},
	{#State 79
		DEFAULT => -183
	},
	{#State 80
		ACTIONS => {
			'line' => 124,
			'CLSPECIAL' => 81
		},
		GOTOS => {
			'special_block_end' => 125
		}
	},
	{#State 81
		DEFAULT => -185
	},
	{#State 82
		DEFAULT => -142
	},
	{#State 83
		DEFAULT => -130
	},
	{#State 84
		DEFAULT => -129
	},
	{#State 85
		DEFAULT => -40
	},
	{#State 86
		DEFAULT => -143
	},
	{#State 87
		DEFAULT => -13
	},
	{#State 88
		ACTIONS => {
			"const" => 24,
			"long" => 37,
			"char" => 13,
			"unsigned" => 50,
			"void" => 29,
			'ID' => 6,
			"int" => 54,
			"short" => 42
		},
		GOTOS => {
			'class_name' => 46,
			'type_name' => 15,
			'type_list' => 127,
			'template' => 41,
			'nconsttype' => 38,
			'type' => 126,
			'basic_type' => 52
		}
	},
	{#State 89
		ACTIONS => {
			'ID' => 6,
			"long" => 37,
			"char" => 13,
			"const" => 24,
			"unsigned" => 50,
			"void" => 29,
			"int" => 54,
			"short" => 42
		},
		GOTOS => {
			'type_name' => 15,
			'type' => 128,
			'nconsttype' => 38,
			'class_name' => 46,
			'basic_type' => 52,
			'template' => 41
		}
	},
	{#State 90
		ACTIONS => {
			'p_any' => 129,
			'p_name' => 34,
			'ID' => 133
		},
		GOTOS => {
			'perc_name' => 130,
			'perc_any_args' => 132,
			'perc_any_arg' => 131
		}
	},
	{#State 91
		DEFAULT => -24,
		GOTOS => {
			'mixed_blocks' => 134
		}
	},
	{#State 92
		ACTIONS => {
			'ID' => 6
		},
		GOTOS => {
			'class_name' => 135
		}
	},
	{#State 93
		DEFAULT => -137
	},
	{#State 94
		ACTIONS => {
			'ID' => 6
		},
		GOTOS => {
			'class_name' => 136
		}
	},
	{#State 95
		DEFAULT => -87
	},
	{#State 96
		DEFAULT => -43
	},
	{#State 97
		DEFAULT => -153
	},
	{#State 98
		ACTIONS => {
			'DOT' => 137,
			'SLASH' => 138
		}
	},
	{#State 99
		ACTIONS => {
			'CLCURLY' => 139
		}
	},
	{#State 100
		DEFAULT => -32,
		GOTOS => {
			'enum_element_list' => 140
		}
	},
	{#State 101
		ACTIONS => {
			'CLCURLY' => 142,
			'OPSPECIAL' => 40,
			'RAW_CODE' => 3,
			'COMMENT' => 20,
			'PREPROCESSOR' => 27,
			'ID' => 143
		},
		GOTOS => {
			'raw' => 141,
			'special_block_start' => 35,
			'enum_element' => 144,
			'special_block' => 5
		}
	},
	{#State 102
		ACTIONS => {
			'ID' => 145
		}
	},
	{#State 103
		DEFAULT => -151
	},
	{#State 104
		ACTIONS => {
			'CLCURLY' => 146
		}
	},
	{#State 105
		ACTIONS => {
			"int" => 54,
			"short" => 42,
			"long" => 37,
			"char" => 13,
			"const" => 24,
			"unsigned" => 50,
			"void" => 151,
			'ID' => 6
		},
		DEFAULT => -160,
		GOTOS => {
			'arg_list' => 150,
			'nonvoid_arg_list' => 149,
			'template' => 41,
			'basic_type' => 52,
			'class_name' => 46,
			'nconsttype' => 38,
			'type' => 147,
			'argument' => 148,
			'type_name' => 15
		}
	},
	{#State 106
		ACTIONS => {
			'CLCURLY' => 152
		}
	},
	{#State 107
		ACTIONS => {
			'CLCURLY' => 153
		}
	},
	{#State 108
		ACTIONS => {
			'CLCURLY' => 154
		}
	},
	{#State 109
		DEFAULT => -102
	},
	{#State 110
		DEFAULT => -104
	},
	{#State 111
		DEFAULT => -103
	},
	{#State 112
		ACTIONS => {
			'OPCURLY' => 155
		}
	},
	{#State 113
		ACTIONS => {
			'OPSPECIAL' => 40
		},
		GOTOS => {
			'special_block_start' => 35,
			'special_block' => 156
		}
	},
	{#State 114
		DEFAULT => -107
	},
	{#State 115
		DEFAULT => -105
	},
	{#State 116
		ACTIONS => {
			'OPSPECIAL' => 40
		},
		GOTOS => {
			'special_block' => 157,
			'special_block_start' => 35
		}
	},
	{#State 117
		DEFAULT => -106
	},
	{#State 118
		ACTIONS => {
			'OPCURLY' => 158
		}
	},
	{#State 119
		DEFAULT => -94
	},
	{#State 120
		ACTIONS => {
			'OPSPECIAL' => 40
		},
		GOTOS => {
			'special_block_start' => 35,
			'special_block' => 159
		}
	},
	{#State 121
		ACTIONS => {
			"private" => 163,
			"protected" => 161,
			"public" => 160
		},
		GOTOS => {
			'base_class' => 162
		}
	},
	{#State 122
		ACTIONS => {
			'COMMA' => 164
		},
		DEFAULT => -55,
		GOTOS => {
			'class_metadata' => 165
		}
	},
	{#State 123
		ACTIONS => {
			'CLCURLY' => 166
		}
	},
	{#State 124
		DEFAULT => -187
	},
	{#State 125
		DEFAULT => -182
	},
	{#State 126
		DEFAULT => -145
	},
	{#State 127
		ACTIONS => {
			'COMMA' => 168,
			'CLANG' => 167
		}
	},
	{#State 128
		ACTIONS => {
			'CLCURLY' => 169
		}
	},
	{#State 129
		DEFAULT => -24,
		GOTOS => {
			'mixed_blocks' => 170
		}
	},
	{#State 130
		ACTIONS => {
			'SEMICOLON' => 171
		}
	},
	{#State 131
		DEFAULT => -123
	},
	{#State 132
		ACTIONS => {
			'p_name' => 34,
			'p_any' => 129,
			'CLCURLY' => 173
		},
		GOTOS => {
			'perc_name' => 130,
			'perc_any_arg' => 172
		}
	},
	{#State 133
		ACTIONS => {
			'CLCURLY' => 174
		}
	},
	{#State 134
		ACTIONS => {
			'OPSPECIAL' => 40,
			'OPCURLY' => 177
		},
		DEFAULT => -121,
		GOTOS => {
			'special_block' => 176,
			'special_block_start' => 35,
			'simple_block' => 175
		}
	},
	{#State 135
		ACTIONS => {
			'CLCURLY' => 178
		}
	},
	{#State 136
		ACTIONS => {
			'CLCURLY' => 179
		}
	},
	{#State 137
		ACTIONS => {
			'ID' => 180
		}
	},
	{#State 138
		ACTIONS => {
			'DASH' => 97,
			'ID' => 98
		},
		GOTOS => {
			'file_name' => 181
		}
	},
	{#State 139
		DEFAULT => -112
	},
	{#State 140
		ACTIONS => {
			'ID' => 143,
			'COMMENT' => 20,
			'CLCURLY' => 182,
			'OPSPECIAL' => 40,
			'PREPROCESSOR' => 27,
			'RAW_CODE' => 3
		},
		GOTOS => {
			'special_block_start' => 35,
			'raw' => 141,
			'special_block' => 5,
			'enum_element' => 144
		}
	},
	{#State 141
		DEFAULT => -37
	},
	{#State 142
		ACTIONS => {
			'SEMICOLON' => 183
		}
	},
	{#State 143
		ACTIONS => {
			'EQUAL' => 184
		},
		DEFAULT => -35
	},
	{#State 144
		ACTIONS => {
			'COMMA' => 185
		},
		DEFAULT => -33
	},
	{#State 145
		DEFAULT => -152
	},
	{#State 146
		DEFAULT => -110
	},
	{#State 147
		ACTIONS => {
			'p_length' => 186,
			'ID' => 187
		}
	},
	{#State 148
		DEFAULT => -158
	},
	{#State 149
		ACTIONS => {
			'COMMA' => 188
		},
		DEFAULT => -156
	},
	{#State 150
		ACTIONS => {
			'CLPAR' => 189
		}
	},
	{#State 151
		ACTIONS => {
			'CLPAR' => -157
		},
		DEFAULT => -135
	},
	{#State 152
		DEFAULT => -3
	},
	{#State 153
		ACTIONS => {
			'OPCURLY' => 190
		}
	},
	{#State 154
		DEFAULT => -114
	},
	{#State 155
		ACTIONS => {
			'ID' => 6
		},
		GOTOS => {
			'class_name_list' => 191,
			'class_name' => 192
		}
	},
	{#State 156
		DEFAULT => -117
	},
	{#State 157
		DEFAULT => -116
	},
	{#State 158
		ACTIONS => {
			'ID' => 193
		}
	},
	{#State 159
		DEFAULT => -115
	},
	{#State 160
		ACTIONS => {
			'ID' => 6,
			'p_name' => 34
		},
		GOTOS => {
			'class_name' => 196,
			'perc_name' => 195,
			'class_name_rename' => 194
		}
	},
	{#State 161
		ACTIONS => {
			'p_name' => 34,
			'ID' => 6
		},
		GOTOS => {
			'class_name_rename' => 197,
			'perc_name' => 195,
			'class_name' => 196
		}
	},
	{#State 162
		DEFAULT => -45
	},
	{#State 163
		ACTIONS => {
			'ID' => 6,
			'p_name' => 34
		},
		GOTOS => {
			'class_name' => 196,
			'perc_name' => 195,
			'class_name_rename' => 198
		}
	},
	{#State 164
		ACTIONS => {
			"private" => 163,
			"protected" => 161,
			"public" => 160
		},
		GOTOS => {
			'base_class' => 199
		}
	},
	{#State 165
		ACTIONS => {
			'OPCURLY' => 202,
			'p_any' => 48,
			'p_catch' => 112
		},
		GOTOS => {
			'perc_catch' => 200,
			'perc_any' => 201
		}
	},
	{#State 166
		DEFAULT => -108
	},
	{#State 167
		DEFAULT => -144
	},
	{#State 168
		ACTIONS => {
			'ID' => 6,
			"void" => 29,
			"unsigned" => 50,
			"const" => 24,
			"char" => 13,
			"long" => 37,
			"short" => 42,
			"int" => 54
		},
		GOTOS => {
			'type_name' => 15,
			'type' => 203,
			'nconsttype' => 38,
			'class_name' => 46,
			'basic_type' => 52,
			'template' => 41
		}
	},
	{#State 169
		ACTIONS => {
			'SEMICOLON' => 204,
			'OPCURLY' => 205
		}
	},
	{#State 170
		ACTIONS => {
			'OPCURLY' => 177,
			'OPSPECIAL' => 40,
			'SEMICOLON' => 206
		},
		GOTOS => {
			'special_block' => 176,
			'special_block_start' => 35,
			'simple_block' => 175
		}
	},
	{#State 171
		DEFAULT => -126
	},
	{#State 172
		DEFAULT => -124
	},
	{#State 173
		DEFAULT => -119
	},
	{#State 174
		DEFAULT => -24,
		GOTOS => {
			'mixed_blocks' => 207
		}
	},
	{#State 175
		DEFAULT => -23
	},
	{#State 176
		DEFAULT => -22
	},
	{#State 177
		ACTIONS => {
			'ID' => 208
		}
	},
	{#State 178
		DEFAULT => -113
	},
	{#State 179
		DEFAULT => -111
	},
	{#State 180
		DEFAULT => -154
	},
	{#State 181
		DEFAULT => -155
	},
	{#State 182
		ACTIONS => {
			'SEMICOLON' => 209
		}
	},
	{#State 183
		DEFAULT => -30
	},
	{#State 184
		ACTIONS => {
			'FLOAT' => 213,
			'QUOTED_STRING' => 211,
			'DASH' => 216,
			'INTEGER' => 212,
			'ID' => 6
		},
		GOTOS => {
			'class_name' => 210,
			'value' => 214,
			'expression' => 215
		}
	},
	{#State 185
		DEFAULT => -34
	},
	{#State 186
		ACTIONS => {
			'OPCURLY' => 217
		}
	},
	{#State 187
		DEFAULT => -162,
		GOTOS => {
			'argument_metadata' => 218
		}
	},
	{#State 188
		ACTIONS => {
			"int" => 54,
			"short" => 42,
			"long" => 37,
			"char" => 13,
			"const" => 24,
			"void" => 29,
			"unsigned" => 50,
			'ID' => 6
		},
		GOTOS => {
			'class_name' => 46,
			'type_name' => 15,
			'template' => 41,
			'nconsttype' => 38,
			'argument' => 219,
			'type' => 147,
			'basic_type' => 52
		}
	},
	{#State 189
		ACTIONS => {
			"const" => 220
		},
		DEFAULT => -80,
		GOTOS => {
			'const' => 221
		}
	},
	{#State 190
		ACTIONS => {
			"int" => 54,
			"short" => 42,
			"char" => 13,
			"long" => 37,
			"unsigned" => 50,
			"void" => 29,
			'ID' => 6
		},
		GOTOS => {
			'basic_type' => 52,
			'type_name' => 222,
			'class_name' => 223
		}
	},
	{#State 191
		ACTIONS => {
			'CLCURLY' => 225,
			'COMMA' => 224
		}
	},
	{#State 192
		DEFAULT => -149
	},
	{#State 193
		ACTIONS => {
			'EQUAL' => 226
		}
	},
	{#State 194
		DEFAULT => -48
	},
	{#State 195
		ACTIONS => {
			'ID' => 6
		},
		GOTOS => {
			'class_name' => 227
		}
	},
	{#State 196
		DEFAULT => -51
	},
	{#State 197
		DEFAULT => -49
	},
	{#State 198
		DEFAULT => -50
	},
	{#State 199
		DEFAULT => -46
	},
	{#State 200
		DEFAULT => -53
	},
	{#State 201
		DEFAULT => -54
	},
	{#State 202
		DEFAULT => -56,
		GOTOS => {
			'class_body_list' => 228
		}
	},
	{#State 203
		DEFAULT => -146
	},
	{#State 204
		DEFAULT => -20
	},
	{#State 205
		ACTIONS => {
			'ID' => 229
		}
	},
	{#State 206
		DEFAULT => -125
	},
	{#State 207
		ACTIONS => {
			'OPCURLY' => 177,
			'OPSPECIAL' => 40
		},
		DEFAULT => -120,
		GOTOS => {
			'special_block_start' => 35,
			'simple_block' => 175,
			'special_block' => 176
		}
	},
	{#State 208
		ACTIONS => {
			'CLCURLY' => 230
		}
	},
	{#State 209
		DEFAULT => -31
	},
	{#State 210
		ACTIONS => {
			'OPPAR' => 231
		},
		DEFAULT => -171
	},
	{#State 211
		DEFAULT => -170
	},
	{#State 212
		DEFAULT => -167
	},
	{#State 213
		DEFAULT => -169
	},
	{#State 214
		ACTIONS => {
			'PIPE' => 232,
			'AMP' => 233
		},
		DEFAULT => -176
	},
	{#State 215
		DEFAULT => -36
	},
	{#State 216
		ACTIONS => {
			'INTEGER' => 234
		}
	},
	{#State 217
		ACTIONS => {
			'ID' => 235
		}
	},
	{#State 218
		ACTIONS => {
			'EQUAL' => 236,
			'p_any' => 48
		},
		DEFAULT => -166,
		GOTOS => {
			'_argument_metadata' => 237,
			'perc_any' => 238
		}
	},
	{#State 219
		DEFAULT => -159
	},
	{#State 220
		DEFAULT => -79
	},
	{#State 221
		DEFAULT => -85
	},
	{#State 222
		ACTIONS => {
			'CLCURLY' => 239
		}
	},
	{#State 223
		DEFAULT => -133
	},
	{#State 224
		ACTIONS => {
			'ID' => 6
		},
		GOTOS => {
			'class_name' => 240
		}
	},
	{#State 225
		DEFAULT => -118
	},
	{#State 226
		ACTIONS => {
			'INTEGER' => 241
		}
	},
	{#State 227
		DEFAULT => -52
	},
	{#State 228
		ACTIONS => {
			"virtual" => 272,
			"long" => 37,
			'ID' => 258,
			'OPSPECIAL' => 40,
			'CLCURLY' => 254,
			"static" => 271,
			"short" => 42,
			"void" => 29,
			'PREPROCESSOR' => 27,
			"const" => 24,
			"package_static" => 250,
			'TILDE' => 251,
			'RAW_CODE' => 3,
			'p_name' => 34,
			"unsigned" => 50,
			'p_any' => 48,
			"class_static" => 247,
			"protected" => 248,
			"private" => 264,
			"int" => 54,
			"public" => 246,
			"char" => 13,
			'p_exceptionmap' => 17,
			'COMMENT' => 20,
			'p_typemap' => 47
		},
		DEFAULT => -71,
		GOTOS => {
			'vmethod' => 268,
			'looks_like_function' => 25,
			'virtual' => 270,
			'exceptionmap' => 269,
			'looks_like_renamed_function' => 267,
			'perc_any' => 266,
			'special_block_start' => 35,
			'nconsttype' => 38,
			'special_block' => 5,
			'looks_like_member' => 255,
			'class_body_element' => 256,
			'static' => 257,
			'method_decl' => 252,
			'member_decl' => 253,
			'template' => 41,
			'type' => 243,
			'dtor' => 262,
			'type_name' => 15,
			'class_name' => 46,
			'method' => 260,
			'nmethod' => 259,
			'member' => 261,
			'raw' => 242,
			'_vmethod' => 265,
			'basic_type' => 52,
			'typemap' => 249,
			'ctor' => 245,
			'perc_name' => 263,
			'access_specifier' => 244
		}
	},
	{#State 229
		ACTIONS => {
			'CLCURLY' => 273
		}
	},
	{#State 230
		DEFAULT => -25
	},
	{#State 231
		ACTIONS => {
			'FLOAT' => 213,
			'DASH' => 216,
			'INTEGER' => 212,
			'ID' => 6,
			'QUOTED_STRING' => 211
		},
		DEFAULT => -175,
		GOTOS => {
			'value' => 275,
			'class_name' => 210,
			'value_list' => 274
		}
	},
	{#State 232
		ACTIONS => {
			'DASH' => 216,
			'INTEGER' => 212,
			'ID' => 6,
			'QUOTED_STRING' => 211,
			'FLOAT' => 213
		},
		GOTOS => {
			'class_name' => 210,
			'value' => 276
		}
	},
	{#State 233
		ACTIONS => {
			'FLOAT' => 213,
			'QUOTED_STRING' => 211,
			'INTEGER' => 212,
			'ID' => 6,
			'DASH' => 216
		},
		GOTOS => {
			'value' => 277,
			'class_name' => 210
		}
	},
	{#State 234
		DEFAULT => -168
	},
	{#State 235
		ACTIONS => {
			'CLCURLY' => 278
		}
	},
	{#State 236
		ACTIONS => {
			'ID' => 6,
			'INTEGER' => 212,
			'DASH' => 216,
			'QUOTED_STRING' => 211,
			'FLOAT' => 213
		},
		GOTOS => {
			'value' => 214,
			'class_name' => 210,
			'expression' => 279
		}
	},
	{#State 237
		DEFAULT => -161
	},
	{#State 238
		DEFAULT => -163
	},
	{#State 239
		ACTIONS => {
			'OPCURLY' => 280
		}
	},
	{#State 240
		DEFAULT => -150
	},
	{#State 241
		ACTIONS => {
			'CLCURLY' => 281
		}
	},
	{#State 242
		DEFAULT => -59
	},
	{#State 243
		ACTIONS => {
			'ID' => 282
		}
	},
	{#State 244
		DEFAULT => -62
	},
	{#State 245
		DEFAULT => -77
	},
	{#State 246
		ACTIONS => {
			'COLON' => 283
		}
	},
	{#State 247
		DEFAULT => -83
	},
	{#State 248
		ACTIONS => {
			'COLON' => 284
		}
	},
	{#State 249
		DEFAULT => -60
	},
	{#State 250
		DEFAULT => -82
	},
	{#State 251
		ACTIONS => {
			'ID' => 285
		}
	},
	{#State 252
		ACTIONS => {
			'SEMICOLON' => 286
		}
	},
	{#State 253
		ACTIONS => {
			'SEMICOLON' => 287
		}
	},
	{#State 254
		DEFAULT => -44
	},
	{#State 255
		DEFAULT => -72
	},
	{#State 256
		DEFAULT => -57
	},
	{#State 257
		ACTIONS => {
			"short" => 42,
			"static" => 271,
			"int" => 54,
			"class_static" => 247,
			'ID' => 6,
			"unsigned" => 50,
			"long" => 37,
			'p_name' => 34,
			"void" => 29,
			"package_static" => 250,
			"const" => 24,
			"char" => 13
		},
		GOTOS => {
			'static' => 257,
			'basic_type' => 52,
			'looks_like_function' => 25,
			'nconsttype' => 38,
			'type' => 12,
			'template' => 41,
			'perc_name' => 289,
			'class_name' => 46,
			'nmethod' => 288,
			'type_name' => 15,
			'looks_like_renamed_function' => 267
		}
	},
	{#State 258
		ACTIONS => {
			'DCOLON' => 59,
			'OPPAR' => 290
		},
		DEFAULT => -147,
		GOTOS => {
			'class_suffix' => 58
		}
	},
	{#State 259
		DEFAULT => -75
	},
	{#State 260
		DEFAULT => -58
	},
	{#State 261
		DEFAULT => -63
	},
	{#State 262
		DEFAULT => -78
	},
	{#State 263
		ACTIONS => {
			'ID' => 258,
			"virtual" => 272,
			"unsigned" => 50,
			"long" => 37,
			"short" => 42,
			"int" => 54,
			'TILDE' => 251,
			"void" => 29,
			"const" => 24,
			"char" => 13,
			'p_name' => 34
		},
		GOTOS => {
			'basic_type' => 52,
			'looks_like_member' => 294,
			'_vmethod' => 265,
			'nconsttype' => 38,
			'template' => 41,
			'perc_name' => 292,
			'ctor' => 295,
			'virtual' => 270,
			'type' => 243,
			'dtor' => 293,
			'looks_like_function' => 95,
			'vmethod' => 291,
			'type_name' => 15,
			'class_name' => 46
		}
	},
	{#State 264
		ACTIONS => {
			'COLON' => 296
		}
	},
	{#State 265
		DEFAULT => -98
	},
	{#State 266
		ACTIONS => {
			'SEMICOLON' => 297
		}
	},
	{#State 267
		DEFAULT => -95,
		GOTOS => {
			'function_metadata' => 298
		}
	},
	{#State 268
		DEFAULT => -76
	},
	{#State 269
		DEFAULT => -61
	},
	{#State 270
		ACTIONS => {
			"short" => 42,
			'p_name' => 34,
			"int" => 54,
			"virtual" => 272,
			"void" => 29,
			"unsigned" => 50,
			"const" => 24,
			"long" => 37,
			"char" => 13,
			'TILDE' => 251,
			'ID' => 6
		},
		GOTOS => {
			'virtual' => 299,
			'basic_type' => 52,
			'nconsttype' => 38,
			'looks_like_function' => 300,
			'dtor' => 301,
			'type' => 12,
			'template' => 41,
			'class_name' => 46,
			'perc_name' => 302,
			'type_name' => 15
		}
	},
	{#State 271
		DEFAULT => -84
	},
	{#State 272
		DEFAULT => -81
	},
	{#State 273
		ACTIONS => {
			'OPSPECIAL' => 40,
			'OPCURLY' => 305
		},
		DEFAULT => -181,
		GOTOS => {
			'special_blocks' => 303,
			'special_block_start' => 35,
			'special_block' => 304
		}
	},
	{#State 274
		ACTIONS => {
			'COMMA' => 307,
			'CLPAR' => 306
		}
	},
	{#State 275
		DEFAULT => -173
	},
	{#State 276
		DEFAULT => -178
	},
	{#State 277
		DEFAULT => -177
	},
	{#State 278
		DEFAULT => -164
	},
	{#State 279
		DEFAULT => -165
	},
	{#State 280
		ACTIONS => {
			'ID' => 308
		}
	},
	{#State 281
		DEFAULT => -109
	},
	{#State 282
		ACTIONS => {
			'OPPAR' => 105
		},
		DEFAULT => -69,
		GOTOS => {
			'member_metadata' => 309
		}
	},
	{#State 283
		DEFAULT => -65
	},
	{#State 284
		DEFAULT => -66
	},
	{#State 285
		ACTIONS => {
			'OPPAR' => 310
		}
	},
	{#State 286
		DEFAULT => -41
	},
	{#State 287
		DEFAULT => -42
	},
	{#State 288
		DEFAULT => -97
	},
	{#State 289
		ACTIONS => {
			"void" => 29,
			"unsigned" => 50,
			"const" => 24,
			"char" => 13,
			"long" => 37,
			'ID' => 6,
			"short" => 42,
			"int" => 54
		},
		GOTOS => {
			'template' => 41,
			'basic_type' => 52,
			'class_name' => 46,
			'looks_like_function' => 95,
			'nconsttype' => 38,
			'type' => 12,
			'type_name' => 15
		}
	},
	{#State 290
		ACTIONS => {
			"short" => 42,
			"int" => 54,
			'ID' => 6,
			"void" => 151,
			"unsigned" => 50,
			"const" => 24,
			"long" => 37,
			"char" => 13
		},
		DEFAULT => -160,
		GOTOS => {
			'template' => 41,
			'arg_list' => 311,
			'nonvoid_arg_list' => 149,
			'class_name' => 46,
			'type_name' => 15,
			'basic_type' => 52,
			'nconsttype' => 38,
			'argument' => 148,
			'type' => 147
		}
	},
	{#State 291
		DEFAULT => -99
	},
	{#State 292
		ACTIONS => {
			'ID' => 312,
			'TILDE' => 251,
			'p_name' => 34,
			"virtual" => 272
		},
		GOTOS => {
			'ctor' => 295,
			'perc_name' => 292,
			'virtual' => 270,
			'vmethod' => 291,
			'dtor' => 293,
			'_vmethod' => 265
		}
	},
	{#State 293
		DEFAULT => -92
	},
	{#State 294
		DEFAULT => -73
	},
	{#State 295
		DEFAULT => -90
	},
	{#State 296
		DEFAULT => -67
	},
	{#State 297
		DEFAULT => -64
	},
	{#State 298
		ACTIONS => {
			'p_catch' => 112,
			'p_postcall' => 113,
			'p_any' => 48,
			'p_alias' => 118,
			'p_cleanup' => 116,
			'p_code' => 120
		},
		DEFAULT => -96,
		GOTOS => {
			'_function_metadata' => 119,
			'perc_postcall' => 110,
			'perc_cleanup' => 111,
			'perc_any' => 114,
			'perc_code' => 109,
			'perc_catch' => 115,
			'perc_alias' => 117
		}
	},
	{#State 299
		ACTIONS => {
			"virtual" => 272,
			'TILDE' => 251,
			'p_name' => 34
		},
		GOTOS => {
			'perc_name' => 302,
			'dtor' => 301,
			'virtual' => 299
		}
	},
	{#State 300
		ACTIONS => {
			'EQUAL' => 313
		},
		DEFAULT => -95,
		GOTOS => {
			'function_metadata' => 314
		}
	},
	{#State 301
		DEFAULT => -93
	},
	{#State 302
		ACTIONS => {
			'p_name' => 34,
			'TILDE' => 251,
			"virtual" => 272
		},
		GOTOS => {
			'dtor' => 293,
			'perc_name' => 302,
			'virtual' => 299
		}
	},
	{#State 303
		ACTIONS => {
			'OPSPECIAL' => 40,
			'SEMICOLON' => 316
		},
		GOTOS => {
			'special_block_start' => 35,
			'special_block' => 315
		}
	},
	{#State 304
		DEFAULT => -179
	},
	{#State 305
		ACTIONS => {
			'p_any' => 129,
			'p_name' => 34
		},
		GOTOS => {
			'perc_any_arg' => 131,
			'perc_name' => 130,
			'perc_any_args' => 317
		}
	},
	{#State 306
		DEFAULT => -172
	},
	{#State 307
		ACTIONS => {
			'FLOAT' => 213,
			'QUOTED_STRING' => 211,
			'INTEGER' => 212,
			'ID' => 6,
			'DASH' => 216
		},
		GOTOS => {
			'value' => 318,
			'class_name' => 210
		}
	},
	{#State 308
		ACTIONS => {
			'CLCURLY' => 319
		}
	},
	{#State 309
		ACTIONS => {
			'p_any' => 48
		},
		DEFAULT => -74,
		GOTOS => {
			'_member_metadata' => 321,
			'perc_any' => 320
		}
	},
	{#State 310
		ACTIONS => {
			'CLPAR' => 322
		}
	},
	{#State 311
		ACTIONS => {
			'CLPAR' => 323
		}
	},
	{#State 312
		ACTIONS => {
			'OPPAR' => 290
		}
	},
	{#State 313
		ACTIONS => {
			'INTEGER' => 324
		}
	},
	{#State 314
		ACTIONS => {
			'p_catch' => 112,
			'p_any' => 48,
			'p_postcall' => 113,
			'p_cleanup' => 116,
			'p_alias' => 118,
			'p_code' => 120
		},
		DEFAULT => -100,
		GOTOS => {
			'perc_alias' => 117,
			'perc_code' => 109,
			'_function_metadata' => 119,
			'perc_catch' => 115,
			'perc_any' => 114,
			'perc_cleanup' => 111,
			'perc_postcall' => 110
		}
	},
	{#State 315
		DEFAULT => -180
	},
	{#State 316
		DEFAULT => -18
	},
	{#State 317
		ACTIONS => {
			'p_name' => 34,
			'CLCURLY' => 325,
			'p_any' => 129
		},
		GOTOS => {
			'perc_any_arg' => 172,
			'perc_name' => 130
		}
	},
	{#State 318
		DEFAULT => -174
	},
	{#State 319
		DEFAULT => -24,
		GOTOS => {
			'mixed_blocks' => 326
		}
	},
	{#State 320
		DEFAULT => -70
	},
	{#State 321
		DEFAULT => -68
	},
	{#State 322
		DEFAULT => -95,
		GOTOS => {
			'function_metadata' => 327
		}
	},
	{#State 323
		DEFAULT => -95,
		GOTOS => {
			'function_metadata' => 328
		}
	},
	{#State 324
		DEFAULT => -95,
		GOTOS => {
			'function_metadata' => 329
		}
	},
	{#State 325
		ACTIONS => {
			'SEMICOLON' => 330
		}
	},
	{#State 326
		ACTIONS => {
			'SEMICOLON' => 331,
			'OPSPECIAL' => 40,
			'OPCURLY' => 177
		},
		GOTOS => {
			'special_block' => 176,
			'simple_block' => 175,
			'special_block_start' => 35
		}
	},
	{#State 327
		ACTIONS => {
			'p_catch' => 112,
			'p_any' => 48,
			'p_postcall' => 113,
			'p_cleanup' => 116,
			'p_alias' => 118,
			'p_code' => 120
		},
		DEFAULT => -91,
		GOTOS => {
			'perc_cleanup' => 111,
			'perc_postcall' => 110,
			'perc_catch' => 115,
			'perc_any' => 114,
			'_function_metadata' => 119,
			'perc_code' => 109,
			'perc_alias' => 117
		}
	},
	{#State 328
		ACTIONS => {
			'p_catch' => 112,
			'p_postcall' => 113,
			'p_any' => 48,
			'p_alias' => 118,
			'p_cleanup' => 116,
			'p_code' => 120
		},
		DEFAULT => -89,
		GOTOS => {
			'perc_any' => 114,
			'perc_catch' => 115,
			'perc_postcall' => 110,
			'perc_cleanup' => 111,
			'perc_alias' => 117,
			'perc_code' => 109,
			'_function_metadata' => 119
		}
	},
	{#State 329
		ACTIONS => {
			'p_catch' => 112,
			'p_postcall' => 113,
			'p_any' => 48,
			'p_alias' => 118,
			'p_cleanup' => 116,
			'p_code' => 120
		},
		DEFAULT => -101,
		GOTOS => {
			'perc_code' => 109,
			'perc_alias' => 117,
			'_function_metadata' => 119,
			'perc_catch' => 115,
			'perc_any' => 114,
			'perc_cleanup' => 111,
			'perc_postcall' => 110
		}
	},
	{#State 330
		DEFAULT => -19
	},
	{#State 331
		DEFAULT => -21
	}
],
                                  yyrules  =>
[
	[#Rule 0
		 '$start', 2, undef
	],
	[#Rule 1
		 'top_list', 1, undef
	],
	[#Rule 2
		 'top_list', 2,
sub
#line 22 "XSP.yp"
{ push @{$_[1]}, @{$_[2]}; $_[1] }
	],
	[#Rule 3
		 'top_list', 4,
sub
#line 24 "XSP.yp"
{ $_[3] }
	],
	[#Rule 4
		 'top', 1,
sub
#line 27 "XSP.yp"
{ !$_[1]               ? [] :
                          ref $_[1] eq 'ARRAY' ? $_[1] :
                                                 [ $_[1] ] }
	],
	[#Rule 5
		 '_top', 1, undef
	],
	[#Rule 6
		 '_top', 1, undef
	],
	[#Rule 7
		 '_top', 1, undef
	],
	[#Rule 8
		 '_top', 1, undef
	],
	[#Rule 9
		 '_top', 1,
sub
#line 32 "XSP.yp"
{ process_function( $_[0], $_[1] ) }
	],
	[#Rule 10
		 'directive', 2,
sub
#line 35 "XSP.yp"
{ ExtUtils::XSpp::Node::Module->new( module => $_[1] ) }
	],
	[#Rule 11
		 'directive', 2,
sub
#line 37 "XSP.yp"
{ ExtUtils::XSpp::Node::Package->new( perl_name => $_[1] ) }
	],
	[#Rule 12
		 'directive', 2,
sub
#line 39 "XSP.yp"
{ ExtUtils::XSpp::Node::File->new( file => $_[1] ) }
	],
	[#Rule 13
		 'directive', 2,
sub
#line 41 "XSP.yp"
{ $_[0]->YYData->{PARSER}->load_plugin( $_[1] ); undef }
	],
	[#Rule 14
		 'directive', 2,
sub
#line 43 "XSP.yp"
{ $_[0]->YYData->{PARSER}->include_file( $_[1] ); undef }
	],
	[#Rule 15
		 'directive', 2,
sub
#line 45 "XSP.yp"
{ add_top_level_directive( $_[0], %{$_[1][1]} ) }
	],
	[#Rule 16
		 'directive', 1,
sub
#line 46 "XSP.yp"
{ }
	],
	[#Rule 17
		 'directive', 1,
sub
#line 47 "XSP.yp"
{ }
	],
	[#Rule 18
		 'typemap', 9,
sub
#line 52 "XSP.yp"
{ my $c = 0;
                      my %args = map { "arg" . ++$c => $_ }
                                 map { join( '', @$_ ) }
                                     @{$_[8] || []};
                      add_typemap( $_[6], $_[3], %args );
                      undef }
	],
	[#Rule 19
		 'typemap', 11,
sub
#line 60 "XSP.yp"
{ # this assumes that there will be at most one named
                      # block for each directive inside the typemap
                      for( my $i = 1; $i <= $#{$_[9]}; $i += 2 ) {
                          $_[9][$i] = join "\n", @{$_[9][$i][0]}
                              if    ref( $_[9][$i] ) eq 'ARRAY'
                                 && ref( $_[9][$i][0] ) eq 'ARRAY';
                      }
                      add_typemap( $_[6], $_[3], @{$_[9]} );
                      undef }
	],
	[#Rule 20
		 'typemap', 5,
sub
#line 70 "XSP.yp"
{ add_typemap( 'simple', $_[3] );
                      add_typemap( 'reference', make_ref($_[3]->clone) );
                      undef }
	],
	[#Rule 21
		 'exceptionmap', 12,
sub
#line 78 "XSP.yp"
{ my $package = "ExtUtils::XSpp::Exception::" . $_[9];
                      my $type = make_type($_[6]); my $c = 0;
                      my %args = map { "arg" . ++$c => $_ }
                                 map { join( "\n", @$_ ) }
                                     @{$_[11] || []};
                      my $e = $package->new( name => $_[3], type => $type, %args );
                      ExtUtils::XSpp::Exception->add_exception( $e );
                      undef }
	],
	[#Rule 22
		 'mixed_blocks', 2,
sub
#line 88 "XSP.yp"
{ [ @{$_[1]}, $_[2] ] }
	],
	[#Rule 23
		 'mixed_blocks', 2,
sub
#line 90 "XSP.yp"
{ [ @{$_[1]}, [ $_[2] ] ] }
	],
	[#Rule 24
		 'mixed_blocks', 0,
sub
#line 91 "XSP.yp"
{ [] }
	],
	[#Rule 25
		 'simple_block', 3,
sub
#line 94 "XSP.yp"
{ $_[2] }
	],
	[#Rule 26
		 'raw', 1,
sub
#line 96 "XSP.yp"
{ add_data_raw( $_[0], [ $_[1] ] ) }
	],
	[#Rule 27
		 'raw', 1,
sub
#line 97 "XSP.yp"
{ add_data_comment( $_[0], $_[1] ) }
	],
	[#Rule 28
		 'raw', 1,
sub
#line 98 "XSP.yp"
{ ExtUtils::XSpp::Node::Preprocessor->new
                              ( rows   => [ $_[1][0] ],
                                symbol => $_[1][1],
                                ) }
	],
	[#Rule 29
		 'raw', 1,
sub
#line 102 "XSP.yp"
{ add_data_raw( $_[0], [ @{$_[1]} ] ) }
	],
	[#Rule 30
		 'enum', 5,
sub
#line 106 "XSP.yp"
{ ExtUtils::XSpp::Node::Enum->new
                ( elements  => $_[3],
                  condition => $_[0]->get_conditional,
                  ) }
	],
	[#Rule 31
		 'enum', 6,
sub
#line 111 "XSP.yp"
{ ExtUtils::XSpp::Node::Enum->new
                ( name      => $_[2],
                  elements  => $_[4],
                  condition => $_[0]->get_conditional,
                  ) }
	],
	[#Rule 32
		 'enum_element_list', 0,
sub
#line 119 "XSP.yp"
{ [] }
	],
	[#Rule 33
		 'enum_element_list', 2,
sub
#line 121 "XSP.yp"
{ push @{$_[1]}, $_[2] if $_[2]; $_[1] }
	],
	[#Rule 34
		 'enum_element_list', 3,
sub
#line 123 "XSP.yp"
{ push @{$_[1]}, $_[2] if $_[2]; $_[1] }
	],
	[#Rule 35
		 'enum_element', 1,
sub
#line 128 "XSP.yp"
{ ExtUtils::XSpp::Node::EnumValue->new
                ( name => $_[1],
                  condition => $_[0]->get_conditional,
                  ) }
	],
	[#Rule 36
		 'enum_element', 3,
sub
#line 133 "XSP.yp"
{ ExtUtils::XSpp::Node::EnumValue->new
                ( name      => $_[1],
                  value     => $_[3],
                  condition => $_[0]->get_conditional,
                  ) }
	],
	[#Rule 37
		 'enum_element', 1, undef
	],
	[#Rule 38
		 'class', 2, undef
	],
	[#Rule 39
		 'class', 2, undef
	],
	[#Rule 40
		 'function', 2, undef
	],
	[#Rule 41
		 'method', 2, undef
	],
	[#Rule 42
		 'member', 2, undef
	],
	[#Rule 43
		 'decorate_class', 2,
sub
#line 147 "XSP.yp"
{ $_[2]->set_perl_name( $_[1] ); $_[2] }
	],
	[#Rule 44
		 'class_decl', 7,
sub
#line 150 "XSP.yp"
{ create_class( $_[0], $_[2], $_[3], $_[4], $_[6],
                                $_[0]->get_conditional ) }
	],
	[#Rule 45
		 'base_classes', 2,
sub
#line 154 "XSP.yp"
{ [ $_[2] ] }
	],
	[#Rule 46
		 'base_classes', 3,
sub
#line 155 "XSP.yp"
{ push @{$_[1]}, $_[3] if $_[3]; $_[1] }
	],
	[#Rule 47
		 'base_classes', 0, undef
	],
	[#Rule 48
		 'base_class', 2,
sub
#line 159 "XSP.yp"
{ $_[2] }
	],
	[#Rule 49
		 'base_class', 2,
sub
#line 160 "XSP.yp"
{ $_[2] }
	],
	[#Rule 50
		 'base_class', 2,
sub
#line 161 "XSP.yp"
{ $_[2] }
	],
	[#Rule 51
		 'class_name_rename', 1,
sub
#line 165 "XSP.yp"
{ create_class( $_[0], $_[1], [], [] ) }
	],
	[#Rule 52
		 'class_name_rename', 2,
sub
#line 166 "XSP.yp"
{ my $klass = create_class( $_[0], $_[2], [], [] );
                             $klass->set_perl_name( $_[1] );
                             $klass
                             }
	],
	[#Rule 53
		 'class_metadata', 2,
sub
#line 172 "XSP.yp"
{ [ @{$_[1]}, @{$_[2]} ] }
	],
	[#Rule 54
		 'class_metadata', 2,
sub
#line 173 "XSP.yp"
{ [ @{$_[1]}, @{$_[2]} ] }
	],
	[#Rule 55
		 'class_metadata', 0,
sub
#line 174 "XSP.yp"
{ [] }
	],
	[#Rule 56
		 'class_body_list', 0,
sub
#line 178 "XSP.yp"
{ [] }
	],
	[#Rule 57
		 'class_body_list', 2,
sub
#line 180 "XSP.yp"
{ push @{$_[1]}, $_[2] if $_[2]; $_[1] }
	],
	[#Rule 58
		 'class_body_element', 1, undef
	],
	[#Rule 59
		 'class_body_element', 1, undef
	],
	[#Rule 60
		 'class_body_element', 1, undef
	],
	[#Rule 61
		 'class_body_element', 1, undef
	],
	[#Rule 62
		 'class_body_element', 1, undef
	],
	[#Rule 63
		 'class_body_element', 1, undef
	],
	[#Rule 64
		 'class_body_element', 2,
sub
#line 186 "XSP.yp"
{ ExtUtils::XSpp::Node::PercAny->new( %{$_[1][1]} ) }
	],
	[#Rule 65
		 'access_specifier', 2,
sub
#line 190 "XSP.yp"
{ ExtUtils::XSpp::Node::Access->new( access => $_[1] ) }
	],
	[#Rule 66
		 'access_specifier', 2,
sub
#line 191 "XSP.yp"
{ ExtUtils::XSpp::Node::Access->new( access => $_[1] ) }
	],
	[#Rule 67
		 'access_specifier', 2,
sub
#line 192 "XSP.yp"
{ ExtUtils::XSpp::Node::Access->new( access => $_[1] ) }
	],
	[#Rule 68
		 'member_metadata', 2,
sub
#line 195 "XSP.yp"
{ [ @{$_[1]}, @{$_[2]} ] }
	],
	[#Rule 69
		 'member_metadata', 0,
sub
#line 196 "XSP.yp"
{ [] }
	],
	[#Rule 70
		 '_member_metadata', 1, undef
	],
	[#Rule 71
		 'member_decl', 0, undef
	],
	[#Rule 72
		 'member_decl', 1, undef
	],
	[#Rule 73
		 'member_decl', 2,
sub
#line 204 "XSP.yp"
{ $_[2]->set_perl_name( $_[1] ); $_[2] }
	],
	[#Rule 74
		 'looks_like_member', 3,
sub
#line 208 "XSP.yp"
{ create_member( $_[0],
                           name      => $_[2],
                           type      => $_[1],
                           condition => $_[0]->get_conditional,
                           @{$_[3]} ) }
	],
	[#Rule 75
		 'method_decl', 1, undef
	],
	[#Rule 76
		 'method_decl', 1, undef
	],
	[#Rule 77
		 'method_decl', 1, undef
	],
	[#Rule 78
		 'method_decl', 1, undef
	],
	[#Rule 79
		 'const', 1,
sub
#line 216 "XSP.yp"
{ 1 }
	],
	[#Rule 80
		 'const', 0,
sub
#line 217 "XSP.yp"
{ 0 }
	],
	[#Rule 81
		 'virtual', 1, undef
	],
	[#Rule 82
		 'static', 1, undef
	],
	[#Rule 83
		 'static', 1, undef
	],
	[#Rule 84
		 'static', 1,
sub
#line 223 "XSP.yp"
{ 'package_static' }
	],
	[#Rule 85
		 'looks_like_function', 6,
sub
#line 228 "XSP.yp"
{
              return { ret_type  => $_[1],
                       name      => $_[2],
                       arguments => $_[4],
                       const     => $_[6],
                       };
          }
	],
	[#Rule 86
		 'looks_like_renamed_function', 1, undef
	],
	[#Rule 87
		 'looks_like_renamed_function', 2,
sub
#line 239 "XSP.yp"
{ $_[2]->{perl_name} = $_[1]; $_[2] }
	],
	[#Rule 88
		 'function_decl', 2,
sub
#line 242 "XSP.yp"
{ add_data_function( $_[0],
                                         name      => $_[1]->{name},
                                         perl_name => $_[1]->{perl_name},
                                         ret_type  => $_[1]->{ret_type},
                                         arguments => $_[1]->{arguments},
                                         condition => $_[0]->get_conditional,
                                         @{$_[2]} ) }
	],
	[#Rule 89
		 'ctor', 5,
sub
#line 251 "XSP.yp"
{ add_data_ctor( $_[0], name      => $_[1],
                                            arguments => $_[3],
                                            condition => $_[0]->get_conditional,
                                            @{ $_[5] } ) }
	],
	[#Rule 90
		 'ctor', 2,
sub
#line 255 "XSP.yp"
{ $_[2]->set_perl_name( $_[1] ); $_[2] }
	],
	[#Rule 91
		 'dtor', 5,
sub
#line 258 "XSP.yp"
{ add_data_dtor( $_[0], name  => $_[2],
                                            condition => $_[0]->get_conditional,
                                            @{ $_[5] },
                                      ) }
	],
	[#Rule 92
		 'dtor', 2,
sub
#line 262 "XSP.yp"
{ $_[2]->set_perl_name( $_[1] ); $_[2] }
	],
	[#Rule 93
		 'dtor', 2,
sub
#line 263 "XSP.yp"
{ $_[2]->set_virtual( 1 ); $_[2] }
	],
	[#Rule 94
		 'function_metadata', 2,
sub
#line 265 "XSP.yp"
{ [ @{$_[1]}, @{$_[2]} ] }
	],
	[#Rule 95
		 'function_metadata', 0,
sub
#line 266 "XSP.yp"
{ [] }
	],
	[#Rule 96
		 'nmethod', 2,
sub
#line 271 "XSP.yp"
{ my $m = add_data_method
                        ( $_[0],
                          name      => $_[1]->{name},
                          perl_name => $_[1]->{perl_name},
                          ret_type  => $_[1]->{ret_type},
                          arguments => $_[1]->{arguments},
                          const     => $_[1]->{const},
                          condition => $_[0]->get_conditional,
                          @{$_[2]},
                          );
            $m
          }
	],
	[#Rule 97
		 'nmethod', 2,
sub
#line 284 "XSP.yp"
{ $_[2]->set_static( $_[1] ); $_[2] }
	],
	[#Rule 98
		 'vmethod', 1, undef
	],
	[#Rule 99
		 'vmethod', 2,
sub
#line 289 "XSP.yp"
{ $_[2]->set_perl_name( $_[1] ); $_[2] }
	],
	[#Rule 100
		 '_vmethod', 3,
sub
#line 294 "XSP.yp"
{ my $m = add_data_method
                        ( $_[0],
                          name      => $_[2]->{name},
                          perl_name => $_[2]->{perl_name},
                          ret_type  => $_[2]->{ret_type},
                          arguments => $_[2]->{arguments},
                          const     => $_[2]->{const},
                          condition => $_[0]->get_conditional,
                          @{$_[3]},
                          );
            $m->set_virtual( 1 );
            $m
          }
	],
	[#Rule 101
		 '_vmethod', 5,
sub
#line 308 "XSP.yp"
{ my $m = add_data_method
                        ( $_[0],
                          name      => $_[2]->{name},
                          perl_name => $_[2]->{perl_name},
                          ret_type  => $_[2]->{ret_type},
                          arguments => $_[2]->{arguments},
                          const     => $_[2]->{const},
                          condition => $_[0]->get_conditional,
                          @{$_[5]},
                          );
            die "Invalid pure virtual method" unless $_[4] eq '0';
            $m->set_virtual( 2 );
            $m
          }
	],
	[#Rule 102
		 '_function_metadata', 1, undef
	],
	[#Rule 103
		 '_function_metadata', 1, undef
	],
	[#Rule 104
		 '_function_metadata', 1, undef
	],
	[#Rule 105
		 '_function_metadata', 1, undef
	],
	[#Rule 106
		 '_function_metadata', 1, undef
	],
	[#Rule 107
		 '_function_metadata', 1, undef
	],
	[#Rule 108
		 'perc_name', 4,
sub
#line 332 "XSP.yp"
{ $_[3] }
	],
	[#Rule 109
		 'perc_alias', 6,
sub
#line 333 "XSP.yp"
{ [ alias => [$_[3], $_[5]] ] }
	],
	[#Rule 110
		 'perc_package', 4,
sub
#line 334 "XSP.yp"
{ $_[3] }
	],
	[#Rule 111
		 'perc_module', 4,
sub
#line 335 "XSP.yp"
{ $_[3] }
	],
	[#Rule 112
		 'perc_file', 4,
sub
#line 336 "XSP.yp"
{ $_[3] }
	],
	[#Rule 113
		 'perc_loadplugin', 4,
sub
#line 337 "XSP.yp"
{ $_[3] }
	],
	[#Rule 114
		 'perc_include', 4,
sub
#line 338 "XSP.yp"
{ $_[3] }
	],
	[#Rule 115
		 'perc_code', 2,
sub
#line 339 "XSP.yp"
{ [ code => $_[2] ] }
	],
	[#Rule 116
		 'perc_cleanup', 2,
sub
#line 340 "XSP.yp"
{ [ cleanup => $_[2] ] }
	],
	[#Rule 117
		 'perc_postcall', 2,
sub
#line 341 "XSP.yp"
{ [ postcall => $_[2] ] }
	],
	[#Rule 118
		 'perc_catch', 4,
sub
#line 342 "XSP.yp"
{ [ map {(catch => $_)} @{$_[3]} ] }
	],
	[#Rule 119
		 'perc_any', 4,
sub
#line 347 "XSP.yp"
{ [ tag => { any => $_[1], named => $_[3] } ] }
	],
	[#Rule 120
		 'perc_any', 5,
sub
#line 349 "XSP.yp"
{ [ tag => { any => $_[1], positional  => [ $_[3], @{$_[5]} ] } ] }
	],
	[#Rule 121
		 'perc_any', 3,
sub
#line 351 "XSP.yp"
{ [ tag => { any => $_[1], positional  => [ $_[2], @{$_[3]} ] } ] }
	],
	[#Rule 122
		 'perc_any', 1,
sub
#line 353 "XSP.yp"
{ [ tag => { any => $_[1] } ] }
	],
	[#Rule 123
		 'perc_any_args', 1,
sub
#line 357 "XSP.yp"
{ $_[1] }
	],
	[#Rule 124
		 'perc_any_args', 2,
sub
#line 358 "XSP.yp"
{ [ @{$_[1]}, @{$_[2]} ] }
	],
	[#Rule 125
		 'perc_any_arg', 3,
sub
#line 362 "XSP.yp"
{ [ $_[1] => $_[2] ] }
	],
	[#Rule 126
		 'perc_any_arg', 2,
sub
#line 363 "XSP.yp"
{ [ name  => $_[1] ] }
	],
	[#Rule 127
		 'type', 2,
sub
#line 367 "XSP.yp"
{ make_const( $_[2] ) }
	],
	[#Rule 128
		 'type', 1, undef
	],
	[#Rule 129
		 'nconsttype', 2,
sub
#line 372 "XSP.yp"
{ make_ptr( $_[1] ) }
	],
	[#Rule 130
		 'nconsttype', 2,
sub
#line 373 "XSP.yp"
{ make_ref( $_[1] ) }
	],
	[#Rule 131
		 'nconsttype', 1,
sub
#line 374 "XSP.yp"
{ make_type( $_[1] ) }
	],
	[#Rule 132
		 'nconsttype', 1, undef
	],
	[#Rule 133
		 'type_name', 1, undef
	],
	[#Rule 134
		 'type_name', 1, undef
	],
	[#Rule 135
		 'type_name', 1, undef
	],
	[#Rule 136
		 'type_name', 1,
sub
#line 382 "XSP.yp"
{ 'unsigned int' }
	],
	[#Rule 137
		 'type_name', 2,
sub
#line 383 "XSP.yp"
{ 'unsigned' . ' ' . $_[2] }
	],
	[#Rule 138
		 'basic_type', 1, undef
	],
	[#Rule 139
		 'basic_type', 1, undef
	],
	[#Rule 140
		 'basic_type', 1, undef
	],
	[#Rule 141
		 'basic_type', 1, undef
	],
	[#Rule 142
		 'basic_type', 2, undef
	],
	[#Rule 143
		 'basic_type', 2, undef
	],
	[#Rule 144
		 'template', 4,
sub
#line 389 "XSP.yp"
{ make_template( $_[1], $_[3] ) }
	],
	[#Rule 145
		 'type_list', 1,
sub
#line 393 "XSP.yp"
{ [ $_[1] ] }
	],
	[#Rule 146
		 'type_list', 3,
sub
#line 394 "XSP.yp"
{ push @{$_[1]}, $_[3]; $_[1] }
	],
	[#Rule 147
		 'class_name', 1, undef
	],
	[#Rule 148
		 'class_name', 2,
sub
#line 398 "XSP.yp"
{ $_[1] . '::' . $_[2] }
	],
	[#Rule 149
		 'class_name_list', 1,
sub
#line 401 "XSP.yp"
{ [ $_[1] ] }
	],
	[#Rule 150
		 'class_name_list', 3,
sub
#line 402 "XSP.yp"
{ push @{$_[1]}, $_[3]; $_[1] }
	],
	[#Rule 151
		 'class_suffix', 2,
sub
#line 405 "XSP.yp"
{ $_[2] }
	],
	[#Rule 152
		 'class_suffix', 3,
sub
#line 406 "XSP.yp"
{ $_[1] . '::' . $_[3] }
	],
	[#Rule 153
		 'file_name', 1,
sub
#line 408 "XSP.yp"
{ '-' }
	],
	[#Rule 154
		 'file_name', 3,
sub
#line 409 "XSP.yp"
{ $_[1] . '.' . $_[3] }
	],
	[#Rule 155
		 'file_name', 3,
sub
#line 410 "XSP.yp"
{ $_[1] . '/' . $_[3] }
	],
	[#Rule 156
		 'arg_list', 1, undef
	],
	[#Rule 157
		 'arg_list', 1,
sub
#line 413 "XSP.yp"
{ undef }
	],
	[#Rule 158
		 'nonvoid_arg_list', 1,
sub
#line 416 "XSP.yp"
{ [ $_[1] ] }
	],
	[#Rule 159
		 'nonvoid_arg_list', 3,
sub
#line 417 "XSP.yp"
{ push @{$_[1]}, $_[3]; $_[1] }
	],
	[#Rule 160
		 'nonvoid_arg_list', 0, undef
	],
	[#Rule 161
		 'argument_metadata', 2,
sub
#line 420 "XSP.yp"
{ [ @{$_[1]}, @{$_[2]} ] }
	],
	[#Rule 162
		 'argument_metadata', 0,
sub
#line 421 "XSP.yp"
{ [] }
	],
	[#Rule 163
		 '_argument_metadata', 1, undef
	],
	[#Rule 164
		 'argument', 5,
sub
#line 427 "XSP.yp"
{ make_argument( @_[0, 1], "length($_[4])" ) }
	],
	[#Rule 165
		 'argument', 5,
sub
#line 429 "XSP.yp"
{ make_argument( @_[0, 1, 2, 5], @{$_[3]} ) }
	],
	[#Rule 166
		 'argument', 3,
sub
#line 431 "XSP.yp"
{ make_argument( @_[0, 1, 2], undef, @{$_[3]} ) }
	],
	[#Rule 167
		 'value', 1, undef
	],
	[#Rule 168
		 'value', 2,
sub
#line 434 "XSP.yp"
{ '-' . $_[2] }
	],
	[#Rule 169
		 'value', 1, undef
	],
	[#Rule 170
		 'value', 1, undef
	],
	[#Rule 171
		 'value', 1, undef
	],
	[#Rule 172
		 'value', 4,
sub
#line 438 "XSP.yp"
{ "$_[1]($_[3])" }
	],
	[#Rule 173
		 'value_list', 1, undef
	],
	[#Rule 174
		 'value_list', 3,
sub
#line 443 "XSP.yp"
{ "$_[1], $_[2]" }
	],
	[#Rule 175
		 'value_list', 0,
sub
#line 444 "XSP.yp"
{ "" }
	],
	[#Rule 176
		 'expression', 1, undef
	],
	[#Rule 177
		 'expression', 3,
sub
#line 450 "XSP.yp"
{ "$_[1] & $_[3]" }
	],
	[#Rule 178
		 'expression', 3,
sub
#line 452 "XSP.yp"
{ "$_[1] | $_[3]" }
	],
	[#Rule 179
		 'special_blocks', 1,
sub
#line 456 "XSP.yp"
{ [ $_[1] ] }
	],
	[#Rule 180
		 'special_blocks', 2,
sub
#line 458 "XSP.yp"
{ [ @{$_[1]}, $_[2] ] }
	],
	[#Rule 181
		 'special_blocks', 0, undef
	],
	[#Rule 182
		 'special_block', 3,
sub
#line 462 "XSP.yp"
{ $_[2] }
	],
	[#Rule 183
		 'special_block', 2,
sub
#line 464 "XSP.yp"
{ [] }
	],
	[#Rule 184
		 'special_block_start', 1,
sub
#line 467 "XSP.yp"
{ push_lex_mode( $_[0], 'special' ) }
	],
	[#Rule 185
		 'special_block_end', 1,
sub
#line 469 "XSP.yp"
{ pop_lex_mode( $_[0], 'special' ) }
	],
	[#Rule 186
		 'lines', 1,
sub
#line 471 "XSP.yp"
{ [ $_[1] ] }
	],
	[#Rule 187
		 'lines', 2,
sub
#line 472 "XSP.yp"
{ push @{$_[1]}, $_[2]; $_[1] }
	]
],
                                  @_);
    bless($self,$class);
}

#line 474 "XSP.yp"


use ExtUtils::XSpp::Lexer;

1;
