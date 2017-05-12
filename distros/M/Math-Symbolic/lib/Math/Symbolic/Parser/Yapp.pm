package Math::Symbolic::Parser::Yapp::Driver;
use strict;
our $VERSION = '1.05';

####################################################################
#
#    This file was generated using Parse::Yapp version 1.05.
#
#        Don't edit this file, use source file instead.
#
#             ANY CHANGE MADE HERE WILL BE LOST !
#
####################################################################
package Math::Symbolic::Parser::Yapp;
use vars qw ( @ISA );
use strict;

@ISA= qw ( Math::Symbolic::Parser::Yapp::Driver );
#Included Parse/Yapp/Driver.pm file----------------------------------------
{
#
# Module Parse::Yapp::Driver
#
# This module is part of the Parse::Yapp package available on your
# nearest CPAN
#
# Any use of this module in a standalone parser make the included
# text under the same copyright as the Parse::Yapp module itself.
#
# This notice should remain unchanged.
#
# (c) Copyright 1998-2001 Francois Desarmenien, all rights reserved.
# (see the pod text in Parse::Yapp module for use and distribution rights)
#

package Math::Symbolic::Parser::Yapp::Driver;

require 5.004;

use strict;

use vars qw ( $VERSION $COMPATIBLE $FILENAME );

$VERSION = '1.05';
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

    my($self)=$class->SUPER::new( yyversion => '1.05',
                                  yystates =>
[
	{#State 0
		ACTIONS => {
			"-" => 1,
			'PRED' => 3,
			'PRIVEFUNC' => 4,
			'FUNC' => 5,
			'NUM' => 6,
			"(" => 7,
			'EFUNC' => 8,
			'VAR' => 9
		},
		GOTOS => {
			'exp' => 2
		}
	},
	{#State 1
		ACTIONS => {
			"-" => 1,
			'PRED' => 3,
			'PRIVEFUNC' => 4,
			'FUNC' => 5,
			'NUM' => 6,
			"(" => 7,
			'VAR' => 9,
			'EFUNC' => 8
		},
		GOTOS => {
			'exp' => 10
		}
	},
	{#State 2
		ACTIONS => {
			'' => 12,
			"-" => 11,
			"^" => 15,
			"*" => 16,
			"+" => 13,
			"/" => 14
		}
	},
	{#State 3
		ACTIONS => {
			"{" => 17
		}
	},
	{#State 4
		DEFAULT => -4
	},
	{#State 5
		ACTIONS => {
			"(" => 18
		}
	},
	{#State 6
		DEFAULT => -1
	},
	{#State 7
		ACTIONS => {
			"-" => 1,
			'PRED' => 3,
			'PRIVEFUNC' => 4,
			'FUNC' => 5,
			'NUM' => 6,
			"(" => 7,
			'VAR' => 9,
			'EFUNC' => 8
		},
		GOTOS => {
			'exp' => 19
		}
	},
	{#State 8
		DEFAULT => -5
	},
	{#State 9
		DEFAULT => -6
	},
	{#State 10
		ACTIONS => {
			"^" => 15
		},
		DEFAULT => -11
	},
	{#State 11
		ACTIONS => {
			"-" => 1,
			'PRED' => 3,
			'PRIVEFUNC' => 4,
			'FUNC' => 5,
			'NUM' => 6,
			"(" => 7,
			'VAR' => 9,
			'EFUNC' => 8
		},
		GOTOS => {
			'exp' => 20
		}
	},
	{#State 12
		DEFAULT => 0
	},
	{#State 13
		ACTIONS => {
			"-" => 1,
			'PRED' => 3,
			'PRIVEFUNC' => 4,
			'FUNC' => 5,
			'NUM' => 6,
			"(" => 7,
			'VAR' => 9,
			'EFUNC' => 8
		},
		GOTOS => {
			'exp' => 21
		}
	},
	{#State 14
		ACTIONS => {
			"-" => 1,
			'PRED' => 3,
			'PRIVEFUNC' => 4,
			'FUNC' => 5,
			'NUM' => 6,
			"(" => 7,
			'VAR' => 9,
			'EFUNC' => 8
		},
		GOTOS => {
			'exp' => 22
		}
	},
	{#State 15
		ACTIONS => {
			"-" => 1,
			'PRED' => 3,
			'PRIVEFUNC' => 4,
			'FUNC' => 5,
			'NUM' => 6,
			"(" => 7,
			'VAR' => 9,
			'EFUNC' => 8
		},
		GOTOS => {
			'exp' => 23
		}
	},
	{#State 16
		ACTIONS => {
			"-" => 1,
			'PRED' => 3,
			'PRIVEFUNC' => 4,
			'FUNC' => 5,
			'NUM' => 6,
			"(" => 7,
			'VAR' => 9,
			'EFUNC' => 8
		},
		GOTOS => {
			'exp' => 24
		}
	},
	{#State 17
		ACTIONS => {
			"-" => 1,
			'PRED' => 3,
			'PRIVEFUNC' => 4,
			'FUNC' => 5,
			'NUM' => 6,
			"(" => 7,
			'VAR' => 9,
			'EFUNC' => 8
		},
		GOTOS => {
			'exp' => 25
		}
	},
	{#State 18
		ACTIONS => {
			"-" => 1,
			'PRED' => 3,
			'PRIVEFUNC' => 4,
			'FUNC' => 5,
			'NUM' => 6,
			"(" => 7,
			'VAR' => 9,
			'EFUNC' => 8
		},
		GOTOS => {
			'exp' => 26,
			'list' => 27
		}
	},
	{#State 19
		ACTIONS => {
			"-" => 11,
			"^" => 15,
			"*" => 16,
			"+" => 13,
			"/" => 14,
			")" => 28
		}
	},
	{#State 20
		ACTIONS => {
			"/" => 14,
			"^" => 15,
			"*" => 16
		},
		DEFAULT => -8
	},
	{#State 21
		ACTIONS => {
			"/" => 14,
			"^" => 15,
			"*" => 16
		},
		DEFAULT => -7
	},
	{#State 22
		ACTIONS => {
			"^" => 15
		},
		DEFAULT => -10
	},
	{#State 23
		ACTIONS => {
			"^" => 15
		},
		DEFAULT => -12
	},
	{#State 24
		ACTIONS => {
			"^" => 15
		},
		DEFAULT => -9
	},
	{#State 25
		ACTIONS => {
			"}" => 29,
			"-" => 11,
			"^" => 15,
			"*" => 16,
			"+" => 13,
			"/" => 14
		}
	},
	{#State 26
		ACTIONS => {
			"-" => 11,
			"+" => 13,
			"/" => 14,
			"," => 30,
			"^" => 15,
			"*" => 16
		},
		DEFAULT => -15
	},
	{#State 27
		ACTIONS => {
			")" => 31
		}
	},
	{#State 28
		DEFAULT => -13
	},
	{#State 29
		DEFAULT => -3
	},
	{#State 30
		ACTIONS => {
			"-" => 1,
			'PRED' => 3,
			'PRIVEFUNC' => 4,
			'FUNC' => 5,
			'NUM' => 6,
			"(" => 7,
			'VAR' => 9,
			'EFUNC' => 8
		},
		GOTOS => {
			'exp' => 26,
			'list' => 32
		}
	},
	{#State 31
		DEFAULT => -2
	},
	{#State 32
		DEFAULT => -14
	}
],
                                  yyrules  =>
[
	[#Rule 0
		 '$start', 2, undef
	],
	[#Rule 1
		 'exp', 1,
sub { $_[1] }
	],
	[#Rule 2
		 'exp', 4,
sub {
                if (exists($Math::Symbolic::Parser::Parser_Functions{$_[1]})) {
                    $Math::Symbolic::Parser::Parser_Functions{$_[1]}->($_[1], @{$_[3]})
                }
                else {
                    Math::Symbolic::Operator->new($_[1], @{$_[3]})
                }
            }
	],
	[#Rule 3
		 'exp', 4,
sub {
                Math::Symbolic::Variable->new(
                    'TRANSFORMATION_HOOK',
                    [$_[1], $_[3]]
                );
            }
	],
	[#Rule 4
		 'exp', 1,
sub {
                $_[1] =~ /^([^(]+)\((.*)\)$/ or die "invalid per-object parser extension function: '$_[1]'";
                $_[0]->{__PRIV_EXT_FUNCTIONS}->{$1}->($2);
            }
	],
	[#Rule 5
		 'exp', 1,
sub {
                $_[1] =~ /^([^(]+)\((.*)\)$/ or die "invalid global parser extension function: '$_[1]'";
                $Math::SymbolicX::ParserExtensionFactory::Functions->{$1}->($2)
            }
	],
	[#Rule 6
		 'exp', 1,
sub { $_[1] }
	],
	[#Rule 7
		 'exp', 3,
sub { Math::Symbolic::Operator->new('+', $_[1], $_[3]) }
	],
	[#Rule 8
		 'exp', 3,
sub { Math::Symbolic::Operator->new('-', $_[1], $_[3]) }
	],
	[#Rule 9
		 'exp', 3,
sub { Math::Symbolic::Operator->new('*', $_[1], $_[3]) }
	],
	[#Rule 10
		 'exp', 3,
sub { Math::Symbolic::Operator->new('/', $_[1], $_[3]) }
	],
	[#Rule 11
		 'exp', 2,
sub { Math::Symbolic::Operator->new('neg', $_[2]) }
	],
	[#Rule 12
		 'exp', 3,
sub { Math::Symbolic::Operator->new('^', $_[1], $_[3]) }
	],
	[#Rule 13
		 'exp', 3,
sub { $_[2] }
	],
	[#Rule 14
		 'list', 3,
sub { unshift @{$_[3]}, $_[1]; $_[3] }
	],
	[#Rule 15
		 'list', 1,
sub { [$_[1]] }
	]
],
                                  @_);
    bless($self,$class);
}



use strict;
use warnings;
use Math::Symbolic qw//;
use constant DAT => 0;
use constant OP  => 1;

sub _Error {
    exists $_[0]->YYData->{ERRMSG}
    and do {
        my $x = $_[0]->YYData->{ERRMSG};
        delete $_[0]->YYData->{ERRMSG};
        die $x;
    };
    die "Syntax error in input string while parsing the following string: '".$_[0]->{USER}{INPUT}."'\n";
}

my $Num = qr/[+-]?(?=\d|\.\d)\d*(?:\.\d*)?(?:[Ee]([+-]?\d+))?/o;
my $Ident = qr/[a-zA-Z][a-zA-Z0-9_]*/o;
my $Op =  qr/\+|\-|\*|\/|\^/o;
my $Func = qr/log|partial_derivative|total_derivative|a?(?:sin|sinh|cos|cosh|tan|cot)|exp|sqrt/;
my $Unary = qr/\+|\-/o;

# taken from perlre
my $balanced_parens_re;
$balanced_parens_re = qr{\((?:(?>[^()]+)|(??{$balanced_parens_re}))*\)};

# This is a hack so we can hook into the new() method.
{
    no warnings; no strict;
    *real_new = \&new;
    *new = sub {
        my $class = shift;
        my %args = @_;
        my $predicates = $args{predicates};
        delete $args{predicates};
        my $parser = real_new($class, %args);
        if ($predicates) {
            $parser->{__PREDICATES} = $predicates;
        }
        return $parser;
    };
}

sub _Lexer {
    my($parser)=shift;

    my $ExtFunc     = $Math::SymbolicX::ParserExtensionFactory::RegularExpression || qr/(?!)/;
    my $PrivExtFunc = $parser->{__PRIV_EXT_FUNC_REGEX};

    my $data = $parser->{USER};
    my $predicates = $parser->{__PREDICATES};

    pos($data->{INPUT}) < length($data->{INPUT})
    or  return('',undef);

    # This is a huge hack
    if (defined $predicates) {
        for ($data->{INPUT}) {
            if ($data->{STATE} == DAT) {
                if ($data->{INPUT} =~ /\G($Func)(?=\()/cg) {
                    return('FUNC', $1);
                }
                elsif ($PrivExtFunc ? $data->{INPUT} =~ /\G($PrivExtFunc$balanced_parens_re)/cg : 0) {
                    $data->{STATE} = OP;
                    return('PRIVEFUNC', $1);
                }
                elsif ($data->{INPUT} =~ /\G($ExtFunc$balanced_parens_re)/cg) {
                    $data->{STATE} = OP;
                    return('EFUNC', $1);
                }
                elsif ($data->{INPUT} =~ /\G($predicates)(?=\{)/cg) {
                    return('PRED', $1);
                }
                elsif ($data->{INPUT} =~ /\G($Ident)((?>\'*))(?:\(($Ident(?:,$Ident)*)\))?/cgo) {
                    $data->{STATE} = OP;
                    my $name  = $1;
                    my $ticks = $2;
                    my $sig   = $3;
                    my $n;
                    if (defined $ticks and ($n = length($ticks))) {
                        my @sig = defined($sig) ? (split /,/, $sig) : ('x');
                        my $return = Math::Symbolic::Variable->new(
                          {name=>$name, signature=>\@sig}
                        );
                        my $var = $sig[0];
                        foreach (1..$n) {
                            $return = Math::Symbolic::Operator->new(
                              'partial_derivative',
                              $return, $var,
                            );
                        }
                        return('VAR', $return);
                    }
                    elsif (defined $sig) {
                        return(
                            'VAR', Math::Symbolic::Variable->new({name=>$name, signature=>[split /,/, $sig]})
                        );
                    }
                    else {
                        return('VAR', Math::Symbolic::Variable->new($name));
                    }
                }
                elsif ($data->{INPUT} =~ /\G\(/cgo) {
                    return('(', '(');
                }
                elsif ($data->{INPUT} =~ /\G\{/cgo) {
                    return('{', '{');
                }
                elsif ($data->{INPUT} =~ /\G($Num)/cgo) {
                    $data->{STATE} = OP;
                    return('NUM', Math::Symbolic::Constant->new($1));
                }
                elsif ($data->{INPUT} =~ /\G($Unary)/cgo) {
                    return($1, $1);
                }
                else {
                    my $pos = pos($data->{INPUT});
                    die "Parse error at position $pos of string '$data->{INPUT}'.\nCould not find a suitable token while expecting data (identifier, function, number, etc.).";
                }
            }
            else { # $data->{STATE} == OP
                if ($data->{INPUT} =~ /\G\)/cgo) {
                    return(')', ')');
                }
                elsif ($data->{INPUT} =~ /\G\}/cgo) {
                    return('}', '}');
                }
                elsif ($data->{INPUT} =~ /\G($Op)/cgo) {
                    $data->{STATE} = DAT;
                    return($1, $1);
                }
                elsif ($data->{INPUT} =~ /\G,/cgo) {
                    $data->{STATE} = DAT;
                    return(',', ',');
                }
                else {
                    my $pos = pos($data->{INPUT});
                    die "Parse error at position $pos of string '$data->{INPUT}'.\nCould not find a suitable token while expecting an operator (+, -, etc).";
                }
            }
        }
    } # }}} end if defined $predicates
    else { # {{{ not defined $predicates
        for ($data->{INPUT}) {
            if ($data->{STATE} == DAT) {
                if ($data->{INPUT} =~ /\G($Func)(?=\()/cg) {
                    return('FUNC', $1);
                }
                elsif ($PrivExtFunc ? $data->{INPUT} =~ /\G($PrivExtFunc\s*$balanced_parens_re)/cg : 0) {
                    $data->{STATE} = OP;
                    return('PRIVEFUNC', $1);
                }
                elsif ($data->{INPUT} =~ /\G($ExtFunc\s*$balanced_parens_re)/cg) {
                    $data->{STATE} = OP;
                    return('EFUNC', $1);
                }
                elsif ($data->{INPUT} =~ /\G($Ident)((?>\'*))(?:\(($Ident(?:,$Ident)*)\))?/cgo) {
                    $data->{STATE} = OP;
                    my $name  = $1;
                    my $ticks = $2;
                    my $sig   = $3;
                    my $n;
                    if (defined $ticks and ($n = length($ticks))) {
                        my @sig = defined($sig) ? (split /,/, $sig) : ('x');
                        my $return = Math::Symbolic::Variable->new(
                          {name=>$name, signature=>\@sig}
                        );
                        my $var = $sig[0];
                        foreach (1..$n) {
                            $return = Math::Symbolic::Operator->new(
                              'partial_derivative',
                              $return, $var,
                            );
                        }
                        return('VAR', $return);
                    }
                    elsif (defined $sig) {
                        return(
                            'VAR', Math::Symbolic::Variable->new({name=>$name, signature=>[split /,/, $sig]})
                        );
                    }
                    else {
                        return('VAR', Math::Symbolic::Variable->new($name));
                    }
                }
                elsif ($data->{INPUT} =~ /\G\(/cgo) {
                    return('(', '(');
                }
                elsif ($data->{INPUT} =~ /\G($Num)/cgo) {
                    $data->{STATE} = OP;
                    return('NUM', Math::Symbolic::Constant->new($1));
                }
                elsif ($data->{INPUT} =~ /\G($Unary)/cgo) {
                    return($1, $1);
                }
                else {
                    my $pos = pos($data->{INPUT});
                    die "Parse error at position $pos of string '$data->{INPUT}'.\nCould not find a suitable token while expecting data (identifier, function, number, etc.).";
                }
            }
            else { # $data->{STATE} == OP
                if ($data->{INPUT} =~ /\G\)/cgo) {
                    return(')', ')');
                }
                elsif ($data->{INPUT} =~ /\G($Op)/cgo) {
                    $data->{STATE} = DAT;
                    return($1, $1);
                }
                elsif ($data->{INPUT} =~ /\G,/cgo) {
                    $data->{STATE} = DAT;
                    return(',', ',');
                }
                else {
                    my $pos = pos($data->{INPUT});
                    die "Parse error at position $pos of string '$data->{INPUT}'.\nCould not find a suitable token while expecting an operator (+, -, etc).";
                }
            }
        }
    } # }}} end else => not defined $predicates

}

sub parse {
    my($self)=shift;
    my $in = shift;
    $in =~ s/\s+//g;
    $self->{USER}{STATE} = DAT;
    $self->{USER}{INPUT} = $in;
    pos($self->{USER}{INPUT}) = 0;
    return $self->YYParse( yylex => \&_Lexer, yyerror => \&_Error );
}

sub parsedebug {
    my($self)=shift;
    my $in = shift;
    $in =~ s/\s+//g;
    $self->{USER}{STATE} = DAT;
    $self->{USER}{INPUT} = $in;
    pos($self->{USER}{INPUT}) = 0;
    return $self->YYParse( yydebug => 0x1F, yylex => \&_Lexer, yyerror => \&_Error );
}

1;

1;
