%{
package Lingua::Shakespeare;

$VERSION = "1.00";

use strict;
use Filter::Util::Call;

my ($yychar, $yyerrflag, $yynerrs, $yyn, @yyss, $yyssp, $yystate, @yyvs, $yyvsp);
my ($yylval, $yys, $yym, $yyval, %yystate, $yydebug, $yylineno, $output);

my ($num_errors, $num_warnings, @token, $current_act, $current_scene);

sub import {
  filter_add({});
  $yylineno = (caller)[2]+1;
  1;
}

sub unimport { filter_del() }

  my $preamble = <<'PREAMBLE';
require Lingua::Shakespeare::Play;
my ($comp1, $comp2);
my $play = Lingua::Shakespeare::Play->new;
$|=1;
PREAMBLE

sub varname {
  (my $name = lc shift) =~ tr/ /_/;
  '$' . $name;
}

sub set_line { "#line $yylineno\n" }

%}


%token <str> ARTICLE
%token <str> BE
%token <str> CHARACTER
%token <str> FIRST_PERSON
%token <str> FIRST_PERSON_POSSESSIVE
%token <str> FIRST_PERSON_REFLEXIVE
%token <str> NEGATIVE_ADJECTIVE
%token <str> NEGATIVE_COMPARATIVE
%token <str> NEGATIVE_NOUN
%token <str> NEUTRAL_ADJECTIVE
%token <str> NEUTRAL_NOUN
%token <str> NOTHING
%token <str> POSITIVE_ADJECTIVE
%token <str> POSITIVE_COMPARATIVE
%token <str> POSITIVE_NOUN
%token <str> SECOND_PERSON
%token <str> SECOND_PERSON_POSSESSIVE
%token <str> SECOND_PERSON_REFLEXIVE
%token <str> THIRD_PERSON_POSSESSIVE

%token <str> COLON
%token <str> COMMA
%token <str> EXCLAMATION_MARK
%token <str> LEFT_BRACKET
%token <str> PERIOD
%token <str> QUESTION_MARK
%token <str> RIGHT_BRACKET

%token <str> AND
%token <str> AS
%token <str> ENTER
%token <str> EXEUNT
%token <str> EXIT
%token <str> HEART
%token <str> IF_NOT
%token <str> IF_SO
%token <str> LESS
%token <str> LET_US
%token <str> LISTEN_TO
%token <str> MIND
%token <str> MORE
%token <str> NOT
%token <str> OPEN
%token <str> PROCEED_TO
%token <str> RECALL
%token <str> REMEMBER
%token <str> RETURN_TO
%token <str> SPEAK
%token <str> THAN
%token <str> THE_CUBE_OF
%token <str> THE_DIFFERENCE_BETWEEN
%token <str> THE_FACTORIAL_OF
%token <str> THE_PRODUCT_OF
%token <str> THE_QUOTIENT_BETWEEN
%token <str> THE_REMAINDER_OF_THE_QUOTIENT_BETWEEN
%token <str> THE_SQUARE_OF
%token <str> THE_SQUARE_ROOT_OF
%token <str> THE_SUM_OF
%token <str> TWICE
%token <str> WE_MUST
%token <str> WE_SHALL

%token <str> ACT_ROMAN
%token <str> SCENE_ROMAN
%token <str> ROMAN_NUMBER

%token <str> NONMATCH


%type <str>        Act
%type <str>        ActHeader
%type <str>        Adjective
%type <stringlist> BinaryOperator
%type <stringlist> CharacterDeclaration
%type <stringlist> CharacterDeclarationList
%type <stringlist> CharacterList
%type <str>        Comment
%type <str>        Comparative
%type <str>        Comparison
%type <str>        Conditional
%type <str>        Constant
%type <str>        EndSymbol
%type <str>        EnterExit
%type <str>        Equality
%type <str>        Inequality
%type <str>        InOut
%type <str>        Jump
%type <str>        JumpPhrase
%type <str>        JumpPhraseBeginning
%type <str>        JumpPhraseEnd
%type <str>        Line
%type <str>        NegativeComparative
%type <str>        NegativeConstant
%type <str>        NegativeNoun
%type <str>        NonnegatedComparison
%type <str>        OpenYour
%type <str>        Play
%type <str>        PositiveComparative
%type <str>        PositiveConstant
%type <str>        PositiveNoun
%type <str>        Pronoun
%type <str>        Question
%type <str>        QuestionSymbol
%type <str>        Recall
%type <str>        Remember
%type <str>        Scene
%type <str>        SceneContents
%type <str>        SceneHeader
%type <str>        Sentence
%type <str>        SentenceList
%type <str>        StartSymbol
%type <str>        Statement
%type <str>        StatementSymbol
%type <str>        String
%type <str>        StringSymbol
%type <str>        Title
%type <str>        UnarticulatedConstant
%type <stringlist> UnaryOperator
%type <str>        UnconditionalSentence
%type <str>        Value


