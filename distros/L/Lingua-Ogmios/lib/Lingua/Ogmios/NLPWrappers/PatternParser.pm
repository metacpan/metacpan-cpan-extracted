####################################################################
#
#    This file was generated using Parse::Yapp version 1.05.
#
#        Don't edit this file, use source file instead.
#
#             ANY CHANGE MADE HERE WILL BE LOST !
#
####################################################################
package Lingua::Ogmios::NLPWrappers::PatternParser;
use vars qw ( @ISA );
use strict;

@ISA= qw ( Parse::Yapp::Driver );
use Parse::Yapp::Driver;

#line 12 "lib/Lingua/Ogmios/NLPWrappers/PatternParser.yp"

    use Data::Dumper;
    use warnings;

    my $node_set = [];
    my $node;
    my @node_stack;
    my @uncomplete;
    my @parse;

    my $action;


    my $num_content_words;
    my @pos_sequence;
    my $priority;

    my $distance;

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
			'REGEXP_SEQ' => -8,
			'' => 2,
			'SYNDEP_SEQ' => -5,
			'SEMTYPE_TAG' => -8,
			'TERMCONTENT_SEQ' => -8,
			"\n" => 5,
			'TERM_SEQ' => -8,
			'WORD_SEQ' => -8,
			'POSTAG_TAG' => -8,
			'OPEN_CHUNK' => -8,
			'DISTANCE_SEQ' => -8,
			'error' => 6
		},
		GOTOS => {
			'pattern' => 3,
			'@1-0' => 4,
			'line' => 7
		}
	},
	{#State 2
		DEFAULT => 0
	},
	{#State 3
		ACTIONS => {
			'REGEXP_SEQ' => 16,
			'SEMTYPE_TAG' => 18,
			'TERMCONTENT_SEQ' => 10,
			'TERM_SEQ' => 20,
			'WORD_SEQ' => 22,
			'POSTAG_TAG' => 12,
			'OPEN_CHUNK' => 13,
			'error' => 14,
			'DISTANCE_SEQ' => 15
		},
		GOTOS => {
			'POSTAG' => 9,
			'WORD' => 8,
			'CHUNK' => 17,
			'DISTANCE' => 11,
			'TERMCONTENT' => 19,
			'REGEXP' => 21,
			'TERM' => 23,
			'SEMTYPE' => 24
		}
	},
	{#State 4
		ACTIONS => {
			'SYNDEP_SEQ' => 25,
			'error' => 26
		},
		GOTOS => {
			'SYN_DEP' => 27
		}
	},
	{#State 5
		DEFAULT => -3
	},
	{#State 6
		ACTIONS => {
			"\npattern: " => 29,
			"\nline:" => 28
		}
	},
	{#State 7
		DEFAULT => -2
	},
	{#State 8
		DEFAULT => -15
	},
	{#State 9
		DEFAULT => -12
	},
	{#State 10
		DEFAULT => -31
	},
	{#State 11
		ACTIONS => {
			'error' => 30,
			'ACTION_SEQ' => 32
		},
		GOTOS => {
			'ACTION' => 31
		}
	},
	{#State 12
		DEFAULT => -23
	},
	{#State 13
		DEFAULT => -35,
		GOTOS => {
			'@2-1' => 33
		}
	},
	{#State 14
		ACTIONS => {
			"\nDISTANCE: " => 35,
			"\nTERM: " => 34,
			"\nREGEXP: " => 39,
			"\nSEMTYPE: " => 40,
			"\nCHUNK: " => 36,
			"\nTERM_CONTENT: " => 37,
			"\nWORD: " => 38,
			"\nPOSTAG: " => 41
		}
	},
	{#State 15
		DEFAULT => -19
	},
	{#State 16
		DEFAULT => -25
	},
	{#State 17
		DEFAULT => -10
	},
	{#State 18
		DEFAULT => -21
	},
	{#State 19
		DEFAULT => -14
	},
	{#State 20
		DEFAULT => -29
	},
	{#State 21
		DEFAULT => -11
	},
	{#State 22
		DEFAULT => -27
	},
	{#State 23
		DEFAULT => -13
	},
	{#State 24
		DEFAULT => -9
	},
	{#State 25
		DEFAULT => -33
	},
	{#State 26
		ACTIONS => {
			"\nSYNDEP: " => 42
		}
	},
	{#State 27
		ACTIONS => {
			'REGEXP_SEQ' => -38,
			'SEMTYPE_TAG' => -38,
			'TERMCONTENT_SEQ' => -38,
			'TERM_SEQ' => -38,
			'WORD_SEQ' => -38,
			'POSTAG_TAG' => -38,
			'error' => 43,
			'DISTANCE_SEQ' => -38
		},
		GOTOS => {
			'phrase' => 44
		}
	},
	{#State 28
		DEFAULT => -7
	},
	{#State 29
		DEFAULT => -16
	},
	{#State 30
		ACTIONS => {
			"\nACTION: " => 45
		}
	},
	{#State 31
		ACTIONS => {
			"\n" => 46
		}
	},
	{#State 32
		DEFAULT => -17
	},
	{#State 33
		ACTIONS => {
			'SYNDEP_SEQ' => 25,
			'error' => 26
		},
		GOTOS => {
			'SYN_DEP' => 47
		}
	},
	{#State 34
		DEFAULT => -30
	},
	{#State 35
		DEFAULT => -20
	},
	{#State 36
		DEFAULT => -37
	},
	{#State 37
		DEFAULT => -32
	},
	{#State 38
		DEFAULT => -28
	},
	{#State 39
		DEFAULT => -26
	},
	{#State 40
		DEFAULT => -22
	},
	{#State 41
		DEFAULT => -24
	},
	{#State 42
		DEFAULT => -34
	},
	{#State 43
		ACTIONS => {
			"\nphrase: " => 48
		}
	},
	{#State 44
		ACTIONS => {
			'REGEXP_SEQ' => 16,
			'SEMTYPE_TAG' => 18,
			'TERMCONTENT_SEQ' => 10,
			'TERM_SEQ' => 20,
			'WORD_SEQ' => 22,
			'POSTAG_TAG' => 12,
			'error' => 52,
			'DISTANCE_SEQ' => 15
		},
		GOTOS => {
			'REGEXP' => 54,
			'POSTAG' => 50,
			'WORD' => 49,
			'TERM' => 55,
			'DISTANCE' => 51,
			'SEMTYPE' => 56,
			'TERMCONTENT' => 53
		}
	},
	{#State 45
		DEFAULT => -18
	},
	{#State 46
		DEFAULT => -4
	},
	{#State 47
		ACTIONS => {
			'REGEXP_SEQ' => -38,
			'CLOSE_CHUNK' => -38,
			'SEMTYPE_TAG' => -38,
			'TERMCONTENT_SEQ' => -38,
			'TERM_SEQ' => -38,
			'WORD_SEQ' => -38,
			'POSTAG_TAG' => -38,
			'error' => 43
		},
		GOTOS => {
			'phrase' => 57
		}
	},
	{#State 48
		DEFAULT => -45
	},
	{#State 49
		DEFAULT => -44
	},
	{#State 50
		DEFAULT => -41
	},
	{#State 51
		ACTIONS => {
			'error' => 30,
			'ACTION_SEQ' => 32
		},
		GOTOS => {
			'ACTION' => 58
		}
	},
	{#State 52
		ACTIONS => {
			"\nTERM_CONTENT: " => 37,
			"\nWORD: " => 38,
			"\nDISTANCE: " => 35,
			"\nTERM: " => 34,
			"\nREGEXP: " => 39,
			"\nPOSTAG: " => 41,
			"\nSEMTYPE: " => 40
		}
	},
	{#State 53
		DEFAULT => -43
	},
	{#State 54
		DEFAULT => -39
	},
	{#State 55
		DEFAULT => -42
	},
	{#State 56
		DEFAULT => -40
	},
	{#State 57
		ACTIONS => {
			'REGEXP_SEQ' => 16,
			'CLOSE_CHUNK' => 60,
			'SEMTYPE_TAG' => 18,
			'TERMCONTENT_SEQ' => 10,
			'TERM_SEQ' => 20,
			'WORD_SEQ' => 22,
			'POSTAG_TAG' => 12,
			'error' => 59
		},
		GOTOS => {
			'REGEXP' => 54,
			'POSTAG' => 50,
			'WORD' => 49,
			'TERM' => 55,
			'SEMTYPE' => 56,
			'TERMCONTENT' => 53
		}
	},
	{#State 58
		ACTIONS => {
			"\n" => 61
		}
	},
	{#State 59
		ACTIONS => {
			"\nTERM_CONTENT: " => 37,
			"\nWORD: " => 38,
			"\nTERM: " => 34,
			"\nREGEXP: " => 39,
			"\nPOSTAG: " => 41,
			"\nSEMTYPE: " => 40
		}
	},
	{#State 60
		DEFAULT => -36
	},
	{#State 61
		DEFAULT => -6
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
#line 40 "lib/Lingua/Ogmios/NLPWrappers/PatternParser.yp"
{ # print STDERR "INPUT $_[2] \n";
         }
	],
	[#Rule 3
		 'line', 1,
sub
#line 44 "lib/Lingua/Ogmios/NLPWrappers/PatternParser.yp"
{ $_[1] }
	],
	[#Rule 4
		 'line', 4,
sub
#line 45 "lib/Lingua/Ogmios/NLPWrappers/PatternParser.yp"
{ 
#   	     print STDERR "=>$_[1] ($action)\n";
  	     $_[0]->YYData->{PPRS}->addSynPattern($node_set, $action, $distance);
	     @$node_set = ();
	 }
	],
	[#Rule 5
		 '@1-0', 0,
sub
#line 50 "lib/Lingua/Ogmios/NLPWrappers/PatternParser.yp"
{  #print STDERR "START\n"; 
	     $node = $node_set;
          }
	],
	[#Rule 6
		 'line', 6,
sub
#line 52 "lib/Lingua/Ogmios/NLPWrappers/PatternParser.yp"
{ 
	      push @$node, shift @$node;
#   	     print "++>$_[1] ($action)\n";
  	     $_[0]->YYData->{PPRS}->addSynPattern($node_set, $action, $distance);
	     @$node_set = ();
	 }
	],
	[#Rule 7
		 'line', 2,
sub
#line 58 "lib/Lingua/Ogmios/NLPWrappers/PatternParser.yp"
{ $_[0]->YYErrok }
	],
	[#Rule 8
		 'pattern', 0,
sub
#line 67 "lib/Lingua/Ogmios/NLPWrappers/PatternParser.yp"
{  #print STDERR "START\n"; 
	     $node = $node_set;
          }
	],
	[#Rule 9
		 'pattern', 2, undef
	],
	[#Rule 10
		 'pattern', 2, undef
	],
	[#Rule 11
		 'pattern', 2, undef
	],
	[#Rule 12
		 'pattern', 2, undef
	],
	[#Rule 13
		 'pattern', 2, undef
	],
	[#Rule 14
		 'pattern', 2, undef
	],
	[#Rule 15
		 'pattern', 2, undef
	],
	[#Rule 16
		 'pattern', 2,
sub
#line 77 "lib/Lingua/Ogmios/NLPWrappers/PatternParser.yp"
{ $_[0]->YYErrok }
	],
	[#Rule 17
		 'ACTION', 1,
sub
#line 80 "lib/Lingua/Ogmios/NLPWrappers/PatternParser.yp"
{
      $action = $_[1];
#        print STDERR "ACTION: $action\n";
      }
	],
	[#Rule 18
		 'ACTION', 2,
sub
#line 84 "lib/Lingua/Ogmios/NLPWrappers/PatternParser.yp"
{ $_[0]->YYErrok }
	],
	[#Rule 19
		 'DISTANCE', 1,
sub
#line 87 "lib/Lingua/Ogmios/NLPWrappers/PatternParser.yp"
{
      $distance = $_[1];
#        print STDERR "DISTANCE: $distance\n";
      }
	],
	[#Rule 20
		 'DISTANCE', 2,
sub
#line 91 "lib/Lingua/Ogmios/NLPWrappers/PatternParser.yp"
{ $_[0]->YYErrok }
	],
	[#Rule 21
		 'SEMTYPE', 1,
sub
#line 94 "lib/Lingua/Ogmios/NLPWrappers/PatternParser.yp"
{
                  # print STDERR "SEMTYPE $_[1]\n";
		push @$node, {'type' => 'semtype',
			      'semtype' => $_[1]};
	   }
	],
	[#Rule 22
		 'SEMTYPE', 2,
sub
#line 99 "lib/Lingua/Ogmios/NLPWrappers/PatternParser.yp"
{ $_[0]->YYErrok }
	],
	[#Rule 23
		 'POSTAG', 1,
sub
#line 102 "lib/Lingua/Ogmios/NLPWrappers/PatternParser.yp"
{
#                 print STDERR "POSTAG $_[1]\n";
		push @$node, {'type' => 'postag',
		    'postag' => $_[1]};
	   }
	],
	[#Rule 24
		 'POSTAG', 2,
sub
#line 107 "lib/Lingua/Ogmios/NLPWrappers/PatternParser.yp"
{ $_[0]->YYErrok }
	],
	[#Rule 25
		 'REGEXP', 1,
sub
#line 110 "lib/Lingua/Ogmios/NLPWrappers/PatternParser.yp"
{
#                 print STDERR "REGEXP $_[1]\n";
		push @$node, {'type' => 'word_re',
			      'word_re' => $_[1]};
	   }
	],
	[#Rule 26
		 'REGEXP', 2,
sub
#line 115 "lib/Lingua/Ogmios/NLPWrappers/PatternParser.yp"
{ $_[0]->YYErrok }
	],
	[#Rule 27
		 'WORD', 1,
sub
#line 118 "lib/Lingua/Ogmios/NLPWrappers/PatternParser.yp"
{
#                 print STDERR "WORD $_[1]\n";
		push @$node, {'type' => 'word',
			      'word' => $_[1]};
	   }
	],
	[#Rule 28
		 'WORD', 2,
sub
#line 123 "lib/Lingua/Ogmios/NLPWrappers/PatternParser.yp"
{ $_[0]->YYErrok }
	],
	[#Rule 29
		 'TERM', 1,
sub
#line 126 "lib/Lingua/Ogmios/NLPWrappers/PatternParser.yp"
{
#                 print STDERR "TERM $_[1]\n";
		push @$node, {'type' => 'term',
			      'term' => $_[1]};
	   }
	],
	[#Rule 30
		 'TERM', 2,
sub
#line 131 "lib/Lingua/Ogmios/NLPWrappers/PatternParser.yp"
{ $_[0]->YYErrok }
	],
	[#Rule 31
		 'TERMCONTENT', 1,
sub
#line 134 "lib/Lingua/Ogmios/NLPWrappers/PatternParser.yp"
{
#                 print STDERR "TERMCONTENT $_[1]\n";
		push @$node, {'type' => 'termContent',
			      'termContent' => $_[1]};
	   }
	],
	[#Rule 32
		 'TERMCONTENT', 2,
sub
#line 139 "lib/Lingua/Ogmios/NLPWrappers/PatternParser.yp"
{ $_[0]->YYErrok }
	],
	[#Rule 33
		 'SYN_DEP', 1,
sub
#line 142 "lib/Lingua/Ogmios/NLPWrappers/PatternParser.yp"
{
#                 print STDERR "SYNDEP $_[1]\n";
		push @$node, {'type' => 'syndep',
			      'syndep' => $_[1]};
	   }
	],
	[#Rule 34
		 'SYN_DEP', 2,
sub
#line 147 "lib/Lingua/Ogmios/NLPWrappers/PatternParser.yp"
{ $_[0]->YYErrok }
	],
	[#Rule 35
		 '@2-1', 0,
sub
#line 152 "lib/Lingua/Ogmios/NLPWrappers/PatternParser.yp"
{ my $nodetmp = [];
		    push @node_stack, $node;
		    push @$node, {'type' => 'chunk',
				  'chunk' => $nodetmp };
		    $node = $nodetmp;
                  }
	],
	[#Rule 36
		 'CHUNK', 5,
sub
#line 157 "lib/Lingua/Ogmios/NLPWrappers/PatternParser.yp"
{
# 		      print STDERR "CHUNK $_[3]\n";
  		      push @$node, shift @$node;
		      $node = pop @node_stack;
	    }
	],
	[#Rule 37
		 'CHUNK', 2,
sub
#line 162 "lib/Lingua/Ogmios/NLPWrappers/PatternParser.yp"
{ $_[0]->YYErrok }
	],
	[#Rule 38
		 'phrase', 0,
sub
#line 166 "lib/Lingua/Ogmios/NLPWrappers/PatternParser.yp"
{# print STDERR "phrase\n";
}
	],
	[#Rule 39
		 'phrase', 2, undef
	],
	[#Rule 40
		 'phrase', 2, undef
	],
	[#Rule 41
		 'phrase', 2, undef
	],
	[#Rule 42
		 'phrase', 2, undef
	],
	[#Rule 43
		 'phrase', 2, undef
	],
	[#Rule 44
		 'phrase', 2, undef
	],
	[#Rule 45
		 'phrase', 2,
sub
#line 174 "lib/Lingua/Ogmios/NLPWrappers/PatternParser.yp"
{ $_[0]->YYErrok }
	]
],
                                  @_);
    bless($self,$class);
}

