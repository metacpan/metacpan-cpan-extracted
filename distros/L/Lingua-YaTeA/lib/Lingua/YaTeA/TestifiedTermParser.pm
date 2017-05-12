####################################################################
#
#    This file was generated using Parse::Yapp version 1.05.
#
#        Don't edit this file, use source file instead.
#
#             ANY CHANGE MADE HERE WILL BE LOST !
#
####################################################################
package Lingua::YaTeA::TestifiedTermParser;
use vars qw ( @ISA );
use strict;

@ISA= qw ( Parse::Yapp::Driver );
use Parse::Yapp::Driver;

#line 12 "lib/Lingua/YaTeA/TestifiedTermParser.yp"

    use Lingua::YaTeA;
    use Data::Dumper;
    use warnings;
    use UNIVERSAL;
    use Scalar::Util qw(blessed);
    my @words;
    my $word;
    my $item;
    my @infos;
    my @IF;
    my @POS;
    my @LF;
    my $src;
    my @lex_items;
    my $testified;
    my $i;
    my $tree;
    my $node_set;
    my $node;
    my $edge;
    my $index = 0;
    my @uncomplete;
    my $level = 0;
    my $num_line =1;


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
			'OPEN_TAG' => -5
		},
		GOTOS => {
			'@1-0' => 3,
			'testified' => 4,
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
		DEFAULT => -4
	},
	{#State 5
		DEFAULT => -3
	},
	{#State 6
		ACTIONS => {
			"\nTESTIFIED: " => 11
		}
	},
	{#State 7
		DEFAULT => -2
	},
	{#State 8
		ACTIONS => {
			'END_TAG' => -14,
			'WORD' => 13,
			'error' => 15,
			'OPEN_TAG' => 10
		},
		GOTOS => {
			'OPEN' => 12,
			'CANDIDATE' => 14,
			'parsing' => 16
		}
	},
	{#State 9
		ACTIONS => {
			"\nOPEN: " => 17
		}
	},
	{#State 10
		DEFAULT => -21
	},
	{#State 11
		DEFAULT => -7
	},
	{#State 12
		ACTIONS => {
			'END_TAG' => -14,
			'WORD' => 13,
			'error' => 15,
			'OPEN_TAG' => 10
		},
		GOTOS => {
			'OPEN' => 12,
			'CANDIDATE' => 14,
			'parsing' => 18
		}
	},
	{#State 13
		ACTIONS => {
			'C_STATUS' => 19
		}
	},
	{#State 14
		ACTIONS => {
			'WORD' => 20,
			'error' => 23,
			'OPEN_TAG' => 10
		},
		GOTOS => {
			'OPEN' => 12,
			'PREP' => 21,
			'CANDIDATE' => 22,
			'DET' => 24
		}
	},
	{#State 15
		ACTIONS => {
			"\nPARSING: " => 26,
			"\nCANDIDATE: " => 25,
			"\nOPEN: " => 17
		}
	},
	{#State 16
		ACTIONS => {
			'END_TAG' => 27,
			'error' => 28
		},
		GOTOS => {
			'END' => 29
		}
	},
	{#State 17
		DEFAULT => -22
	},
	{#State 18
		ACTIONS => {
			'END_TAG' => 30,
			'error' => 31
		},
		GOTOS => {
			'CLOSE' => 32
		}
	},
	{#State 19
		DEFAULT => -18
	},
	{#State 20
		ACTIONS => {
			'P_STATUS' => 33,
			'C_STATUS' => 19,
			'D_STATUS' => 34
		}
	},
	{#State 21
		ACTIONS => {
			'WORD' => 20,
			'error' => 23,
			'OPEN_TAG' => 10
		},
		GOTOS => {
			'OPEN' => 12,
			'PREP' => 35,
			'CANDIDATE' => 36,
			'DET' => 37
		}
	},
	{#State 22
		DEFAULT => -13
	},
	{#State 23
		ACTIONS => {
			"\nCANDIDATE: " => 25,
			"\nOPEN: " => 17
		}
	},
	{#State 24
		ACTIONS => {
			'WORD' => 13,
			'error' => 23,
			'OPEN_TAG' => 10
		},
		GOTOS => {
			'OPEN' => 12,
			'CANDIDATE' => 38
		}
	},
	{#State 25
		DEFAULT => -20
	},
	{#State 26
		DEFAULT => -15
	},
	{#State 27
		DEFAULT => -23
	},
	{#State 28
		ACTIONS => {
			"\nEND: " => 39
		}
	},
	{#State 29
		ACTIONS => {
			'INFOS' => 41
		},
		GOTOS => {
			'infos' => 40
		}
	},
	{#State 30
		ACTIONS => {
			'C_STATUS' => 42
		}
	},
	{#State 31
		ACTIONS => {
			"\nCLOSE: " => 43
		}
	},
	{#State 32
		DEFAULT => -19
	},
	{#State 33
		DEFAULT => -16
	},
	{#State 34
		DEFAULT => -17
	},
	{#State 35
		ACTIONS => {
			'WORD' => 13,
			'error' => 23,
			'OPEN_TAG' => 10
		},
		GOTOS => {
			'OPEN' => 12,
			'CANDIDATE' => 44
		}
	},
	{#State 36
		DEFAULT => -10
	},
	{#State 37
		ACTIONS => {
			'WORD' => 13,
			'error' => 23,
			'OPEN_TAG' => 10
		},
		GOTOS => {
			'OPEN' => 12,
			'CANDIDATE' => 45
		}
	},
	{#State 38
		DEFAULT => -12
	},
	{#State 39
		DEFAULT => -24
	},
	{#State 40
		DEFAULT => -6
	},
	{#State 41
		DEFAULT => -8
	},
	{#State 42
		DEFAULT => -25
	},
	{#State 43
		DEFAULT => -26
	},
	{#State 44
		DEFAULT => -11
	},
	{#State 45
		DEFAULT => -9
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
#line 40 "lib/Lingua/YaTeA/TestifiedTermParser.yp"
{  #print STDERR "\n INPUT  \n";
                      }
	],
	[#Rule 3
		 'line', 1,
sub
#line 44 "lib/Lingua/YaTeA/TestifiedTermParser.yp"
{ # print "VIDE: " . $_[1] 
          $num_line++; 
          }
	],
	[#Rule 4
		 'line', 1,
sub
#line 47 "lib/Lingua/YaTeA/TestifiedTermParser.yp"
{ 
	      $num_line++; 
	      @lex_items = ();
	      @words= ();
	      my $testified;
	      # print STDERR "=>$_[1]\n";
	      my $testified_infos;
	      if($_[0]->YYData->{TTS}->getTestifiedInfos(\$testified_infos,\@IF,\@POS,\@LF,$src,\@lex_items,$_[0]->YYData->{MATCH},$_[0]->YYData->{FILTERING_LEXICON},$_[0]->YYData->{TAGSET}) == 1) {
		  if(scalar @lex_items > 1) {  
		      $testified = Lingua::YaTeA::MultiWordTestifiedTerm->new($testified_infos->{"NUM_CONTENT_WORDS"},\@lex_items,$_[0]->YYData->{TAGSET},$src,$_[0]->YYData->{MATCH});
		  }
	      }               
	      if ((blessed($testified)) && ($testified->isa('Lingua::YaTeA::TestifiedTerm'))) {
		  #print STDERR "ajout tt: " . $testified->getIF . "\n";
		  $_[0]->YYData->{TTS}->addTestified($testified);
		  
		  if ((blessed($testified)) && ($testified->isa('Lingua::YaTeA::MultiWordTestifiedTerm'))) {               
		      $tree =  Lingua::YaTeA::Tree->new;
		      $tree->setNodeSet($node_set);
		      # $tree->print($testified_infos->{"WORDS"});
		      $tree->setIndexSet($testified->getIndexSet);
		      $tree->setHead;
		      $testified->addTree($tree);
		      $testified->setParsingMethod("USER");
		  }
	      }
	      # print "fin creation :" . $testified->getIF . "\n";               
	      $level = 0;
	      $index = 0;
          }
	],
	[#Rule 5
		 '@1-0', 0,
sub
#line 80 "lib/Lingua/YaTeA/TestifiedTermParser.yp"
{
                $node_set = Lingua::YaTeA::NodeSet->new;
           }
	],
	[#Rule 6
		 'testified', 5,
sub
#line 83 "lib/Lingua/YaTeA/TestifiedTermParser.yp"
{ #print "trouve testified2 $_[1]\n";
           }
	],
	[#Rule 7
		 'testified', 2,
sub
#line 85 "lib/Lingua/YaTeA/TestifiedTermParser.yp"
{ $_[0]->YYErrok }
	],
	[#Rule 8
		 'infos', 1,
sub
#line 88 "lib/Lingua/YaTeA/TestifiedTermParser.yp"
{
           # print "infos $_[1]\n";
           @infos = split /\t/, $_[1];
           @IF = split / /, $infos[0];
           @POS = split / /, $infos[1];
           @LF = split / /, $infos[2];
           $src = $infos[3];
       }
	],
	[#Rule 9
		 'parsing', 4, undef
	],
	[#Rule 10
		 'parsing', 3, undef
	],
	[#Rule 11
		 'parsing', 4, undef
	],
	[#Rule 12
		 'parsing', 3, undef
	],
	[#Rule 13
		 'parsing', 2,
sub
#line 104 "lib/Lingua/YaTeA/TestifiedTermParser.yp"
{ 
           # print STDERR "PARSING $_[1]\n"
           }
	],
	[#Rule 14
		 'parsing', 0, undef
	],
	[#Rule 15
		 'parsing', 2,
sub
#line 108 "lib/Lingua/YaTeA/TestifiedTermParser.yp"
{ $_[0]->YYErrok }
	],
	[#Rule 16
		 'PREP', 2,
sub
#line 112 "lib/Lingua/YaTeA/TestifiedTermParser.yp"
{ 
       # print STDERR "PREP $_[1] $_[2]\n";
         $node->{"PREP"} = Lingua::YaTeA::TermLeaf->new($index); 
         $index++;
      }
	],
	[#Rule 17
		 'DET', 2,
sub
#line 118 "lib/Lingua/YaTeA/TestifiedTermParser.yp"
{ 
       # print STDERR "DET $_[1] $_[2]\n";
       $node->{"DET"} = Lingua::YaTeA::TermLeaf->new($index);
       $index++;
}
	],
	[#Rule 18
		 'CANDIDATE', 2,
sub
#line 124 "lib/Lingua/YaTeA/TestifiedTermParser.yp"
{ 
           # print STDERR "CANDIDATE1 $_[1] $_[2]\n";
           $edge = Lingua::YaTeA::TermLeaf->new($index);
           $node->addEdge($edge,$_[2]);
           # print "ajout du edge :" ;
           # print Dumper($edge) . "\n";
           $index++;
           }
	],
	[#Rule 19
		 'CANDIDATE', 3,
sub
#line 132 "lib/Lingua/YaTeA/TestifiedTermParser.yp"
{ 
             #print STDERR "CANDIDATE2 $_[1]\n";
             }
	],
	[#Rule 20
		 'CANDIDATE', 2,
sub
#line 135 "lib/Lingua/YaTeA/TestifiedTermParser.yp"
{ $_[0]->YYErrok }
	],
	[#Rule 21
		 'OPEN', 1,
sub
#line 138 "lib/Lingua/YaTeA/TestifiedTermParser.yp"
{ 
               # print STDERR "OPEN $_[1]\n";
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
                }
	],
	[#Rule 22
		 'OPEN', 2,
sub
#line 152 "lib/Lingua/YaTeA/TestifiedTermParser.yp"
{ $_[0]->YYErrok }
	],
	[#Rule 23
		 'END', 1,
sub
#line 156 "lib/Lingua/YaTeA/TestifiedTermParser.yp"
{ 
             # print STDERR "END $_[1]\n"; 
             }
	],
	[#Rule 24
		 'END', 2,
sub
#line 159 "lib/Lingua/YaTeA/TestifiedTermParser.yp"
{ $_[0]->YYErrok }
	],
	[#Rule 25
		 'CLOSE', 2,
sub
#line 162 "lib/Lingua/YaTeA/TestifiedTermParser.yp"
{ 
       # print STDERR "CLOSE_TAG $_[1] $_[2]\n";
                pop @uncomplete;
         $node->linkToFather(\@uncomplete,$_[2]);
         $node = $uncomplete[$#uncomplete];
         $level--;        
        }
	],
	[#Rule 26
		 'CLOSE', 2,
sub
#line 169 "lib/Lingua/YaTeA/TestifiedTermParser.yp"
{ $_[0]->YYErrok }
	]
],
                                  @_);
    bless($self,$class);
}