%start StartSymbol

%%

StartSymbol: Play { $output = $1 unless $num_errors; }
	   ;

Act: ActHeader Scene { $$ = $1 . ";\n" . $2; }
   | Act Scene       { $$ = $1 . $2; }
   ;

ActHeader: ACT_ROMAN COLON Comment EndSymbol 
		{
		  ($current_act = uc $1) =~ tr/ /_/;
		  $$ = "\n\n$current_act:\t" . $3;
		}
	 | ACT_ROMAN COLON Comment error
		{
		  report_warning("period or exclamation mark");
		  ($current_act = uc $1) =~ tr/ /_/;
		  $$ = "\n\n$current_act:\t" . $3;
		}
	 | ACT_ROMAN error Comment EndSymbol
		{
		  report_warning("colon");
		  ($current_act = uc $1) =~ tr/ /_/;
		  $$ = "\n\n$current_act:\t" . $3;
		}
	 ;

Adjective: POSITIVE_ADJECTIVE { $$ = $1;}
         | NEUTRAL_ADJECTIVE { $$ = $1; }
         | NEGATIVE_ADJECTIVE { $$ = $1; }
	 ;

BinaryOperator: THE_DIFFERENCE_BETWEEN { $$ = "int_sub"; }
	      | THE_PRODUCT_OF { $$ = "int_mul" ; }
	      | THE_QUOTIENT_BETWEEN { $$ = "int_div"; }
	      | THE_REMAINDER_OF_THE_QUOTIENT_BETWEEN { $$ = "int_mod" ; }
	      | THE_SUM_OF { $$ = "int_add"; }
	      ;

CharacterDeclaration: CHARACTER COMMA Comment EndSymbol
			{
			  $$ = set_line()
			    . "my " . varname($1) . " = "
			    . "\$play->declare_character('" . $1 . "');\t"
			    . $3;
			}
		    | error COMMA Comment EndSymbol
			{ $$ = report_error("character name"); }
		    | CHARACTER error Comment EndSymbol
			{ $$ = report_error("comma"); }
		    ;

CharacterDeclarationList: CharacterDeclaration
				{ $$ = $1; }
			| CharacterDeclarationList CharacterDeclaration
				{ $$ = $1 . $2; }
			;

CharacterList: CHARACTER AND CHARACTER
		{ $$ = [ $1, $3]; }
	     | CHARACTER COMMA CharacterList
		{ push @{ $$ = $3 }, $1; }
	     ;

Comment: String    { $$ = "# " . $1 . "\n"; }
       | error     { report_warning("comment"); $$=""; }
       ;

Comparative: NegativeComparative { $$ = q{$comp1 < $comp2}; }
	   | PositiveComparative { $$ = q{$comp1 > $comp2}; }
	   ;

Comparison: NOT NonnegatedComparison { $$ = "!" . $2; }
	  | NonnegatedComparison { $$ = $1; }
	  ;

Conditional: IF_SO { $$ = q{$truth_flag}; }
	   | IF_NOT { $$ = q{not($truth_flag)}; }
	   ;

Constant: ARTICLE UnarticulatedConstant { $$ = $2; }
	| FIRST_PERSON_POSSESSIVE UnarticulatedConstant { $$ = $2; }
	| SECOND_PERSON_POSSESSIVE UnarticulatedConstant { $$ = $2; }
	| THIRD_PERSON_POSSESSIVE UnarticulatedConstant { $$ = $2; }
	| NOTHING { $$ = "0"; }
	;

EndSymbol: QuestionSymbol { $$ = $1; }
	 | StatementSymbol { $$ = $1; }
	 ;

