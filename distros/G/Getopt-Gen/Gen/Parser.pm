####################################################################
#
#    This file was generated using Parse::Yapp version 1.05.
#
#        Don't edit this file, use source file instead.
#
#             ANY CHANGE MADE HERE WILL BE LOST !
#
####################################################################
package Getopt::Gen::Parser;
use vars qw ( @ISA );
use strict;

@ISA= qw ( Parse::Yapp::Driver );
use Parse::Yapp::Driver;

#line 16 "Gen/Parser.yp"


###############################################################
#
#        Source: Getopt::Gen::Parser.yp
# Source Author: Bryan Jurish <Gen/cmdline_pod.pm>
#
#   Description: Yapp parser for DWDS query strings
#
###############################################################

#==============================================================
# * WARNING * WARNING * WARNING * WARNING * WARNING * WARNING *
#==============================================================
#  Do *NOT* change Parser.pm directly, change Parser.yp
#  and re-call 'yapp' instead!
#==============================================================

package Getopt::Gen::Parser;

#--------------------------------------
# Package variables
#--------------------------------------
our $VERSION = 0.04;

#--------------------------------------
# Hint routines
#--------------------------------------
# undef = $yapp_parser->show_hint($hint_code,$curtok,$curval)
sub show_hint {
  $_[0]->{USER}{'hint'} = $_[1];
  $_[0]->YYCurtok($_[2]) if (defined($_[2]));
  $_[0]->YYCurval($_[3]) if (defined($_[3]));
  $_[0]->YYError;
}