#line 173 "lib/Lingua/YaTeA/TestifiedTermParser.yp"


sub _Error {
        exists $_[0]->YYData->{ERRMSG}
    and do {
        print $_[0]->YYData->{ERRMSG};
        delete $_[0]->YYData->{ERRMSG};
        return;
    };
    print  "EXPECT: ";
    print $_[0]->YYExpect . "\n";
    print  "CURTOK: ";
    print "-" . $_[0]->YYCurtok . "-\n";
    print  "CURVAL: ";
    print $_[0]->YYCurval . "\n";
    print  "Lexer: ";
    print Dumper($_[0]->YYLexer) . "\n";
   print "Syntax error.\n";
}

sub _Lexer {
    my($parser)=shift;
    my $fh = $parser->YYData->{FH};

   
    my $open = '(\()';   
    my $word = $parser->YYData->{WORD};;
    my $close = '(\)<=[MH]>)';
    my $end = '(\))';
    my $d_status = '<=(D)>';
    my $p_status = '<=(P)>';
    my $c_status = '<=([MH])>';
    my $infos = '\t(.+)';
            

     $parser->YYData->{INPUT}
     or  $parser->YYData->{INPUT} = <$fh>
    or  return('',undef);

     $parser->YYData->{INPUT}=~s/^[ \t]*#.*//;
 

    for ($parser->YYData->{INPUT}) {
        #print "TEST-" .$parser->YYData->{INPUT}. "-\n";
        s/^$open\s*// and return ('OPEN_TAG', $1);
        s/^$end// and return('END_TAG', $1);
        s/^$word\s*// and return ('WORD', $1);
        s/^$c_status\s*// and return ('C_STATUS', $1);
        s/^$d_status\s*// and return ('D_STATUS', $1);
        s/^$p_status\s*// and return ('P_STATUS', $1);
        s/^$close\s*// and return('CLOSE_TAG', $1);        
        s/^$infos\s*// and return('INFOS', $1, $2);
        s/^.+//s  and return($1,$1);
        }
}