EnterExit: LEFT_BRACKET ENTER CHARACTER RIGHT_BRACKET
		{
		  $$ = set_line() . '$play->enter_scene(' . varname($3) . ");\n";
		}
	 | LEFT_BRACKET ENTER CharacterList RIGHT_BRACKET
		{
		  $$ = "";
		  foreach my $character (@{ $3 }) {
		    $$ .= set_line() . '$play->enter_scene(' . varname($character) . ");\n";
		  }
		}
	 | LEFT_BRACKET EXIT CHARACTER RIGHT_BRACKET
		{
		  $$ = set_line() . '$play->exit_scene(' . varname($3) . ");\n";
		}
	 | LEFT_BRACKET EXEUNT CharacterList RIGHT_BRACKET
		{
		  $$ = "";
		  foreach my $character (@{ $3 }) {
		    $$ .= set_line() . '$play->exit_scene(' . varname($character) . ");\n";
		  }
		}
	 | LEFT_BRACKET EXEUNT RIGHT_BRACKET
		{
		  $$ = set_line() . "\$play->exit_scene_all;\n";
		}
	 | LEFT_BRACKET ENTER error RIGHT_BRACKET
		{
		  $$ = report_error("character or character list");
		}
	 | LEFT_BRACKET EXIT error RIGHT_BRACKET
		{
		  $$ = report_error("character");
		}
	 | LEFT_BRACKET EXEUNT error RIGHT_BRACKET
		{
		  $$ = report_error("character list or nothing");
		}
	 | LEFT_BRACKET error RIGHT_BRACKET
		{
		  $$ = report_error("'enter', 'exit' or 'exeunt'");
		}
	 ;

Equality: AS Adjective AS { $$ = q{$comp1 == $comp2}; }
	| AS error AS { $$ = report_error("adjective"); }
	| AS Adjective error { $$ = report_error("as"); }
	;

Inequality: Comparative THAN { $$ = $1; }
	  | Comparative error { report_warning("'than'"); $$ = $1; }
	  ;

InOut: OpenYour HEART StatementSymbol
	{ $$ = set_line() . "\$play->second_person->int_output;\n"; }
     | SPEAK SECOND_PERSON_POSSESSIVE MIND StatementSymbol
	{ $$ = set_line() . "\$play->second_person->char_output;\n"; }
     | LISTEN_TO SECOND_PERSON_POSSESSIVE HEART StatementSymbol
	{ $$ = set_line() . "\$play->second_person->int_input;\n"; }
     | OpenYour MIND StatementSymbol
	{ $$ = set_line() . "\$play->second_person->char_input;\n"; }
     | OpenYour error StatementSymbol
	{ $$ = report_error("'mind' or 'heart'"); }
     | SPEAK error MIND StatementSymbol
	{
	  report_warning("possessive pronoun, second person");
	  $$ = set_line() . "\$play->second_person->char_output;\n";
	}
     | LISTEN_TO error HEART StatementSymbol
	{
	  report_warning("possessive pronoun, second person");
	  $$ = set_line() . "\$play->second_person->int_input;\n";
	}
     | SPEAK SECOND_PERSON_POSSESSIVE error StatementSymbol
	{
	  report_warning("'mind'");
	  $$ = set_line() . "\$play->second_person->char_output;\n";
	}
     | LISTEN_TO SECOND_PERSON_POSSESSIVE error StatementSymbol
	{
	  report_warning("'heart'");
	  $$ = set_line() . "\$play->second_person->int_input;\n";
	} 
     | OpenYour HEART error
	{
	  report_warning("period or exclamation mark");
	  $$ = set_line() . "\$play->second_person->int_output;\n";
	}
     | SPEAK SECOND_PERSON_POSSESSIVE MIND error
	{
	  report_warning("period or exclamation mark");
	  $$ = set_line() . "\$play->second_person->char_output;\n";
	} 
     | LISTEN_TO SECOND_PERSON_POSSESSIVE HEART error
	{
	  report_warning("period or exclamation mark");
	  $$ = set_line() . "\$play->second_person->int_input;\n";
	}
     | OpenYour MIND error
	{
	  report_warning("period or exclamation mark");
	  $$ = set_line() . "\$play->second_person->char_input;\n";
	}
     ;

Jump: JumpPhrase ACT_ROMAN StatementSymbol
	{
	  ( my $label = uc $2) =~ tr/ /_/;
	  $$ = "goto $label;\n";
	}
    | JumpPhrase SCENE_ROMAN StatementSymbol
	{
	  ( my $label = uc "$current_act " . uc $2) =~ tr/ /_/;
	  $$ = "goto $label;\n";
	}
    | JumpPhrase error StatementSymbol
	{ $$ = report_error("'act [roman number]' or 'scene [roman number]'"); }
    ;

