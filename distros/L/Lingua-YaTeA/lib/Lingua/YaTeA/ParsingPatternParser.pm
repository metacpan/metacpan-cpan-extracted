####################################################################
#
#    This file was generated using Parse::Yapp version 1.05.
#
#        Don't edit this file, use source file instead.
#
#             ANY CHANGE MADE HERE WILL BE LOST !
#
####################################################################
package Lingua::YaTeA::ParsingPatternParser;
use vars qw ( @ISA );
use strict;

@ISA= qw ( Parse::Yapp::Driver );
use Parse::Yapp::Driver;

#line 12 "lib/Lingua/YaTeA/ParsingPatternParser.yp"

    use Lingua::YaTeA;
#     use Data::Dumper;
    use warnings;

    my $node_set;
    my $level = 0;
    my $node;
    my @uncomplete;
    my @parse;
    my $edge;
    my $num_content_words;
    my @pos_sequence;
    my $priority;
    my $direction;
    my $pos_sequence;
    my $pattern;
    my $parse;
    my $num_line = 1;


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
			'input' => 1
		}
	},
	{#State 1
		ACTIONS => {
			'' => 2,
			"\n" => 5,
			'error' => 6,
			'OPEN_TAG' => -6
		},
		GOTOS => {
			'parsingpattern' => 4,
			'@1-0' => 3,
			'line' => 7
		}
	},
	{#State 2
		DEFAULT => 0
	},
	{#State 3
		ACTIONS => {
			'error' => 9,
			'OPEN_TAG' => 10
		},
		GOTOS => {
			'OPEN' => 8
		}
	},
	{#State 4
		ACTIONS => {
			"\n" => 11
		}
	},
	{#State 5
		DEFAULT => -3
	},
	{#State 6
		ACTIONS => {
			"\n" => 12,
			"parsingpattern" => 13
		}
	},
	{#State 7
		DEFAULT => -2
	},
	{#State 8
		ACTIONS => {
			'error' => 17,
			'OPEN_TAG' => 10,
			'CANDIDATE_TAG' => 18
		},
		GOTOS => {
			'OPEN' => 14,
			'pattern' => 15,
			'CANDIDATE' => 16
		}
	},
	{#State 9
		ACTIONS => {
			"\nOPEN: " => 19
		}
	},
	{#State 10
		DEFAULT => -15
	},
	{#State 11
		DEFAULT => -4
	},
	{#State 12
		DEFAULT => -5
	},
	{#State 13
		DEFAULT => -8
	},
	{#State 14
		ACTIONS => {
			'error' => 17,
			'OPEN_TAG' => 10,
			'CANDIDATE_TAG' => 18
		},
		GOTOS => {
			'OPEN' => 14,
			'pattern' => 20,
			'CANDIDATE' => 16
		}
	},
	{#State 15
		ACTIONS => {
			'END_TAG' => 21,
			'error' => 22
		},
		GOTOS => {
			'END' => 23
		}
	},
	{#State 16
		ACTIONS => {
			'DET_TAG' => 26,
			'error' => 28,
			'OPEN_TAG' => 10,
			'CANDIDATE_TAG' => 18,
			'PREP_TAG' => 25
		},
		GOTOS => {
			'OPEN' => 14,
			'PREP' => 27,
			'CANDIDATE' => 24,
			'DET' => 29
		}
	},
	{#State 17
		ACTIONS => {
			"\nCANDIDATE: " => 30,
			"\nOPEN: " => 19,
			"\nnew_pattern: " => 31
		}
	},
	{#State 18
		ACTIONS => {
			'POSITION_TAG' => 32
		}
	},
	{#State 19
		DEFAULT => -16
	},
	{#State 20
		ACTIONS => {
			'CLOSE_TAG' => 34,
			'error' => 35
		},
		GOTOS => {
			'CLOSE' => 33
		}
	},
	{#State 21
		DEFAULT => -26
	},
	{#State 22
		ACTIONS => {
			"\nEND: " => 36
		}
	},
	{#State 23
		ACTIONS => {
			'PRIORITY_TAG' => 38,
			'error' => 39
		},
		GOTOS => {
			'priority' => 37
		}
	},
	{#State 24
		DEFAULT => -13
	},
	{#State 25
		DEFAULT => -20
	},
	{#State 26
		DEFAULT => -22
	},
	{#State 27
		ACTIONS => {
			'DET_TAG' => 26,
			'error' => 28,
			'OPEN_TAG' => 10,
			'CANDIDATE_TAG' => 18,
			'PREP_TAG' => 25
		},
		GOTOS => {
			'OPEN' => 14,
			'PREP' => 41,
			'CANDIDATE' => 40,
			'DET' => 42
		}
	},
	{#State 28
		ACTIONS => {
			"\nCANDIDATE: " => 30,
			"\nDET: " => 43,
			"\nOPEN: " => 19,
			"\nPREP: " => 44
		}
	},
	{#State 29
		ACTIONS => {
			'error' => 46,
			'OPEN_TAG' => 10,
			'CANDIDATE_TAG' => 18
		},
		GOTOS => {
			'OPEN' => 14,
			'CANDIDATE' => 45
		}
	},
	{#State 30
		DEFAULT => -19
	},
	{#State 31
		DEFAULT => -14
	},
	{#State 32
		DEFAULT => -17
	},
	{#State 33
		DEFAULT => -18
	},
	{#State 34
		DEFAULT => -24
	},
	{#State 35
		ACTIONS => {
			"\nCLOSE: " => 47
		}
	},
	{#State 36
		DEFAULT => -27
	},
	{#State 37
		ACTIONS => {
			'DIRECTION_TAG' => 49,
			'error' => 50
		},
		GOTOS => {
			'direction' => 48
		}
	},
	{#State 38
		DEFAULT => -28
	},
	{#State 39
		ACTIONS => {
			"\npriority: " => 51
		}
	},
	{#State 40
		DEFAULT => -10
	},
	{#State 41
		ACTIONS => {
			'error' => 46,
			'OPEN_TAG' => 10,
			'CANDIDATE_TAG' => 18
		},
		GOTOS => {
			'OPEN' => 14,
			'CANDIDATE' => 52
		}
	},
	{#State 42
		ACTIONS => {
			'error' => 46,
			'OPEN_TAG' => 10,
			'CANDIDATE_TAG' => 18
		},
		GOTOS => {
			'OPEN' => 14,
			'CANDIDATE' => 53
		}
	},
	{#State 43
		DEFAULT => -23
	},
	{#State 44
		DEFAULT => -21
	},
	{#State 45
		DEFAULT => -12
	},
	{#State 46
		ACTIONS => {
			"\nCANDIDATE: " => 30,
			"\nOPEN: " => 19
		}
	},
	{#State 47
		DEFAULT => -25
	},
	{#State 48
		DEFAULT => -7
	},
	{#State 49
		DEFAULT => -30
	},
	{#State 50
		ACTIONS => {
			"\ndirection: " => 54
		}
	},
	{#State 51
		DEFAULT => -29
	},
	{#State 52
		DEFAULT => -11
	},
	{#State 53
		DEFAULT => -9
	},
	{#State 54
		DEFAULT => -31
	}
],
                                  yyrules  =>