sub new {
        my($class)=shift;
        ref($class)
    and $class=ref($class);

    my($self)=$class->SUPER::new( yyversion => '1.05',
                                  yystates =>
[
	{#State 0
		ACTIONS => {
			'EOI' => 1
		},
		DEFAULT => -1,
		GOTOS => {
			'specs' => 2
		}
	},
	{#State 1
		DEFAULT => -2
	},
	{#State 2
		ACTIONS => {
			'EOI' => 7,
			'' => 5,
			'NEWLINE' => 4
		},
		GOTOS => {
			'newlines' => 6,
			'newline' => 3
		}
	},
	{#State 3
		DEFAULT => -67
	},
	{#State 4
		DEFAULT => -69
	},
	{#State 5
		DEFAULT => 0
	},
	{#State 6
		ACTIONS => {
			'TOK_OPTION' => 37,
			'TOK_PODPREAMBLE' => 36,
			'TOK_VERSION' => 25,
			'TOK_PACKAGE' => 32,
			'TOK_GROUP' => 29,
			'TOK_PURPOSE' => 28,
			'TOK_LONG' => 30,
			'TOK_CODE' => 17,
			'TOK_UNNAMED' => 18,
			'TOK_LONGDOUBLE' => 19,
			'TOK_SHORT' => 16,
			'SYMBOL' => 23,
			'TOK_STRING' => 24,
			'NEWLINE' => 4,
			'TOK_RCFILE' => 22,
			'TOK_DOUBLE' => 21,
			'TOK_FLAG' => 8,
			'TOK_FUNCT' => 9,
			'TOK_FLOAT' => 13,
			'TOK_INT' => 14,
			'TOK_TOGGLE' => 12,
			'TOK_ON_REPARSE' => 15,
			'TOK_ARGUMENT' => 10
		},
		DEFAULT => -4,
		GOTOS => {
			'spec' => 27,
			'extended_spec' => 26,
			'newline' => 31,
			'basic_spec' => 11,
			'extended_option_type' => 34,
			'ggo_option_spec' => 33,
			'symbol' => 20,
			'user_spec' => 35
		}
	},
	{#State 7
		DEFAULT => -3
	},
	{#State 8
		DEFAULT => -18
	},
	{#State 9
		DEFAULT => -17
	},
	{#State 10
		ACTIONS => {
			'DQ_STRING' => 38,
			'SQ_STRING' => 43,
			'BR_STRING' => 40,
			'SYMBOL' => 42,
			'BQ_STRING' => 39
		},
		GOTOS => {
			'string' => 41
		}
	},
	{#State 11
		DEFAULT => -6
	},
	{#State 12
		DEFAULT => -19
	},
	{#State 13
		DEFAULT => -24
	},
	{#State 14
		DEFAULT => -21
	},
	{#State 15
		ACTIONS => {
			'BR_STRING' => 40,
			'BQ_STRING' => 39,
			'SYMBOL' => 42,
			'SQ_STRING' => 43,
			'DQ_STRING' => 38
		},
		GOTOS => {
			'reparse_action' => 44,
			'string' => 45
		}
	},
	{#State 16
		DEFAULT => -22
	},
	{#State 17
		ACTIONS => {
			'DQ_STRING' => 38,
			'SQ_STRING' => 43,
			'BR_STRING' => 40,
			'SYMBOL' => 42,
			'BQ_STRING' => 39
		},
		GOTOS => {
			'string' => 46
		}
	},
	{#State 18
		ACTIONS => {
			'BR_STRING' => 40,
			'SYMBOL' => 42,
			'BQ_STRING' => 39,
			'SQ_STRING' => 43,
			'DQ_STRING' => 38
		},
		GOTOS => {
			'string' => 47
		}
	},
	{#State 19
		DEFAULT => -26
	},
	{#State 20
		ACTIONS => {
			'BR_STRING' => 40,
			'BQ_STRING' => 39,
			'SYMBOL' => 42,
			'SQ_STRING' => 43,
			'DQ_STRING' => 38
		},
		GOTOS => {
			'string' => 48,
			'user_value' => 49
		}
	},
	{#State 21
		DEFAULT => -25
	},
	{#State 22
		ACTIONS => {
			'BQ_STRING' => 39,
			'SYMBOL' => 42,
			'BR_STRING' => 40,
			'DQ_STRING' => 38,
			'SQ_STRING' => 43
		},
		GOTOS => {
			'string' => 50
		}
	},
	{#State 23
		DEFAULT => -60
	},
	{#State 24
		DEFAULT => -20
	},
	{#State 25
		ACTIONS => {
			'SQ_STRING' => 43,
			'DQ_STRING' => 38,
			'SYMBOL' => 42,
			'BQ_STRING' => 39,
			'BR_STRING' => 40
		},
		GOTOS => {
			'string' => 51
		}
	},
	{#State 26
		DEFAULT => -8
	},
	{#State 27
		DEFAULT => -5
	},
	{#State 28
		ACTIONS => {
			'BR_STRING' => 40,
			'SYMBOL' => 42,
			'BQ_STRING' => 39,
			'SQ_STRING' => 43,
			'DQ_STRING' => 38
		},
		GOTOS => {
			'string' => 52
		}
	},
	{#State 29
		ACTIONS => {
			'DQ_STRING' => 38,
			'SQ_STRING' => 43,
			'SYMBOL' => 42,
			'BQ_STRING' => 39,
			'BR_STRING' => 40
		},
		GOTOS => {
			'string' => 53
		}
	},
	{#State 30
		DEFAULT => -23
	},
	{#State 31
		DEFAULT => -68
	},
	{#State 32
		ACTIONS => {
			'BR_STRING' => 40,
			'BQ_STRING' => 39,
			'SYMBOL' => 42,
			'SQ_STRING' => 43,
			'DQ_STRING' => 38
		},
		GOTOS => {
			'string' => 54
		}
	},
	{#State 33
		DEFAULT => -7
	},
	{#State 34
		ACTIONS => {
			'DQ_STRING' => 38,
			'SQ_STRING' => 43,
			'MINUS' => 57,
			'BR_STRING' => 40,
			'BQ_STRING' => 39,
			'SYMBOL' => 42
		},
		GOTOS => {
			'longname' => 55,
			'string' => 56,
			'extended_option_body' => 58
		}
	},
	{#State 35
		DEFAULT => -9
	},
	{#State 36
		ACTIONS => {
			'SYMBOL' => 42,
			'BQ_STRING' => 39,
			'BR_STRING' => 40,
			'SQ_STRING' => 43,
			'DQ_STRING' => 38
		},
		GOTOS => {
			'string' => 59
		}
	},
	{#State 37
		ACTIONS => {
			'BQ_STRING' => 39,
			'SYMBOL' => 42,
			'BR_STRING' => 40,
			'MINUS' => 57,
			'SQ_STRING' => 43,
			'DQ_STRING' => 38
		},
		GOTOS => {
			'longname' => 60,
			'string' => 56
		}
	},
	{#State 38
		DEFAULT => -62
	},
	{#State 39
		DEFAULT => -65
	},
	{#State 40
		DEFAULT => -64
	},
	{#State 41
		ACTIONS => {
			'SQ_STRING' => 43,
			'DQ_STRING' => 38,
			'SYMBOL' => 42,
			'BQ_STRING' => 39,
			'BR_STRING' => 40
		},
		GOTOS => {
			'string' => 61
		}
	},
	{#State 42
		DEFAULT => -66
	},
	{#State 43
		DEFAULT => -63
	},
	{#State 44
		DEFAULT => -14
	},
	{#State 45
		DEFAULT => -28
	},
	{#State 46
		DEFAULT => -10
	},
	{#State 47
		DEFAULT => -15
	},
	{#State 48
		DEFAULT => -30
	},
	{#State 49
		DEFAULT => -29
	},
	{#State 50
		DEFAULT => -11
	},
	{#State 51
		DEFAULT => -32
	},
	{#State 52
		DEFAULT => -33
	},
	{#State 53
		DEFAULT => -13
	},
	{#State 54
		DEFAULT => -31
	},
	{#State 55
		ACTIONS => {
			'SYMBOL' => 64,
			'MINUS' => 63
		},
		GOTOS => {
			'shortname' => 62
		}
	},
	{#State 56
		DEFAULT => -53
	},
	{#State 57
		DEFAULT => -54
	},
	{#State 58
		DEFAULT => -16
	},
	{#State 59
		DEFAULT => -34
	},
	{#State 60
		ACTIONS => {
			'MINUS' => 63,
			'SYMBOL' => 64
		},
		GOTOS => {
			'shortname' => 65
		}
	},
	{#State 61
		DEFAULT => -42,
		GOTOS => {
			'kw_decls' => 66
		}
	},
	{#State 62
		ACTIONS => {
			'BQ_STRING' => 39,
			'SYMBOL' => 42,
			'BR_STRING' => 40,
			'SQ_STRING' => 43,
			'DQ_STRING' => 38
		},
		GOTOS => {
			'string' => 67,
			'description' => 68
		}
	},
	{#State 63
		DEFAULT => -56
	},
	{#State 64
		DEFAULT => -55
	},
	{#State 65
		ACTIONS => {
			'DQ_STRING' => 38,
			'SQ_STRING' => 43,
			'BQ_STRING' => 39,
			'SYMBOL' => 42,
			'BR_STRING' => 40
		},
		GOTOS => {
			'string' => 67,
			'description' => 69
		}
	},
	{#State 66
		ACTIONS => {
			'TOK_CODE' => 70,
			'SYMBOL' => 23
		},
		DEFAULT => -12,
		GOTOS => {
			'symbol' => 71
		}
	},
	{#State 67
		DEFAULT => -57
	},
	{#State 68
		DEFAULT => -42,
		GOTOS => {
			'kw_decls' => 72
		}
	},
	{#State 69
		ACTIONS => {
			'TOK_STRING' => 77,
			'TOK_DOUBLE' => 76,
			'TOK_NO' => 85,
			'TOK_LONGDOUBLE' => 81,
			'TOK_SHORT' => 78,
			'TOK_FLOAT' => 73,
			'TOK_INT' => 74,
			'TOK_LONG' => 82,
			'TOK_FLAG' => 75
		},
		GOTOS => {
			'functType' => 84,
			'ggo_option_body' => 80,
			'option_argument_type' => 79,
			'flagType' => 83
		}
	},
	{#State 70
		DEFAULT => -61
	},
	{#State 71
		ACTIONS => {
			'EQUALS' => 86
		}
	},
	{#State 72
		ACTIONS => {
			'SYMBOL' => 23,
			'TOK_CODE' => 70
		},
		DEFAULT => -27,
		GOTOS => {
			'symbol' => 71
		}
	},
	{#State 73
		DEFAULT => -50
	},
	{#State 74
		DEFAULT => -47
	},
	{#State 75
		DEFAULT => -45
	},
	{#State 76
		DEFAULT => -51
	},
	{#State 77
		DEFAULT => -46
	},
	{#State 78
		DEFAULT => -48
	},
	{#State 79
		DEFAULT => -42,
		GOTOS => {
			'kw_decls' => 87
		}
	},
	{#State 80
		DEFAULT => -35
	},
	{#State 81
		DEFAULT => -52
	},
	{#State 82
		DEFAULT => -49
	},
	{#State 83
		DEFAULT => -42,
		GOTOS => {
			'kw_decls' => 88
		}
	},
	{#State 84
		DEFAULT => -36
	},
	{#State 85
		DEFAULT => -44
	},
	{#State 86
		ACTIONS => {
			'BR_STRING' => 40,
			'SYMBOL' => 42,
			'BQ_STRING' => 39,
			'DQ_STRING' => 38,
			'SQ_STRING' => 43
		},
		GOTOS => {
			'string' => 89
		}
	},
	{#State 87
		ACTIONS => {
			'TOK_CODE' => 70,
			'TOK_YES' => 90,
			'TOK_NO' => 91,
			'SYMBOL' => 23
		},
		GOTOS => {
			'symbol' => 71,
			'yesno' => 93,
			'required' => 92
		}
	},
	{#State 88
		ACTIONS => {
			'SYMBOL' => 23,
			'TOK_CODE' => 70,
			'TOK_OFF' => 95,
			'TOK_ON' => 96
		},
		GOTOS => {
			'onoff_value' => 94,
			'symbol' => 71
		}
	},
	{#State 89
		DEFAULT => -43
	},
	{#State 90
		DEFAULT => -41
	},
	{#State 91
		DEFAULT => -40
	},
	{#State 92
		DEFAULT => -38
	},
	{#State 93
		DEFAULT => -39
	},
	{#State 94
		DEFAULT => -37
	},
	{#State 95
		DEFAULT => -59
	},
	{#State 96
		DEFAULT => -58
	}
],
                                  yyrules  =>
[
	[#Rule 0
		 '$start', 2, undef
	],
	[#Rule 1
		 'specs', 0,
sub
#line 69 "Gen/Parser.yp"
{ 1 }
	],
	[#Rule 2
		 'specs', 1,
sub
#line 70 "Gen/Parser.yp"
{ 1 }
	],
	[#Rule 3
		 'specs', 2, undef
	],
	[#Rule 4
		 'specs', 2, undef
	],
	[#Rule 5
		 'specs', 3, undef
	],
	[#Rule 6
		 'spec', 1, undef
	],
	[#Rule 7
		 'spec', 1, undef
	],
	[#Rule 8
		 'spec', 1, undef
	],
	[#Rule 9
		 'spec', 1, undef
	],
	[#Rule 10
		 'extended_spec', 2,
sub
#line 87 "Gen/Parser.yp"
{
    $_[0]->{USER}{og}->add_user_code($_[2]);
  }
	],
	[#Rule 11
		 'extended_spec', 2,
sub
#line 90 "Gen/Parser.yp"
{
    $_[0]->{USER}{og}->add_rcfile($_[2]);
  }
	],
	[#Rule 12
		 'extended_spec', 4,
sub
#line 93 "Gen/Parser.yp"
{
    $_[0]->{USER}{og}->add_argument({name=>$_[2],descr=>$_[3],%{$_[4]}});
  }
	],
	[#Rule 13
		 'extended_spec', 2,
sub
#line 96 "Gen/Parser.yp"
{
    $_[0]->{USER}{og}->add_group($_[2]);
  }
	],
	[#Rule 14
		 'extended_spec', 2,
sub
#line 99 "Gen/Parser.yp"
{
    $_[0]->{USER}{og}->set_reparse_action($_[2]);
  }
	],
	[#Rule 15
		 'extended_spec', 2,
sub
#line 102 "Gen/Parser.yp"
{
    $_[0]{USER}{og}{unnamed} = $_[2];
  }
	],
	[#Rule 16
		 'extended_spec', 2,
sub
#line 106 "Gen/Parser.yp"
{
    $_[0]->{USER}{og}->add_option({ type=>$_[1], %{$_[2]}, },
				  $_[0]);
  }
	],
	[#Rule 17
		 'extended_option_type', 1,
sub
#line 114 "Gen/Parser.yp"
{ 'funct' }
	],
	[#Rule 18
		 'extended_option_type', 1,
sub
#line 115 "Gen/Parser.yp"
{ 'flag2' }
	],
	[#Rule 19
		 'extended_option_type', 1,
sub
#line 116 "Gen/Parser.yp"
{ 'flag' }
	],
	[#Rule 20
		 'extended_option_type', 1,
sub
#line 117 "Gen/Parser.yp"
{ 'string' }
	],
	[#Rule 21
		 'extended_option_type', 1,
sub
#line 118 "Gen/Parser.yp"
{ 'int' }
	],
	[#Rule 22
		 'extended_option_type', 1,
sub
#line 119 "Gen/Parser.yp"
{ 'short' }
	],
	[#Rule 23
		 'extended_option_type', 1,
sub
#line 120 "Gen/Parser.yp"
{ 'long' }
	],
	[#Rule 24
		 'extended_option_type', 1,
sub
#line 121 "Gen/Parser.yp"
{ 'float' }
	],
	[#Rule 25
		 'extended_option_type', 1,
sub
#line 122 "Gen/Parser.yp"
{ 'double' }
	],
	[#Rule 26
		 'extended_option_type', 1,
sub
#line 123 "Gen/Parser.yp"
{ 'longdouble' }
	],
	[#Rule 27
		 'extended_option_body', 4,
sub
#line 128 "Gen/Parser.yp"
{ my %hash = (long=>$_[1],
		short=>$_[2],
		descr=>$_[3],
		%{$_[4]});
    \%hash;
  }
	],
	[#Rule 28
		 'reparse_action', 1, undef
	],
	[#Rule 29
		 'user_spec', 2,
sub
#line 143 "Gen/Parser.yp"
{
    $_[0]->{USER}{og}{USER}{$_[1]} = $_[2];
  }
	],
	[#Rule 30
		 'user_value', 1, undef
	],
	[#Rule 31
		 'basic_spec', 2,
sub
#line 155 "Gen/Parser.yp"
{ $_[0]->{USER}{og}{package} = $_[2]; }
	],
	[#Rule 32
		 'basic_spec', 2,
sub
#line 156 "Gen/Parser.yp"
{ $_[0]->{USER}{og}{version} = $_[2]; }
	],
	[#Rule 33
		 'basic_spec', 2,
sub
#line 157 "Gen/Parser.yp"
{ $_[0]->{USER}{og}{purpose} = $_[2]; }
	],
	[#Rule 34
		 'basic_spec', 2,
sub
#line 158 "Gen/Parser.yp"
{ $_[0]->{USER}{og}{podpreamble} = $_[2]; }
	],
	[#Rule 35
		 'ggo_option_spec', 5,
sub
#line 162 "Gen/Parser.yp"
{
    $_[0]->{USER}{og}->add_option({
				   long=>$_[2],
				   short=>$_[3],
				   descr=>$_[4],
				   %{$_[5]},
				  },
				  $_[0]);
  }
	],
	[#Rule 36
		 'ggo_option_body', 1,
sub
#line 177 "Gen/Parser.yp"
{
    ## -- function-option
    {type=>'funct',default=>0};
  }
	],
	[#Rule 37
		 'ggo_option_body', 3,
sub
#line 181 "Gen/Parser.yp"
{
    ## -- flag option
    {type=>'flag', %{$_[2]}, default=>$_[3]};
  }
	],
	[#Rule 38
		 'ggo_option_body', 3,
sub
#line 185 "Gen/Parser.yp"
{
    ## -- option with an argument
    {type=>$_[1], %{$_[2]}, required=>$_[3]};
  }
	],
	[#Rule 39
		 'required', 1, undef
	],
	[#Rule 40
		 'yesno', 1,
sub
#line 195 "Gen/Parser.yp"
{ "0" }
	],
	[#Rule 41
		 'yesno', 1,
sub
#line 196 "Gen/Parser.yp"
{ "1" }
	],
	[#Rule 42
		 'kw_decls', 0,
sub
#line 199 "Gen/Parser.yp"
{ {} }
	],
	[#Rule 43
		 'kw_decls', 4,
sub
#line 201 "Gen/Parser.yp"
{
      my %hash = (%{$_[1]}, $_[2]=>$_[4]);
      \%hash;
    }
	],
	[#Rule 44
		 'functType', 1, undef
	],
	[#Rule 45
		 'flagType', 1, undef
	],
	[#Rule 46
		 'option_argument_type', 1, undef
	],
	[#Rule 47
		 'option_argument_type', 1, undef
	],
	[#Rule 48
		 'option_argument_type', 1, undef
	],
	[#Rule 49
		 'option_argument_type', 1, undef
	],
	[#Rule 50
		 'option_argument_type', 1, undef
	],
	[#Rule 51
		 'option_argument_type', 1, undef
	],
	[#Rule 52
		 'option_argument_type', 1, undef
	],
	[#Rule 53
		 'longname', 1, undef
	],
	[#Rule 54
		 'longname', 1,
sub
#line 221 "Gen/Parser.yp"
{ "-" }
	],
	[#Rule 55
		 'shortname', 1,
sub
#line 224 "Gen/Parser.yp"
{
    if (length("$_[1]") ne 1) {
      $_[0]->show_hint('NOT_SHORT_ENOUGH','SHORT_OPTION_NAME',$_[1]);
    }
    $_[1];
  }
	],
	[#Rule 56
		 'shortname', 1,
sub
#line 230 "Gen/Parser.yp"
{ "-" }
	],
	[#Rule 57
		 'description', 1, undef
	],
	[#Rule 58
		 'onoff_value', 1,
sub
#line 237 "Gen/Parser.yp"
{ "1" }
	],
	[#Rule 59
		 'onoff_value', 1,
sub
#line 238 "Gen/Parser.yp"
{ "0" }
	],
	[#Rule 60
		 'symbol', 1, undef
	],
	[#Rule 61
		 'symbol', 1, undef
	],
	[#Rule 62
		 'string', 1,
sub
#line 248 "Gen/Parser.yp"
{ $_[1] }
	],
	[#Rule 63
		 'string', 1,
sub
#line 249 "Gen/Parser.yp"
{ $_[1] }
	],
	[#Rule 64
		 'string', 1,
sub
#line 250 "Gen/Parser.yp"
{ $_[1] }
	],
	[#Rule 65
		 'string', 1,
sub
#line 251 "Gen/Parser.yp"
{ $_[1] }
	],
	[#Rule 66
		 'string', 1,
sub
#line 252 "Gen/Parser.yp"
{ $_[1] }
	],
	[#Rule 67
		 'newlines', 1, undef
	],
	[#Rule 68
		 'newlines', 2, undef
	],
	[#Rule 69
		 'newline', 1, undef
	]
],
                                  @_);
    bless($self,$class);
}