JumpPhrase: JumpPhraseBeginning JumpPhraseEnd { $$ = $1 . " " . $2; }
	  | error JumpPhraseEnd { $$ = report_warning("'let us', 'we must' or 'we shall'"); }
	  | JumpPhraseBeginning error { $$ = report_warning("'proceed to' or 'return to'"); }
	  ;

JumpPhraseBeginning: LET_US { $$ = $1; }
		   | WE_MUST { $$ = $1; }
		   | WE_SHALL { $$ = $1; }
		   ;

JumpPhraseEnd: PROCEED_TO { $$ = $1; }
	     | RETURN_TO { $$ = $1; }
	     ;

Line: CHARACTER COLON SentenceList
	{ $$ = set_line() . '$play->activate_character(' . varname($1) . ");\n" . $3; } 
    | CHARACTER COLON error
	{ $$ = report_error("sentence list"); }
    | CHARACTER error SentenceList
	{ $$ = report_error("colon"); }
    ;

NegativeComparative: NEGATIVE_COMPARATIVE { $$ = $1; }
		   | MORE NEGATIVE_ADJECTIVE { $$ = $1 . " " . $2; }
		   | LESS POSITIVE_ADJECTIVE { $$ = $1 . " " . $2; }
		   ;

NegativeConstant: NegativeNoun { $$ = "(-1)"; }
		| NEGATIVE_ADJECTIVE NegativeConstant { $$ = "2*" . $2; }
		| NEUTRAL_ADJECTIVE NegativeConstant { $$ = "2*" . $2; }
		;

NegativeNoun: NEGATIVE_NOUN { $$ = $1; }
	    ;

NonnegatedComparison: Equality { $$ = "(" . $1 . ")"; }
		    | Inequality { $$ = "(" . $1 . ")"; }
		    ;

OpenYour: OPEN SECOND_PERSON_POSSESSIVE { $$ = ""; }
	| OPEN error { $$ = report_warning("possessive pronoun, second person"); }
	;

Play: Title CharacterDeclarationList Act
	{ $$ = "# " . $1 . "\n" . $preamble . $2 . $3; }
    | Play Act
	{ $$ = $1 . $2; }
    | Title CharacterDeclarationList error
	{ $$ = report_error("act"); }
    | Title error Act
	{ $$ = report_error("character declaration list"); }
    | error CharacterDeclarationList Act
	{ report_warning("title"); $$ =  $preamble . $2 . $3; }
    ;

PositiveComparative: POSITIVE_COMPARATIVE { $$ = $1; }
		   | MORE POSITIVE_ADJECTIVE { $$ = $1 . " " . $2; }
		   | LESS NEGATIVE_ADJECTIVE { $$ = $1 . " " . $2; }
		   ;

PositiveConstant: PositiveNoun { $$ = "1"; }
		| POSITIVE_ADJECTIVE PositiveConstant { $$ = "2*" . $2; }
		| NEUTRAL_ADJECTIVE PositiveConstant { $$ = "2*" . $2; }
		;

PositiveNoun: NEUTRAL_NOUN { $$ = $1; }
	    | POSITIVE_NOUN { $$ = $1; }
	    ;

Pronoun: FIRST_PERSON { $$ = '$play->first_person'; }
       | FIRST_PERSON_REFLEXIVE { $$ = '$play->first_person'; }
       | SECOND_PERSON { $$ = '$play->second_person'; }
       | SECOND_PERSON_REFLEXIVE { $$ = '$play->second_person'; }
       ;

Question: BE Value Comparison Value QuestionSymbol
	    {
	      $$ = "\$comp1 = " . $2 . ";\n";
	      $$ .= "\$comp2 = " . $4 . ";\n";
	      $$ .= "\$truth_flag = " . $3 . ";\n";
	    }
	| BE error Comparison Value QuestionSymbol
	    {
	      $$ = report_error("value");
	    }
	| BE Value error Value QuestionSymbol
	    {
	      $$ = report_error("comparison");
	    }
	| BE Value Comparison error QuestionSymbol
	    {
	      $$ = report_error("value");
	    }
	;

QuestionSymbol: QUESTION_MARK
	      ;