[
	[#Rule 0
		 '$start', 2, undef
	],
	[#Rule 1
		 'input', 0, undef
	],
	[#Rule 2
		 'input', 2,
sub
#line 34 "lib/Lingua/YaTeA/ParsingPatternParser.yp"
{ # print STDERR "INPUT $_[1] \n";
		      }
	],
	[#Rule 3
		 'line', 1,
sub
#line 38 "lib/Lingua/YaTeA/ParsingPatternParser.yp"
{ $_[1] }
	],
	[#Rule 4
		 'line', 2,
sub
#line 39 "lib/Lingua/YaTeA/ParsingPatternParser.yp"
{ 
# 	     print STDERR "=>$_[1]\n";

	     $pos_sequence = join(" ",@pos_sequence);
	     $parse = join(" ",@parse);
# 	     print STDERR "parse = $parse\n";
	     $node_set->setRoot; 
	     $pattern = Lingua::YaTeA::ParsingPattern->new($parse,$pos_sequence,$node_set,$priority,$direction,$num_content_words,$num_line);
	     
  	     $_[0]->YYData->{PPRS}->addPattern($pattern);
	     @pos_sequence = ();
	     @uncomplete = ();
	     @parse = ();
	     $level = 0;
  	     $_[0]->YYData->{PPRS}->checkContentWords($num_content_words,$num_line);

	     if ($num_content_words > $Lingua::YaTeA::ParsingPatternRecordSet::max_content_words)
	     {
		 $Lingua::YaTeA::ParsingPatternRecordSet::max_content_words = $num_content_words;
	     }
	     $num_content_words = 0;
	     $num_line++;
	 }
	],
	[#Rule 5
		 'line', 2,
sub
#line 62 "lib/Lingua/YaTeA/ParsingPatternParser.yp"
{ $_[0]->YYErrok }
	],
	[#Rule 6
		 '@1-0', 0,
sub
#line 65 "lib/Lingua/YaTeA/ParsingPatternParser.yp"
{ # print STDERR "START\n";

		  $node_set = Lingua::YaTeA::NodeSet->new;

                }
	],
	[#Rule 7
		 'parsingpattern', 6, undef
	],
	[#Rule 8
		 'parsingpattern', 2,
sub
#line 70 "lib/Lingua/YaTeA/ParsingPatternParser.yp"
{ $_[0]->YYErrok }
	],
	[#Rule 9
		 'pattern', 4, undef
	],
	[#Rule 10
		 'pattern', 3, undef
	],
	[#Rule 11
		 'pattern', 4, undef
	],
	[#Rule 12
		 'pattern', 3, undef
	],
	[#Rule 13
		 'pattern', 2, undef
	],
	[#Rule 14
		 'pattern', 2,
sub
#line 79 "lib/Lingua/YaTeA/ParsingPatternParser.yp"
{ $_[0]->YYErrok }
	],
	[#Rule 15
		 'OPEN', 1,
sub
#line 82 "lib/Lingua/YaTeA/ParsingPatternParser.yp"
{# print STDERR "OPEN $_[1]\n";

		if ($level == 0)
		{
		    $node = Lingua::YaTeA::RootNode->new($level);
		}
		else
		{
		    $node = Lingua::YaTeA::InternalNode->new($level);
		}
		$node_set->addNode($node);
		push @uncomplete, $node;
		$level++;
		push @parse, $_[1];
}
	],
	[#Rule 16
		 'OPEN', 2,
sub
#line 97 "lib/Lingua/YaTeA/ParsingPatternParser.yp"
{ $_[0]->YYErrok }
	],
	[#Rule 17
		 'CANDIDATE', 2,
sub
#line 100 "lib/Lingua/YaTeA/ParsingPatternParser.yp"
{
#                print STDERR "CANDIDATE $_[1] $_[2]\n";

	       $edge = Lingua::YaTeA::PatternLeaf->new($_[1],$node);
	       $node->addEdge($edge,$_[2]);
	       $num_content_words++;
	       push @pos_sequence,$_[1];  
	       push @parse, "$_[1]<=$_[2]>";

	   }
	],
	[#Rule 18
		 'CANDIDATE', 3, undef
	],
	[#Rule 19
		 'CANDIDATE', 2,
sub
#line 111 "lib/Lingua/YaTeA/ParsingPatternParser.yp"
{ $_[0]->YYErrok }
	],
	[#Rule 20
		 'PREP', 1,
sub
#line 114 "lib/Lingua/YaTeA/ParsingPatternParser.yp"
{# print STDERR "PREP $_[1]\n";
		$node->{"PREP"} = $_[1]; 
		push @pos_sequence, $_[1];
		push @parse, $_[1];
	    }
	],
	[#Rule 21
		 'PREP', 2,
sub
#line 119 "lib/Lingua/YaTeA/ParsingPatternParser.yp"
{ $_[0]->YYErrok }
	],
	[#Rule 22
		 'DET', 1,
sub
#line 123 "lib/Lingua/YaTeA/ParsingPatternParser.yp"
{# print STDERR "DET $_[1]\n";
	      $node->{"DET"} = $_[1]; 
	      push @pos_sequence, $_[1]; 
	      push @parse, $_[1];
	  }
	],
	[#Rule 23
		 'DET', 2,
sub
#line 128 "lib/Lingua/YaTeA/ParsingPatternParser.yp"
{ $_[0]->YYErrok }
	],
	[#Rule 24
		 'CLOSE', 1,
sub
#line 131 "lib/Lingua/YaTeA/ParsingPatternParser.yp"
{# print STDERR "CLOSE_TAG $_[1]\n";
		  pop @uncomplete;
		  $node->linkToFather(\@uncomplete,$_[1]);
		  $node = $uncomplete[$#uncomplete];
		  $level--;
		  push @parse, ')';
	      }
	],
	[#Rule 25
		 'CLOSE', 2,
sub
#line 138 "lib/Lingua/YaTeA/ParsingPatternParser.yp"
{ $_[0]->YYErrok }
	],
	[#Rule 26
		 'END', 1,
sub
#line 141 "lib/Lingua/YaTeA/ParsingPatternParser.yp"
{# print STDERR "END $_[1]\n"; 
	      push @parse, $_[1];
	      $_[1];
	  }
	],
	[#Rule 27
		 'END', 2,
sub
#line 145 "lib/Lingua/YaTeA/ParsingPatternParser.yp"
{ $_[0]->YYErrok }
	],
	[#Rule 28
		 'priority', 1,
sub
#line 147 "lib/Lingua/YaTeA/ParsingPatternParser.yp"
{# print STDERR "PRIORITY\n";
			$priority = $_[1];
		    }
	],
	[#Rule 29
		 'priority', 2,
sub
#line 150 "lib/Lingua/YaTeA/ParsingPatternParser.yp"
{ $_[0]->YYErrok }
	],
	[#Rule 30
		 'direction', 1,
sub
#line 153 "lib/Lingua/YaTeA/ParsingPatternParser.yp"
{# print STDERR "DIRECTION $_[1]\n";
			  $direction = $_[1];
		      }
	],
	[#Rule 31
		 'direction', 2,
sub
#line 156 "lib/Lingua/YaTeA/ParsingPatternParser.yp"
{ $_[0]->YYErrok }
	]
],
                                  @_);
    bless($self,$class);
}