=head1 NAME

Lingua::YaTeA::TestifiedTermParser - Perl extension for the parser of testified term file (based on Parse::Yapp)

=head1 SYNOPSIS

  use Lingua::YaTeA::TestifiedTermParser;

  my $fh = FileHandle->new("<$file_path");

  my $parser = Lingua::YaTeA::TestifiedTermParser->new();

  $parser->YYData->{TTS} = $this;
  $parser->YYData->{WORD} = $word_characters_regexp;
  $parser->YYData->{TAGSET} = $tag_set;
  $parser->YYData->{MATCH} = $match_type;
  $parser->YYData->{FH} = $fh;
  $parser->YYData->{FILTERING_LEXICON} = $filtering_lexicon_h;

  $parser->YYParse(yylex => \&Lingua::YaTeA::ParsingPatternParser::_Lexer, yyerror => \&Lingua::YaTeA::ParsingPatternParser::_Error);


=head1 DESCRIPTION

The module implements a parser for analysing testified term file.  

The parser takes into account several information: the word character
list (field C<WORD>) i.e. all the possible characters in a word, the
Part-of-Speech tagset (field C<TAGSET>), the type of matching (field
C<MATCH>), the file handler to read (field C<FH>), and the lexicon of
the corpus (field C<FILTERING_LEXICON>).

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

Thierry Hamon <thierry.hamon@univ-paris13.fr> and Sophie Aubin <sophie.aubin@lipn.univ-paris13.fr>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Thierry Hamon and Sophie Aubin

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;