Recall: RECALL String StatementSymbol
	{
	  $$ = "\$play->second_person->pop;\n";
	}
      | RECALL error StatementSymbol
	{
	  report_warning("string");
	  $$ = "\$play->second_person->pop;\n";
	}
      | RECALL String error
	{
	  report_warning("period or exclamation mark");
	  $$ = "\$play->second_person->pop;\n";
	}
      ;

Remember: REMEMBER Value StatementSymbol
	  {
	    $$ = '$play->second_person->push(' . $2 . ");\n";
	  }
	| REMEMBER error StatementSymbol
	  {
	    $$ = report_error("value");
	  }
	| REMEMBER Value error
	  {
	    report_warning("period or exclamation mark");
	    $$ = '$play->second_person->push(' . $2 . ");\n";
	  }
	;

Scene: SceneHeader SceneContents { $$ = $1 . $2; }
     ;

SceneContents: EnterExit { $$ = $1; }
	     | Line { $$ = $1; }
	     | SceneContents EnterExit { $$ = $1 . $2; }
	     | SceneContents Line { $$ = $1 . $2; }
	     ;

SceneHeader: SCENE_ROMAN COLON Comment EndSymbol
		{
		  ($current_scene = $current_act . "_" . uc $1) =~ tr/ /_/;
		  $$ = "\n$current_scene:\t" . $3 . "\n";
		}
	   | SCENE_ROMAN COLON Comment error
		{
		  report_warning("period or exclamation mark");
		  ($current_scene = $current_act . "_" . uc $1) =~ tr/ /_/;
		  $$ = "\n$current_scene:\t" . $3 . "\n";
		}
	   | SCENE_ROMAN error Comment EndSymbol
		{
		  report_warning("colon");
		  ($current_scene = $current_act . "_" . uc $1) =~ tr/ /_/;
		  $$ = "\n$current_scene:\t" . $3 . "\n";
		}
	   ;

Sentence: UnconditionalSentence
		{ $$ = $1; } 
	| Conditional COMMA UnconditionalSentence
		{ $$ = "if (" . $1 . ") {\n" . $3 . "}\n"; } 
	| Conditional error UnconditionalSentence
		{
		  report_warning("comma");
		  $$ = "if (" . $1 . ") {\n" . $3 . "}\n";
		}
	;

SentenceList: Sentence { $$ = $1; }
	    | SentenceList Sentence { $$ = $1 . $2; }
	    ;

Statement: SECOND_PERSON BE Constant StatementSymbol
	      {
		$$ = set_line() . '$play->second_person->assign(' . $3 . ");\n";
	      }
	 | SECOND_PERSON UnarticulatedConstant StatementSymbol
	      {
		$$ = set_line() . '$play->second_person->assign(' . $2 . ");\n";
	      }
	 | SECOND_PERSON BE Equality Value StatementSymbol
	      {
		$$ = set_line() . '$play->second_person->assign(' . $4 . ");\n";
	      }
	 | SECOND_PERSON BE Constant error
	      {
		report_warning("period or exclamation mark");
		$$ = set_line() . '$play->second_person->assign(' . $3 . ");\n";
	      }
	 | SECOND_PERSON BE error StatementSymbol
	      {
		$$ = report_error("constant");
	      }
	 | SECOND_PERSON error Constant StatementSymbol
	      {
		report_warning("be");
		$$ = set_line() . '$play->second_person->assign(' . $3 . ");\n";
	      }
	 | SECOND_PERSON UnarticulatedConstant error
	      {
		report_warning("period or exclamation mark");
		$$ = set_line() . '$play->second_person->assign(' . $2 . ");\n";
	      }
	 | SECOND_PERSON error StatementSymbol
	      {
		$$ = report_error("constant without article");
	      }
	 | SECOND_PERSON BE Equality Value error
	      {
		report_warning("period or exclamation mark");
		$$ = set_line() . '$play->second_person->assign(' . $4 . ");\n";
	      }
	 | SECOND_PERSON BE Equality error StatementSymbol
	      {
		$$ = report_error("value");
	      }
	 | SECOND_PERSON BE error Value StatementSymbol
	      {
		report_warning("equality");
		$$ = set_line() . '$play->second_person->assign(' . $4 . ");\n";
	      }
	 | SECOND_PERSON error Equality Value StatementSymbol
	      {
		report_warning("be");
		$$ = set_line() . '$play->second_person->assign(' . $4 . ");\n";
	      }
	 ;