#line 159 "lib/Lingua/YaTeA/ParsingPatternParser.yp"




sub _Error {
        exists $_[0]->YYData->{ERRMSG}
    and do {
        print $_[0]->YYData->{ERRMSG};
        delete $_[0]->YYData->{ERRMSG};
        return;
    };
    print "Syntax error.\n";
}

sub _Lexer {
    my($parser)=shift;

     my $fh = $parser->YYData->{FH};

    my $open = '(\()';
    my $det = $parser->YYData->{DETERMINERS};
    my $prep = $parser->YYData->{PREPOSITIONS};
    my $candidates = $parser->YYData->{CANDIDATES};
    my $positions = '<=(([MH])||(C[12]))>';
    my $close = '\)<=(([MH])||(C[12]))>';
    my $end = '(\))\t+';
    my $priority = '([0-9]+)\t+';
    my $direction = '((LEFT)|(RIGHT))';


        $parser->YYData->{INPUT}
     or  $parser->YYData->{INPUT} = <$fh>
    or  return('',undef);

    $parser->YYData->{INPUT}=~s/^[ \t]*#.*//;
    $parser->YYData->{INPUT}=~s/^[ \t]*//;



    for ($parser->YYData->{INPUT}) {
        s/^$open\s*// and return ('OPEN_TAG', $1);
	s/^$candidates\s*// and return('CANDIDATE_TAG', $1);
	s/^$prep// and return('PREP_TAG', $1);
	s/^$det// and return('DET_TAG', $1);
	s/^$positions\s*// and return('POSITION_TAG', $1);
	s/^$close// and return('CLOSE_TAG', $1);
	s/^$end// and return('END_TAG', $1);
	s/^$priority// and return('PRIORITY_TAG', $1);
	s/^$direction// and return('DIRECTION_TAG', $1);
        s/^(.)//s  and return($1,$1);
	
    }
}