#line 177 "lib/Lingua/Ogmios/NLPWrappers/PatternParser.yp"




sub _Error {
        exists $_[0]->YYData->{ERRMSG}
    and do {
        print $_[0]->YYData->{ERRMSG};
        delete $_[0]->YYData->{ERRMSG};
        return;
    };
    print STDERR "Syntax error.\n";
    print "Syntax error.\n";
}

sub _Lexer {
    my($parser)=shift;

    my $fh = $parser->YYData->{FH};

    my $semtype = '(@semtype\(([^\)]+)\))';
    my $openchunk = '(\[)';
    my $closechunk = '(\])';
    my $syn_dep = '(@syndep\(([^\)]+)\))';
    my $postag = '(@postag\(([^\)]+)\))';
#     my $regexp = '(@re_begin(.*?)@re_end)';
    my $regexp = '(@word_re(\(.*?\))@)';
    my $termcontent = '(@term\(([^\)]+)\))';
    my $term = '(@term@)';
    my $word = '([^ \|\n\]]+)';
    my $action = '(\|\|\s*([^\n]+))';
    my $distance = '(\|\|\s*([0-9]+))';

    $parser->YYData->{INPUT}
    or  $parser->YYData->{INPUT} = <$fh>
    or  return('', undef); 

    $parser->YYData->{INPUT} =~ s/^[ \t]*#.*//;
    $parser->YYData->{INPUT} =~ s/^[ \t]*//;

#      warn "==>" .  $parser->YYData->{INPUT} . ";\n";
#     print "==>" .  $parser->YYData->{INPUT} . ";\n";

    for ($parser->YYData->{INPUT}) {
        s/^$semtype\s*// and return ('SEMTYPE_TAG', $2);
        s/^$openchunk\s*// and return ('OPEN_CHUNK', $1);
	s/^$closechunk// and return('CLOSE_CHUNK', $1);
	s/^$syn_dep// and return('SYNDEP_SEQ', $2);
	s/^$postag// and return('POSTAG_TAG', $2);
	s/^$regexp// and return('REGEXP_SEQ', $2);
	s/^$termcontent// and return('TERMCONTENT_SEQ', $2);
	s/^$term// and return('TERM_SEQ', $1);
	s/^$distance// and return('DISTANCE_SEQ', $2);
	s/^$action// and return('ACTION_SEQ', $2);
	s/^$word// and return('WORD_SEQ', $1);
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


=head1 METHODS


=head2 new()


=head2 _Lexer()


=head2 _Error()



=head1 SEE ALSO



=head1 AUTHOR

Thierry Hamon <thierry.hamon@limsi.fr>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Thierry Hamon

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;