StatementSymbol: EXCLAMATION_MARK
	       | PERIOD
	       ;

String: StringSymbol        { $$ = $1;      }
      | String StringSymbol { $$ = $1 . " " . $2; }
      ;

StringSymbol: ARTICLE                                { $$ = $1; }
            | BE                                     { $$ = $1; }
            | CHARACTER                              { $$ = $1; }
            | FIRST_PERSON                           { $$ = $1; }
            | FIRST_PERSON_POSSESSIVE                { $$ = $1; }
            | FIRST_PERSON_REFLEXIVE                 { $$ = $1; }
            | NEGATIVE_ADJECTIVE                     { $$ = $1; }
            | NEGATIVE_COMPARATIVE                   { $$ = $1; }
            | NEGATIVE_NOUN                          { $$ = $1; }
            | NEUTRAL_ADJECTIVE                      { $$ = $1; }
            | NEUTRAL_NOUN                           { $$ = $1; }
            | NOTHING                                { $$ = $1; }
            | POSITIVE_ADJECTIVE                     { $$ = $1; }
            | POSITIVE_COMPARATIVE                   { $$ = $1; }
            | POSITIVE_NOUN                          { $$ = $1; }
            | SECOND_PERSON                          { $$ = $1; }
            | SECOND_PERSON_POSSESSIVE               { $$ = $1; }
            | SECOND_PERSON_REFLEXIVE                { $$ = $1; }
            | THIRD_PERSON_POSSESSIVE                { $$ = $1; }

            | COMMA                                  { $$ = $1; }

            | AND                                    { $$ = $1; }
            | AS                                     { $$ = $1; }
            | ENTER                                  { $$ = $1; }
            | EXEUNT                                 { $$ = $1; }
            | EXIT                                   { $$ = $1; }
            | HEART                                  { $$ = $1; }
            | IF_NOT                                 { $$ = $1; }
            | IF_SO                                  { $$ = $1; }
            | LESS                                   { $$ = $1; }
            | LET_US                                 { $$ = $1; }
            | LISTEN_TO                              { $$ = $1; }
            | MIND                                   { $$ = $1; }
            | MORE                                   { $$ = $1; }
            | NOT                                    { $$ = $1; }
            | OPEN                                   { $$ = $1; }
            | PROCEED_TO                             { $$ = $1; }
            | RECALL                                 { $$ = $1; }
            | REMEMBER                               { $$ = $1; }
            | RETURN_TO                              { $$ = $1; }
            | SPEAK                                  { $$ = $1; }
            | THAN                                   { $$ = $1; }
            | THE_CUBE_OF                            { $$ = $1; }
            | THE_DIFFERENCE_BETWEEN                 { $$ = $1; }
            | THE_FACTORIAL_OF                       { $$ = $1; }
            | THE_PRODUCT_OF                         { $$ = $1; }
            | THE_QUOTIENT_BETWEEN                   { $$ = $1; }
            | THE_REMAINDER_OF_THE_QUOTIENT_BETWEEN  { $$ = $1; }
            | THE_SQUARE_OF                          { $$ = $1; }
            | THE_SQUARE_ROOT_OF                     { $$ = $1; }
            | THE_SUM_OF                             { $$ = $1; }
            | TWICE                                  { $$ = $1; }
            | WE_MUST                                { $$ = $1; }
            | WE_SHALL                               { $$ = $1; }

            | ACT_ROMAN                              { $$ = $1; }
            | SCENE_ROMAN                            { $$ = $1; }
            | ROMAN_NUMBER                           { $$ = $1; }

            | NONMATCH                               { $$ = $1; }
            ;

Title: String EndSymbol { $$ = $1; }
     ;

UnarticulatedConstant: PositiveConstant { $$ = $1; }
		     | NegativeConstant { $$ = $1; }
		     ;

UnaryOperator: THE_CUBE_OF { $$ = "int_cube"; }
	     | THE_FACTORIAL_OF { $$ = "int_factorial"; }
	     | THE_SQUARE_OF { $$ = "int_square"; }
	     | THE_SQUARE_ROOT_OF { $$ = "int_sqrt"; }
	     | TWICE { $$ = "int_twice"; }
	     ;

UnconditionalSentence: InOut { $$ = $1; }
		     | Jump { $$ = $1; }
		     | Question { $$ = $1; }
		     | Recall { $$ = $1; }
		     | Remember { $$ = $1; }
		     | Statement { $$ = $1; }
		     ;