# sub Run {
#     my($self)=shift;
#     $self->YYParse( yylex => \&_Lexer, yyerror => \&_Error );
# }

# my($parsingpattern)=new ParsingPatternParser;
# $parsingpattern->Run;


__END__

=head1 NAME

Lingua::YaTeA::ParsingPatternParser - Perl extension for parsing the file containing the parsing patterns (based on Parse::Yapp)

=head1 SYNOPSIS

  use Lingua::YaTeA::ParsingPatternParser;

  my $fh = FileHandle->new("<$file_path");

  my $parser = Lingua::YaTeA::ParsingPatternParser->new();

  $parser->YYData->{PPRS} = $this;
  $parser->YYData->{FH} = $fh;
  $parser->YYData->{CANDIDATES} = $tag_set->getTagList("CANDIDATES");
  $parser->YYData->{PREPOSITIONS} = $tag_set->getTagList("PREPOSITIONS");
  $parser->YYData->{DETERMINERS} = $tag_set->getTagList("DETERMINERS");

  $parser->YYParse(yylex => \&Lingua::YaTeA::ParsingPatternParser::_Lexer, yyerror => \&Lingua::YaTeA::ParsingPatternParser::_Error);

=head1 DESCRIPTION

The module implements a parser for analysing parsing pattern file.  

The parser takes into account several information: the file handler to
read (field C<FH>), the list of the possible Part-of-Speech tags
(field C<CANDIDATES>), the list of prepositions (field
C<PREPOSITIONS>), and the list of determiners (field C<DETERMINERS>).

=head1 METHODS

=head2 _Error()

    _Error($error_objet);

The method is used to manage the parsing error and prints a message
explaining the error.

=head2 _Lexer()

    _Lexer($parser_info);

The method applies the parser on the data contains in the structure
C<$parser_info> (field C<INPUT>).



=head1 SEE ALSO

Sophie Aubin and Thierry Hamon. Improving Term Extraction with
Terminological Resources. In Advances in Natural Language Processing
(5th International Conference on NLP, FinTAL 2006). pages
380-387. Tapio Salakoski, Filip Ginter, Sampo Pyysalo, Tapio Pahikkala
(Eds). August 2006. LNAI 4139.


=head1 AUTHOR

Thierry Hamon <thierry.hamon@univ-paris13.fr>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Thierry Hamon and Sophie Aubin

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;