#line 263 "Gen/Parser.yp"

##############################################################
# Footer Section
###############################################################

package Getopt::Gen::Parser;

1;

__END__
# Pod docs
=pod

=head1 NAME

Getopt::Gen::Parser - Low-level Yapp parser for Getopt::Gen.

=head1 SYNOPSIS

  use Getopt::Gen::Parser;

  $qpp = Getopt::Gen::Parser->new();
  $qpp->parse(yylex => sub { ... });
  # ... any other Parse::Yapp parser routine

  $qpp->show_hint($hint_code,$curtok,$curval);

=cut

#-------------------------------------------------------------
# Description
#-------------------------------------------------------------
=pod

=head1 DESCRIPTION

Getopt::Gen::Parser is a parser class for use by Getopt::Gen.
This class should not need to be accessed directly.  Instead,
use the interface methods in C<Getopt::Gen>.

=cut

#-------------------------------------------------------------
# Variables
#-------------------------------------------------------------
=pod

=head1 PACKAGE VARIABLES

The following package variables are declared by
Getopt::Gen::Parser.

(None).

=cut

#-------------------------------------------------------------
# Tags
#-------------------------------------------------------------
=pod

=head1 EXPORTS

None.

=cut

#-------------------------------------------------------------
# Methods
#-------------------------------------------------------------
=pod

=head1 METHODS

Most methods are inherited from C<Parse::Yapp::Driver>.
See L<Parse::Yapp> for details on these.

=over 4

=item * C<show_hint($hint_code,$curtok,$curval)>

Hack.  Places $hint_code into the 'hint' field of
the parser object's C<USER> (read "YYData()") hashref,
sets YYCurtok and YYCurval to $curtok and $curval
respectively, and calls the parser object's YYError()
method.  See L<Getopt::Gen> for details on
the 'hint' convention.

=back

=cut

#-------------------------------------------------------------
# Bugs and Limitations
#-------------------------------------------------------------
=pod

=head1 BUGS AND LIMITATIONS

Probably many.

=cut

#-------------------------------------------------------------
# Footer
#-------------------------------------------------------------
=pod

=head1 ACKNOWLEDGEMENTS

Perl by Larry Wall.

Parse::Yapp by Francois Desarmenien.

=head1 AUTHOR

Bryan Jurish E<lt>Gen/cmdline_pod.pmE<gt>

=head1 SEE ALSO

perl(1).
yapp(1).
Parse::Yapp(3pm).
Getopt::Gen(3pm).

=cut

1;