Value: CHARACTER
	  {
	    $$ = varname($1) . '->value';
	  }
     | Constant
	  {
	    $$ = $1;
	  }
     | Pronoun
	  {
	    $$ = $1 . '->value';
	  }
     | BinaryOperator Value AND Value
	  {
	    $$ = '$play->' . $1 . "(" . $2 . "," . $4 . ")";
	  }
     | UnaryOperator Value
	  {
	    $$ = '$play->' . $1 . "(" . $2 . ")";
	  }
     | BinaryOperator Value AND error
	  {
	    $$ = report_error("value");
	  }
     | BinaryOperator Value error Value
	  {
	    report_warning("'and'");
	    $$ = '$play->' . $1 . "(" . $2 . "," . $4 . ")";
	  }
     | BinaryOperator error AND Value
	  {
	    $$ = report_error("value");
	  }
     | UnaryOperator error
	  {
	    $$ = report_error("value");
	  }
     ;

%%
__YYSTATES__

my %act_or_scene = ( act => $ACT_ROMAN, scene => $SCENE_ROMAN );


my %R2A = qw(
	I	1	IV	4	V	5	IX	9
	X	10	XL	40	L	50	XC	90
	C	100	CD	400	D	500	CM	900
	M	1000
);

sub roman {
  my $r = uc(shift);

  return unless length($r) and $r =~ /^M*(C[DM]|D?C{1,3}ID)?(X[LC]|L?X{1,3}|L)?(I[VX]|V?I{1,3}|V)?$/;
  my $n = 0;
  while($r =~ /\G(I[VX]?|X[LC]?|C[DM]|[VLMD])/g) {
    $n += $R2A{$1};
  }
  $n
}


my $type = 0;
my %word;
while(<DATA>) {
  chomp;
  if (s/^\$//) {
    no strict;
    $type = eval "const$_();";
  }
  else {
    my @words = split(/\s+/, lc $_);
    my $parent = \(\%word );
    foreach my $w (@words) {
      $$parent ||= {};
      $$parent = { '' => $$parent } if 'HASH' ne ref $$parent;
      $parent = \(${$parent}->{$w});
    }
   $$parent = $type;
  }
}


sub get_tokens {
  local $_ = "";
  while (filter_read() > 0) {
    ++$yylineno;
    push @token, /[-\w']+|[:,!\[.\?\]]/g and return 1; # '
  }
  return 0;
}

sub __yylex { my $n = _yylex(); warn "$n $yylval\n"; $n }

sub yylex {
  get_tokens() or return -1
    unless @token;
  $yylval = shift @token;
  my $type = $word{lc $yylval};

  if (defined $type) {
    return $type unless ref $type;
    my @word = ($yylval);
    my @type = ($type);
    while (1) {
      get_tokens() or last
	unless @token;
      my $next_type = $type->{lc $token[0]} or last;
      push @word, shift @token;
      $yylval = join(" ",@word), return $next_type unless ref $next_type;
      push @type, ($type = $next_type);
    }
    while ($type = pop @type) {
      if ($type = $type->{''}) {
	$yylval = join(" ",@word);
	return $type;
      }
      last if @word == 1;
    }
  }

  if ($yylval =~ /^(act|scene)$/i and (@token or get_tokens()) and roman($token[0])) {
    my $n = $act_or_scene{lc $yylval};
    $yylval .= " " . shift @token;
    return $n;
  }

  if (roman($yylval)) {
    return $ROMAN_NUMBER;
  }

  return $NONMATCH;
}

sub yyerror {
  $yyerrflag = 0;
}

sub report_error {
  my $expected_symbol = shift;
  warn sprintf("Error at line %d: %s expected\n", $yylineno, $expected_symbol);
  $num_errors++;
  "";
}

sub report_warning {
  my $expected_symbol = shift;
  warn sprintf("Warning at line %d: %s expected\n", $yylineno, $expected_symbol);
  $num_warnings++;
  "";
}


sub filter {
  $num_errors = $num_warnings = 0;
  @token = ();

  get_tokens() or return 0;

  yyparse();

  die("$num_errors errors and $num_warnings warnings found. No code output.\n")
    if $num_errors;

  warn("$num_warnings warnings found. Code may be defective.\n")
    if $num_warnings;

  $_ = $output;

  return 1;
}

1;

