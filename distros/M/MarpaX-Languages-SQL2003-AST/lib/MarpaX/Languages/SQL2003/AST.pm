use strict;
use warnings FATAL => 'all';

package MarpaX::Languages::SQL2003::AST;
use MarpaX::Languages::SQL2003::AST::Actions;
use Carp qw/croak/;

# ABSTRACT: Translate SQL-2003 source to an AST

use Marpa::R2 2.100000;

our $VERSION = '0.005'; # VERSION

our $DATA = do {local $/; <DATA>};
our @HOSTS = qw/C Ada Cobol Fortran Mumps Pascal PLI/;
our %HOST2G = map {$_ => $_} @HOSTS;
# Exception: PLI
$HOST2G{PLI} = 'Pl_I';
our %HOST_IDENTIFIER_DEFAULT_PRIORITY = ();
our $DATA_DEFAULT = $DATA;
foreach (0..$#HOSTS) {
  $HOST_IDENTIFIER_DEFAULT_PRIORITY{$HOSTS[$_]} = -$_;
  $DATA_DEFAULT .= "\n:lexeme ~ <$HOST2G{$HOSTS[$_]}_Host_Identifier> priority => $HOST_IDENTIFIER_DEFAULT_PRIORITY{$HOSTS[$_]}\n";
}
our %G = ($HOSTS[0] => Marpa::R2::Scanless::G->new({source => \$DATA_DEFAULT}));


# ----------------------------------------------------------------------------------------

sub new {
  my ($class, %opts) = @_;

  my $host = (exists($opts{host}) && defined($opts{host})) ? $opts{host} : '';
  if (! grep {$host eq $_} @HOSTS) {
    $host = $HOSTS[0];
  }

  if (! defined($G{$host})) {
    our %HOST_IDENTIFIER_PRIORITY = ();
    foreach (keys %HOST_IDENTIFIER_DEFAULT_PRIORITY) {
      $HOST_IDENTIFIER_PRIORITY{$_} = $HOST_IDENTIFIER_DEFAULT_PRIORITY{$_};
    }
    my $data = $DATA;
    foreach (0..$#HOSTS) {
      $HOST_IDENTIFIER_PRIORITY{$HOSTS[$_]} = ($HOSTS[$_] eq $host) ? 1 : -$_;
      $data .= "\n:lexeme ~ <$HOST2G{$HOSTS[$_]}_Host_Identifier> priority => $HOST_IDENTIFIER_PRIORITY{$HOSTS[$_]}\n";
    }
    $G{$host} = Marpa::R2::Scanless::G->new({source => \$data});
  }

  my $self  = {G => $G{$host}};

  #
  # This "hiden" variable is used by the test suite only
  #
  if (defined($MarpaX::Languages::SQL2003::AST::start)) {
    my $data = $DATA;
    my $q = quotemeta(':start ::= <SQL_Start_Sequence>');
    $data =~ s/$q/$MarpaX::Languages::SQL2003::AST::start/sxmg;
    $self->{G} = Marpa::R2::Scanless::G->new({source => \$data});
  }

  bless($self, $class);

  return $self;
}

# ----------------------------------------------------------------------------------------


sub Marpa::R2::Scanless::G::_parse_debug {
  my ( $slg, $input_ref, $arg1, @more_args ) = @_;
  if ( not defined $input_ref or ref $input_ref ne 'SCALAR' ) {
    Marpa::R2::exception(
                         q{$slr->parse(): first argument must be a ref to string});
  }
  my @recce_args = ( { grammar => $slg } );
  my @semantics_package_arg = ();
 DO_ARG1: {
    last if not defined $arg1;
    my $reftype = ref $arg1;
    if ( $reftype eq 'HASH' ) {
      # if second arg is ref to hash, it is the first set
      # of named args for
      # the recognizer
      push @recce_args, $arg1;
      last DO_ARG1;
    } ## end if ( $reftype eq 'HASH' )
    if ( $reftype eq q{} ) {

      # if second arg is a string, it is the semantic package
      push @semantics_package_arg, { semantics_package => $arg1 };
    }
    if ( ref $arg1 and ref $input_ref ne 'HASH' ) {
      Marpa::R2::exception(
                           q{$slr->parse(): second argument must be a package name or a ref to HASH}
                          );
    }
  } ## end DO_ARG1:
  if ( grep { ref $_ ne 'HASH' } @more_args ) {
    Marpa::R2::exception(
                         q{$slr->parse(): third and later arguments must be ref to HASH});
  }
  my $slr = Marpa::R2::Scanless::R->new( @recce_args, @more_args,
                                         @semantics_package_arg );
  my $input_length = ${$input_ref};
  my $length_read  = eval {$slr->read($input_ref)} || die "$@\n" . $slr->show_progress() . "\nTerminals expected: " . join(' ', @{$slr->terminals_expected}) . "\n";
  if ( $length_read != length $input_length ) {
    die 'read in $slr->parse() ended prematurely', "\n",
      "  The input length is $input_length\n",
        "  The length read is $length_read\n",
          "  The cause may be an event\n",
            "  The $slr->parse() method does not allow parses to trigger events";
  } ## end if ( $length_read != length $input_length )

  my @value_ref = ();
  while (defined(my $value_ref = $slr->value())) {
    push(@value_ref, $value_ref);
  }
  Marpa::R2::exception(
                       '$slr->parse() read the input, but there was no parse', "\n", "Context is: ", $slr->show_progress(), "\n", "Terminals expected: ",  join(' ', @{$slr->terminals_expected}))
      if not @value_ref;

  if (scalar(@value_ref) > 1) {
    my $croak = "AMBIGUITY:\n";
    foreach (@value_ref) {
      $croak .= "\n" . ${$_}->toString(1) . "\n";
    }
    croak $croak;
  }

  return $value_ref[0];
} ## end sub Marpa::R2::Scanless::G::parse

# ----------------------------------------------------------------------------------------

sub _parse {
  my $self = shift;

  return $ENV{TEST_DEBUG} ? $self->{G}->_parse_debug(@_) : $self->{G}->parse(@_);
}

# ----------------------------------------------------------------------------------------

sub parse {
  my ($self, $input, %opts) = @_;

  my $xml = (exists($opts{xml}) && $opts{xml}) ? 1 : 0;

  my $basenameSemanticsPackage = $xml ? 'XML' : 'Blessed';
  my %otherOpts = map {$_ => $opts{$_}} grep {$_ ne 'xml'} keys %opts;

  my $value = $self->_parse(\$input,
                            join('::',__PACKAGE__, 'Actions', $basenameSemanticsPackage),
                            {%otherOpts,
                             ranking_method => 'high_rule_only'});

  return defined($value) ? ${$value} : undef;
}

# ----------------------------------------------------------------------------------------


sub asXML {
  my ($self, $input, %opts) = @_;

  return $self->parse($input, xml => 1, %opts);
}

# ----------------------------------------------------------------------------------------


sub asBlessed {
  my ($self, $input, %opts) = @_;

  return $self->parse($input, xml => 0, %opts);
}


1;

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Languages::SQL2003::AST - Translate SQL-2003 source to an AST

=head1 VERSION

version 0.005

=head1 SYNOPSIS

    use strict;
    use warnings FATAL => 'all';
    use MarpaX::Languages::SQL2003::AST;
    #
    # Parse SQL
    #
    my $input = 'select * from myTable;';
    my $obj = MarpaX::Languages::SQL2003::AST->new(host => 'C');
    my $ast = $obj->parse($input);
    my $xml = $obj->parse($input, xml => 1);

=head1 DESCRIPTION

This module translates SQL-2003 to an AST.

=head1 SUBROUTINES/METHODS

=head2 new($class, %opts)

Instantiate a new object. %opts supported keys are:

=over

=item host

Target host language. Supported values are: Ada, C, Cobol, Fortran, Mumps, Pascal, PLI. Default value C.

=back

=head2 parse($self, $input, %opts)

Parse $input and return $self. Accept an optional %opts hash whose keys can be:

=over

=item xml

If $opts{xml} is a true value, produces the AST as an XML::LibXML::Document object. Default is a false value, meaning that the AST is a composite structure of blessed hash references and array references.

=back

Any other key will be passed as-is to the Marpa's parse() method, i.e. it has to have a meaning to Marpa's recognizer. Typical examples are: trace_terminals => 1, trace_values => 1.

=head2 asXML($self, $input, %opts)

Alias to $self->parse($input, xml => 1, %opts).

Please refer to L<MarpaX::Languages::SQL2003::AST::Actions> for the semantic actions.

=head2 asBlessed($self, $input, %opts)

Alias to $self->parse($input, xml => 0, %opts).

Please refer to L<MarpaX::Languages::SQL2003::AST::Actions> for the semantic actions.

=head1 NOTES

This module is using a generated Marpa::R2's BNF grammar, based on a manipulation of L<http://savage.net.au/SQL/sql-2003-2.bnf>, the later being in EBNF format. That is, some rules or lexemes in the output may appear as Genxxx or GenLexyyy, showing unfortunately some of the internals of the EBNF to BNF transformation.

=head1 SEE ALSO

L<MarpaX::Languages::SQL2003::AST::Actions>, L<Marpa::R2>

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://rt.cpan.org/Public/Dist/Display.html?Name=MarpaX-Languages-SQL2003-AST>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/jddurand/marpax-languages-sql2003-ast>

  git clone git://github.com/jddurand/marpax-languages-sql2003-ast.git

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
#
# This is a generated grammar
#
inaccessible is ok by default
:default ::= action => _nonTerminalSemantic
lexeme default = action => [start,length,value,value] latm => 1

:start ::= <SQL_Start_Sequence>
<SQL_Start_Many> ::= <SQL_Start>+ rank => 0
<SQL_Start_Sequence> ::= <SQL_Start_Many> rank => 0
<SQL_Start> ::= <Preparable_Statement> rank => 0
              | <Direct_SQL_Statement> rank => -1
              | <Embedded_SQL_Declare_Section> rank => -2
              | <Embedded_SQL_Statement> rank => -3
              | <SQL_Client_Module_Definition> rank => -4
<SQL_Terminal_Character> ::= <SQL_Language_Character> rank => 0
<SQL_Language_Character_L0> ~ <Simple_Latin_Letter_L0>
                              | <Digit_L0>
                              | <SQL_Special_Character_L0>
<SQL_Language_Character> ~ <SQL_Language_Character_L0>
<Simple_Latin_Letter_L0> ~ <Simple_Latin_Upper_Case_Letter_L0>
                           | <Simple_Latin_Lower_Case_Letter_L0>
<Simple_Latin_Upper_Case_Letter_L0> ~ <Lex001>
<Simple_Latin_Lower_Case_Letter_L0> ~ <Lex002>
<Digit_L0> ~ <Lex003>
<Digit> ~ <Digit_L0>
<SQL_Special_Character_L0> ~ <Space_L0>
                             | <Double_Quote_L0>
                             | <Percent_L0>
                             | <Ampersand_L0>
                             | <Quote_L0>
                             | <Left_Paren_L0>
                             | <Right_Paren_L0>
                             | <Asterisk_L0>
                             | <Plus_Sign_L0>
                             | <Comma_L0>
                             | <Minus_Sign_L0>
                             | <Period_L0>
                             | <Solidus_L0>
                             | <Colon_L0>
                             | <Semicolon_L0>
                             | <Less_Than_Operator_L0>
                             | <Equals_Operator_L0>
                             | <Greater_Than_Operator_L0>
                             | <Question_Mark_L0>
                             | <Left_Bracket_L0>
                             | <Right_Bracket_L0>
                             | <Circumflex_L0>
                             | <Underscore_L0>
                             | <Vertical_Bar_L0>
                             | <Left_Brace_L0>
                             | <Right_Brace_L0>
<SQL_Special_Character> ~ <SQL_Special_Character_L0>
<Space_L0> ~ <Lex004>
<Double_Quote_L0> ~ <Lex005>
<Percent_L0> ~ <Lex006>
<Percent> ~ <Percent_L0>
<Ampersand_L0> ~ <Lex007>
<Ampersand> ~ <Ampersand_L0>
<Quote_L0> ~ <Lex008>
<Quote> ~ <Quote_L0>
<Left_Paren_L0> ~ <Lex009>
<Left_Paren> ~ <Left_Paren_L0>
<Right_Paren_L0> ~ <Lex010>
<Right_Paren> ~ <Right_Paren_L0>
<Asterisk_L0> ~ <Lex011>
<Asterisk> ~ <Asterisk_L0>
<Plus_Sign_L0> ~ <Lex012>
<Plus_Sign> ~ <Plus_Sign_L0>
<Comma_L0> ~ <Lex013>
<Comma> ~ <Comma_L0>
<Minus_Sign_L0> ~ <Lex014>
<Minus_Sign> ~ <Minus_Sign_L0>
<Period_L0> ~ <Lex015>
<Period> ~ <Period_L0>
<Solidus_L0> ~ <Lex016>
<Solidus> ~ <Solidus_L0>
<Colon_L0> ~ <Lex017>
<Colon> ~ <Colon_L0>
<Semicolon_L0> ~ <Lex018>
<Semicolon> ~ <Semicolon_L0>
<Less_Than_Operator_L0> ~ <Lex019>
<Less_Than_Operator> ~ <Less_Than_Operator_L0>
<Equals_Operator_L0> ~ <Lex020>
<Equals_Operator> ~ <Equals_Operator_L0>
<Greater_Than_Operator_L0> ~ <Lex021>
<Greater_Than_Operator> ~ <Greater_Than_Operator_L0>
<Question_Mark_L0> ~ <Lex022>
<Question_Mark> ~ <Question_Mark_L0>
<Left_Bracket_Or_Trigraph> ::= <Left_Bracket> rank => 0
                             | <Left_Bracket_Trigraph> rank => -1
<Right_Bracket_Or_Trigraph> ::= <Right_Bracket> rank => 0
                              | <Right_Bracket_Trigraph> rank => -1
<Left_Bracket_L0> ~ <Lex023>
<Left_Bracket> ~ <Left_Bracket_L0>
<Left_Bracket_Trigraph_L0> ~ <Lex024>
<Left_Bracket_Trigraph> ~ <Left_Bracket_Trigraph_L0>
<Right_Bracket_L0> ~ <Lex025>
<Right_Bracket> ~ <Right_Bracket_L0>
<Right_Bracket_Trigraph_L0> ~ <Lex026>
<Right_Bracket_Trigraph> ~ <Right_Bracket_Trigraph_L0>
<Circumflex_L0> ~ <Lex027>
<Circumflex> ~ <Circumflex_L0>
<Underscore_L0> ~ <_>
<Underscore> ~ <Underscore_L0>
<Vertical_Bar_L0> ~ <Lex029>
<Vertical_Bar> ~ <Vertical_Bar_L0>
<Left_Brace_L0> ~ <Lex030>
<Left_Brace> ~ <Left_Brace_L0>
<Right_Brace_L0> ~ <Lex031>
<Right_Brace> ~ <Right_Brace_L0>
<Token> ::= <Nondelimiter_Token> rank => 0
          | <Delimiter_Token> rank => -1
<Nondelimiter_Token> ::= <Regular_Identifier> rank => 0
                       | <Key_Word> rank => -1
                       | <Unsigned_Numeric_Literal> rank => -2
                       | <National_Character_String_Literal> rank => -3
                       | <Large_Object_Length_Token> rank => -4
<Regular_Identifier_L0_Internal> ~ <SQL_Language_Identifier_L0_Internal>
<Regular_Identifier_L0> ~ <Regular_Identifier_L0_Internal>
<Regular_Identifier> ~ <Regular_Identifier_L0>
<Genlex115> ~ <Digit_L0>
<Genlex115_Many> ~ <Genlex115>+
<Large_Object_Length_Token> ~ <Genlex115_Many> <Multiplier_L0>
<Multiplier_L0> ~ <Lex032>
                  | <Lex033>
                  | <Lex034>
<Multiplier> ~ <Multiplier_L0>
<Delimited_Identifier_L0> ~ <Lex035> <Delimited_Identifier_Body_L0> <Lex036>
<Delimited_Identifier> ~ <Delimited_Identifier_L0>
<Genlex124> ~ <Delimited_Identifier_Part_L0>
<Genlex124_Many> ~ <Genlex124>+
<Delimited_Identifier_Body_L0> ~ <Genlex124_Many>
<Delimited_Identifier_Part_L0> ~ <Nondoublequote_Character_L0>
                                 | <Doublequote_Symbol_L0>
<Genlex129> ~ <Separator_L0>
<Genlex129_Any> ~ <Genlex129>*
<Genlex131> ~ <Genlex129_Any> <Lex039> <Unicode_Delimiter_Body_L0> <Lex040>
<Genlex131_Many> ~ <Genlex131>+
<Unicode_Delimited_Identifier_Value> ~ <Lex037> <Lex038> <Genlex131_Many>
<Genlex134> ~ <Separator_L0>
<Genlex134_Any> ~ <Genlex134>*
<Unicode_Delimited_Identifier> ::= <Unicode_Delimited_Identifier_Value> rank => 0 action => _unicodeDelimitedIdentifier
                                 | <Unicode_Delimited_Identifier_Value> <Genlex134_Any> <Unicode_Escape_Specifier> rank => -1 action => _unicodeDelimitedIdentifierUescape
<Genlex138> ~ <Lex042> <Unicode_Escape_Character_L0> <Lex043>
<Gen139> ::= <UESCAPE> <Genlex138> rank => 0
<Gen139_Maybe> ::= <Gen139> rank => 0
<Gen139_Maybe> ::= rank => -1
<Unicode_Escape_Specifier> ::= <Gen139_Maybe> rank => 0
<Genlex143> ~ <Unicode_Identifier_Part_L0>
<Genlex143_Many> ~ <Genlex143>+
<Unicode_Delimiter_Body_L0> ~ <Genlex143_Many>
<Unicode_Identifier_Part_L0> ~ <Unicode_Delimited_Identifier_Part_L0>
                               | <Unicode_Escape_Value_Internal_L0>
<Unicode_Delimited_Identifier_Part_L0> ~ <Nondoublequote_Character_L0>
                                         | <Doublequote_Symbol_L0>
<Unicode_Escape_Value_Internal_L0> ~ <Unicode_4_Digit_Escape_Value_L0>
                                     | <Unicode_6_Digit_Escape_Value_L0>
                                     | <Unicode_Character_Escape_Value_L0>
<Unicode_Escape_Value_L0> ~ <Unicode_Escape_Value_Internal_L0>
<Unicode_Hexit_L0> ~ <Lex044>
<Unicode_4_Digit_Escape_Value_L0> ~ <Unicode_Escape_Character_L0> <Unicode_Hexit_L0> <Unicode_Hexit_L0> <Unicode_Hexit_L0> <Unicode_Hexit_L0>
<Unicode_6_Digit_Escape_Value_L0> ~ <Unicode_Escape_Character_L0> <Lex045> <Unicode_Hexit_L0> <Unicode_Hexit_L0> <Unicode_Hexit_L0> <Unicode_Hexit_L0> <Unicode_Hexit_L0> <Unicode_Hexit_L0>
<Unicode_Character_Escape_Value_L0> ~ <Unicode_Escape_Character_L0> <Unicode_Escape_Character_L0>
<Unicode_Escape_Character_L0> ~ <Lex046>
<Nondoublequote_Character_L0> ~ <Lex047>
                                | <Unicode_Escape_Character_L0> <Lex048>
<Doublequote_Symbol_L0> ~ <Lex049>
<Delimiter_Token> ::= <Character_String_Literal> rank => 0
                    | <Date_String> rank => -1
                    | <Time_String> rank => -2
                    | <Timestamp_String> rank => -3
                    | <Interval_String> rank => -4
                    | <Delimited_Identifier> rank => -5
                    | <Unicode_Delimited_Identifier> rank => -6
                    | <SQL_Special_Character> rank => -7
                    | <Not_Equals_Operator> rank => -8
                    | <Greater_Than_Or_Equals_Operator> rank => -9
                    | <Less_Than_Or_Equals_Operator> rank => -10
                    | <Concatenation_Operator> rank => -11
                    | <Right_Arrow> rank => -12
                    | <Left_Bracket_Trigraph> rank => -13
                    | <Right_Bracket_Trigraph> rank => -14
                    | <Double_Colon> rank => -15
                    | <Double_Period> rank => -16
<Not_Equals_Operator_L0> ~ <Less_Than_Operator_L0> <Greater_Than_Operator_L0>
<Not_Equals_Operator> ~ <Not_Equals_Operator_L0>
<Greater_Than_Or_Equals_Operator_L0> ~ <Greater_Than_Operator_L0> <Equals_Operator_L0>
<Greater_Than_Or_Equals_Operator> ~ <Greater_Than_Or_Equals_Operator_L0>
<Less_Than_Or_Equals_Operator_L0> ~ <Less_Than_Operator_L0> <Equals_Operator_L0>
<Less_Than_Or_Equals_Operator> ~ <Less_Than_Or_Equals_Operator_L0>
<Concatenation_Operator_L0> ~ <Vertical_Bar_L0> <Vertical_Bar_L0>
<Concatenation_Operator> ~ <Concatenation_Operator_L0>
<Right_Arrow_L0> ~ <Minus_Sign_L0> <Greater_Than_Operator_L0>
<Right_Arrow> ~ <Right_Arrow_L0>
<Double_Colon_L0> ~ <Colon_L0> <Colon_L0>
<Double_Colon> ~ <Double_Colon_L0>
<Double_Period_L0> ~ <Period_L0> <Period_L0>
<Double_Period> ~ <Double_Period_L0>
<Separator_L0> ~ <Discard_L0>
<Key_Word> ::= <Reserved_Word> rank => 0
             | <Non_Reserved_Word> rank => -1
<Non_Reserved_Word> ::= <A> rank => 0
                      | <ABS> rank => -1
                      | <ABSOLUTE> rank => -2
                      | <ACTION> rank => -3
                      | <ADA> rank => -4
                      | <ADMIN> rank => -5
                      | <AFTER> rank => -6
                      | <ALWAYS> rank => -7
                      | <ASC> rank => -8
                      | <ASSERTION> rank => -9
                      | <ASSIGNMENT> rank => -10
                      | <ATTRIBUTE> rank => -11
                      | <ATTRIBUTES> rank => -12
                      | <AVG> rank => -13
                      | <BEFORE> rank => -14
                      | <BERNOULLI> rank => -15
                      | <BREADTH> rank => -16
                      | <C> rank => -17
                      | <CARDINALITY> rank => -18
                      | <CASCADE> rank => -19
                      | <CATALOG> rank => -20
                      | <CATALOG_NAME> rank => -21
                      | <CEIL> rank => -22
                      | <CEILING> rank => -23
                      | <CHAIN> rank => -24
                      | <CHARACTERISTICS> rank => -25
                      | <CHARACTERS> rank => -26
                      | <CHARACTER_LENGTH> rank => -27
                      | <CHARACTER_SET_CATALOG> rank => -28
                      | <CHARACTER_SET_NAME> rank => -29
                      | <CHARACTER_SET_SCHEMA> rank => -30
                      | <CHAR_LENGTH> rank => -31
                      | <CHECKED> rank => -32
                      | <CLASS_ORIGIN> rank => -33
                      | <COALESCE> rank => -34
                      | <COBOL> rank => -35
                      | <CODE_UNITS> rank => -36
                      | <COLLATION> rank => -37
                      | <COLLATION_CATALOG> rank => -38
                      | <COLLATION_NAME> rank => -39
                      | <COLLATION_SCHEMA> rank => -40
                      | <COLLECT> rank => -41
                      | <COLUMN_NAME> rank => -42
                      | <COMMAND_FUNCTION> rank => -43
                      | <COMMAND_FUNCTION_CODE> rank => -44
                      | <COMMITTED> rank => -45
                      | <CONDITION> rank => -46
                      | <CONDITION_NUMBER> rank => -47
                      | <CONNECTION_NAME> rank => -48
                      | <CONSTRAINTS> rank => -49
                      | <CONSTRAINT_CATALOG> rank => -50
                      | <CONSTRAINT_NAME> rank => -51
                      | <CONSTRAINT_SCHEMA> rank => -52
                      | <CONSTRUCTORS> rank => -53
                      | <CONTAINS> rank => -54
                      | <CONVERT> rank => -55
                      | <CORR> rank => -56
                      | <COUNT> rank => -57
                      | <COVAR_POP> rank => -58
                      | <COVAR_SAMP> rank => -59
                      | <CUME_DIST> rank => -60
                      | <CURRENT_COLLATION> rank => -61
                      | <CURSOR_NAME> rank => -62
                      | <DATA> rank => -63
                      | <DATETIME_INTERVAL_CODE> rank => -64
                      | <DATETIME_INTERVAL_PRECISION> rank => -65
                      | <DEFAULTS> rank => -66
                      | <DEFERRABLE> rank => -67
                      | <DEFERRED> rank => -68
                      | <DEFINED> rank => -69
                      | <DEFINER> rank => -70
                      | <DEGREE> rank => -71
                      | <DENSE_RANK> rank => -72
                      | <DEPTH> rank => -73
                      | <DERIVED> rank => -74
                      | <DESC> rank => -75
                      | <DESCRIPTOR> rank => -76
                      | <DIAGNOSTICS> rank => -77
                      | <DISPATCH> rank => -78
                      | <DOMAIN> rank => -79
                      | <DYNAMIC_FUNCTION> rank => -80
                      | <DYNAMIC_FUNCTION_CODE> rank => -81
                      | <EQUALS> rank => -82
                      | <EVERY> rank => -83
                      | <EXCEPTION> rank => -84
                      | <EXCLUDE> rank => -85
                      | <EXCLUDING> rank => -86
                      | <EXP> rank => -87
                      | <EXTRACT> rank => -88
                      | <FINAL> rank => -89
                      | <FIRST> rank => -90
                      | <FLOOR> rank => -91
                      | <FOLLOWING> rank => -92
                      | <FORTRAN> rank => -93
                      | <FOUND> rank => -94
                      | <FUSION> rank => -95
                      | <G> rank => -96
                      | <GENERAL> rank => -97
                      | <GO> rank => -98
                      | <GOTO> rank => -99
                      | <GRANTED> rank => -100
                      | <HIERARCHY> rank => -101
                      | <IMPLEMENTATION> rank => -102
                      | <INCLUDING> rank => -103
                      | <INCREMENT> rank => -104
                      | <INITIALLY> rank => -105
                      | <INSTANCE> rank => -106
                      | <INSTANTIABLE> rank => -107
                      | <INTERSECTION> rank => -108
                      | <INVOKER> rank => -109
                      | <ISOLATION> rank => -110
                      | <K> rank => -111
                      | <KEY> rank => -112
                      | <KEY_MEMBER> rank => -113
                      | <KEY_TYPE> rank => -114
                      | <LAST> rank => -115
                      | <LENGTH> rank => -116
                      | <LEVEL> rank => -117
                      | <LN> rank => -118
                      | <LOCATOR> rank => -119
                      | <LOWER> rank => -120
                      | <M> rank => -121
                      | <MAP> rank => -122
                      | <MATCHED> rank => -123
                      | <MAX> rank => -124
                      | <MAXVALUE> rank => -125
                      | <MESSAGE_LENGTH> rank => -126
                      | <MESSAGE_OCTET_LENGTH> rank => -127
                      | <MESSAGE_TEXT> rank => -128
                      | <MIN> rank => -129
                      | <MINVALUE> rank => -130
                      | <MOD> rank => -131
                      | <MORE> rank => -132
                      | <MUMPS> rank => -133
                      | <NAME> rank => -134
                      | <NAMES> rank => -135
                      | <NESTING> rank => -136
                      | <NEXT> rank => -137
                      | <NORMALIZE> rank => -138
                      | <NORMALIZED> rank => -139
                      | <NULLABLE> rank => -140
                      | <NULLIF> rank => -141
                      | <NULLS> rank => -142
                      | <NUMBER> rank => -143
                      | <OBJECT> rank => -144
                      | <OCTETS> rank => -145
                      | <OCTET_LENGTH> rank => -146
                      | <OPTION> rank => -147
                      | <OPTIONS> rank => -148
                      | <ORDERING> rank => -149
                      | <ORDINALITY> rank => -150
                      | <OTHERS> rank => -151
                      | <OVERLAY> rank => -152
                      | <OVERRIDING> rank => -153
                      | <PAD> rank => -154
                      | <PARAMETER_MODE> rank => -155
                      | <PARAMETER_NAME> rank => -156
                      | <PARAMETER_ORDINAL_POSITION> rank => -157
                      | <PARAMETER_SPECIFIC_CATALOG> rank => -158
                      | <PARAMETER_SPECIFIC_NAME> rank => -159
                      | <PARAMETER_SPECIFIC_SCHEMA> rank => -160
                      | <PARTIAL> rank => -161
                      | <PASCAL> rank => -162
                      | <PATH> rank => -163
                      | <PERCENTILE_CONT> rank => -164
                      | <PERCENTILE_DISC> rank => -165
                      | <PERCENT_RANK> rank => -166
                      | <PLACING> rank => -167
                      | <PLI> rank => -168
                      | <POSITION> rank => -169
                      | <POWER> rank => -170
                      | <PRECEDING> rank => -171
                      | <PRESERVE> rank => -172
                      | <PRIOR> rank => -173
                      | <PRIVILEGES> rank => -174
                      | <PUBLIC> rank => -175
                      | <RANK> rank => -176
                      | <READ> rank => -177
                      | <RELATIVE> rank => -178
                      | <REPEATABLE> rank => -179
                      | <RESTART> rank => -180
                      | <RETURNED_CARDINALITY> rank => -181
                      | <RETURNED_LENGTH> rank => -182
                      | <RETURNED_OCTET_LENGTH> rank => -183
                      | <RETURNED_SQLSTATE> rank => -184
                      | <ROLE> rank => -185
                      | <ROUTINE> rank => -186
                      | <ROUTINE_CATALOG> rank => -187
                      | <ROUTINE_NAME> rank => -188
                      | <ROUTINE_SCHEMA> rank => -189
                      | <ROW_COUNT> rank => -190
                      | <ROW_NUMBER> rank => -191
                      | <SCALE> rank => -192
                      | <SCHEMA> rank => -193
                      | <SCHEMA_NAME> rank => -194
                      | <SCOPE_CATALOG> rank => -195
                      | <SCOPE_NAME> rank => -196
                      | <SCOPE_SCHEMA> rank => -197
                      | <SECTION> rank => -198
                      | <SECURITY> rank => -199
                      | <SELF> rank => -200
                      | <SEQUENCE> rank => -201
                      | <SERIALIZABLE> rank => -202
                      | <SERVER_NAME> rank => -203
                      | <SESSION> rank => -204
                      | <SETS> rank => -205
                      | <SIMPLE> rank => -206
                      | <SIZE> rank => -207
                      | <SOURCE> rank => -208
                      | <SPACE> rank => -209
                      | <SPECIFIC_NAME> rank => -210
                      | <SQRT> rank => -211
                      | <STATE> rank => -212
                      | <STATEMENT> rank => -213
                      | <STDDEV_POP> rank => -214
                      | <STDDEV_SAMP> rank => -215
                      | <STRUCTURE> rank => -216
                      | <STYLE> rank => -217
                      | <SUBCLASS_ORIGIN> rank => -218
                      | <SUBSTRING> rank => -219
                      | <SUM> rank => -220
                      | <TABLESAMPLE> rank => -221
                      | <TABLE_NAME> rank => -222
                      | <TEMPORARY> rank => -223
                      | <TIES> rank => -224
                      | <TOP_LEVEL_COUNT> rank => -225
                      | <TRANSACTION> rank => -226
                      | <TRANSACTIONS_COMMITTED> rank => -227
                      | <TRANSACTIONS_ROLLED_BACK> rank => -228
                      | <TRANSACTION_ACTIVE> rank => -229
                      | <TRANSFORM> rank => -230
                      | <TRANSFORMS> rank => -231
                      | <TRANSLATE> rank => -232
                      | <TRIGGER_CATALOG> rank => -233
                      | <TRIGGER_NAME> rank => -234
                      | <TRIGGER_SCHEMA> rank => -235
                      | <TRIM> rank => -236
                      | <TYPE> rank => -237
                      | <UNBOUNDED> rank => -238
                      | <UNCOMMITTED> rank => -239
                      | <UNDER> rank => -240
                      | <UNNAMED> rank => -241
                      | <USAGE> rank => -242
                      | <USER_DEFINED_TYPE_CATALOG> rank => -243
                      | <USER_DEFINED_TYPE_CODE> rank => -244
                      | <USER_DEFINED_TYPE_NAME> rank => -245
                      | <USER_DEFINED_TYPE_SCHEMA> rank => -246
                      | <VIEW> rank => -247
                      | <WORK> rank => -248
                      | <WRITE> rank => -249
                      | <ZONE> rank => -250
<Reserved_Word> ::= <ADD> rank => 0
                  | <ALL> rank => -1
                  | <ALLOCATE> rank => -2
                  | <ALTER> rank => -3
                  | <AND> rank => -4
                  | <ANY> rank => -5
                  | <ARE> rank => -6
                  | <ARRAY> rank => -7
                  | <AS> rank => -8
                  | <ASENSITIVE> rank => -9
                  | <ASYMMETRIC> rank => -10
                  | <AT> rank => -11
                  | <ATOMIC> rank => -12
                  | <AUTHORIZATION> rank => -13
                  | <BEGIN> rank => -14
                  | <BETWEEN> rank => -15
                  | <BIGINT> rank => -16
                  | <BINARY> rank => -17
                  | <BLOB> rank => -18
                  | <BOOLEAN> rank => -19
                  | <BOTH> rank => -20
                  | <BY> rank => -21
                  | <CALL> rank => -22
                  | <CALLED> rank => -23
                  | <CASCADED> rank => -24
                  | <CASE> rank => -25
                  | <CAST> rank => -26
                  | <CHAR> rank => -27
                  | <CHARACTER> rank => -28
                  | <CHECK> rank => -29
                  | <CLOB> rank => -30
                  | <CLOSE> rank => -31
                  | <COLLATE> rank => -32
                  | <COLUMN> rank => -33
                  | <COMMIT> rank => -34
                  | <CONNECT> rank => -35
                  | <CONSTRAINT> rank => -36
                  | <CONTINUE> rank => -37
                  | <CORRESPONDING> rank => -38
                  | <CREATE> rank => -39
                  | <CROSS> rank => -40
                  | <CUBE> rank => -41
                  | <CURRENT> rank => -42
                  | <CURRENT_DATE> rank => -43
                  | <CURRENT_DEFAULT_TRANSFORM_GROUP> rank => -44
                  | <CURRENT_PATH> rank => -45
                  | <CURRENT_ROLE> rank => -46
                  | <CURRENT_TIME> rank => -47
                  | <CURRENT_TIMESTAMP> rank => -48
                  | <CURRENT_TRANSFORM_GROUP_FOR_TYPE> rank => -49
                  | <CURRENT_USER> rank => -50
                  | <CURSOR> rank => -51
                  | <CYCLE> rank => -52
                  | <DATE> rank => -53
                  | <DAY> rank => -54
                  | <DEALLOCATE> rank => -55
                  | <DEC> rank => -56
                  | <DECIMAL> rank => -57
                  | <DECLARE> rank => -58
                  | <DEFAULT> rank => -59
                  | <DELETE> rank => -60
                  | <DEREF> rank => -61
                  | <DESCRIBE> rank => -62
                  | <DETERMINISTIC> rank => -63
                  | <DISCONNECT> rank => -64
                  | <DISTINCT> rank => -65
                  | <DOUBLE> rank => -66
                  | <DROP> rank => -67
                  | <DYNAMIC> rank => -68
                  | <EACH> rank => -69
                  | <ELEMENT> rank => -70
                  | <ELSE> rank => -71
                  | <END> rank => -72
                  | <Lex374> rank => -73
                  | <ESCAPE> rank => -74
                  | <EXCEPT> rank => -75
                  | <EXEC> rank => -76
                  | <EXECUTE> rank => -77
                  | <EXISTS> rank => -78
                  | <EXTERNAL> rank => -79
                  | <FALSE> rank => -80
                  | <FETCH> rank => -81
                  | <FILTER> rank => -82
                  | <FLOAT> rank => -83
                  | <FOR> rank => -84
                  | <FOREIGN> rank => -85
                  | <FREE> rank => -86
                  | <FROM> rank => -87
                  | <FULL> rank => -88
                  | <FUNCTION> rank => -89
                  | <GET> rank => -90
                  | <GLOBAL> rank => -91
                  | <GRANT> rank => -92
                  | <GROUP> rank => -93
                  | <GROUPING> rank => -94
                  | <HAVING> rank => -95
                  | <HOLD> rank => -96
                  | <HOUR> rank => -97
                  | <IDENTITY> rank => -98
                  | <IMMEDIATE> rank => -99
                  | <IN> rank => -100
                  | <INDICATOR> rank => -101
                  | <INNER> rank => -102
                  | <INOUT> rank => -103
                  | <INPUT> rank => -104
                  | <INSENSITIVE> rank => -105
                  | <INSERT> rank => -106
                  | <INT> rank => -107
                  | <INTEGER> rank => -108
                  | <INTERSECT> rank => -109
                  | <INTERVAL> rank => -110
                  | <INTO> rank => -111
                  | <IS> rank => -112
                  | <ISOLATION> rank => -113
                  | <JOIN> rank => -114
                  | <LANGUAGE> rank => -115
                  | <LARGE> rank => -116
                  | <LATERAL> rank => -117
                  | <LEADING> rank => -118
                  | <LEFT> rank => -119
                  | <LIKE> rank => -120
                  | <LOCAL> rank => -121
                  | <LOCALTIME> rank => -122
                  | <LOCALTIMESTAMP> rank => -123
                  | <MATCH> rank => -124
                  | <MEMBER> rank => -125
                  | <MERGE> rank => -126
                  | <METHOD> rank => -127
                  | <MINUTE> rank => -128
                  | <MODIFIES> rank => -129
                  | <MODULE> rank => -130
                  | <MONTH> rank => -131
                  | <MULTISET> rank => -132
                  | <NATIONAL> rank => -133
                  | <NATURAL> rank => -134
                  | <NCHAR> rank => -135
                  | <NCLOB> rank => -136
                  | <NEW> rank => -137
                  | <NO> rank => -138
                  | <NONE> rank => -139
                  | <NOT> rank => -140
                  | <NULL> rank => -141
                  | <NUMERIC> rank => -142
                  | <OF> rank => -143
                  | <OLD> rank => -144
                  | <ON> rank => -145
                  | <ONLY> rank => -146
                  | <OPEN> rank => -147
                  | <OR> rank => -148
                  | <ORDER> rank => -149
                  | <OUT> rank => -150
                  | <OUTER> rank => -151
                  | <OUTPUT> rank => -152
                  | <OVER> rank => -153
                  | <OVERLAPS> rank => -154
                  | <PARAMETER> rank => -155
                  | <PARTITION> rank => -156
                  | <PRECISION> rank => -157
                  | <PREPARE> rank => -158
                  | <PRIMARY> rank => -159
                  | <PROCEDURE> rank => -160
                  | <RANGE> rank => -161
                  | <READS> rank => -162
                  | <REAL> rank => -163
                  | <RECURSIVE> rank => -164
                  | <REF> rank => -165
                  | <REFERENCES> rank => -166
                  | <REFERENCING> rank => -167
                  | <REGR_AVGX> rank => -168
                  | <REGR_AVGY> rank => -169
                  | <REGR_COUNT> rank => -170
                  | <REGR_INTERCEPT> rank => -171
                  | <Lex472> rank => -172
                  | <REGR_SLOPE> rank => -173
                  | <REGR_SXX> rank => -174
                  | <REGR_SXY> rank => -175
                  | <REGR_SYY> rank => -176
                  | <RELEASE> rank => -177
                  | <RESULT> rank => -178
                  | <RETURN> rank => -179
                  | <RETURNS> rank => -180
                  | <REVOKE> rank => -181
                  | <RIGHT> rank => -182
                  | <ROLLBACK> rank => -183
                  | <ROLLUP> rank => -184
                  | <ROW> rank => -185
                  | <ROWS> rank => -186
                  | <SAVEPOINT> rank => -187
                  | <SCROLL> rank => -188
                  | <SEARCH> rank => -189
                  | <SECOND> rank => -190
                  | <SELECT> rank => -191
                  | <SENSITIVE> rank => -192
                  | <SESSION_USER> rank => -193
                  | <SET> rank => -194
                  | <SIMILAR> rank => -195
                  | <SMALLINT> rank => -196
                  | <SOME> rank => -197
                  | <SPECIFIC> rank => -198
                  | <SPECIFICTYPE> rank => -199
                  | <SQL> rank => -200
                  | <SQLEXCEPTION> rank => -201
                  | <SQLSTATE> rank => -202
                  | <SQLWARNING> rank => -203
                  | <START> rank => -204
                  | <STATIC> rank => -205
                  | <SUBMULTISET> rank => -206
                  | <SYMMETRIC> rank => -207
                  | <SYSTEM> rank => -208
                  | <SYSTEM_USER> rank => -209
                  | <TABLE> rank => -210
                  | <THEN> rank => -211
                  | <TIME> rank => -212
                  | <TIMESTAMP> rank => -213
                  | <TIMEZONE_HOUR> rank => -214
                  | <TIMEZONE_MINUTE> rank => -215
                  | <TO> rank => -216
                  | <TRAILING> rank => -217
                  | <TRANSLATION> rank => -218
                  | <TREAT> rank => -219
                  | <TRIGGER> rank => -220
                  | <TRUE> rank => -221
                  | <UNION> rank => -222
                  | <UNIQUE> rank => -223
                  | <UNKNOWN> rank => -224
                  | <UNNEST> rank => -225
                  | <UPDATE> rank => -226
                  | <UPPER> rank => -227
                  | <USER> rank => -228
                  | <USING> rank => -229
                  | <VALUE> rank => -230
                  | <VALUES> rank => -231
                  | <VAR_POP> rank => -232
                  | <VAR_SAMP> rank => -233
                  | <VARCHAR> rank => -234
                  | <VARYING> rank => -235
                  | <WHEN> rank => -236
                  | <WHENEVER> rank => -237
                  | <WHERE> rank => -238
                  | <WIDTH_BUCKET> rank => -239
                  | <WINDOW> rank => -240
                  | <WITH> rank => -241
                  | <WITHIN> rank => -242
                  | <WITHOUT> rank => -243
                  | <YEAR> rank => -244
<Literal> ::= <Signed_Numeric_Literal> rank => 0
            | <General_Literal> rank => -1
<Unsigned_Literal> ::= <Unsigned_Numeric_Literal> rank => 0
                     | <General_Literal> rank => -1
<General_Literal> ::= <Character_String_Literal> rank => 0
                    | <National_Character_String_Literal> rank => -1
                    | <Unicode_Character_String_Literal> rank => -2
                    | <Binary_String_Literal> rank => -3
                    | <Datetime_Literal> rank => -4
                    | <Interval_Literal> rank => -5
                    | <Boolean_Literal> rank => -6
<Character_String_Literal> ::= <Character_String_Literal_L0> rank => 0 action => _characterStringLiteral
<Genlex704> ~ <Introducer_L0> <Character_Set_Specification_L0_Internal>
<Genlex704_Maybe> ~ <Genlex704>
<Genlex704_Maybe> ~
<Genlex707> ~ <Separator_L0>
<Genlex707_Any> ~ <Genlex707>*
<Genlex709> ~ <Genlex707_Any> <Character_String_Literal_Unit_L0>
<Genlex709_Any> ~ <Genlex709>*
<Character_String_Literal_L0> ~ <Genlex704_Maybe> <Character_String_Literal_Unit_L0> <Genlex709_Any>
<Genlex712> ~ <Character_Representation_L0>
<Genlex712_Any> ~ <Genlex712>*
<Character_String_Literal_Unit_L0> ~ <Quote_L0> <Genlex712_Any> <Quote_L0>
<Introducer_L0> ~ <Underscore_L0>
<Character_Representation_L0> ~ <Nonquote_Character_L0>
                                | <Quote_Symbol_L0>
<Character_Representation> ~ <Character_Representation_L0>
<Nonquote_Character_L0> ~ <Lex545>
                          | <Lex546> <Lex547>
<Quote_Symbol_L0> ~ <Lex548> <Lex549>
<National_Character_String_Literal> ::= <National_Character_String_Literal_L0> rank => 0 action => _nationalCharacterStringLiteral
<Genlex723> ~ <Character_Representation_L0>
<Genlex723_Any> ~ <Genlex723>*
<Genlex725> ~ <Separator_L0>
<Genlex725_Any> ~ <Genlex725>*
<Genlex727> ~ <Character_Representation_L0>
<Genlex727_Any> ~ <Genlex727>*
<Genlex729> ~ <Genlex725_Any> <Quote_L0> <Genlex727_Any> <Quote_L0>
<Genlex729_Any> ~ <Genlex729>*
<National_Character_String_Literal_L0> ~ <Lex550> <Quote_L0> <Genlex723_Any> <Quote_L0> <Genlex729_Any>
<Gen732> ::= <ESCAPE> <Escape_Character> rank => 0
<Gen732_Maybe> ::= <Gen732> rank => 0
<Gen732_Maybe> ::= rank => -1
<Unicode_Character_String_Literal> ::= <Unicode_Character_String_Literal_Value> <Gen732_Maybe> rank => 0
<Genlex736> ~ <Introducer_L0> <Character_Set_Specification_L0_Internal>
<Genlex736_Maybe> ~ <Genlex736>
<Genlex736_Maybe> ~
<Genlex739> ~ <Unicode_Representation_L0>
<Genlex739_Any> ~ <Genlex739>*
<Genlex741> ~ <Unicode_Representation_L0>
<Genlex741_Any> ~ <Genlex741>*
<Genlex743> ~ <Separator_L0> <Quote_L0> <Genlex741_Any> <Quote_L0>
<Genlex743_Any> ~ <Genlex743>*
<Unicode_Character_String_Literal_Value> ~ <Genlex736_Maybe> <Lex551> <Ampersand_L0> <Quote_L0> <Genlex739_Any> <Quote_L0> <Genlex743_Any>
<Unicode_Representation_L0> ~ <Character_Representation_L0>
                              | <Unicode_Escape_Value_L0>
<Gen748> ::= <Hexit> <Hexit> rank => 0
<Gen748_Any> ::= <Gen748>* rank => 0
<Gen750> ::= <Quote> <Gen748_Any> <Quote> rank => 0
<Gen750_Many> ::= <Gen750>+ rank => 0
<Gen752> ::= <ESCAPE> <Escape_Character> rank => 0
<Gen752_Maybe> ::= <Gen752> rank => 0
<Gen752_Maybe> ::= rank => -1
<Binary_String_Literal> ::= <X> <Gen750_Many> <Gen752_Maybe> rank => 0
<Hexit> ::= <Digit> rank => 0
          | <A> rank => -1
          | <B> rank => -2
          | <C> rank => -3
          | <D> rank => -4
          | <E> rank => -5
          | <F> rank => -6
          | <a> rank => -7
          | <b> rank => -8
          | <c> rank => -9
          | <d> rank => -10
          | <e> rank => -11
          | <f> rank => -12
<Sign_Maybe> ::= <Sign> rank => 0
<Sign_Maybe> ::= rank => -1
<Signed_Numeric_Literal> ::= <Sign_Maybe> <Unsigned_Numeric_Literal> rank => 0
<Unsigned_Numeric_Literal_L0_Internal> ~ <Exact_Numeric_Literal_L0>
                                         | <Approximate_Numeric_Literal_L0>
<Unsigned_Numeric_Literal_L0> ~ <Unsigned_Numeric_Literal_L0_Internal>
<Unsigned_Numeric_Literal> ::= <Unsigned_Numeric_Literal_L0> rank => 0 action => _unsignedNumericLiteral
<Unsigned_Integer_L0> ~ <Lex563_Many>
<Unsigned_Integer> ~ <Unsigned_Integer_L0>
<Genlex778> ~ <Unsigned_Integer_L0>
<Genlex778_Maybe> ~ <Genlex778>
<Genlex778_Maybe> ~
<Genlex781> ~ <Period_L0> <Genlex778_Maybe>
<Genlex781_Maybe> ~ <Genlex781>
<Genlex781_Maybe> ~
<Exact_Numeric_Literal_L0> ~ <Unsigned_Integer_L0> <Genlex781_Maybe>
                             | <Period_L0> <Unsigned_Integer_L0>
<Sign_L0> ~ <Plus_Sign_L0>
            | <Minus_Sign_L0>
<Sign> ~ <Sign_L0>
<Approximate_Numeric_Literal_L0> ~ <Mantissa_L0> <Lex564> <Exponent_L0>
<Mantissa_L0> ~ <Exact_Numeric_Literal_L0>
<Exponent_L0> ~ <Signed_Integer_L0>
<Genlex792> ~ <Sign_L0>
<Genlex792_Maybe> ~ <Genlex792>
<Genlex792_Maybe> ~
<Signed_Integer_L0> ~ <Genlex792_Maybe> <Unsigned_Integer_L0>
<Datetime_Literal> ::= <Date_Literal> rank => 0
                     | <Time_Literal> rank => -1
                     | <Timestamp_Literal> rank => -2
<Date_Literal> ::= <DATE> <Date_String> rank => 0
<Time_Literal> ::= <TIME> <Time_String> rank => 0
<Timestamp_Literal> ::= <TIMESTAMP> <Timestamp_String> rank => 0
<Date_String_L0> ~ <Quote_L0> <Unquoted_Date_String_L0> <Quote_L0>
<Date_String> ~ <Date_String_L0>
<Time_String_L0> ~ <Quote_L0> <Unquoted_Time_String_L0> <Quote_L0>
<Time_String> ~ <Time_String_L0>
<Timestamp_String_L0> ~ <Quote_L0> <Unquoted_Timestamp_String_L0> <Quote_L0>
<Timestamp_String> ~ <Timestamp_String_L0>
<Time_Zone_Interval_L0> ~ <Sign_L0> <Hours_Value_L0> <Colon_L0> <Minutes_Value_L0>
<Date_Value_L0> ~ <Years_Value_L0> <Minus_Sign_L0> <Months_Value_L0> <Minus_Sign_L0> <Days_Value_L0>
<Time_Value_L0> ~ <Hours_Value_L0> <Colon_L0> <Minutes_Value_L0> <Colon_L0> <Seconds_Value_L0>
<Interval_Literal> ::= <INTERVAL> <Sign_Maybe> <Interval_String> <Interval_Qualifier> rank => 0
<Interval_String_L0> ~ <Quote_L0> <Unquoted_Interval_String_L0> <Quote_L0>
<Interval_String> ~ <Interval_String_L0>
<Unquoted_Date_String_L0> ~ <Date_Value_L0>
<Genlex815> ~ <Time_Zone_Interval_L0>
<Genlex815_Maybe> ~ <Genlex815>
<Genlex815_Maybe> ~
<Unquoted_Time_String_L0> ~ <Time_Value_L0> <Genlex815_Maybe>
<Unquoted_Timestamp_String_L0> ~ <Unquoted_Date_String_L0> <Space_L0> <Unquoted_Time_String_L0>
<Genlex820> ~ <Sign_L0>
<Genlex820_Maybe> ~ <Genlex820>
<Genlex820_Maybe> ~
<Genlex823> ~ <Year_Month_Literal_L0>
              | <Day_Time_Literal_L0>
<Unquoted_Interval_String_L0> ~ <Genlex820_Maybe> <Genlex823>
<Genlex826> ~ <Years_Value_L0> <Minus_Sign_L0>
<Genlex826_Maybe> ~ <Genlex826>
<Genlex826_Maybe> ~
<Year_Month_Literal_L0> ~ <Years_Value_L0>
                          | <Genlex826_Maybe> <Months_Value_L0>
<Day_Time_Literal_L0> ~ <Day_Time_Interval_L0>
                        | <Time_Interval_L0>
<Genlex833> ~ <Colon_L0> <Seconds_Value_L0>
<Genlex833_Maybe> ~ <Genlex833>
<Genlex833_Maybe> ~
<Genlex836> ~ <Colon_L0> <Minutes_Value_L0> <Genlex833_Maybe>
<Genlex836_Maybe> ~ <Genlex836>
<Genlex836_Maybe> ~
<Genlex839> ~ <Space_L0> <Hours_Value_L0> <Genlex836_Maybe>
<Genlex839_Maybe> ~ <Genlex839>
<Genlex839_Maybe> ~
<Day_Time_Interval_L0> ~ <Days_Value_L0> <Genlex839_Maybe>
<Genlex843> ~ <Colon_L0> <Seconds_Value_L0>
<Genlex843_Maybe> ~ <Genlex843>
<Genlex843_Maybe> ~
<Genlex846> ~ <Colon_L0> <Minutes_Value_L0> <Genlex843_Maybe>
<Genlex846_Maybe> ~ <Genlex846>
<Genlex846_Maybe> ~
<Genlex849> ~ <Colon_L0> <Seconds_Value_L0>
<Genlex849_Maybe> ~ <Genlex849>
<Genlex849_Maybe> ~
<Time_Interval_L0> ~ <Hours_Value_L0> <Genlex846_Maybe>
                     | <Minutes_Value_L0> <Genlex849_Maybe>
                     | <Seconds_Value_L0>
<Years_Value_L0> ~ <Datetime_Value_L0>
<Months_Value_L0> ~ <Datetime_Value_L0>
<Days_Value_L0> ~ <Datetime_Value_L0>
<Hours_Value_L0> ~ <Datetime_Value_L0>
<Minutes_Value_L0> ~ <Datetime_Value_L0>
<Genlex860> ~ <Seconds_Fraction_L0>
<Genlex860_Maybe> ~ <Genlex860>
<Genlex860_Maybe> ~
<Genlex863> ~ <Period_L0> <Genlex860_Maybe>
<Genlex863_Maybe> ~ <Genlex863>
<Genlex863_Maybe> ~
<Seconds_Value_L0> ~ <Seconds_Integer_Value_L0> <Genlex863_Maybe>
<Seconds_Integer_Value_L0> ~ <Unsigned_Integer_L0>
<Seconds_Fraction_L0> ~ <Unsigned_Integer_L0>
<Datetime_Value_L0> ~ <Unsigned_Integer_L0>
<Boolean_Literal> ::= <TRUE> rank => 0
                    | <FALSE> rank => -1
                    | <UNKNOWN> rank => -2
<Host_Identifier_L0_Internal> ~ <Lex565_Many>
<Host_Identifier_L0> ~ <Host_Identifier_L0_Internal>
                       | <Lex566> <Host_Identifier_L0> <Lex567>
<Identifier_L0_Internal> ~ <Actual_Identifier_L0>
<Identifier> ~ <Identifier_L0_Internal>
<Actual_Identifier_L0> ~ <Regular_Identifier_L0_Internal>
                         | <Delimited_Identifier_L0>
<Genlex880> ~ <Underscore_L0>
              | <SQL_Language_Identifier_Part_L0>
<Genlex880_Any> ~ <Genlex880>*
<SQL_Language_Identifier_L0_Internal> ~ <SQL_Language_Identifier_Start_L0> <Genlex880_Any>
<SQL_Language_Identifier_Start_L0> ~ <Simple_Latin_Letter_L0>
<SQL_Language_Identifier_Part_L0> ~ <Simple_Latin_Letter_L0>
                                    | <Digit_L0>
<Authorization_Identifier> ::= <Role_Name> rank => 0
                             | <User_Identifier> rank => -1
<Table_Name> ::= <Local_Or_Schema_Qualified_Name> rank => 0
<Domain_Name> ::= <Schema_Qualified_Name> rank => 0
<Unqualified_Schema_Name_L0_Internal> ~ <Identifier_L0_Internal>
<Unqualified_Schema_Name_L0> ~ <Unqualified_Schema_Name_L0_Internal>
<Unqualified_Schema_Name> ::= <Unqualified_Schema_Name_L0> rank => 0
<Genlex894> ~ <Catalog_Name_L0_Internal> <Period_L0>
<Genlex894_Maybe> ~ <Genlex894>
<Genlex894_Maybe> ~
<Schema_Name_L0_Internal> ~ <Genlex894_Maybe> <Unqualified_Schema_Name_L0_Internal>
<Schema_Name_L0> ~ <Schema_Name_L0_Internal>
<Schema_Name> ::= <Schema_Name_L0> rank => 0
<Catalog_Name_L0_Internal> ~ <Identifier_L0_Internal>
<Catalog_Name_L0> ~ <Catalog_Name_L0_Internal>
<Catalog_Name> ::= <Catalog_Name_L0> rank => 0
<Genlex903> ~ <Schema_Name_L0_Internal> <Period_L0>
<Genlex903_Maybe> ~ <Genlex903>
<Genlex903_Maybe> ~
<Schema_Qualified_Name> ~ <Genlex903_Maybe> <Qualified_Identifier_L0>
<Genlex907> ~ <Local_Or_Schema_Qualifier_L0> <Period_L0>
<Genlex907_Maybe> ~ <Genlex907>
<Genlex907_Maybe> ~
<Local_Or_Schema_Qualified_Name> ~ <Genlex907_Maybe> <Qualified_Identifier_L0>
<Local_Or_Schema_Qualifier_L0> ~ <Schema_Name_L0_Internal>
                                 | <Lex568>
<Qualified_Identifier_L0> ~ <Identifier_L0_Internal>
<Qualified_Identifier> ~ <Qualified_Identifier_L0>
<Column_Name_L0> ~ <Identifier_L0_Internal>
<Column_Name> ~ <Column_Name_L0>
<Correlation_Name> ::= <Identifier> rank => 0
<Query_Name> ::= <Identifier> rank => 0
<SQL_Client_Module_Name> ::= <Identifier> rank => 0
<Procedure_Name> ::= <Identifier> rank => 0
<Schema_Qualified_Routine_Name> ::= <Schema_Qualified_Name> rank => 0
<Method_Name> ::= <Identifier> rank => 0
<Specific_Name> ::= <Schema_Qualified_Name> rank => 0
<Cursor_Name> ::= <Local_Qualified_Name> rank => 0
<Genlex925> ~ <Local_Qualifier_L0> <Period_L0>
<Genlex925_Maybe> ~ <Genlex925>
<Genlex925_Maybe> ~
<Local_Qualified_Name> ~ <Genlex925_Maybe> <Qualified_Identifier_L0>
<Local_Qualifier_L0> ~ <Lex569>
<Host_Parameter_Name> ::= <Colon> <Identifier> rank => 0
<SQL_Parameter_Name> ::= <Identifier> rank => 0
<Constraint_Name> ::= <Schema_Qualified_Name> rank => 0
<External_Routine_Name> ::= <Identifier> rank => 0
                          | <Character_String_Literal> rank => -1
<Trigger_Name> ::= <Schema_Qualified_Name> rank => 0
<Collation_Name> ::= <Schema_Qualified_Name> rank => 0
<Genlex937> ~ <Schema_Name_L0_Internal> <Period_L0>
<Genlex937_Maybe> ~ <Genlex937>
<Genlex937_Maybe> ~
<Character_Set_Name_L0_Internal> ~ <Genlex937_Maybe> <SQL_Language_Identifier_L0_Internal>
<Character_Set_Name_L0> ~ <Character_Set_Name_L0_Internal>
<Character_Set_Name> ~ <Character_Set_Name_L0>
<Transliteration_Name> ::= <Schema_Qualified_Name> rank => 0
<Transcoding_Name> ::= <Schema_Qualified_Name> rank => 0
<User_Defined_Type_Name> ::= <Schema_Qualified_Type_Name> rank => 0
<Schema_Resolved_User_Defined_Type_Name> ::= <User_Defined_Type_Name> rank => 0
<Genlex947> ~ <Schema_Name_L0_Internal> <Period_L0>
<Genlex947_Maybe> ~ <Genlex947>
<Genlex947_Maybe> ~
<Schema_Qualified_Type_Name> ~ <Genlex947_Maybe> <Qualified_Identifier_L0>
<Attribute_Name> ::= <Identifier> rank => 0
<Field_Name> ::= <Identifier> rank => 0
<Savepoint_Name> ::= <Identifier> rank => 0
<Sequence_Generator_Name> ::= <Schema_Qualified_Name> rank => 0
<Role_Name> ::= <Identifier> rank => 0
<User_Identifier> ::= <Identifier> rank => 0
<Connection_Name> ::= <Simple_Value_Specification> rank => 0
<Sql_Server_Name> ::= <Simple_Value_Specification> rank => 0
<Connection_User_Name> ::= <Simple_Value_Specification> rank => 0
<SQL_Statement_Name> ::= <Statement_Name> rank => 0
                       | <Extended_Statement_Name> rank => -1
<Statement_Name> ::= <Identifier> rank => 0
<Scope_Option_Maybe> ::= <Scope_Option> rank => 0
<Scope_Option_Maybe> ::= rank => -1
<Extended_Statement_Name> ::= <Scope_Option_Maybe> <Simple_Value_Specification> rank => 0
<Dynamic_Cursor_Name> ::= <Cursor_Name> rank => 0
                        | <Extended_Cursor_Name> rank => -1
<Extended_Cursor_Name> ::= <Scope_Option_Maybe> <Simple_Value_Specification> rank => 0
<Descriptor_Name> ::= <Scope_Option_Maybe> <Simple_Value_Specification> rank => 0
<Scope_Option> ::= <GLOBAL> rank => 0
                 | <LOCAL> rank => -1
<Window_Name> ::= <Identifier> rank => 0
<Data_Type> ::= <Predefined_Type> rank => 0
              | <Row_Type> rank => -1
              | <Path_Resolved_User_Defined_Type_Name> rank => -2
              | <Reference_Type> rank => -3
              | <Collection_Type> rank => -4
<Gen978> ::= <CHARACTER> <SET> <Character_Set_Specification> rank => 0
<Gen978_Maybe> ::= <Gen978> rank => 0
<Gen978_Maybe> ::= rank => -1
<Collate_Clause_Maybe> ::= <Collate_Clause> rank => 0
<Collate_Clause_Maybe> ::= rank => -1
<Predefined_Type> ::= <Character_String_Type> <Gen978_Maybe> <Collate_Clause_Maybe> rank => 0
                    | <National_Character_String_Type> <Collate_Clause_Maybe> rank => -1
                    | <Binary_Large_Object_String_Type> rank => -2
                    | <Numeric_Type> rank => -3
                    | <Boolean_Type> rank => -4
                    | <Datetime_Type> rank => -5
                    | <Interval_Type> rank => -6
<Gen990> ::= <Left_Paren> <Length> <Right_Paren> rank => 0
<Gen990_Maybe> ::= <Gen990> rank => 0
<Gen990_Maybe> ::= rank => -1
<Gen993> ::= <Left_Paren> <Length> <Right_Paren> rank => 0
<Gen993_Maybe> ::= <Gen993> rank => 0
<Gen993_Maybe> ::= rank => -1
<Gen996> ::= <Left_Paren> <Large_Object_Length> <Right_Paren> rank => 0
<Gen996_Maybe> ::= <Gen996> rank => 0
<Gen996_Maybe> ::= rank => -1
<Gen999> ::= <Left_Paren> <Large_Object_Length> <Right_Paren> rank => 0
<Gen999_Maybe> ::= <Gen999> rank => 0
<Gen999_Maybe> ::= rank => -1
<Gen1002> ::= <Left_Paren> <Large_Object_Length> <Right_Paren> rank => 0
<Gen1002_Maybe> ::= <Gen1002> rank => 0
<Gen1002_Maybe> ::= rank => -1
<Character_String_Type> ::= <CHARACTER> <Gen990_Maybe> rank => 0
                          | <CHAR> <Gen993_Maybe> rank => -1
                          | <CHARACTER> <VARYING> <Left_Paren> <Length> <Right_Paren> rank => -2
                          | <CHAR> <VARYING> <Left_Paren> <Length> <Right_Paren> rank => -3
                          | <VARCHAR> <Left_Paren> <Length> <Right_Paren> rank => -4
                          | <CHARACTER> <LARGE> <OBJECT> <Gen996_Maybe> rank => -5
                          | <CHAR> <LARGE> <OBJECT> <Gen999_Maybe> rank => -6
                          | <CLOB> <Gen1002_Maybe> rank => -7
<Gen1013> ::= <Left_Paren> <Length> <Right_Paren> rank => 0
<Gen1013_Maybe> ::= <Gen1013> rank => 0
<Gen1013_Maybe> ::= rank => -1
<Gen1016> ::= <Left_Paren> <Length> <Right_Paren> rank => 0
<Gen1016_Maybe> ::= <Gen1016> rank => 0
<Gen1016_Maybe> ::= rank => -1
<Gen1019> ::= <Left_Paren> <Length> <Right_Paren> rank => 0
<Gen1019_Maybe> ::= <Gen1019> rank => 0
<Gen1019_Maybe> ::= rank => -1
<Gen1022> ::= <Left_Paren> <Large_Object_Length> <Right_Paren> rank => 0
<Gen1022_Maybe> ::= <Gen1022> rank => 0
<Gen1022_Maybe> ::= rank => -1
<Gen1025> ::= <Left_Paren> <Large_Object_Length> <Right_Paren> rank => 0
<Gen1025_Maybe> ::= <Gen1025> rank => 0
<Gen1025_Maybe> ::= rank => -1
<Gen1028> ::= <Left_Paren> <Large_Object_Length> <Right_Paren> rank => 0
<Gen1028_Maybe> ::= <Gen1028> rank => 0
<Gen1028_Maybe> ::= rank => -1
<National_Character_String_Type> ::= <NATIONAL> <CHARACTER> <Gen1013_Maybe> rank => 0
                                   | <NATIONAL> <CHAR> <Gen1016_Maybe> rank => -1
                                   | <NCHAR> <Gen1019_Maybe> rank => -2
                                   | <NATIONAL> <CHARACTER> <VARYING> <Left_Paren> <Length> <Right_Paren> rank => -3
                                   | <NATIONAL> <CHAR> <VARYING> <Left_Paren> <Length> <Right_Paren> rank => -4
                                   | <NCHAR> <VARYING> <Left_Paren> <Length> <Right_Paren> rank => -5
                                   | <NATIONAL> <CHARACTER> <LARGE> <OBJECT> <Gen1022_Maybe> rank => -6
                                   | <NCHAR> <LARGE> <OBJECT> <Gen1025_Maybe> rank => -7
                                   | <NCLOB> <Gen1028_Maybe> rank => -8
<Gen1040> ::= <Left_Paren> <Large_Object_Length> <Right_Paren> rank => 0
<Gen1040_Maybe> ::= <Gen1040> rank => 0
<Gen1040_Maybe> ::= rank => -1
<Gen1043> ::= <Left_Paren> <Large_Object_Length> <Right_Paren> rank => 0
<Gen1043_Maybe> ::= <Gen1043> rank => 0
<Gen1043_Maybe> ::= rank => -1
<Binary_Large_Object_String_Type> ::= <BINARY> <LARGE> <OBJECT> <Gen1040_Maybe> rank => 0
                                    | <BLOB> <Gen1043_Maybe> rank => -1
<Numeric_Type> ::= <Exact_Numeric_Type> rank => 0
                 | <Approximate_Numeric_Type> rank => -1
<Gen1050> ::= <Comma> <Scale> rank => 0
<Gen1050_Maybe> ::= <Gen1050> rank => 0
<Gen1050_Maybe> ::= rank => -1
<Gen1053> ::= <Left_Paren> <Precision> <Gen1050_Maybe> <Right_Paren> rank => 0
<Gen1053_Maybe> ::= <Gen1053> rank => 0
<Gen1053_Maybe> ::= rank => -1
<Gen1056> ::= <Comma> <Scale> rank => 0
<Gen1056_Maybe> ::= <Gen1056> rank => 0
<Gen1056_Maybe> ::= rank => -1
<Gen1059> ::= <Left_Paren> <Precision> <Gen1056_Maybe> <Right_Paren> rank => 0
<Gen1059_Maybe> ::= <Gen1059> rank => 0
<Gen1059_Maybe> ::= rank => -1
<Gen1062> ::= <Comma> <Scale> rank => 0
<Gen1062_Maybe> ::= <Gen1062> rank => 0
<Gen1062_Maybe> ::= rank => -1
<Gen1065> ::= <Left_Paren> <Precision> <Gen1062_Maybe> <Right_Paren> rank => 0
<Gen1065_Maybe> ::= <Gen1065> rank => 0
<Gen1065_Maybe> ::= rank => -1
<Exact_Numeric_Type> ::= <NUMERIC> <Gen1053_Maybe> rank => 0
                       | <DECIMAL> <Gen1059_Maybe> rank => -1
                       | <DEC> <Gen1065_Maybe> rank => -2
                       | <SMALLINT> rank => -3
                       | <INTEGER> rank => -4
                       | <INT> rank => -5
                       | <BIGINT> rank => -6
<Gen1075> ::= <Left_Paren> <Precision> <Right_Paren> rank => 0
<Gen1075_Maybe> ::= <Gen1075> rank => 0
<Gen1075_Maybe> ::= rank => -1
<Approximate_Numeric_Type> ::= <FLOAT> <Gen1075_Maybe> rank => 0
                             | <REAL> rank => -1
                             | <DOUBLE> <PRECISION> rank => -2
<Length> ::= <Unsigned_Integer> rank => 0
<Multiplier_Maybe> ::= <Multiplier> rank => 0
<Multiplier_Maybe> ::= rank => -1
<Char_Length_Units_Maybe> ::= <Char_Length_Units> rank => 0
<Char_Length_Units_Maybe> ::= rank => -1
<Large_Object_Length> ::= <Unsigned_Integer> <Multiplier_Maybe> <Char_Length_Units_Maybe> rank => 0
                        | <Large_Object_Length_Token> <Char_Length_Units_Maybe> rank => -1
<Char_Length_Units> ::= <CHARACTERS> rank => 0
                      | <CODE_UNITS> rank => -1
                      | <OCTETS> rank => -2
<Precision> ::= <Unsigned_Integer> rank => 0
<Scale> ::= <Unsigned_Integer> rank => 0
<Boolean_Type> ::= <BOOLEAN> rank => 0
<Gen1094> ::= <Left_Paren> <Time_Precision> <Right_Paren> rank => 0
<Gen1094_Maybe> ::= <Gen1094> rank => 0
<Gen1094_Maybe> ::= rank => -1
<Gen1097> ::= <With_Or_Without_Time_Zone> rank => 0
<Gen1097_Maybe> ::= <Gen1097> rank => 0
<Gen1097_Maybe> ::= rank => -1
<Gen1100> ::= <Left_Paren> <Timestamp_Precision> <Right_Paren> rank => 0
<Gen1100_Maybe> ::= <Gen1100> rank => 0
<Gen1100_Maybe> ::= rank => -1
<Gen1103> ::= <With_Or_Without_Time_Zone> rank => 0
<Gen1103_Maybe> ::= <Gen1103> rank => 0
<Gen1103_Maybe> ::= rank => -1
<Datetime_Type> ::= <DATE> rank => 0
                  | <TIME> <Gen1094_Maybe> <Gen1097_Maybe> rank => -1
                  | <TIMESTAMP> <Gen1100_Maybe> <Gen1103_Maybe> rank => -2
<With_Or_Without_Time_Zone> ::= <WITH> <TIME> <ZONE> rank => 0
                              | <WITHOUT> <TIME> <ZONE> rank => -1
<Time_Precision> ::= <Time_Fractional_Seconds_Precision> rank => 0
<Timestamp_Precision> ::= <Time_Fractional_Seconds_Precision> rank => 0
<Time_Fractional_Seconds_Precision> ::= <Unsigned_Integer> rank => 0
<Interval_Type> ::= <INTERVAL> <Interval_Qualifier> rank => 0
<Row_Type> ::= <ROW> <Row_Type_Body> rank => 0
<Gen1116> ::= <Comma> <Field_Definition> rank => 0
<Gen1116_Any> ::= <Gen1116>* rank => 0
<Row_Type_Body> ::= <Left_Paren> <Field_Definition> <Gen1116_Any> <Right_Paren> rank => 0
<Scope_Clause_Maybe> ::= <Scope_Clause> rank => 0
<Scope_Clause_Maybe> ::= rank => -1
<Reference_Type> ::= <REF> <Left_Paren> <Referenced_Type> <Right_Paren> <Scope_Clause_Maybe> rank => 0
<Scope_Clause> ::= <SCOPE> <Table_Name> rank => 0
<Referenced_Type> ::= <Path_Resolved_User_Defined_Type_Name> rank => 0
<Path_Resolved_User_Defined_Type_Name> ::= <User_Defined_Type_Name> rank => 0
<Collection_Type> ::= <Array_Type> rank => 0
                    | <Multiset_Type> rank => -1
<Gen1127> ::= <Left_Bracket_Or_Trigraph> <Unsigned_Integer> <Right_Bracket_Or_Trigraph> rank => 0
<Gen1127_Maybe> ::= <Gen1127> rank => 0
<Gen1127_Maybe> ::= rank => -1
<Array_Type> ::= <Data_Type> <ARRAY> <Gen1127_Maybe> rank => 0
<Multiset_Type> ::= <Data_Type> <MULTISET> rank => 0
<Reference_Scope_Check_Maybe> ::= <Reference_Scope_Check> rank => 0
<Reference_Scope_Check_Maybe> ::= rank => -1
<Field_Definition> ::= <Field_Name> <Data_Type> <Reference_Scope_Check_Maybe> rank => 0
<Value_Expression_Primary> ::= <Parenthesized_Value_Expression> rank => 0
                             | <Nonparenthesized_Value_Expression_Primary> rank => -1
<Parenthesized_Value_Expression> ::= <Left_Paren> <Value_Expression> <Right_Paren> rank => 0
<Nonparenthesized_Value_Expression_Primary> ::= <Unsigned_Value_Specification> rank => 0
                                              | <Column_Reference> rank => -1
                                              | <Set_Function_Specification> rank => -2
                                              | <Window_Function> rank => -3
                                              | <Scalar_Subquery> rank => -4
                                              | <Case_Expression> rank => -5
                                              | <Cast_Specification> rank => -6
                                              | <Field_Reference> rank => -7
                                              | <Subtype_Treatment> rank => -8
                                              | <Method_Invocation> rank => -9
                                              | <Static_Method_Invocation> rank => -10
                                              | <New_Specification> rank => -11
                                              | <Attribute_Or_Method_Reference> rank => -12
                                              | <Reference_Resolution> rank => -13
                                              | <Collection_Value_Constructor> rank => -14
                                              | <Array_Element_Reference> rank => -15
                                              | <Multiset_Element_Reference> rank => -16
                                              | <Routine_Invocation> rank => -17
                                              | <Next_Value_Expression> rank => -18
<Value_Specification> ::= <Literal> rank => 0
                        | <General_Value_Specification> rank => -1
<Unsigned_Value_Specification> ::= <Unsigned_Literal> rank => 0
                                 | <General_Value_Specification> rank => -1
<General_Value_Specification> ::= <Host_Parameter_Specification> rank => 0
                                | <SQL_Parameter_Reference> rank => -1
                                | <Dynamic_Parameter_Specification> rank => -2
                                | <Embedded_Variable_Specification> rank => -3
                                | <Current_Collation_Specification> rank => -4
                                | <CURRENT_DEFAULT_TRANSFORM_GROUP> rank => -5
                                | <CURRENT_PATH> rank => -6
                                | <CURRENT_ROLE> rank => -7
                                | <CURRENT_TRANSFORM_GROUP_FOR_TYPE> <Path_Resolved_User_Defined_Type_Name> rank => -8
                                | <CURRENT_USER> rank => -9
                                | <SESSION_USER> rank => -10
                                | <SYSTEM_USER> rank => -11
                                | <USER> rank => -12
                                | <VALUE> rank => -13
<Simple_Value_Specification> ::= <Literal> rank => 0
                               | <Host_Parameter_Name> rank => -1
                               | <SQL_Parameter_Reference> rank => -2
                               | <Embedded_Variable_Name> rank => -3
<Target_Specification> ::= <Host_Parameter_Specification> rank => 0
                         | <SQL_Parameter_Reference> rank => -1
                         | <Column_Reference> rank => -2
                         | <Target_Array_Element_Specification> rank => -3
                         | <Dynamic_Parameter_Specification> rank => -4
                         | <Embedded_Variable_Specification> rank => -5
<Simple_Target_Specification> ::= <Host_Parameter_Specification> rank => 0
                                | <SQL_Parameter_Reference> rank => -1
                                | <Column_Reference> rank => -2
                                | <Embedded_Variable_Name> rank => -3
<Indicator_Parameter_Maybe> ::= <Indicator_Parameter> rank => 0
<Indicator_Parameter_Maybe> ::= rank => -1
<Host_Parameter_Specification> ::= <Host_Parameter_Name> <Indicator_Parameter_Maybe> rank => 0
<Dynamic_Parameter_Specification> ::= <Question_Mark> rank => 0
<Indicator_Variable_Maybe> ::= <Indicator_Variable> rank => 0
<Indicator_Variable_Maybe> ::= rank => -1
<Embedded_Variable_Specification> ::= <Embedded_Variable_Name> <Indicator_Variable_Maybe> rank => 0
<Indicator_Maybe> ::= <INDICATOR> rank => 0
<Indicator_Maybe> ::= rank => -1
<Indicator_Variable> ::= <Indicator_Maybe> <Embedded_Variable_Name> rank => 0
<Indicator_Parameter> ::= <Indicator_Maybe> <Host_Parameter_Name> rank => 0
<Target_Array_Element_Specification> ::= <Target_Array_Reference> <Left_Bracket_Or_Trigraph> <Simple_Value_Specification> <Right_Bracket_Or_Trigraph> rank => 0
<Target_Array_Reference> ::= <SQL_Parameter_Reference> rank => 0
                           | <Column_Reference> rank => -1
<Current_Collation_Specification> ::= <CURRENT_COLLATION> <Left_Paren> <String_Value_Expression> <Right_Paren> rank => 0
<Contextually_Typed_Value_Specification> ::= <Implicitly_Typed_Value_Specification> rank => 0
                                           | <Default_Specification> rank => -1
<Implicitly_Typed_Value_Specification> ::= <Null_Specification> rank => 0
                                         | <Empty_Specification> rank => -1
<Null_Specification> ::= <NULL> rank => 0
<Empty_Specification> ::= <ARRAY> <Left_Bracket_Or_Trigraph> <Right_Bracket_Or_Trigraph> rank => 0
                        | <MULTISET> <Left_Bracket_Or_Trigraph> <Right_Bracket_Or_Trigraph> rank => -1
<Default_Specification> ::= <DEFAULT> rank => 0
<Genlex1212> ~ <Period_L0> <Identifier_L0_Internal>
<Genlex1212_Any> ~ <Genlex1212>*
<Identifier_Chain> ~ <Identifier_L0_Internal> <Genlex1212_Any>
<Basic_Identifier_Chain> ::= <Identifier_Chain> rank => 0
<Genlex1216> ~ <Lex571> <Period_L0> <Qualified_Identifier_L0> <Period_L0> <Column_Name_L0>
<Column_Reference> ::= <Basic_Identifier_Chain> rank => 0
                     | <Genlex1216> rank => -1
<SQL_Parameter_Reference> ::= <Basic_Identifier_Chain> rank => 0
<Set_Function_Specification> ::= <Aggregate_Function> rank => 0
                               | <Grouping_Operation> rank => -1
<Gen1222> ::= <Comma> <Column_Reference> rank => 0
<Gen1222_Any> ::= <Gen1222>* rank => 0
<Grouping_Operation> ::= <GROUPING> <Left_Paren> <Column_Reference> <Gen1222_Any> <Right_Paren> rank => 0
<Window_Function> ::= <Window_Function_Type> <OVER> <Window_Name_Or_Specification> rank => 0
<Window_Function_Type> ::= <Rank_Function_Type> <Left_Paren> <Right_Paren> rank => 0
                         | <ROW_NUMBER> <Left_Paren> <Right_Paren> rank => -1
                         | <Aggregate_Function> rank => -2
<Rank_Function_Type> ::= <RANK> rank => 0
                       | <DENSE_RANK> rank => -1
                       | <PERCENT_RANK> rank => -2
                       | <CUME_DIST> rank => -3
<Window_Name_Or_Specification> ::= <Window_Name> rank => 0
                                 | <In_Line_Window_Specification> rank => -1
<In_Line_Window_Specification> ::= <Window_Specification> rank => 0
<Case_Expression> ::= <Case_Abbreviation> rank => 0
                    | <Case_Specification> rank => -1
<Gen1238> ::= <Comma> <Value_Expression> rank => 0
<Gen1238_Many> ::= <Gen1238>+ rank => 0
<Case_Abbreviation> ::= <NULLIF> <Left_Paren> <Value_Expression> <Comma> <Value_Expression> <Right_Paren> rank => 0
                      | <COALESCE> <Left_Paren> <Value_Expression> <Gen1238_Many> <Right_Paren> rank => -1
<Case_Specification> ::= <Simple_Case> rank => 0
                       | <Searched_Case> rank => -1
<Simple_When_Clause_Many> ::= <Simple_When_Clause>+ rank => 0
<Else_Clause_Maybe> ::= <Else_Clause> rank => 0
<Else_Clause_Maybe> ::= rank => -1
<Simple_Case> ::= <CASE> <Case_Operand> <Simple_When_Clause_Many> <Else_Clause_Maybe> <END> rank => 0
<Searched_When_Clause_Many> ::= <Searched_When_Clause>+ rank => 0
<Searched_Case> ::= <CASE> <Searched_When_Clause_Many> <Else_Clause_Maybe> <END> rank => 0
<Simple_When_Clause> ::= <WHEN> <When_Operand> <THEN> <Result> rank => 0
<Searched_When_Clause> ::= <WHEN> <Search_Condition> <THEN> <Result> rank => 0
<Else_Clause> ::= <ELSE> <Result> rank => 0
<Case_Operand> ::= <Row_Value_Predicand> rank => 0
                 | <Overlaps_Predicate> rank => -1
<When_Operand> ::= <Row_Value_Predicand> rank => 0
                 | <Comparison_Predicate_Part_2> rank => -1
                 | <Between_Predicate_Part_2> rank => -2
                 | <In_Predicate_Part_2> rank => -3
                 | <Character_Like_Predicate_Part_2> rank => -4
                 | <Octet_Like_Predicate_Part_2> rank => -5
                 | <Similar_Predicate_Part_2> rank => -6
                 | <Null_Predicate_Part_2> rank => -7
                 | <Quantified_Comparison_Predicate_Part_2> rank => -8
                 | <Match_Predicate_Part_2> rank => -9
                 | <Overlaps_Predicate_Part_2> rank => -10
                 | <Distinct_Predicate_Part_2> rank => -11
                 | <Member_Predicate_Part_2> rank => -12
                 | <Submultiset_Predicate_Part_2> rank => -13
                 | <Set_Predicate_Part_2> rank => -14
                 | <Type_Predicate_Part_2> rank => -15
<Result> ::= <Result_Expression> rank => 0
           | <NULL> rank => -1
<Result_Expression> ::= <Value_Expression> rank => 0
<Cast_Specification> ::= <CAST> <Left_Paren> <Cast_Operand> <AS> <Cast_Target> <Right_Paren> rank => 0
<Cast_Operand> ::= <Value_Expression> rank => 0
                 | <Implicitly_Typed_Value_Specification> rank => -1
<Cast_Target> ::= <Domain_Name> rank => 0
                | <Data_Type> rank => -1
<Next_Value_Expression> ::= <NEXT> <VALUE> <FOR> <Sequence_Generator_Name> rank => 0
<Field_Reference> ::= <Value_Expression_Primary> <Period> <Field_Name> rank => 0
<Subtype_Treatment> ::= <TREAT> <Left_Paren> <Subtype_Operand> <AS> <Target_Subtype> <Right_Paren> rank => 0
<Subtype_Operand> ::= <Value_Expression> rank => 0
<Target_Subtype> ::= <Path_Resolved_User_Defined_Type_Name> rank => 0
                   | <Reference_Type> rank => -1
<Method_Invocation> ::= <Direct_Invocation> rank => 0
                      | <Generalized_Invocation> rank => -1
<SQL_Argument_List_Maybe> ::= <SQL_Argument_List> rank => 0
<SQL_Argument_List_Maybe> ::= rank => -1
<Direct_Invocation> ::= <Value_Expression_Primary> <Period> <Method_Name> <SQL_Argument_List_Maybe> rank => 0
<Generalized_Invocation> ::= <Left_Paren> <Value_Expression_Primary> <AS> <Data_Type> <Right_Paren> <Period> <Method_Name> <SQL_Argument_List_Maybe> rank => 0
<Method_Selection> ::= <Routine_Invocation> rank => 0
<Constructor_Method_Selection> ::= <Routine_Invocation> rank => 0
<Static_Method_Invocation> ::= <Path_Resolved_User_Defined_Type_Name> <Double_Colon> <Method_Name> <SQL_Argument_List_Maybe> rank => 0
<Static_Method_Selection> ::= <Routine_Invocation> rank => 0
<New_Specification> ::= <NEW> <Routine_Invocation> rank => 0
<New_Invocation> ::= <Method_Invocation> rank => 0
                   | <Routine_Invocation> rank => -1
<Attribute_Or_Method_Reference> ::= <Value_Expression_Primary> <Dereference_Operator> <Qualified_Identifier> <SQL_Argument_List_Maybe> rank => 0
<Dereference_Operator> ::= <Right_Arrow> rank => 0
<Dereference_Operation> ::= <Reference_Value_Expression> <Dereference_Operator> <Attribute_Name> rank => 0
<Method_Reference> ::= <Value_Expression_Primary> <Dereference_Operator> <Method_Name> <SQL_Argument_List> rank => 0
<Reference_Resolution> ::= <DEREF> <Left_Paren> <Reference_Value_Expression> <Right_Paren> rank => 0
<Array_Element_Reference> ::= <Array_Value_Expression> <Left_Bracket_Or_Trigraph> <Numeric_Value_Expression> <Right_Bracket_Or_Trigraph> rank => 0
<Multiset_Element_Reference> ::= <ELEMENT> <Left_Paren> <Multiset_Value_Expression> <Right_Paren> rank => 0
<Value_Expression> ::= <Common_Value_Expression> rank => 0
                     | <Boolean_Value_Expression> rank => -1
                     | <Row_Value_Expression> rank => -2
<Common_Value_Expression> ::= <Numeric_Value_Expression> rank => 0
                            | <String_Value_Expression> rank => -1
                            | <Datetime_Value_Expression> rank => -2
                            | <Interval_Value_Expression> rank => -3
                            | <User_Defined_Type_Value_Expression> rank => -4
                            | <Reference_Value_Expression> rank => -5
                            | <Collection_Value_Expression> rank => -6
<User_Defined_Type_Value_Expression> ::= <Value_Expression_Primary> rank => 0
<Reference_Value_Expression> ::= <Value_Expression_Primary> rank => 0
<Collection_Value_Expression> ::= <Array_Value_Expression> rank => 0
                                | <Multiset_Value_Expression> rank => -1
<Collection_Value_Constructor> ::= <Array_Value_Constructor> rank => 0
                                 | <Multiset_Value_Constructor> rank => -1
<Numeric_Value_Expression> ::= <Term> rank => 0
                             | <Numeric_Value_Expression> <Plus_Sign> <Term> rank => -1
                             | <Numeric_Value_Expression> <Minus_Sign> <Term> rank => -2
<Term> ::= <Factor> rank => 0
         | <Term> <Asterisk> <Factor> rank => -1
         | <Term> <Solidus> <Factor> rank => -2
<Factor> ::= <Sign_Maybe> <Numeric_Primary> rank => 0
<Numeric_Primary> ::= <Value_Expression_Primary> rank => 0
                    | <Numeric_Value_Function> rank => -1
<Numeric_Value_Function> ::= <Position_Expression> rank => 0
                           | <Extract_Expression> rank => -1
                           | <Length_Expression> rank => -2
                           | <Cardinality_Expression> rank => -3
                           | <Absolute_Value_Expression> rank => -4
                           | <Modulus_Expression> rank => -5
                           | <Natural_Logarithm> rank => -6
                           | <Exponential_Function> rank => -7
                           | <Power_Function> rank => -8
                           | <Square_Root> rank => -9
                           | <Floor_Function> rank => -10
                           | <Ceiling_Function> rank => -11
                           | <Width_Bucket_Function> rank => -12
<Position_Expression> ::= <String_Position_Expression> rank => 0
                        | <Blob_Position_Expression> rank => -1
<Gen1345> ::= <USING> <Char_Length_Units> rank => 0
<Gen1345_Maybe> ::= <Gen1345> rank => 0
<Gen1345_Maybe> ::= rank => -1
<String_Position_Expression> ::= <POSITION> <Left_Paren> <String_Value_Expression> <IN> <String_Value_Expression> <Gen1345_Maybe> <Right_Paren> rank => 0
<Blob_Position_Expression> ::= <POSITION> <Left_Paren> <Blob_Value_Expression> <IN> <Blob_Value_Expression> <Right_Paren> rank => 0
<Length_Expression> ::= <Char_Length_Expression> rank => 0
                      | <Octet_Length_Expression> rank => -1
<Gen1352> ::= <CHAR_LENGTH> rank => 0
            | <CHARACTER_LENGTH> rank => -1
<Gen1354> ::= <USING> <Char_Length_Units> rank => 0
<Gen1354_Maybe> ::= <Gen1354> rank => 0
<Gen1354_Maybe> ::= rank => -1
<Char_Length_Expression> ::= <Gen1352> <Left_Paren> <String_Value_Expression> <Gen1354_Maybe> <Right_Paren> rank => 0
<Octet_Length_Expression> ::= <OCTET_LENGTH> <Left_Paren> <String_Value_Expression> <Right_Paren> rank => 0
<Extract_Expression> ::= <EXTRACT> <Left_Paren> <Extract_Field> <FROM> <Extract_Source> <Right_Paren> rank => 0
<Extract_Field> ::= <Primary_Datetime_Field> rank => 0
                  | <Time_Zone_Field> rank => -1
<Time_Zone_Field> ::= <TIMEZONE_HOUR> rank => 0
                    | <TIMEZONE_MINUTE> rank => -1
<Extract_Source> ::= <Datetime_Value_Expression> rank => 0
                   | <Interval_Value_Expression> rank => -1
<Cardinality_Expression> ::= <CARDINALITY> <Left_Paren> <Collection_Value_Expression> <Right_Paren> rank => 0
<Absolute_Value_Expression> ::= <ABS> <Left_Paren> <Numeric_Value_Expression> <Right_Paren> rank => 0
<Modulus_Expression> ::= <MOD> <Left_Paren> <Numeric_Value_Expression> <Comma> <Numeric_Value_Expression> <Right_Paren> rank => 0
<Natural_Logarithm> ::= <LN> <Left_Paren> <Numeric_Value_Expression> <Right_Paren> rank => 0
<Exponential_Function> ::= <EXP> <Left_Paren> <Numeric_Value_Expression> <Right_Paren> rank => 0
<Power_Function> ::= <POWER> <Left_Paren> <Numeric_Value_Expression_Base> <Comma> <Numeric_Value_Expression_Exponent> <Right_Paren> rank => 0
<Numeric_Value_Expression_Base> ::= <Numeric_Value_Expression> rank => 0
<Numeric_Value_Expression_Exponent> ::= <Numeric_Value_Expression> rank => 0
<Square_Root> ::= <SQRT> <Left_Paren> <Numeric_Value_Expression> <Right_Paren> rank => 0
<Floor_Function> ::= <FLOOR> <Left_Paren> <Numeric_Value_Expression> <Right_Paren> rank => 0
<Gen1376> ::= <CEIL> rank => 0
            | <CEILING> rank => -1
<Ceiling_Function> ::= <Gen1376> <Left_Paren> <Numeric_Value_Expression> <Right_Paren> rank => 0
<Width_Bucket_Function> ::= <WIDTH_BUCKET> <Left_Paren> <Width_Bucket_Operand> <Comma> <Width_Bucket_Bound_1> <Comma> <Width_Bucket_Bound_2> <Comma> <Width_Bucket_Count> <Right_Paren> rank => 0
<Width_Bucket_Operand> ::= <Numeric_Value_Expression> rank => 0
<Width_Bucket_Bound_1> ::= <Numeric_Value_Expression> rank => 0
<Width_Bucket_Bound_2> ::= <Numeric_Value_Expression> rank => 0
<Width_Bucket_Count> ::= <Numeric_Value_Expression> rank => 0
<String_Value_Expression> ::= <Character_Value_Expression> rank => 0
                            | <Blob_Value_Expression> rank => -1
<Character_Value_Expression> ::= <Concatenation> rank => 0
                               | <Character_Factor> rank => -1
<Concatenation> ::= <Character_Value_Expression> <Concatenation_Operator> <Character_Factor> rank => 0
<Character_Factor> ::= <Character_Primary> <Collate_Clause_Maybe> rank => 0
<Character_Primary> ::= <Value_Expression_Primary> rank => 0
                      | <String_Value_Function> rank => -1
<Blob_Value_Expression> ::= <Blob_Concatenation> rank => 0
                          | <Blob_Factor> rank => -1
<Blob_Factor> ::= <Blob_Primary> rank => 0
<Blob_Primary> ::= <Value_Expression_Primary> rank => 0
                 | <String_Value_Function> rank => -1
<Blob_Concatenation> ::= <Blob_Value_Expression> <Concatenation_Operator> <Blob_Factor> rank => 0
<String_Value_Function> ::= <Character_Value_Function> rank => 0
                          | <Blob_Value_Function> rank => -1
<Character_Value_Function> ::= <Character_Substring_Function> rank => 0
                             | <Regular_Expression_Substring_Function> rank => -1
                             | <Fold> rank => -2
                             | <Transcoding> rank => -3
                             | <Character_Transliteration> rank => -4
                             | <Trim_Function> rank => -5
                             | <Character_Overlay_Function> rank => -6
                             | <Normalize_Function> rank => -7
                             | <Specific_Type_Method> rank => -8
<Gen1409> ::= <FOR> <String_Length> rank => 0
<Gen1409_Maybe> ::= <Gen1409> rank => 0
<Gen1409_Maybe> ::= rank => -1
<Gen1412> ::= <USING> <Char_Length_Units> rank => 0
<Gen1412_Maybe> ::= <Gen1412> rank => 0
<Gen1412_Maybe> ::= rank => -1
<Character_Substring_Function> ::= <SUBSTRING> <Left_Paren> <Character_Value_Expression> <FROM> <Start_Position> <Gen1409_Maybe> <Gen1412_Maybe> <Right_Paren> rank => 0
<Regular_Expression_Substring_Function> ::= <SUBSTRING> <Left_Paren> <Character_Value_Expression> <SIMILAR> <Character_Value_Expression> <ESCAPE> <Escape_Character> <Right_Paren> rank => 0
<Gen1417> ::= <UPPER> rank => 0
            | <LOWER> rank => -1
<Fold> ::= <Gen1417> <Left_Paren> <Character_Value_Expression> <Right_Paren> rank => 0
<Transcoding> ::= <CONVERT> <Left_Paren> <Character_Value_Expression> <USING> <Transcoding_Name> <Right_Paren> rank => 0
<Character_Transliteration> ::= <TRANSLATE> <Left_Paren> <Character_Value_Expression> <USING> <Transliteration_Name> <Right_Paren> rank => 0
<Trim_Function> ::= <TRIM> <Left_Paren> <Trim_Operands> <Right_Paren> rank => 0
<Trim_Specification_Maybe> ::= <Trim_Specification> rank => 0
<Trim_Specification_Maybe> ::= rank => -1
<Trim_Character_Maybe> ::= <Trim_Character> rank => 0
<Trim_Character_Maybe> ::= rank => -1
<Gen1427> ::= <Trim_Specification_Maybe> <Trim_Character_Maybe> <FROM> rank => 0
<Gen1427_Maybe> ::= <Gen1427> rank => 0
<Gen1427_Maybe> ::= rank => -1
<Trim_Operands> ::= <Gen1427_Maybe> <Trim_Source> rank => 0
<Trim_Source> ::= <Character_Value_Expression> rank => 0
<Trim_Specification> ::= <LEADING> rank => 0
                       | <TRAILING> rank => -1
                       | <BOTH> rank => -2
<Trim_Character> ::= <Character_Value_Expression> rank => 0
<Gen1436> ::= <FOR> <String_Length> rank => 0
<Gen1436_Maybe> ::= <Gen1436> rank => 0
<Gen1436_Maybe> ::= rank => -1
<Gen1439> ::= <USING> <Char_Length_Units> rank => 0
<Gen1439_Maybe> ::= <Gen1439> rank => 0
<Gen1439_Maybe> ::= rank => -1
<Character_Overlay_Function> ::= <OVERLAY> <Left_Paren> <Character_Value_Expression> <PLACING> <Character_Value_Expression> <FROM> <Start_Position> <Gen1436_Maybe> <Gen1439_Maybe> <Right_Paren> rank => 0
<Normalize_Function> ::= <NORMALIZE> <Left_Paren> <Character_Value_Expression> <Right_Paren> rank => 0
<Specific_Type_Method> ::= <User_Defined_Type_Value_Expression> <Period> <SPECIFICTYPE> rank => 0
<Blob_Value_Function> ::= <Blob_Substring_Function> rank => 0
                        | <Blob_Trim_Function> rank => -1
                        | <Blob_Overlay_Function> rank => -2
<Gen1448> ::= <FOR> <String_Length> rank => 0
<Gen1448_Maybe> ::= <Gen1448> rank => 0
<Gen1448_Maybe> ::= rank => -1
<Blob_Substring_Function> ::= <SUBSTRING> <Left_Paren> <Blob_Value_Expression> <FROM> <Start_Position> <Gen1448_Maybe> <Right_Paren> rank => 0
<Blob_Trim_Function> ::= <TRIM> <Left_Paren> <Blob_Trim_Operands> <Right_Paren> rank => 0
<Trim_Octet_Maybe> ::= <Trim_Octet> rank => 0
<Trim_Octet_Maybe> ::= rank => -1
<Gen1455> ::= <Trim_Specification_Maybe> <Trim_Octet_Maybe> <FROM> rank => 0
<Gen1455_Maybe> ::= <Gen1455> rank => 0
<Gen1455_Maybe> ::= rank => -1
<Blob_Trim_Operands> ::= <Gen1455_Maybe> <Blob_Trim_Source> rank => 0
<Blob_Trim_Source> ::= <Blob_Value_Expression> rank => 0
<Trim_Octet> ::= <Blob_Value_Expression> rank => 0
<Gen1461> ::= <FOR> <String_Length> rank => 0
<Gen1461_Maybe> ::= <Gen1461> rank => 0
<Gen1461_Maybe> ::= rank => -1
<Blob_Overlay_Function> ::= <OVERLAY> <Left_Paren> <Blob_Value_Expression> <PLACING> <Blob_Value_Expression> <FROM> <Start_Position> <Gen1461_Maybe> <Right_Paren> rank => 0
<Start_Position> ::= <Numeric_Value_Expression> rank => 0
<String_Length> ::= <Numeric_Value_Expression> rank => 0
<Datetime_Value_Expression> ::= <Datetime_Term> rank => 0
                              | <Interval_Value_Expression> <Plus_Sign> <Datetime_Term> rank => -1
                              | <Datetime_Value_Expression> <Plus_Sign> <Interval_Term> rank => -2
                              | <Datetime_Value_Expression> <Minus_Sign> <Interval_Term> rank => -3
<Datetime_Term> ::= <Datetime_Factor> rank => 0
<Time_Zone_Maybe> ::= <Time_Zone> rank => 0
<Time_Zone_Maybe> ::= rank => -1
<Datetime_Factor> ::= <Datetime_Primary> <Time_Zone_Maybe> rank => 0
<Datetime_Primary> ::= <Value_Expression_Primary> rank => 0
                     | <Datetime_Value_Function> rank => -1
<Time_Zone> ::= <AT> <Time_Zone_Specifier> rank => 0
<Time_Zone_Specifier> ::= <LOCAL> rank => 0
                        | <TIME> <ZONE> <Interval_Primary> rank => -1
<Datetime_Value_Function> ::= <Current_Date_Value_Function> rank => 0
                            | <Current_Time_Value_Function> rank => -1
                            | <Current_Timestamp_Value_Function> rank => -2
                            | <Current_Local_Time_Value_Function> rank => -3
                            | <Current_Local_Timestamp_Value_Function> rank => -4
<Current_Date_Value_Function> ::= <CURRENT_DATE> rank => 0
<Gen1486> ::= <Left_Paren> <Time_Precision> <Right_Paren> rank => 0
<Gen1486_Maybe> ::= <Gen1486> rank => 0
<Gen1486_Maybe> ::= rank => -1
<Current_Time_Value_Function> ::= <CURRENT_TIME> <Gen1486_Maybe> rank => 0
<Gen1490> ::= <Left_Paren> <Time_Precision> <Right_Paren> rank => 0
<Gen1490_Maybe> ::= <Gen1490> rank => 0
<Gen1490_Maybe> ::= rank => -1
<Current_Local_Time_Value_Function> ::= <LOCALTIME> <Gen1490_Maybe> rank => 0
<Gen1494> ::= <Left_Paren> <Timestamp_Precision> <Right_Paren> rank => 0
<Gen1494_Maybe> ::= <Gen1494> rank => 0
<Gen1494_Maybe> ::= rank => -1
<Current_Timestamp_Value_Function> ::= <CURRENT_TIMESTAMP> <Gen1494_Maybe> rank => 0
<Gen1498> ::= <Left_Paren> <Timestamp_Precision> <Right_Paren> rank => 0
<Gen1498_Maybe> ::= <Gen1498> rank => 0
<Gen1498_Maybe> ::= rank => -1
<Current_Local_Timestamp_Value_Function> ::= <LOCALTIMESTAMP> <Gen1498_Maybe> rank => 0
<Interval_Value_Expression> ::= <Interval_Term> rank => 0
                              | <Interval_Value_Expression_1> <Plus_Sign> <Interval_Term_1> rank => -1
                              | <Interval_Value_Expression_1> <Minus_Sign> <Interval_Term_1> rank => -2
                              | <Left_Paren> <Datetime_Value_Expression> <Minus_Sign> <Datetime_Term> <Right_Paren> <Interval_Qualifier> rank => -3
<Interval_Term> ::= <Interval_Factor> rank => 0
                  | <Interval_Term_2> <Asterisk> <Factor> rank => -1
                  | <Interval_Term_2> <Solidus> <Factor> rank => -2
                  | <Term> <Asterisk> <Interval_Factor> rank => -3
<Interval_Factor> ::= <Sign_Maybe> <Interval_Primary> rank => 0
<Interval_Qualifier_Maybe> ::= <Interval_Qualifier> rank => 0
<Interval_Qualifier_Maybe> ::= rank => -1
<Interval_Primary> ::= <Value_Expression_Primary> <Interval_Qualifier_Maybe> rank => 0
                     | <Interval_Value_Function> rank => -1
<Interval_Value_Expression_1> ::= <Interval_Value_Expression> rank => 0
<Interval_Term_1> ::= <Interval_Term> rank => 0
<Interval_Term_2> ::= <Interval_Term> rank => 0
<Interval_Value_Function> ::= <Interval_Absolute_Value_Function> rank => 0
<Interval_Absolute_Value_Function> ::= <ABS> <Left_Paren> <Interval_Value_Expression> <Right_Paren> rank => 0
<Boolean_Value_Expression> ::= <Boolean_Term> rank => 0
                             | <Boolean_Value_Expression> <OR> <Boolean_Term> rank => -1
<Boolean_Term> ::= <Boolean_Factor> rank => 0
                 | <Boolean_Term> <AND> <Boolean_Factor> rank => -1
<Not_Maybe> ::= <NOT> rank => 0
<Not_Maybe> ::= rank => -1
<Boolean_Factor> ::= <Not_Maybe> <Boolean_Test> rank => 0
<Gen1527> ::= <IS> <Not_Maybe> <Truth_Value> rank => 0
<Gen1527_Maybe> ::= <Gen1527> rank => 0
<Gen1527_Maybe> ::= rank => -1
<Boolean_Test> ::= <Boolean_Primary> <Gen1527_Maybe> rank => 0
<Truth_Value> ::= <TRUE> rank => 0
                | <FALSE> rank => -1
                | <UNKNOWN> rank => -2
<Boolean_Primary> ::= <Predicate> rank => 0
                    | <Boolean_Predicand> rank => -1
<Boolean_Predicand> ::= <Parenthesized_Boolean_Value_Expression> rank => 0
                      | <Nonparenthesized_Value_Expression_Primary> rank => -1
<Parenthesized_Boolean_Value_Expression> ::= <Left_Paren> <Boolean_Value_Expression> <Right_Paren> rank => 0
<Array_Value_Expression> ::= <Array_Concatenation> rank => 0
                           | <Array_Factor> rank => -1
<Array_Concatenation> ::= <Array_Value_Expression_1> <Concatenation_Operator> <Array_Factor> rank => 0
<Array_Value_Expression_1> ::= <Array_Value_Expression> rank => 0
<Array_Factor> ::= <Value_Expression_Primary> rank => 0
<Array_Value_Constructor> ::= <Array_Value_Constructor_By_Enumeration> rank => 0
                            | <Array_Value_Constructor_By_Query> rank => -1
<Array_Value_Constructor_By_Enumeration> ::= <ARRAY> <Left_Bracket_Or_Trigraph> <Array_Element_List> <Right_Bracket_Or_Trigraph> rank => 0
<Gen1547> ::= <Comma> <Array_Element> rank => 0
<Gen1547_Any> ::= <Gen1547>* rank => 0
<Array_Element_List> ::= <Array_Element> <Gen1547_Any> rank => 0
<Array_Element> ::= <Value_Expression> rank => 0
<Order_By_Clause_Maybe> ::= <Order_By_Clause> rank => 0
<Order_By_Clause_Maybe> ::= rank => -1
<Array_Value_Constructor_By_Query> ::= <ARRAY> <Left_Paren> <Query_Expression> <Order_By_Clause_Maybe> <Right_Paren> rank => 0
<Gen1554> ::= <ALL> rank => 0
            | <DISTINCT> rank => -1
<Gen1556> ::= <ALL> rank => 0
            | <DISTINCT> rank => -1
<Multiset_Value_Expression> ::= <Multiset_Term> rank => 0
                              | <Multiset_Value_Expression> <MULTISET> <UNION> <Gen1554> <Multiset_Term> rank => -1
                              | <Multiset_Value_Expression> <MULTISET> <EXCEPT> <Gen1556> <Multiset_Term> rank => -2
<Gen1561> ::= <ALL> rank => 0
            | <DISTINCT> rank => -1
<Multiset_Term> ::= <Multiset_Primary> rank => 0
                  | <Multiset_Term> <MULTISET> <INTERSECT> <Gen1561> <Multiset_Primary> rank => -1
<Multiset_Primary> ::= <Multiset_Value_Function> rank => 0
                     | <Value_Expression_Primary> rank => -1
<Multiset_Value_Function> ::= <Multiset_Set_Function> rank => 0
<Multiset_Set_Function> ::= <SET> <Left_Paren> <Multiset_Value_Expression> <Right_Paren> rank => 0
<Multiset_Value_Constructor> ::= <Multiset_Value_Constructor_By_Enumeration> rank => 0
                               | <Multiset_Value_Constructor_By_Query> rank => -1
                               | <Table_Value_Constructor_By_Query> rank => -2
<Multiset_Value_Constructor_By_Enumeration> ::= <MULTISET> <Left_Bracket_Or_Trigraph> <Multiset_Element_List> <Right_Bracket_Or_Trigraph> rank => 0
<Gen1573> ::= <Comma> <Multiset_Element> rank => 0
<Gen1573_Any> ::= <Gen1573>* rank => 0
<Multiset_Element_List> ::= <Multiset_Element> <Gen1573_Any> rank => 0
<Multiset_Element> ::= <Value_Expression> rank => 0
<Multiset_Value_Constructor_By_Query> ::= <MULTISET> <Left_Paren> <Query_Expression> <Right_Paren> rank => 0
<Table_Value_Constructor_By_Query> ::= <TABLE> <Left_Paren> <Query_Expression> <Right_Paren> rank => 0
<Row_Value_Constructor> ::= <Common_Value_Expression> rank => 0
                          | <Boolean_Value_Expression> rank => -1
                          | <Explicit_Row_Value_Constructor> rank => -2
<Explicit_Row_Value_Constructor> ::= <Left_Paren> <Row_Value_Constructor_Element> <Comma> <Row_Value_Constructor_Element_List> <Right_Paren> rank => 0
                                   | <ROW> <Left_Paren> <Row_Value_Constructor_Element_List> <Right_Paren> rank => -1
                                   | <Row_Subquery> rank => -2
<Gen1585> ::= <Comma> <Row_Value_Constructor_Element> rank => 0
<Gen1585_Any> ::= <Gen1585>* rank => 0
<Row_Value_Constructor_Element_List> ::= <Row_Value_Constructor_Element> <Gen1585_Any> rank => 0
<Row_Value_Constructor_Element> ::= <Value_Expression> rank => 0
<Contextually_Typed_Row_Value_Constructor> ::= <Common_Value_Expression> rank => 0
                                             | <Boolean_Value_Expression> rank => -1
                                             | <Contextually_Typed_Value_Specification> rank => -2
                                             | <Left_Paren> <Contextually_Typed_Row_Value_Constructor_Element> <Comma> <Contextually_Typed_Row_Value_Constructor_Element_List> <Right_Paren> rank => -3
                                             | <ROW> <Left_Paren> <Contextually_Typed_Row_Value_Constructor_Element_List> <Right_Paren> rank => -4
<Gen1594> ::= <Comma> <Contextually_Typed_Row_Value_Constructor_Element> rank => 0
<Gen1594_Any> ::= <Gen1594>* rank => 0
<Contextually_Typed_Row_Value_Constructor_Element_List> ::= <Contextually_Typed_Row_Value_Constructor_Element> <Gen1594_Any> rank => 0
<Contextually_Typed_Row_Value_Constructor_Element> ::= <Value_Expression> rank => 0
                                                     | <Contextually_Typed_Value_Specification> rank => -1
<Row_Value_Constructor_Predicand> ::= <Common_Value_Expression> rank => 0
                                    | <Boolean_Predicand> rank => -1
                                    | <Explicit_Row_Value_Constructor> rank => -2
<Row_Value_Expression> ::= <Row_Value_Special_Case> rank => 0
                         | <Explicit_Row_Value_Constructor> rank => -1
<Table_Row_Value_Expression> ::= <Row_Value_Special_Case> rank => 0
                               | <Row_Value_Constructor> rank => -1
<Contextually_Typed_Row_Value_Expression> ::= <Row_Value_Special_Case> rank => 0
                                            | <Contextually_Typed_Row_Value_Constructor> rank => -1
<Row_Value_Predicand> ::= <Row_Value_Special_Case> rank => 0
                        | <Row_Value_Constructor_Predicand> rank => -1
<Row_Value_Special_Case> ::= <Nonparenthesized_Value_Expression_Primary> rank => 0
<Table_Value_Constructor> ::= <VALUES> <Row_Value_Expression_List> rank => 0
<Gen1612> ::= <Comma> <Table_Row_Value_Expression> rank => 0
<Gen1612_Any> ::= <Gen1612>* rank => 0
<Row_Value_Expression_List> ::= <Table_Row_Value_Expression> <Gen1612_Any> rank => 0
<Contextually_Typed_Table_Value_Constructor> ::= <VALUES> <Contextually_Typed_Row_Value_Expression_List> rank => 0
<Gen1616> ::= <Comma> <Contextually_Typed_Row_Value_Expression> rank => 0
<Gen1616_Any> ::= <Gen1616>* rank => 0
<Contextually_Typed_Row_Value_Expression_List> ::= <Contextually_Typed_Row_Value_Expression> <Gen1616_Any> rank => 0
<Where_Clause_Maybe> ::= <Where_Clause> rank => 0
<Where_Clause_Maybe> ::= rank => -1
<Group_By_Clause_Maybe> ::= <Group_By_Clause> rank => 0
<Group_By_Clause_Maybe> ::= rank => -1
<Having_Clause_Maybe> ::= <Having_Clause> rank => 0
<Having_Clause_Maybe> ::= rank => -1
<Window_Clause_Maybe> ::= <Window_Clause> rank => 0
<Window_Clause_Maybe> ::= rank => -1
<Table_Expression> ::= <From_Clause> <Where_Clause_Maybe> <Group_By_Clause_Maybe> <Having_Clause_Maybe> <Window_Clause_Maybe> rank => 0
<From_Clause> ::= <FROM> <Table_Reference_List> rank => 0
<Gen1629> ::= <Comma> <Table_Reference> rank => 0
<Gen1629_Any> ::= <Gen1629>* rank => 0
<Table_Reference_List> ::= <Table_Reference> <Gen1629_Any> rank => 0
<Sample_Clause_Maybe> ::= <Sample_Clause> rank => 0
<Sample_Clause_Maybe> ::= rank => -1
<Table_Reference> ::= <Table_Primary_Or_Joined_Table> <Sample_Clause_Maybe> rank => 0
<Table_Primary_Or_Joined_Table> ::= <Table_Primary> rank => 0
                                  | <Joined_Table> rank => -1
<Repeatable_Clause_Maybe> ::= <Repeatable_Clause> rank => 0
<Repeatable_Clause_Maybe> ::= rank => -1
<Sample_Clause> ::= <TABLESAMPLE> <Sample_Method> <Left_Paren> <Sample_Percentage> <Right_Paren> <Repeatable_Clause_Maybe> rank => 0
<Sample_Method> ::= <BERNOULLI> rank => 0
                  | <SYSTEM> rank => -1
<Repeatable_Clause> ::= <REPEATABLE> <Left_Paren> <Repeat_Argument> <Right_Paren> rank => 0
<Sample_Percentage> ::= <Numeric_Value_Expression> rank => 0
<Repeat_Argument> ::= <Numeric_Value_Expression> rank => 0
<As_Maybe> ::= <AS> rank => 0
<As_Maybe> ::= rank => -1
<Gen1647> ::= <Left_Paren> <Derived_Column_List> <Right_Paren> rank => 0
<Gen1647_Maybe> ::= <Gen1647> rank => 0
<Gen1647_Maybe> ::= rank => -1
<Gen1650> ::= <As_Maybe> <Correlation_Name> <Gen1647_Maybe> rank => 0
<Gen1650_Maybe> ::= <Gen1650> rank => 0
<Gen1650_Maybe> ::= rank => -1
<Gen1653> ::= <Left_Paren> <Derived_Column_List> <Right_Paren> rank => 0
<Gen1653_Maybe> ::= <Gen1653> rank => 0
<Gen1653_Maybe> ::= rank => -1
<Gen1656> ::= <Left_Paren> <Derived_Column_List> <Right_Paren> rank => 0
<Gen1656_Maybe> ::= <Gen1656> rank => 0
<Gen1656_Maybe> ::= rank => -1
<Gen1659> ::= <Left_Paren> <Derived_Column_List> <Right_Paren> rank => 0
<Gen1659_Maybe> ::= <Gen1659> rank => 0
<Gen1659_Maybe> ::= rank => -1
<Gen1662> ::= <Left_Paren> <Derived_Column_List> <Right_Paren> rank => 0
<Gen1662_Maybe> ::= <Gen1662> rank => 0
<Gen1662_Maybe> ::= rank => -1
<Gen1665> ::= <Left_Paren> <Derived_Column_List> <Right_Paren> rank => 0
<Gen1665_Maybe> ::= <Gen1665> rank => 0
<Gen1665_Maybe> ::= rank => -1
<Gen1668> ::= <As_Maybe> <Correlation_Name> <Gen1665_Maybe> rank => 0
<Gen1668_Maybe> ::= <Gen1668> rank => 0
<Gen1668_Maybe> ::= rank => -1
<Table_Primary> ::= <Table_Or_Query_Name> <Gen1650_Maybe> rank => 0
                  | <Derived_Table> <As_Maybe> <Correlation_Name> <Gen1653_Maybe> rank => -1
                  | <Lateral_Derived_Table> <As_Maybe> <Correlation_Name> <Gen1656_Maybe> rank => -2
                  | <Collection_Derived_Table> <As_Maybe> <Correlation_Name> <Gen1659_Maybe> rank => -3
                  | <Table_Function_Derived_Table> <As_Maybe> <Correlation_Name> <Gen1662_Maybe> rank => -4
                  | <Only_Spec> <Gen1668_Maybe> rank => -5
                  | <Left_Paren> <Joined_Table> <Right_Paren> rank => -6
<Only_Spec> ::= <ONLY> <Left_Paren> <Table_Or_Query_Name> <Right_Paren> rank => 0
<Lateral_Derived_Table> ::= <LATERAL> <Table_Subquery> rank => 0
<Gen1680> ::= <WITH> <ORDINALITY> rank => 0
<Gen1680_Maybe> ::= <Gen1680> rank => 0
<Gen1680_Maybe> ::= rank => -1
<Collection_Derived_Table> ::= <UNNEST> <Left_Paren> <Collection_Value_Expression> <Right_Paren> <Gen1680_Maybe> rank => 0
<Table_Function_Derived_Table> ::= <TABLE> <Left_Paren> <Collection_Value_Expression> <Right_Paren> rank => 0
<Derived_Table> ::= <Table_Subquery> rank => 0
<Table_Or_Query_Name> ::= <Table_Name> rank => 0
                        | <Query_Name> rank => -1
<Derived_Column_List> ::= <Column_Name_List> rank => 0
<Gen1689> ::= <Comma> <Column_Name> rank => 0
<Gen1689_Any> ::= <Gen1689>* rank => 0
<Column_Name_List> ::= <Column_Name> <Gen1689_Any> rank => 0
<Joined_Table> ::= <Cross_Join> rank => 0
                 | <Qualified_Join> rank => -1
                 | <Natural_Join> rank => -2
                 | <Union_Join> rank => -3
<Cross_Join> ::= <Table_Reference> <CROSS> <JOIN> <Table_Primary> rank => 0
<Join_Type_Maybe> ::= <Join_Type> rank => 0
<Join_Type_Maybe> ::= rank => -1
<Qualified_Join> ::= <Table_Reference> <Join_Type_Maybe> <JOIN> <Table_Reference> <Join_Specification> rank => 0
<Natural_Join> ::= <Table_Reference> <NATURAL> <Join_Type_Maybe> <JOIN> <Table_Primary> rank => 0
<Union_Join> ::= <Table_Reference> <UNION> <JOIN> <Table_Primary> rank => 0
<Join_Specification> ::= <Join_Condition> rank => 0
                       | <Named_Columns_Join> rank => -1
<Join_Condition> ::= <ON> <Search_Condition> rank => 0
<Named_Columns_Join> ::= <USING> <Left_Paren> <Join_Column_List> <Right_Paren> rank => 0
<Outer_Maybe> ::= <OUTER> rank => 0
<Outer_Maybe> ::= rank => -1
<Join_Type> ::= <INNER> rank => 0
              | <Outer_Join_Type> <Outer_Maybe> rank => -1
<Outer_Join_Type> ::= <LEFT> rank => 0
                    | <RIGHT> rank => -1
                    | <FULL> rank => -2
<Join_Column_List> ::= <Column_Name_List> rank => 0
<Where_Clause> ::= <WHERE> <Search_Condition> rank => 0
<Set_Quantifier_Maybe> ::= <Set_Quantifier> rank => 0
<Set_Quantifier_Maybe> ::= rank => -1
<Group_By_Clause> ::= <GROUP> <BY> <Set_Quantifier_Maybe> <Grouping_Element_List> rank => 0
<Gen1718> ::= <Comma> <Grouping_Element> rank => 0
<Gen1718_Any> ::= <Gen1718>* rank => 0
<Grouping_Element_List> ::= <Grouping_Element> <Gen1718_Any> rank => 0
<Grouping_Element> ::= <Ordinary_Grouping_Set> rank => 0
                     | <Rollup_List> rank => -1
                     | <Cube_List> rank => -2
                     | <Grouping_Sets_Specification> rank => -3
                     | <Empty_Grouping_Set> rank => -4
<Ordinary_Grouping_Set> ::= <Grouping_Column_Reference> rank => 0
                          | <Left_Paren> <Grouping_Column_Reference_List> <Right_Paren> rank => -1
<Grouping_Column_Reference> ::= <Column_Reference> <Collate_Clause_Maybe> rank => 0
<Gen1729> ::= <Comma> <Grouping_Column_Reference> rank => 0
<Gen1729_Any> ::= <Gen1729>* rank => 0
<Grouping_Column_Reference_List> ::= <Grouping_Column_Reference> <Gen1729_Any> rank => 0
<Rollup_List> ::= <ROLLUP> <Left_Paren> <Ordinary_Grouping_Set_List> <Right_Paren> rank => 0
<Gen1733> ::= <Comma> <Ordinary_Grouping_Set> rank => 0
<Gen1733_Any> ::= <Gen1733>* rank => 0
<Ordinary_Grouping_Set_List> ::= <Ordinary_Grouping_Set> <Gen1733_Any> rank => 0
<Cube_List> ::= <CUBE> <Left_Paren> <Ordinary_Grouping_Set_List> <Right_Paren> rank => 0
<Grouping_Sets_Specification> ::= <GROUPING> <SETS> <Left_Paren> <Grouping_Set_List> <Right_Paren> rank => 0
<Gen1738> ::= <Comma> <Grouping_Set> rank => 0
<Gen1738_Any> ::= <Gen1738>* rank => 0
<Grouping_Set_List> ::= <Grouping_Set> <Gen1738_Any> rank => 0
<Grouping_Set> ::= <Ordinary_Grouping_Set> rank => 0
                 | <Rollup_List> rank => -1
                 | <Cube_List> rank => -2
                 | <Grouping_Sets_Specification> rank => -3
                 | <Empty_Grouping_Set> rank => -4
<Empty_Grouping_Set> ::= <Left_Paren> <Right_Paren> rank => 0
<Having_Clause> ::= <HAVING> <Search_Condition> rank => 0
<Window_Clause> ::= <WINDOW> <Window_Definition_List> rank => 0
<Gen1749> ::= <Comma> <Window_Definition> rank => 0
<Gen1749_Any> ::= <Gen1749>* rank => 0
<Window_Definition_List> ::= <Window_Definition> <Gen1749_Any> rank => 0
<Window_Definition> ::= <New_Window_Name> <AS> <Window_Specification> rank => 0
<New_Window_Name> ::= <Window_Name> rank => 0
<Window_Specification> ::= <Left_Paren> <Window_Specification_Details> <Right_Paren> rank => 0
<Existing_Window_Name_Maybe> ::= <Existing_Window_Name> rank => 0
<Existing_Window_Name_Maybe> ::= rank => -1
<Window_Partition_Clause_Maybe> ::= <Window_Partition_Clause> rank => 0
<Window_Partition_Clause_Maybe> ::= rank => -1
<Window_Order_Clause_Maybe> ::= <Window_Order_Clause> rank => 0
<Window_Order_Clause_Maybe> ::= rank => -1
<Window_Frame_Clause_Maybe> ::= <Window_Frame_Clause> rank => 0
<Window_Frame_Clause_Maybe> ::= rank => -1
<Window_Specification_Details> ::= <Existing_Window_Name_Maybe> <Window_Partition_Clause_Maybe> <Window_Order_Clause_Maybe> <Window_Frame_Clause_Maybe> rank => 0
<Existing_Window_Name> ::= <Window_Name> rank => 0
<Window_Partition_Clause> ::= <PARTITION> <BY> <Window_Partition_Column_Reference_List> rank => 0
<Gen1766> ::= <Comma> <Window_Partition_Column_Reference> rank => 0
<Gen1766_Any> ::= <Gen1766>* rank => 0
<Window_Partition_Column_Reference_List> ::= <Window_Partition_Column_Reference> <Gen1766_Any> rank => 0
<Window_Partition_Column_Reference> ::= <Column_Reference> <Collate_Clause_Maybe> rank => 0
<Window_Order_Clause> ::= <ORDER> <BY> <Sort_Specification_List> rank => 0
<Window_Frame_Exclusion_Maybe> ::= <Window_Frame_Exclusion> rank => 0
<Window_Frame_Exclusion_Maybe> ::= rank => -1
<Window_Frame_Clause> ::= <Window_Frame_Units> <Window_Frame_Extent> <Window_Frame_Exclusion_Maybe> rank => 0
<Window_Frame_Units> ::= <ROWS> rank => 0
                       | <RANGE> rank => -1
<Window_Frame_Extent> ::= <Window_Frame_Start> rank => 0
                        | <Window_Frame_Between> rank => -1
<Window_Frame_Start> ::= <UNBOUNDED> <PRECEDING> rank => 0
                       | <Window_Frame_Preceding> rank => -1
                       | <CURRENT> <ROW> rank => -2
<Window_Frame_Preceding> ::= <Unsigned_Value_Specification> <PRECEDING> rank => 0
<Window_Frame_Between> ::= <BETWEEN> <Window_Frame_Bound_1> <AND> <Window_Frame_Bound_2> rank => 0
<Window_Frame_Bound_1> ::= <Window_Frame_Bound> rank => 0
<Window_Frame_Bound_2> ::= <Window_Frame_Bound> rank => 0
<Window_Frame_Bound> ::= <Window_Frame_Start> rank => 0
                       | <UNBOUNDED> <FOLLOWING> rank => -1
                       | <Window_Frame_Following> rank => -2
<Window_Frame_Following> ::= <Unsigned_Value_Specification> <FOLLOWING> rank => 0
<Window_Frame_Exclusion> ::= <EXCLUDE> <CURRENT> <ROW> rank => 0
                           | <EXCLUDE> <GROUP> rank => -1
                           | <EXCLUDE> <TIES> rank => -2
                           | <EXCLUDE> <NO> <OTHERS> rank => -3
<Query_Specification> ::= <SELECT> <Set_Quantifier_Maybe> <Select_List> <Table_Expression> rank => 0
<Gen1794> ::= <Comma> <Select_Sublist> rank => 0
<Gen1794_Any> ::= <Gen1794>* rank => 0
<Select_List> ::= <Asterisk> rank => 0
                | <Select_Sublist> <Gen1794_Any> rank => -1
<Select_Sublist> ::= <Derived_Column> rank => 0
                   | <Qualified_Asterisk> rank => -1
<Genlex1800> ~ <Asterisked_Identifier_Chain_L0> <Period_L0> <Asterisk_L0>
<Qualified_Asterisk> ::= <Genlex1800> rank => 0
                       | <All_Fields_Reference> rank => -1
<Genlex1803> ~ <Period_L0> <Asterisked_Identifier_L0>
<Genlex1803_Any> ~ <Genlex1803>*
<Asterisked_Identifier_Chain_L0> ~ <Asterisked_Identifier_L0> <Genlex1803_Any>
<Asterisked_Identifier_L0> ~ <Identifier_L0_Internal>
<As_Clause_Maybe> ::= <As_Clause> rank => 0
<As_Clause_Maybe> ::= rank => -1
<Derived_Column> ::= <Value_Expression> <As_Clause_Maybe> rank => 0
<As_Clause> ::= <As_Maybe> <Column_Name> rank => 0
<Gen1811> ::= <AS> <Left_Paren> <All_Fields_Column_Name_List> <Right_Paren> rank => 0
<Gen1811_Maybe> ::= <Gen1811> rank => 0
<Gen1811_Maybe> ::= rank => -1
<All_Fields_Reference> ::= <Value_Expression_Primary> <Period> <Asterisk> <Gen1811_Maybe> rank => 0
<All_Fields_Column_Name_List> ::= <Column_Name_List> rank => 0
<With_Clause_Maybe> ::= <With_Clause> rank => 0
<With_Clause_Maybe> ::= rank => -1
<Query_Expression> ::= <With_Clause_Maybe> <Query_Expression_Body> rank => 0
<Recursive_Maybe> ::= <RECURSIVE> rank => 0
<Recursive_Maybe> ::= rank => -1
<With_Clause> ::= <WITH> <Recursive_Maybe> <With_List> rank => 0
<Gen1822> ::= <Comma> <With_List_Element> rank => 0
<Gen1822_Any> ::= <Gen1822>* rank => 0
<With_List> ::= <With_List_Element> <Gen1822_Any> rank => 0
<Gen1825> ::= <Left_Paren> <With_Column_List> <Right_Paren> rank => 0
<Gen1825_Maybe> ::= <Gen1825> rank => 0
<Gen1825_Maybe> ::= rank => -1
<Search_Or_Cycle_Clause_Maybe> ::= <Search_Or_Cycle_Clause> rank => 0
<Search_Or_Cycle_Clause_Maybe> ::= rank => -1
<With_List_Element> ::= <Query_Name> <Gen1825_Maybe> <AS> <Left_Paren> <Query_Expression> <Right_Paren> <Search_Or_Cycle_Clause_Maybe> rank => 0
<With_Column_List> ::= <Column_Name_List> rank => 0
<Query_Expression_Body> ::= <Non_Join_Query_Expression> rank => 0
                          | <Joined_Table> rank => -1
<Gen1834> ::= <ALL> rank => 0
            | <DISTINCT> rank => -1
<Gen1834_Maybe> ::= <Gen1834> rank => 0
<Gen1834_Maybe> ::= rank => -1
<Corresponding_Spec_Maybe> ::= <Corresponding_Spec> rank => 0
<Corresponding_Spec_Maybe> ::= rank => -1
<Gen1840> ::= <ALL> rank => 0
            | <DISTINCT> rank => -1
<Gen1840_Maybe> ::= <Gen1840> rank => 0
<Gen1840_Maybe> ::= rank => -1
<Non_Join_Query_Expression> ::= <Non_Join_Query_Term> rank => 0
                              | <Query_Expression_Body> <UNION> <Gen1834_Maybe> <Corresponding_Spec_Maybe> <Query_Term> rank => -1
                              | <Query_Expression_Body> <EXCEPT> <Gen1840_Maybe> <Corresponding_Spec_Maybe> <Query_Term> rank => -2
<Query_Term> ::= <Non_Join_Query_Term> rank => 0
               | <Joined_Table> rank => -1
<Gen1849> ::= <ALL> rank => 0
            | <DISTINCT> rank => -1
<Gen1849_Maybe> ::= <Gen1849> rank => 0
<Gen1849_Maybe> ::= rank => -1
<Non_Join_Query_Term> ::= <Non_Join_Query_Primary> rank => 0
                        | <Query_Term> <INTERSECT> <Gen1849_Maybe> <Corresponding_Spec_Maybe> <Query_Primary> rank => -1
<Query_Primary> ::= <Non_Join_Query_Primary> rank => 0
                  | <Joined_Table> rank => -1
<Non_Join_Query_Primary> ::= <Simple_Table> rank => 0
                           | <Left_Paren> <Non_Join_Query_Expression> <Right_Paren> rank => -1
<Simple_Table> ::= <Query_Specification> rank => 0
                 | <Table_Value_Constructor> rank => -1
                 | <Explicit_Table> rank => -2
<Explicit_Table> ::= <TABLE> <Table_Or_Query_Name> rank => 0
<Gen1863> ::= <BY> <Left_Paren> <Corresponding_Column_List> <Right_Paren> rank => 0
<Gen1863_Maybe> ::= <Gen1863> rank => 0
<Gen1863_Maybe> ::= rank => -1
<Corresponding_Spec> ::= <CORRESPONDING> <Gen1863_Maybe> rank => 0
<Corresponding_Column_List> ::= <Column_Name_List> rank => 0
<Search_Or_Cycle_Clause> ::= <Search_Clause> rank => 0
                           | <Cycle_Clause> rank => -1
                           | <Search_Clause> <Cycle_Clause> rank => -2
<Search_Clause> ::= <SEARCH> <Recursive_Search_Order> <SET> <Sequence_Column> rank => 0
<Recursive_Search_Order> ::= <DEPTH> <FIRST> <BY> <Sort_Specification_List> rank => 0
                           | <BREADTH> <FIRST> <BY> <Sort_Specification_List> rank => -1
<Sequence_Column> ::= <Column_Name> rank => 0
<Cycle_Clause> ::= <CYCLE> <Cycle_Column_List> <SET> <Cycle_Mark_Column> <TO> <Cycle_Mark_Value> <DEFAULT> <Non_Cycle_Mark_Value> <USING> <Path_Column> rank => 0
<Gen1876> ::= <Comma> <Cycle_Column> rank => 0
<Gen1876_Any> ::= <Gen1876>* rank => 0
<Cycle_Column_List> ::= <Cycle_Column> <Gen1876_Any> rank => 0
<Cycle_Column> ::= <Column_Name> rank => 0
<Cycle_Mark_Column> ::= <Column_Name> rank => 0
<Path_Column> ::= <Column_Name> rank => 0
<Cycle_Mark_Value> ::= <Value_Expression> rank => 0
<Non_Cycle_Mark_Value> ::= <Value_Expression> rank => 0
<Scalar_Subquery> ::= <Subquery> rank => 0
<Row_Subquery> ::= <Subquery> rank => 0
<Table_Subquery> ::= <Subquery> rank => 0
<Subquery> ::= <Left_Paren> <Query_Expression> <Right_Paren> rank => 0
<Predicate> ::= <Comparison_Predicate> rank => 0
              | <Between_Predicate> rank => -1
              | <In_Predicate> rank => -2
              | <Like_Predicate> rank => -3
              | <Similar_Predicate> rank => -4
              | <Null_Predicate> rank => -5
              | <Quantified_Comparison_Predicate> rank => -6
              | <Exists_Predicate> rank => -7
              | <Unique_Predicate> rank => -8
              | <Normalized_Predicate> rank => -9
              | <Match_Predicate> rank => -10
              | <Overlaps_Predicate> rank => -11
              | <Distinct_Predicate> rank => -12
              | <Member_Predicate> rank => -13
              | <Submultiset_Predicate> rank => -14
              | <Set_Predicate> rank => -15
              | <Type_Predicate> rank => -16
<Comparison_Predicate> ::= <Row_Value_Predicand> <Comparison_Predicate_Part_2> rank => 0
<Comparison_Predicate_Part_2> ::= <Comp_Op> <Row_Value_Predicand> rank => 0
<Comp_Op> ::= <Equals_Operator> rank => 0
            | <Not_Equals_Operator> rank => -1
            | <Less_Than_Operator> rank => -2
            | <Greater_Than_Operator> rank => -3
            | <Less_Than_Or_Equals_Operator> rank => -4
            | <Greater_Than_Or_Equals_Operator> rank => -5
<Between_Predicate> ::= <Row_Value_Predicand> <Between_Predicate_Part_2> rank => 0
<Gen1914> ::= <ASYMMETRIC> rank => 0
            | <SYMMETRIC> rank => -1
<Gen1914_Maybe> ::= <Gen1914> rank => 0
<Gen1914_Maybe> ::= rank => -1
<Between_Predicate_Part_2> ::= <Not_Maybe> <BETWEEN> <Gen1914_Maybe> <Row_Value_Predicand> <AND> <Row_Value_Predicand> rank => 0
<In_Predicate> ::= <Row_Value_Predicand> <In_Predicate_Part_2> rank => 0
<In_Predicate_Part_2> ::= <Not_Maybe> <IN> <In_Predicate_Value> rank => 0
<In_Predicate_Value> ::= <Table_Subquery> rank => 0
                       | <Left_Paren> <In_Value_List> <Right_Paren> rank => -1
<Gen1923> ::= <Comma> <Row_Value_Expression> rank => 0
<Gen1923_Any> ::= <Gen1923>* rank => 0
<In_Value_List> ::= <Row_Value_Expression> <Gen1923_Any> rank => 0
<Like_Predicate> ::= <Character_Like_Predicate> rank => 0
                   | <Octet_Like_Predicate> rank => -1
<Character_Like_Predicate> ::= <Row_Value_Predicand> <Character_Like_Predicate_Part_2> rank => 0
<Gen1929> ::= <ESCAPE> <Escape_Character> rank => 0
<Gen1929_Maybe> ::= <Gen1929> rank => 0
<Gen1929_Maybe> ::= rank => -1
<Character_Like_Predicate_Part_2> ::= <Not_Maybe> <LIKE> <Character_Pattern> <Gen1929_Maybe> rank => 0
<Character_Pattern> ::= <Character_Value_Expression> rank => 0
<Escape_Character> ::= <Character_Value_Expression> rank => 0
<Octet_Like_Predicate> ::= <Row_Value_Predicand> <Octet_Like_Predicate_Part_2> rank => 0
<Gen1936> ::= <ESCAPE> <Escape_Octet> rank => 0
<Gen1936_Maybe> ::= <Gen1936> rank => 0
<Gen1936_Maybe> ::= rank => -1
<Octet_Like_Predicate_Part_2> ::= <Not_Maybe> <LIKE> <Octet_Pattern> <Gen1936_Maybe> rank => 0
<Octet_Pattern> ::= <Blob_Value_Expression> rank => 0
<Escape_Octet> ::= <Blob_Value_Expression> rank => 0
<Similar_Predicate> ::= <Row_Value_Predicand> <Similar_Predicate_Part_2> rank => 0
<Gen1943> ::= <ESCAPE> <Escape_Character> rank => 0
<Gen1943_Maybe> ::= <Gen1943> rank => 0
<Gen1943_Maybe> ::= rank => -1
<Similar_Predicate_Part_2> ::= <Not_Maybe> <SIMILAR> <TO> <Similar_Pattern> <Gen1943_Maybe> rank => 0
<Similar_Pattern> ::= <Character_Value_Expression> rank => 0
<Regular_Expression> ::= <Regular_Term> rank => 0
                       | <Regular_Expression> <Vertical_Bar> <Regular_Term> rank => -1
<Regular_Term> ::= <Regular_Factor> rank => 0
                 | <Regular_Term> <Regular_Factor> rank => -1
<Regular_Factor> ::= <Regular_Primary> rank => 0
                   | <Regular_Primary> <Asterisk> rank => -1
                   | <Regular_Primary> <Plus_Sign> rank => -2
                   | <Regular_Primary> <Question_Mark> rank => -3
                   | <Regular_Primary> <Repeat_Factor> rank => -4
<Upper_Limit_Maybe> ::= <Upper_Limit> rank => 0
<Upper_Limit_Maybe> ::= rank => -1
<Repeat_Factor> ::= <Left_Brace> <Low_Value> <Upper_Limit_Maybe> <Right_Brace> rank => 0
<High_Value_Maybe> ::= <High_Value> rank => 0
<High_Value_Maybe> ::= rank => -1
<Upper_Limit> ::= <Comma> <High_Value_Maybe> rank => 0
<Low_Value> ::= <Unsigned_Integer> rank => 0
<High_Value> ::= <Unsigned_Integer> rank => 0
<Regular_Primary> ::= <Character_Specifier> rank => 0
                    | <Percent> rank => -1
                    | <Regular_Character_Set> rank => -2
                    | <Left_Paren> <Regular_Expression> <Right_Paren> rank => -3
<Character_Specifier> ::= <Non_Escaped_Character> rank => 0
                        | <Escaped_Character> rank => -1
<Non_Escaped_Character> ~ <Lex572>
<Escaped_Character> ~ <Lex573> <Lex574>
<Character_Enumeration_Many> ::= <Character_Enumeration>+ rank => 0
<Character_Enumeration_Include_Many> ::= <Character_Enumeration_Include>+ rank => 0
<Character_Enumeration_Exclude_Many> ::= <Character_Enumeration_Exclude>+ rank => 0
<Regular_Character_Set> ::= <Underscore> rank => 0
                          | <Left_Bracket> <Character_Enumeration_Many> <Right_Bracket> rank => -1
                          | <Left_Bracket> <Circumflex> <Character_Enumeration_Many> <Right_Bracket> rank => -2
                          | <Left_Bracket> <Character_Enumeration_Include_Many> <Circumflex> <Character_Enumeration_Exclude_Many> <Right_Bracket> rank => -3
<Character_Enumeration_Include> ::= <Character_Enumeration> rank => 0
<Character_Enumeration_Exclude> ::= <Character_Enumeration> rank => 0
<Character_Enumeration> ::= <Character_Specifier> rank => 0
                          | <Character_Specifier> <Minus_Sign> <Character_Specifier> rank => -1
                          | <Left_Bracket> <Colon> <Regular_Character_Set_Identifier> <Colon> <Right_Bracket> rank => -2
<Regular_Character_Set_Identifier> ::= <Identifier> rank => 0
<Null_Predicate> ::= <Row_Value_Predicand> <Null_Predicate_Part_2> rank => 0
<Null_Predicate_Part_2> ::= <IS> <Not_Maybe> <NULL> rank => 0
<Quantified_Comparison_Predicate> ::= <Row_Value_Predicand> <Quantified_Comparison_Predicate_Part_2> rank => 0
<Quantified_Comparison_Predicate_Part_2> ::= <Comp_Op> <Quantifier> <Table_Subquery> rank => 0
<Quantifier> ::= <All> rank => 0
               | <Some> rank => -1
<All> ::= <ALL> rank => 0
<Some> ::= <SOME> rank => 0
         | <ANY> rank => -1
<Exists_Predicate> ::= <EXISTS> <Table_Subquery> rank => 0
<Unique_Predicate> ::= <UNIQUE> <Table_Subquery> rank => 0
<Normalized_Predicate> ::= <String_Value_Expression> <IS> <Not_Maybe> <NORMALIZED> rank => 0
<Match_Predicate> ::= <Row_Value_Predicand> <Match_Predicate_Part_2> rank => 0
<Unique_Maybe> ::= <UNIQUE> rank => 0
<Unique_Maybe> ::= rank => -1
<Gen2001> ::= <SIMPLE> rank => 0
            | <PARTIAL> rank => -1
            | <FULL> rank => -2
<Gen2001_Maybe> ::= <Gen2001> rank => 0
<Gen2001_Maybe> ::= rank => -1
<Match_Predicate_Part_2> ::= <MATCH> <Unique_Maybe> <Gen2001_Maybe> <Table_Subquery> rank => 0
<Overlaps_Predicate> ::= <Overlaps_Predicate_Part_1> <Overlaps_Predicate_Part_2> rank => 0
<Overlaps_Predicate_Part_1> ::= <Row_Value_Predicand_1> rank => 0
<Overlaps_Predicate_Part_2> ::= <OVERLAPS> <Row_Value_Predicand_2> rank => 0
<Row_Value_Predicand_1> ::= <Row_Value_Predicand> rank => 0
<Row_Value_Predicand_2> ::= <Row_Value_Predicand> rank => 0
<Distinct_Predicate> ::= <Row_Value_Predicand_3> <Distinct_Predicate_Part_2> rank => 0
<Distinct_Predicate_Part_2> ::= <IS> <DISTINCT> <FROM> <Row_Value_Predicand_4> rank => 0
<Row_Value_Predicand_3> ::= <Row_Value_Predicand> rank => 0
<Row_Value_Predicand_4> ::= <Row_Value_Predicand> rank => 0
<Member_Predicate> ::= <Row_Value_Predicand> <Member_Predicate_Part_2> rank => 0
<Of_Maybe> ::= <OF> rank => 0
<Of_Maybe> ::= rank => -1
<Member_Predicate_Part_2> ::= <Not_Maybe> <MEMBER> <Of_Maybe> <Multiset_Value_Expression> rank => 0
<Submultiset_Predicate> ::= <Row_Value_Predicand> <Submultiset_Predicate_Part_2> rank => 0
<Submultiset_Predicate_Part_2> ::= <Not_Maybe> <SUBMULTISET> <Of_Maybe> <Multiset_Value_Expression> rank => 0
<Set_Predicate> ::= <Row_Value_Predicand> <Set_Predicate_Part_2> rank => 0
<Set_Predicate_Part_2> ::= <IS> <Not_Maybe> <A> <SET> rank => 0
<Type_Predicate> ::= <Row_Value_Predicand> <Type_Predicate_Part_2> rank => 0
<Type_Predicate_Part_2> ::= <IS> <Not_Maybe> <OF> <Left_Paren> <Type_List> <Right_Paren> rank => 0
<Gen2026> ::= <Comma> <User_Defined_Type_Specification> rank => 0
<Gen2026_Any> ::= <Gen2026>* rank => 0
<Type_List> ::= <User_Defined_Type_Specification> <Gen2026_Any> rank => 0
<User_Defined_Type_Specification> ::= <Inclusive_User_Defined_Type_Specification> rank => 0
                                    | <Exclusive_User_Defined_Type_Specification> rank => -1
<Inclusive_User_Defined_Type_Specification> ::= <Path_Resolved_User_Defined_Type_Name> rank => 0
<Exclusive_User_Defined_Type_Specification> ::= <ONLY> <Path_Resolved_User_Defined_Type_Name> rank => 0
<Search_Condition> ::= <Boolean_Value_Expression> rank => 0
<Interval_Qualifier> ::= <Start_Field> <TO> <End_Field> rank => 0
                       | <Single_Datetime_Field> rank => -1
<Gen2036> ::= <Left_Paren> <Interval_Leading_Field_Precision> <Right_Paren> rank => 0
<Gen2036_Maybe> ::= <Gen2036> rank => 0
<Gen2036_Maybe> ::= rank => -1
<Start_Field> ::= <Non_Second_Primary_Datetime_Field> <Gen2036_Maybe> rank => 0
<Gen2040> ::= <Left_Paren> <Interval_Fractional_Seconds_Precision> <Right_Paren> rank => 0
<Gen2040_Maybe> ::= <Gen2040> rank => 0
<Gen2040_Maybe> ::= rank => -1
<End_Field> ::= <Non_Second_Primary_Datetime_Field> rank => 0
              | <SECOND> <Gen2040_Maybe> rank => -1
<Gen2045> ::= <Left_Paren> <Interval_Leading_Field_Precision> <Right_Paren> rank => 0
<Gen2045_Maybe> ::= <Gen2045> rank => 0
<Gen2045_Maybe> ::= rank => -1
<Gen2048> ::= <Comma> <Interval_Fractional_Seconds_Precision> rank => 0
<Gen2048_Maybe> ::= <Gen2048> rank => 0
<Gen2048_Maybe> ::= rank => -1
<Gen2051> ::= <Left_Paren> <Interval_Leading_Field_Precision> <Gen2048_Maybe> <Right_Paren> rank => 0
<Gen2051_Maybe> ::= <Gen2051> rank => 0
<Gen2051_Maybe> ::= rank => -1
<Single_Datetime_Field> ::= <Non_Second_Primary_Datetime_Field> <Gen2045_Maybe> rank => 0
                          | <SECOND> <Gen2051_Maybe> rank => -1
<Primary_Datetime_Field> ::= <Non_Second_Primary_Datetime_Field> rank => 0
                           | <SECOND> rank => -1
<Non_Second_Primary_Datetime_Field> ::= <YEAR> rank => 0
                                      | <MONTH> rank => -1
                                      | <DAY> rank => -2
                                      | <HOUR> rank => -3
                                      | <MINUTE> rank => -4
<Interval_Fractional_Seconds_Precision> ::= <Unsigned_Integer> rank => 0
<Interval_Leading_Field_Precision> ::= <Unsigned_Integer> rank => 0
<Language_Clause> ::= <LANGUAGE> <Language_Name> rank => 0
<Language_Name> ::= <ADA> rank => 0
                  | <C> rank => -1
                  | <COBOL> rank => -2
                  | <FORTRAN> rank => -3
                  | <MUMPS> rank => -4
                  | <PASCAL> rank => -5
                  | <PLI> rank => -6
                  | <SQL> rank => -7
<Path_Specification> ::= <PATH> <Schema_Name_List> rank => 0
<Gen2075> ::= <Comma> <Schema_Name> rank => 0
<Gen2075_Any> ::= <Gen2075>* rank => 0
<Schema_Name_List> ::= <Schema_Name> <Gen2075_Any> rank => 0
<Routine_Invocation> ::= <Routine_Name> <SQL_Argument_List> rank => 0
<Genlex2079> ~ <Schema_Name_L0_Internal> <Period_L0>
<Genlex2079_Maybe> ~ <Genlex2079>
<Genlex2079_Maybe> ~
<Routine_Name> ~ <Genlex2079_Maybe> <Qualified_Identifier_L0>
<Gen2083> ::= <Comma> <SQL_Argument> rank => 0
<Gen2083_Any> ::= <Gen2083>* rank => 0
<Gen2085> ::= <SQL_Argument> <Gen2083_Any> rank => 0
<Gen2085_Maybe> ::= <Gen2085> rank => 0
<Gen2085_Maybe> ::= rank => -1
<SQL_Argument_List> ::= <Left_Paren> <Gen2085_Maybe> <Right_Paren> rank => 0
<SQL_Argument> ::= <Value_Expression> rank => 0
                 | <Generalized_Expression> rank => -1
                 | <Target_Specification> rank => -2
<Generalized_Expression> ::= <Value_Expression> <AS> <Path_Resolved_User_Defined_Type_Name> rank => 0
<Character_Set_Specification_L0_Internal> ~ <Standard_Character_Set_Name_L0_Internal>
                                            | <Implementation_Defined_Character_Set_Name_L0_Internal>
                                            | <User_Defined_Character_Set_Name_L0_Internal>
<Character_Set_Specification> ~ <Character_Set_Specification_L0_Internal>
<Standard_Character_Set_Name_L0_Internal> ~ <Character_Set_Name_L0_Internal>
<Implementation_Defined_Character_Set_Name_L0_Internal> ~ <Character_Set_Name_L0_Internal>
<User_Defined_Character_Set_Name_L0_Internal> ~ <Character_Set_Name_L0_Internal>
<Gen2100> ::= <FOR> <Schema_Resolved_User_Defined_Type_Name> rank => 0
<Gen2100_Maybe> ::= <Gen2100> rank => 0
<Gen2100_Maybe> ::= rank => -1
<Specific_Routine_Designator> ::= <SPECIFIC> <Routine_Type> <Specific_Name> rank => 0
                                | <Routine_Type> <Member_Name> <Gen2100_Maybe> rank => -1
<Gen2105> ::= <INSTANCE> rank => 0
            | <STATIC> rank => -1
            | <CONSTRUCTOR> rank => -2
<Gen2105_Maybe> ::= <Gen2105> rank => 0
<Gen2105_Maybe> ::= rank => -1
<Routine_Type> ::= <ROUTINE> rank => 0
                 | <FUNCTION> rank => -1
                 | <PROCEDURE> rank => -2
                 | <Gen2105_Maybe> <METHOD> rank => -3
<Data_Type_List_Maybe> ::= <Data_Type_List> rank => 0
<Data_Type_List_Maybe> ::= rank => -1
<Member_Name> ::= <Member_Name_Alternatives> <Data_Type_List_Maybe> rank => 0
<Member_Name_Alternatives> ::= <Schema_Qualified_Routine_Name> rank => 0
                             | <Method_Name> rank => -1
<Gen2119> ::= <Comma> <Data_Type> rank => 0
<Gen2119_Any> ::= <Gen2119>* rank => 0
<Gen2121> ::= <Data_Type> <Gen2119_Any> rank => 0
<Gen2121_Maybe> ::= <Gen2121> rank => 0
<Gen2121_Maybe> ::= rank => -1
<Data_Type_List> ::= <Left_Paren> <Gen2121_Maybe> <Right_Paren> rank => 0
<Collate_Clause> ::= <COLLATE> <Collation_Name> rank => 0
<Constraint_Name_Definition> ::= <CONSTRAINT> <Constraint_Name> rank => 0
<Gen2127> ::= <Not_Maybe> <DEFERRABLE> rank => 0
<Gen2127_Maybe> ::= <Gen2127> rank => 0
<Gen2127_Maybe> ::= rank => -1
<Constraint_Check_Time_Maybe> ::= <Constraint_Check_Time> rank => 0
<Constraint_Check_Time_Maybe> ::= rank => -1
<Constraint_Characteristics> ::= <Constraint_Check_Time> <Gen2127_Maybe> rank => 0
                               | <Not_Maybe> <DEFERRABLE> <Constraint_Check_Time_Maybe> rank => -1
<Constraint_Check_Time> ::= <INITIALLY> <DEFERRED> rank => 0
                          | <INITIALLY> <IMMEDIATE> rank => -1
<Filter_Clause_Maybe> ::= <Filter_Clause> rank => 0
<Filter_Clause_Maybe> ::= rank => -1
<Aggregate_Function> ::= <COUNT> <Left_Paren> <Asterisk> <Right_Paren> <Filter_Clause_Maybe> rank => 0
                       | <General_Set_Function> <Filter_Clause_Maybe> rank => -1
                       | <Binary_Set_Function> <Filter_Clause_Maybe> rank => -2
                       | <Ordered_Set_Function> <Filter_Clause_Maybe> rank => -3
<General_Set_Function> ::= <Set_Function_Type> <Left_Paren> <Set_Quantifier_Maybe> <Value_Expression> <Right_Paren> rank => 0
<Set_Function_Type> ::= <Computational_Operation> rank => 0
<Computational_Operation> ::= <AVG> rank => 0
                            | <MAX> rank => -1
                            | <MIN> rank => -2
                            | <SUM> rank => -3
                            | <EVERY> rank => -4
                            | <ANY> rank => -5
                            | <SOME> rank => -6
                            | <COUNT> rank => -7
                            | <STDDEV_POP> rank => -8
                            | <STDDEV_SAMP> rank => -9
                            | <VAR_SAMP> rank => -10
                            | <VAR_POP> rank => -11
                            | <COLLECT> rank => -12
                            | <FUSION> rank => -13
                            | <INTERSECTION> rank => -14
<Set_Quantifier> ::= <DISTINCT> rank => 0
                   | <ALL> rank => -1
<Filter_Clause> ::= <FILTER> <Left_Paren> <WHERE> <Search_Condition> <Right_Paren> rank => 0
<Binary_Set_Function> ::= <Binary_Set_Function_Type> <Left_Paren> <Dependent_Variable_Expression> <Comma> <Independent_Variable_Expression> <Right_Paren> rank => 0
<Binary_Set_Function_Type> ::= <COVAR_POP> rank => 0
                             | <COVAR_SAMP> rank => -1
                             | <CORR> rank => -2
                             | <REGR_SLOPE> rank => -3
                             | <REGR_INTERCEPT> rank => -4
                             | <REGR_COUNT> rank => -5
                             | <Lex472> rank => -6
                             | <REGR_AVGX> rank => -7
                             | <REGR_AVGY> rank => -8
                             | <REGR_SXX> rank => -9
                             | <REGR_SYY> rank => -10
                             | <REGR_SXY> rank => -11
<Dependent_Variable_Expression> ::= <Numeric_Value_Expression> rank => 0
<Independent_Variable_Expression> ::= <Numeric_Value_Expression> rank => 0
<Ordered_Set_Function> ::= <Hypothetical_Set_Function> rank => 0
                         | <Inverse_Distribution_Function> rank => -1
<Hypothetical_Set_Function> ::= <Rank_Function_Type> <Left_Paren> <Hypothetical_Set_Function_Value_Expression_List> <Right_Paren> <Within_Group_Specification> rank => 0
<Within_Group_Specification> ::= <WITHIN> <GROUP> <Left_Paren> <ORDER> <BY> <Sort_Specification_List> <Right_Paren> rank => 0
<Gen2181> ::= <Comma> <Value_Expression> rank => 0
<Gen2181_Any> ::= <Gen2181>* rank => 0
<Hypothetical_Set_Function_Value_Expression_List> ::= <Value_Expression> <Gen2181_Any> rank => 0
<Inverse_Distribution_Function> ::= <Inverse_Distribution_Function_Type> <Left_Paren> <Inverse_Distribution_Function_Argument> <Right_Paren> <Within_Group_Specification> rank => 0
<Inverse_Distribution_Function_Argument> ::= <Numeric_Value_Expression> rank => 0
<Inverse_Distribution_Function_Type> ::= <PERCENTILE_CONT> rank => 0
                                       | <PERCENTILE_DISC> rank => -1
<Gen2188> ::= <Comma> <Sort_Specification> rank => 0
<Gen2188_Any> ::= <Gen2188>* rank => 0
<Sort_Specification_List> ::= <Sort_Specification> <Gen2188_Any> rank => 0
<Ordering_Specification_Maybe> ::= <Ordering_Specification> rank => 0
<Ordering_Specification_Maybe> ::= rank => -1
<Null_Ordering_Maybe> ::= <Null_Ordering> rank => 0
<Null_Ordering_Maybe> ::= rank => -1
<Sort_Specification> ::= <Sort_Key> <Ordering_Specification_Maybe> <Null_Ordering_Maybe> rank => 0
<Sort_Key> ::= <Value_Expression> rank => 0
<Ordering_Specification> ::= <ASC> rank => 0
                           | <DESC> rank => -1
<Null_Ordering> ::= <NULLS> <FIRST> rank => 0
                  | <NULLS> <LAST> rank => -1
<Schema_Character_Set_Or_Path_Maybe> ::= <Schema_Character_Set_Or_Path> rank => 0
<Schema_Character_Set_Or_Path_Maybe> ::= rank => -1
<Schema_Element_Any> ::= <Schema_Element>* rank => 0
<Schema_Definition> ::= <CREATE> <SCHEMA> <Schema_Name_Clause> <Schema_Character_Set_Or_Path_Maybe> <Schema_Element_Any> rank => 0
<Schema_Character_Set_Or_Path> ::= <Schema_Character_Set_Specification> rank => 0
                                 | <Schema_Path_Specification> rank => -1
                                 | <Schema_Character_Set_Specification> <Schema_Path_Specification> rank => -2
                                 | <Schema_Path_Specification> <Schema_Character_Set_Specification> rank => -3
<Schema_Name_Clause> ::= <Schema_Name> rank => 0
                       | <AUTHORIZATION> <Schema_Authorization_Identifier> rank => -1
                       | <Schema_Name> <AUTHORIZATION> <Schema_Authorization_Identifier> rank => -2
<Schema_Authorization_Identifier> ::= <Authorization_Identifier> rank => 0
<Schema_Character_Set_Specification> ::= <DEFAULT> <CHARACTER> <SET> <Character_Set_Specification> rank => 0
<Schema_Path_Specification> ::= <Path_Specification> rank => 0
<Schema_Element> ::= <Table_Definition> rank => 0
                   | <View_Definition> rank => -1
                   | <Domain_Definition> rank => -2
                   | <Character_Set_Definition> rank => -3
                   | <Collation_Definition> rank => -4
                   | <Transliteration_Definition> rank => -5
                   | <Assertion_Definition> rank => -6
                   | <Trigger_Definition> rank => -7
                   | <User_Defined_Type_Definition> rank => -8
                   | <User_Defined_Cast_Definition> rank => -9
                   | <User_Defined_Ordering_Definition> rank => -10
                   | <Transform_Definition> rank => -11
                   | <Schema_Routine> rank => -12
                   | <Sequence_Generator_Definition> rank => -13
                   | <Grant_Statement> rank => -14
                   | <Role_Definition> rank => -15
<Drop_Schema_Statement> ::= <DROP> <SCHEMA> <Schema_Name> <Drop_Behavior> rank => 0
<Drop_Behavior> ::= <CASCADE> rank => 0
                  | <RESTRICT> rank => -1
<Table_Scope_Maybe> ::= <Table_Scope> rank => 0
<Table_Scope_Maybe> ::= rank => -1
<Gen2236> ::= <ON> <COMMIT> <Table_Commit_Action> <ROWS> rank => 0
<Gen2236_Maybe> ::= <Gen2236> rank => 0
<Gen2236_Maybe> ::= rank => -1
<Table_Definition> ::= <CREATE> <Table_Scope_Maybe> <TABLE> <Table_Name> <Table_Contents_Source> <Gen2236_Maybe> rank => 0
<Subtable_Clause_Maybe> ::= <Subtable_Clause> rank => 0
<Subtable_Clause_Maybe> ::= rank => -1
<Table_Element_List_Maybe> ::= <Table_Element_List> rank => 0
<Table_Element_List_Maybe> ::= rank => -1
<Table_Contents_Source> ::= <Table_Element_List> rank => 0
                          | <OF> <Path_Resolved_User_Defined_Type_Name> <Subtable_Clause_Maybe> <Table_Element_List_Maybe> rank => -1
                          | <As_Subquery_Clause> rank => -2
<Table_Scope> ::= <Global_Or_Local> <TEMPORARY> rank => 0
<Global_Or_Local> ::= <GLOBAL> rank => 0
                    | <LOCAL> rank => -1
<Table_Commit_Action> ::= <PRESERVE> rank => 0
                        | <DELETE> rank => -1
<Gen2252> ::= <Comma> <Table_Element> rank => 0
<Gen2252_Any> ::= <Gen2252>* rank => 0
<Table_Element_List> ::= <Left_Paren> <Table_Element> <Gen2252_Any> <Right_Paren> rank => 0
<Table_Element> ::= <Column_Definition> rank => 0
                  | <Table_Constraint_Definition> rank => -1
                  | <Like_Clause> rank => -2
                  | <Self_Referencing_Column_Specification> rank => -3
                  | <Column_Options> rank => -4
<Self_Referencing_Column_Specification> ::= <REF> <IS> <Self_Referencing_Column_Name> <Reference_Generation> rank => 0
<Reference_Generation> ::= <SYSTEM> <GENERATED> rank => 0
                         | <USER> <GENERATED> rank => -1
                         | <DERIVED> rank => -2
<Self_Referencing_Column_Name> ::= <Column_Name> rank => 0
<Column_Options> ::= <Column_Name> <WITH> <OPTIONS> <Column_Option_List> rank => 0
<Default_Clause_Maybe> ::= <Default_Clause> rank => 0
<Default_Clause_Maybe> ::= rank => -1
<Column_Constraint_Definition_Any> ::= <Column_Constraint_Definition>* rank => 0
<Column_Option_List> ::= <Scope_Clause_Maybe> <Default_Clause_Maybe> <Column_Constraint_Definition_Any> rank => 0
<Subtable_Clause> ::= <UNDER> <Supertable_Clause> rank => 0
<Supertable_Clause> ::= <Supertable_Name> rank => 0
<Supertable_Name> ::= <Table_Name> rank => 0
<Like_Options_Maybe> ::= <Like_Options> rank => 0
<Like_Options_Maybe> ::= rank => -1
<Like_Clause> ::= <LIKE> <Table_Name> <Like_Options_Maybe> rank => 0
<Like_Options> ::= <Identity_Option> rank => 0
                 | <Column_Default_Option> rank => -1
<Identity_Option> ::= <INCLUDING> <IDENTITY> rank => 0
                    | <EXCLUDING> <IDENTITY> rank => -1
<Column_Default_Option> ::= <INCLUDING> <DEFAULTS> rank => 0
                          | <EXCLUDING> <DEFAULTS> rank => -1
<Gen2282> ::= <Left_Paren> <Column_Name_List> <Right_Paren> rank => 0
<Gen2282_Maybe> ::= <Gen2282> rank => 0
<Gen2282_Maybe> ::= rank => -1
<As_Subquery_Clause> ::= <Gen2282_Maybe> <AS> <Subquery> <With_Or_Without_Data> rank => 0
<With_Or_Without_Data> ::= <WITH> <NO> <DATA> rank => 0
                         | <WITH> <DATA> rank => -1
<Gen2288> ::= <Data_Type> rank => 0
            | <Domain_Name> rank => -1
<Gen2288_Maybe> ::= <Gen2288> rank => 0
<Gen2288_Maybe> ::= rank => -1
<Gen2292> ::= <Default_Clause> rank => 0
            | <Identity_Column_Specification> rank => -1
            | <Generation_Clause> rank => -2
<Gen2292_Maybe> ::= <Gen2292> rank => 0
<Gen2292_Maybe> ::= rank => -1
<Column_Definition> ::= <Column_Name> <Gen2288_Maybe> <Reference_Scope_Check_Maybe> <Gen2292_Maybe> <Column_Constraint_Definition_Any> <Collate_Clause_Maybe> rank => 0
<Constraint_Name_Definition_Maybe> ::= <Constraint_Name_Definition> rank => 0
<Constraint_Name_Definition_Maybe> ::= rank => -1
<Constraint_Characteristics_Maybe> ::= <Constraint_Characteristics> rank => 0
<Constraint_Characteristics_Maybe> ::= rank => -1
<Column_Constraint_Definition> ::= <Constraint_Name_Definition_Maybe> <Column_Constraint> <Constraint_Characteristics_Maybe> rank => 0
<Column_Constraint> ::= <NOT> <NULL> rank => 0
                      | <Unique_Specification> rank => -1
                      | <References_Specification> rank => -2
                      | <Check_Constraint_Definition> rank => -3
<Gen2307> ::= <ON> <DELETE> <Reference_Scope_Check_Action> rank => 0
<Gen2307_Maybe> ::= <Gen2307> rank => 0
<Gen2307_Maybe> ::= rank => -1
<Reference_Scope_Check> ::= <REFERENCES> <ARE> <Not_Maybe> <CHECKED> <Gen2307_Maybe> rank => 0
<Reference_Scope_Check_Action> ::= <Referential_Action> rank => 0
<Gen2312> ::= <ALWAYS> rank => 0
            | <BY> <DEFAULT> rank => -1
<Gen2314> ::= <Left_Paren> <Common_Sequence_Generator_Options> <Right_Paren> rank => 0
<Gen2314_Maybe> ::= <Gen2314> rank => 0
<Gen2314_Maybe> ::= rank => -1
<Identity_Column_Specification> ::= <GENERATED> <Gen2312> <AS> <IDENTITY> <Gen2314_Maybe> rank => 0
<Generation_Clause> ::= <Generation_Rule> <AS> <Generation_Expression> rank => 0
<Generation_Rule> ::= <GENERATED> <ALWAYS> rank => 0
<Generation_Expression> ::= <Left_Paren> <Value_Expression> <Right_Paren> rank => 0
<Default_Clause> ::= <DEFAULT> <Default_Option> rank => 0
<Default_Option> ::= <Literal> rank => 0
                   | <Datetime_Value_Function> rank => -1
                   | <USER> rank => -2
                   | <CURRENT_USER> rank => -3
                   | <CURRENT_ROLE> rank => -4
                   | <SESSION_USER> rank => -5
                   | <SYSTEM_USER> rank => -6
                   | <CURRENT_PATH> rank => -7
                   | <Implicitly_Typed_Value_Specification> rank => -8
<Table_Constraint_Definition> ::= <Constraint_Name_Definition_Maybe> <Table_Constraint> <Constraint_Characteristics_Maybe> rank => 0
<Table_Constraint> ::= <Unique_Constraint_Definition> rank => 0
                     | <Referential_Constraint_Definition> rank => -1
                     | <Check_Constraint_Definition> rank => -2
<Gen2335> ::= <VALUE> rank => 0
<Unique_Constraint_Definition> ::= <Unique_Specification> <Left_Paren> <Unique_Column_List> <Right_Paren> rank => 0
                                 | <UNIQUE> <Gen2335> rank => -1
<Unique_Specification> ::= <UNIQUE> rank => 0
                         | <PRIMARY> <KEY> rank => -1
<Unique_Column_List> ::= <Column_Name_List> rank => 0
<Referential_Constraint_Definition> ::= <FOREIGN> <KEY> <Left_Paren> <Referencing_Columns> <Right_Paren> <References_Specification> rank => 0
<Gen2342> ::= <MATCH> <Match_Type> rank => 0
<Gen2342_Maybe> ::= <Gen2342> rank => 0
<Gen2342_Maybe> ::= rank => -1
<Referential_Triggered_Action_Maybe> ::= <Referential_Triggered_Action> rank => 0
<Referential_Triggered_Action_Maybe> ::= rank => -1
<References_Specification> ::= <REFERENCES> <Referenced_Table_And_Columns> <Gen2342_Maybe> <Referential_Triggered_Action_Maybe> rank => 0
<Match_Type> ::= <FULL> rank => 0
               | <PARTIAL> rank => -1
               | <SIMPLE> rank => -2
<Referencing_Columns> ::= <Reference_Column_List> rank => 0
<Gen2352> ::= <Left_Paren> <Reference_Column_List> <Right_Paren> rank => 0
<Gen2352_Maybe> ::= <Gen2352> rank => 0
<Gen2352_Maybe> ::= rank => -1
<Referenced_Table_And_Columns> ::= <Table_Name> <Gen2352_Maybe> rank => 0
<Reference_Column_List> ::= <Column_Name_List> rank => 0
<Delete_Rule_Maybe> ::= <Delete_Rule> rank => 0
<Delete_Rule_Maybe> ::= rank => -1
<Update_Rule_Maybe> ::= <Update_Rule> rank => 0
<Update_Rule_Maybe> ::= rank => -1
<Referential_Triggered_Action> ::= <Update_Rule> <Delete_Rule_Maybe> rank => 0
                                 | <Delete_Rule> <Update_Rule_Maybe> rank => -1
<Update_Rule> ::= <ON> <UPDATE> <Referential_Action> rank => 0
<Delete_Rule> ::= <ON> <DELETE> <Referential_Action> rank => 0
<Referential_Action> ::= <CASCADE> rank => 0
                       | <SET> <NULL> rank => -1
                       | <SET> <DEFAULT> rank => -2
                       | <RESTRICT> rank => -3
                       | <NO> <ACTION> rank => -4
<Check_Constraint_Definition> ::= <CHECK> <Left_Paren> <Search_Condition> <Right_Paren> rank => 0
<Alter_Table_Statement> ::= <ALTER> <TABLE> <Table_Name> <Alter_Table_Action> rank => 0
<Alter_Table_Action> ::= <Add_Column_Definition> rank => 0
                       | <Alter_Column_Definition> rank => -1
                       | <Drop_Column_Definition> rank => -2
                       | <Add_Table_Constraint_Definition> rank => -3
                       | <Drop_Table_Constraint_Definition> rank => -4
<Column_Maybe> ::= <COLUMN> rank => 0
<Column_Maybe> ::= rank => -1
<Add_Column_Definition> ::= <ADD> <Column_Maybe> <Column_Definition> rank => 0
<Alter_Column_Definition> ::= <ALTER> <Column_Maybe> <Column_Name> <Alter_Column_Action> rank => 0
<Alter_Column_Action> ::= <Set_Column_Default_Clause> rank => 0
                        | <Drop_Column_Default_Clause> rank => -1
                        | <Add_Column_Scope_Clause> rank => -2
                        | <Drop_Column_Scope_Clause> rank => -3
                        | <Alter_Identity_Column_Specification> rank => -4
<Set_Column_Default_Clause> ::= <SET> <Default_Clause> rank => 0
<Drop_Column_Default_Clause> ::= <DROP> <DEFAULT> rank => 0
<Add_Column_Scope_Clause> ::= <ADD> <Scope_Clause> rank => 0
<Drop_Column_Scope_Clause> ::= <DROP> <SCOPE> <Drop_Behavior> rank => 0
<Alter_Identity_Column_Option_Many> ::= <Alter_Identity_Column_Option>+ rank => 0
<Alter_Identity_Column_Specification> ::= <Alter_Identity_Column_Option_Many> rank => 0
<Alter_Identity_Column_Option> ::= <Alter_Sequence_Generator_Restart_Option> rank => 0
                                 | <SET> <Basic_Sequence_Generator_Option> rank => -1
<Drop_Column_Definition> ::= <DROP> <Column_Maybe> <Column_Name> <Drop_Behavior> rank => 0
<Add_Table_Constraint_Definition> ::= <ADD> <Table_Constraint_Definition> rank => 0
<Drop_Table_Constraint_Definition> ::= <DROP> <CONSTRAINT> <Constraint_Name> <Drop_Behavior> rank => 0
<Drop_Table_Statement> ::= <DROP> <TABLE> <Table_Name> <Drop_Behavior> rank => 0
<Levels_Clause_Maybe> ::= <Levels_Clause> rank => 0
<Levels_Clause_Maybe> ::= rank => -1
<Gen2400> ::= <WITH> <Levels_Clause_Maybe> <CHECK> <OPTION> rank => 0
<Gen2400_Maybe> ::= <Gen2400> rank => 0
<Gen2400_Maybe> ::= rank => -1
<View_Definition> ::= <CREATE> <Recursive_Maybe> <VIEW> <Table_Name> <View_Specification> <AS> <Query_Expression> <Gen2400_Maybe> rank => 0
<View_Specification> ::= <Regular_View_Specification> rank => 0
                       | <Referenceable_View_Specification> rank => -1
<Gen2406> ::= <Left_Paren> <View_Column_List> <Right_Paren> rank => 0
<Gen2406_Maybe> ::= <Gen2406> rank => 0
<Gen2406_Maybe> ::= rank => -1
<Regular_View_Specification> ::= <Gen2406_Maybe> rank => 0
<Subview_Clause_Maybe> ::= <Subview_Clause> rank => 0
<Subview_Clause_Maybe> ::= rank => -1
<View_Element_List_Maybe> ::= <View_Element_List> rank => 0
<View_Element_List_Maybe> ::= rank => -1
<Referenceable_View_Specification> ::= <OF> <Path_Resolved_User_Defined_Type_Name> <Subview_Clause_Maybe> <View_Element_List_Maybe> rank => 0
<Subview_Clause> ::= <UNDER> <Table_Name> rank => 0
<Gen2416> ::= <Comma> <View_Element> rank => 0
<Gen2416_Any> ::= <Gen2416>* rank => 0
<View_Element_List> ::= <Left_Paren> <View_Element> <Gen2416_Any> <Right_Paren> rank => 0
<View_Element> ::= <Self_Referencing_Column_Specification> rank => 0
                 | <View_Column_Option> rank => -1
<View_Column_Option> ::= <Column_Name> <WITH> <OPTIONS> <Scope_Clause> rank => 0
<Levels_Clause> ::= <CASCADED> rank => 0
                  | <LOCAL> rank => -1
<View_Column_List> ::= <Column_Name_List> rank => 0
<Drop_View_Statement> ::= <DROP> <VIEW> <Table_Name> <Drop_Behavior> rank => 0
<Domain_Constraint_Any> ::= <Domain_Constraint>* rank => 0
<Domain_Definition> ::= <CREATE> <DOMAIN> <Domain_Name> <As_Maybe> <Data_Type> <Default_Clause_Maybe> <Domain_Constraint_Any> <Collate_Clause_Maybe> rank => 0
<Domain_Constraint> ::= <Constraint_Name_Definition_Maybe> <Check_Constraint_Definition> <Constraint_Characteristics_Maybe> rank => 0
<Alter_Domain_Statement> ::= <ALTER> <DOMAIN> <Domain_Name> <Alter_Domain_Action> rank => 0
<Alter_Domain_Action> ::= <Set_Domain_Default_Clause> rank => 0
                        | <Drop_Domain_Default_Clause> rank => -1
                        | <Add_Domain_Constraint_Definition> rank => -2
                        | <Drop_Domain_Constraint_Definition> rank => -3
<Set_Domain_Default_Clause> ::= <SET> <Default_Clause> rank => 0
<Drop_Domain_Default_Clause> ::= <DROP> <DEFAULT> rank => 0
<Add_Domain_Constraint_Definition> ::= <ADD> <Domain_Constraint> rank => 0
<Drop_Domain_Constraint_Definition> ::= <DROP> <CONSTRAINT> <Constraint_Name> rank => 0
<Drop_Domain_Statement> ::= <DROP> <DOMAIN> <Domain_Name> <Drop_Behavior> rank => 0
<Character_Set_Definition> ::= <CREATE> <CHARACTER> <SET> <Character_Set_Name> <As_Maybe> <Character_Set_Source> <Collate_Clause_Maybe> rank => 0
<Character_Set_Source> ::= <GET> <Character_Set_Specification> rank => 0
<Drop_Character_Set_Statement> ::= <DROP> <CHARACTER> <SET> <Character_Set_Name> rank => 0
<Pad_Characteristic_Maybe> ::= <Pad_Characteristic> rank => 0
<Pad_Characteristic_Maybe> ::= rank => -1
<Collation_Definition> ::= <CREATE> <COLLATION> <Collation_Name> <FOR> <Character_Set_Specification> <FROM> <Existing_Collation_Name> <Pad_Characteristic_Maybe> rank => 0
<Existing_Collation_Name> ::= <Collation_Name> rank => 0
<Pad_Characteristic> ::= <NO> <PAD> rank => 0
                       | <PAD> <SPACE> rank => -1
<Drop_Collation_Statement> ::= <DROP> <COLLATION> <Collation_Name> <Drop_Behavior> rank => 0
<Transliteration_Definition> ::= <CREATE> <TRANSLATION> <Transliteration_Name> <FOR> <Source_Character_Set_Specification> <TO> <Target_Character_Set_Specification> <FROM> <Transliteration_Source> rank => 0
<Source_Character_Set_Specification> ::= <Character_Set_Specification> rank => 0
<Target_Character_Set_Specification> ::= <Character_Set_Specification> rank => 0
<Transliteration_Source> ::= <Existing_Transliteration_Name> rank => 0
                           | <Transliteration_Routine> rank => -1
<Existing_Transliteration_Name> ::= <Transliteration_Name> rank => 0
<Transliteration_Routine> ::= <Specific_Routine_Designator> rank => 0
<Drop_Transliteration_Statement> ::= <DROP> <TRANSLATION> <Transliteration_Name> rank => 0
<Assertion_Definition> ::= <CREATE> <ASSERTION> <Constraint_Name> <CHECK> <Left_Paren> <Search_Condition> <Right_Paren> <Constraint_Characteristics_Maybe> rank => 0
<Drop_Assertion_Statement> ::= <DROP> <ASSERTION> <Constraint_Name> rank => 0
<Gen2459> ::= <REFERENCING> <Old_Or_New_Values_Alias_List> rank => 0
<Gen2459_Maybe> ::= <Gen2459> rank => 0
<Gen2459_Maybe> ::= rank => -1
<Trigger_Definition> ::= <CREATE> <TRIGGER> <Trigger_Name> <Trigger_Action_Time> <Trigger_Event> <ON> <Table_Name> <Gen2459_Maybe> <Triggered_Action> rank => 0
<Trigger_Action_Time> ::= <BEFORE> rank => 0
                        | <AFTER> rank => -1
<Gen2465> ::= <OF> <Trigger_Column_List> rank => 0
<Gen2465_Maybe> ::= <Gen2465> rank => 0
<Gen2465_Maybe> ::= rank => -1
<Trigger_Event> ::= <INSERT> rank => 0
                  | <DELETE> rank => -1
                  | <UPDATE> <Gen2465_Maybe> rank => -2
<Trigger_Column_List> ::= <Column_Name_List> rank => 0
<Gen2472> ::= <ROW> rank => 0
            | <STATEMENT> rank => -1
<Gen2474> ::= <FOR> <EACH> <Gen2472> rank => 0
<Gen2474_Maybe> ::= <Gen2474> rank => 0
<Gen2474_Maybe> ::= rank => -1
<Gen2477> ::= <WHEN> <Left_Paren> <Search_Condition> <Right_Paren> rank => 0
<Gen2477_Maybe> ::= <Gen2477> rank => 0
<Gen2477_Maybe> ::= rank => -1
<Triggered_Action> ::= <Gen2474_Maybe> <Gen2477_Maybe> <Triggered_SQL_Statement> rank => 0
<Gen2481> ::= <SQL_Procedure_Statement> <Semicolon> rank => 0
<Gen2481_Many> ::= <Gen2481>+ rank => 0
<Triggered_SQL_Statement> ::= <SQL_Procedure_Statement> rank => 0
                            | <BEGIN> <ATOMIC> <Gen2481_Many> <END> rank => -1
<Old_Or_New_Values_Alias_Many> ::= <Old_Or_New_Values_Alias>+ rank => 0
<Old_Or_New_Values_Alias_List> ::= <Old_Or_New_Values_Alias_Many> rank => 0
<Row_Maybe> ::= <ROW> rank => 0
<Row_Maybe> ::= rank => -1
<Old_Or_New_Values_Alias> ::= <OLD> <Row_Maybe> <As_Maybe> <Old_Values_Correlation_Name> rank => 0
                            | <NEW> <Row_Maybe> <As_Maybe> <New_Values_Correlation_Name> rank => -1
                            | <OLD> <TABLE> <As_Maybe> <Old_Values_Table_Alias> rank => -2
                            | <NEW> <TABLE> <As_Maybe> <New_Values_Table_Alias> rank => -3
<Old_Values_Table_Alias> ::= <Identifier> rank => 0
<New_Values_Table_Alias> ::= <Identifier> rank => 0
<Old_Values_Correlation_Name> ::= <Correlation_Name> rank => 0
<New_Values_Correlation_Name> ::= <Correlation_Name> rank => 0
<Drop_Trigger_Statement> ::= <DROP> <TRIGGER> <Trigger_Name> rank => 0
<User_Defined_Type_Definition> ::= <CREATE> <TYPE> <User_Defined_Type_Body> rank => 0
<Subtype_Clause_Maybe> ::= <Subtype_Clause> rank => 0
<Subtype_Clause_Maybe> ::= rank => -1
<Gen2501> ::= <AS> <Representation> rank => 0
<Gen2501_Maybe> ::= <Gen2501> rank => 0
<Gen2501_Maybe> ::= rank => -1
<User_Defined_Type_Option_List_Maybe> ::= <User_Defined_Type_Option_List> rank => 0
<User_Defined_Type_Option_List_Maybe> ::= rank => -1
<Method_Specification_List_Maybe> ::= <Method_Specification_List> rank => 0
<Method_Specification_List_Maybe> ::= rank => -1
<User_Defined_Type_Body> ::= <Schema_Resolved_User_Defined_Type_Name> <Subtype_Clause_Maybe> <Gen2501_Maybe> <User_Defined_Type_Option_List_Maybe> <Method_Specification_List_Maybe> rank => 0
<User_Defined_Type_Option_Any> ::= <User_Defined_Type_Option>* rank => 0
<User_Defined_Type_Option_List> ::= <User_Defined_Type_Option> <User_Defined_Type_Option_Any> rank => 0
<User_Defined_Type_Option> ::= <Instantiable_Clause> rank => 0
                             | <Finality> rank => -1
                             | <Reference_Type_Specification> rank => -2
                             | <Ref_Cast_Option> rank => -3
                             | <Cast_Option> rank => -4
<Subtype_Clause> ::= <UNDER> <Supertype_Name> rank => 0
<Supertype_Name> ::= <Path_Resolved_User_Defined_Type_Name> rank => 0
<Representation> ::= <Predefined_Type> rank => 0
                   | <Member_List> rank => -1
<Gen2520> ::= <Comma> <Member> rank => 0
<Gen2520_Any> ::= <Gen2520>* rank => 0
<Member_List> ::= <Left_Paren> <Member> <Gen2520_Any> <Right_Paren> rank => 0
<Member> ::= <Attribute_Definition> rank => 0
<Instantiable_Clause> ::= <INSTANTIABLE> rank => 0
                        | <NOT> <INSTANTIABLE> rank => -1
<Finality> ::= <FINAL> rank => 0
             | <NOT> <FINAL> rank => -1
<Reference_Type_Specification> ::= <User_Defined_Representation> rank => 0
                                 | <Derived_Representation> rank => -1
                                 | <System_Generated_Representation> rank => -2
<User_Defined_Representation> ::= <REF> <USING> <Predefined_Type> rank => 0
<Derived_Representation> ::= <REF> <FROM> <List_Of_Attributes> rank => 0
<System_Generated_Representation> ::= <REF> <IS> <SYSTEM> <GENERATED> rank => 0
<Cast_To_Type_Maybe> ::= <Cast_To_Type> rank => 0
<Cast_To_Type_Maybe> ::= rank => -1
<Ref_Cast_Option> ::= <Cast_To_Ref> <Cast_To_Type_Maybe> rank => 0
                    | <Cast_To_Type> rank => -1
<Cast_To_Ref> ::= <CAST> <Left_Paren> <SOURCE> <AS> <REF> <Right_Paren> <WITH> <Cast_To_Ref_Identifier> rank => 0
<Cast_To_Ref_Identifier> ::= <Identifier> rank => 0
<Cast_To_Type> ::= <CAST> <Left_Paren> <REF> <AS> <SOURCE> <Right_Paren> <WITH> <Cast_To_Type_Identifier> rank => 0
<Cast_To_Type_Identifier> ::= <Identifier> rank => 0
<Gen2542> ::= <Comma> <Attribute_Name> rank => 0
<Gen2542_Any> ::= <Gen2542>* rank => 0
<List_Of_Attributes> ::= <Left_Paren> <Attribute_Name> <Gen2542_Any> <Right_Paren> rank => 0
<Cast_To_Distinct_Maybe> ::= <Cast_To_Distinct> rank => 0
<Cast_To_Distinct_Maybe> ::= rank => -1
<Cast_Option> ::= <Cast_To_Distinct_Maybe> <Cast_To_Source> rank => 0
                | <Cast_To_Source> rank => -1
<Cast_To_Distinct> ::= <CAST> <Left_Paren> <SOURCE> <AS> <DISTINCT> <Right_Paren> <WITH> <Cast_To_Distinct_Identifier> rank => 0
<Cast_To_Distinct_Identifier> ::= <Identifier> rank => 0
<Cast_To_Source> ::= <CAST> <Left_Paren> <DISTINCT> <AS> <SOURCE> <Right_Paren> <WITH> <Cast_To_Source_Identifier> rank => 0
<Cast_To_Source_Identifier> ::= <Identifier> rank => 0
<Gen2553> ::= <Comma> <Method_Specification> rank => 0
<Gen2553_Any> ::= <Gen2553>* rank => 0
<Method_Specification_List> ::= <Method_Specification> <Gen2553_Any> rank => 0
<Method_Specification> ::= <Original_Method_Specification> rank => 0
                         | <Overriding_Method_Specification> rank => -1
<Gen2558> ::= <SELF> <AS> <RESULT> rank => 0
<Gen2558_Maybe> ::= <Gen2558> rank => 0
<Gen2558_Maybe> ::= rank => -1
<Gen2561> ::= <SELF> <AS> <LOCATOR> rank => 0
<Gen2561_Maybe> ::= <Gen2561> rank => 0
<Gen2561_Maybe> ::= rank => -1
<Method_Characteristics_Maybe> ::= <Method_Characteristics> rank => 0
<Method_Characteristics_Maybe> ::= rank => -1
<Original_Method_Specification> ::= <Partial_Method_Specification> <Gen2558_Maybe> <Gen2561_Maybe> <Method_Characteristics_Maybe> rank => 0
<Overriding_Method_Specification> ::= <OVERRIDING> <Partial_Method_Specification> rank => 0
<Gen2568> ::= <INSTANCE> rank => 0
            | <STATIC> rank => -1
            | <CONSTRUCTOR> rank => -2
<Gen2568_Maybe> ::= <Gen2568> rank => 0
<Gen2568_Maybe> ::= rank => -1
<Gen2573> ::= <SPECIFIC> <Specific_Method_Name> rank => 0
<Gen2573_Maybe> ::= <Gen2573> rank => 0
<Gen2573_Maybe> ::= rank => -1
<Partial_Method_Specification> ::= <Gen2568_Maybe> <METHOD> <Method_Name> <SQL_Parameter_Declaration_List> <Returns_Clause> <Gen2573_Maybe> rank => 0
<Genlex2577> ~ <Schema_Name_L0_Internal> <Period_L0>
<Genlex2577_Maybe> ~ <Genlex2577>
<Genlex2577_Maybe> ~
<Specific_Method_Name> ~ <Genlex2577_Maybe> <Qualified_Identifier_L0>
<Method_Characteristic_Many> ::= <Method_Characteristic>+ rank => 0
<Method_Characteristics> ::= <Method_Characteristic_Many> rank => 0
<Method_Characteristic> ::= <Language_Clause> rank => 0
                          | <Parameter_Style_Clause> rank => -1
                          | <Deterministic_Characteristic> rank => -2
                          | <SQL_Data_Access_Indication> rank => -3
                          | <Null_Call_Clause> rank => -4
<Attribute_Default_Maybe> ::= <Attribute_Default> rank => 0
<Attribute_Default_Maybe> ::= rank => -1
<Attribute_Definition> ::= <Attribute_Name> <Data_Type> <Reference_Scope_Check_Maybe> <Attribute_Default_Maybe> <Collate_Clause_Maybe> rank => 0
<Attribute_Default> ::= <Default_Clause> rank => 0
<Alter_Type_Statement> ::= <ALTER> <TYPE> <Schema_Resolved_User_Defined_Type_Name> <Alter_Type_Action> rank => 0
<Alter_Type_Action> ::= <Add_Attribute_Definition> rank => 0
                      | <Drop_Attribute_Definition> rank => -1
                      | <Add_Original_Method_Specification> rank => -2
                      | <Add_Overriding_Method_Specification> rank => -3
                      | <Drop_Method_Specification> rank => -4
<Add_Attribute_Definition> ::= <ADD> <ATTRIBUTE> <Attribute_Definition> rank => 0
<Drop_Attribute_Definition> ::= <DROP> <ATTRIBUTE> <Attribute_Name> <RESTRICT> rank => 0
<Add_Original_Method_Specification> ::= <ADD> <Original_Method_Specification> rank => 0
<Add_Overriding_Method_Specification> ::= <ADD> <Overriding_Method_Specification> rank => 0
<Drop_Method_Specification> ::= <DROP> <Specific_Method_Specification_Designator> <RESTRICT> rank => 0
<Gen2603> ::= <INSTANCE> rank => 0
            | <STATIC> rank => -1
            | <CONSTRUCTOR> rank => -2
<Gen2603_Maybe> ::= <Gen2603> rank => 0
<Gen2603_Maybe> ::= rank => -1
<Specific_Method_Specification_Designator> ::= <Gen2603_Maybe> <METHOD> <Method_Name> <Data_Type_List> rank => 0
<Drop_Data_Type_Statement> ::= <DROP> <TYPE> <Schema_Resolved_User_Defined_Type_Name> <Drop_Behavior> rank => 0
<SQL_Invoked_Routine> ::= <Schema_Routine> rank => 0
<Schema_Routine> ::= <Schema_Procedure> rank => 0
                   | <Schema_Function> rank => -1
<Schema_Procedure> ::= <CREATE> <SQL_Invoked_Procedure> rank => 0
<Schema_Function> ::= <CREATE> <SQL_Invoked_Function> rank => 0
<SQL_Invoked_Procedure> ::= <PROCEDURE> <Schema_Qualified_Routine_Name> <SQL_Parameter_Declaration_List> <Routine_Characteristics> <Routine_Body> rank => 0
<Gen2616> ::= <Function_Specification> rank => 0
            | <Method_Specification_Designator> rank => -1
<SQL_Invoked_Function> ::= <Gen2616> <Routine_Body> rank => 0
<Gen2619> ::= <Comma> <SQL_Parameter_Declaration> rank => 0
<Gen2619_Any> ::= <Gen2619>* rank => 0
<Gen2621> ::= <SQL_Parameter_Declaration> <Gen2619_Any> rank => 0
<Gen2621_Maybe> ::= <Gen2621> rank => 0
<Gen2621_Maybe> ::= rank => -1
<SQL_Parameter_Declaration_List> ::= <Left_Paren> <Gen2621_Maybe> <Right_Paren> rank => 0
<Parameter_Mode_Maybe> ::= <Parameter_Mode> rank => 0
<Parameter_Mode_Maybe> ::= rank => -1
<SQL_Parameter_Name_Maybe> ::= <SQL_Parameter_Name> rank => 0
<SQL_Parameter_Name_Maybe> ::= rank => -1
<Result_Maybe> ::= <RESULT> rank => 0
<Result_Maybe> ::= rank => -1
<SQL_Parameter_Declaration> ::= <Parameter_Mode_Maybe> <SQL_Parameter_Name_Maybe> <Parameter_Type> <Result_Maybe> rank => 0
<Parameter_Mode> ::= <IN> rank => 0
                   | <OUT> rank => -1
                   | <INOUT> rank => -2
<Locator_Indication_Maybe> ::= <Locator_Indication> rank => 0
<Locator_Indication_Maybe> ::= rank => -1
<Parameter_Type> ::= <Data_Type> <Locator_Indication_Maybe> rank => 0
<Locator_Indication> ::= <AS> <LOCATOR> rank => 0
<Dispatch_Clause_Maybe> ::= <Dispatch_Clause> rank => 0
<Dispatch_Clause_Maybe> ::= rank => -1
<Function_Specification> ::= <FUNCTION> <Schema_Qualified_Routine_Name> <SQL_Parameter_Declaration_List> <Returns_Clause> <Routine_Characteristics> <Dispatch_Clause_Maybe> rank => 0
<Gen2642> ::= <INSTANCE> rank => 0
            | <STATIC> rank => -1
            | <CONSTRUCTOR> rank => -2
<Gen2642_Maybe> ::= <Gen2642> rank => 0
<Gen2642_Maybe> ::= rank => -1
<Returns_Clause_Maybe> ::= <Returns_Clause> rank => 0
<Returns_Clause_Maybe> ::= rank => -1
<Method_Specification_Designator> ::= <SPECIFIC> <METHOD> <Specific_Method_Name> rank => 0
                                    | <Gen2642_Maybe> <METHOD> <Method_Name> <SQL_Parameter_Declaration_List> <Returns_Clause_Maybe> <FOR> <Schema_Resolved_User_Defined_Type_Name> rank => -1
<Routine_Characteristic_Any> ::= <Routine_Characteristic>* rank => 0
<Routine_Characteristics> ::= <Routine_Characteristic_Any> rank => 0
<Routine_Characteristic> ::= <Language_Clause> rank => 0
                           | <Parameter_Style_Clause> rank => -1
                           | <SPECIFIC> <Specific_Name> rank => -2
                           | <Deterministic_Characteristic> rank => -3
                           | <SQL_Data_Access_Indication> rank => -4
                           | <Null_Call_Clause> rank => -5
                           | <Dynamic_Result_Sets_Characteristic> rank => -6
                           | <Savepoint_Level_Indication> rank => -7
<Savepoint_Level_Indication> ::= <NEW> <SAVEPOINT> <LEVEL> rank => 0
                               | <OLD> <SAVEPOINT> <LEVEL> rank => -1
<Dynamic_Result_Sets_Characteristic> ::= <DYNAMIC> <RESULT> <SETS> <Maximum_Dynamic_Result_Sets> rank => 0
<Parameter_Style_Clause> ::= <PARAMETER> <STYLE> <Parameter_Style> rank => 0
<Dispatch_Clause> ::= <STATIC> <DISPATCH> rank => 0
<Returns_Clause> ::= <RETURNS> <Returns_Type> rank => 0
<Result_Cast_Maybe> ::= <Result_Cast> rank => 0
<Result_Cast_Maybe> ::= rank => -1
<Returns_Type> ::= <Returns_Data_Type> <Result_Cast_Maybe> rank => 0
                 | <Returns_Table_Type> rank => -1
<Returns_Table_Type> ::= <TABLE> <Table_Function_Column_List> rank => 0
<Gen2672> ::= <Comma> <Table_Function_Column_List_Element> rank => 0
<Gen2672_Any> ::= <Gen2672>* rank => 0
<Table_Function_Column_List> ::= <Left_Paren> <Table_Function_Column_List_Element> <Gen2672_Any> <Right_Paren> rank => 0
<Table_Function_Column_List_Element> ::= <Column_Name> <Data_Type> rank => 0
<Result_Cast> ::= <CAST> <FROM> <Result_Cast_From_Type> rank => 0
<Result_Cast_From_Type> ::= <Data_Type> <Locator_Indication_Maybe> rank => 0
<Returns_Data_Type> ::= <Data_Type> <Locator_Indication_Maybe> rank => 0
<Routine_Body> ::= <SQL_Routine_Spec> rank => 0
                 | <External_Body_Reference> rank => -1
<Rights_Clause_Maybe> ::= <Rights_Clause> rank => 0
<Rights_Clause_Maybe> ::= rank => -1
<SQL_Routine_Spec> ::= <Rights_Clause_Maybe> <SQL_Routine_Body> rank => 0
<Rights_Clause> ::= <SQL> <SECURITY> <INVOKER> rank => 0
                  | <SQL> <SECURITY> <DEFINER> rank => -1
<SQL_Routine_Body> ::= <SQL_Procedure_Statement> rank => 0
<Gen2687> ::= <NAME> <External_Routine_Name> rank => 0
<Gen2687_Maybe> ::= <Gen2687> rank => 0
<Gen2687_Maybe> ::= rank => -1
<Parameter_Style_Clause_Maybe> ::= <Parameter_Style_Clause> rank => 0
<Parameter_Style_Clause_Maybe> ::= rank => -1
<Transform_Group_Specification_Maybe> ::= <Transform_Group_Specification> rank => 0
<Transform_Group_Specification_Maybe> ::= rank => -1
<External_Security_Clause_Maybe> ::= <External_Security_Clause> rank => 0
<External_Security_Clause_Maybe> ::= rank => -1
<External_Body_Reference> ::= <EXTERNAL> <Gen2687_Maybe> <Parameter_Style_Clause_Maybe> <Transform_Group_Specification_Maybe> <External_Security_Clause_Maybe> rank => 0
<External_Security_Clause> ::= <EXTERNAL> <SECURITY> <DEFINER> rank => 0
                             | <EXTERNAL> <SECURITY> <INVOKER> rank => -1
                             | <EXTERNAL> <SECURITY> <IMPLEMENTATION> <DEFINED> rank => -2
<Parameter_Style> ::= <SQL> rank => 0
                    | <GENERAL> rank => -1
<Deterministic_Characteristic> ::= <DETERMINISTIC> rank => 0
                                 | <NOT> <DETERMINISTIC> rank => -1
<SQL_Data_Access_Indication> ::= <NO> <SQL> rank => 0
                               | <CONTAINS> <SQL> rank => -1
                               | <READS> <SQL> <DATA> rank => -2
                               | <MODIFIES> <SQL> <DATA> rank => -3
<Null_Call_Clause> ::= <RETURNS> <NULL> <ON> <NULL> <INPUT> rank => 0
                     | <CALLED> <ON> <NULL> <INPUT> rank => -1
<Maximum_Dynamic_Result_Sets> ::= <Unsigned_Integer> rank => 0
<Gen2711> ::= <Single_Group_Specification> rank => 0
            | <Multiple_Group_Specification> rank => -1
<Transform_Group_Specification> ::= <TRANSFORM> <GROUP> <Gen2711> rank => 0
<Single_Group_Specification> ::= <Group_Name> rank => 0
<Gen2715> ::= <Comma> <Group_Specification> rank => 0
<Gen2715_Any> ::= <Gen2715>* rank => 0
<Multiple_Group_Specification> ::= <Group_Specification> <Gen2715_Any> rank => 0
<Group_Specification> ::= <Group_Name> <FOR> <TYPE> <Path_Resolved_User_Defined_Type_Name> rank => 0
<Alter_Routine_Statement> ::= <ALTER> <Specific_Routine_Designator> <Alter_Routine_Characteristics> <Alter_Routine_Behavior> rank => 0
<Alter_Routine_Characteristic_Many> ::= <Alter_Routine_Characteristic>+ rank => 0
<Alter_Routine_Characteristics> ::= <Alter_Routine_Characteristic_Many> rank => 0
<Alter_Routine_Characteristic> ::= <Language_Clause> rank => 0
                                 | <Parameter_Style_Clause> rank => -1
                                 | <SQL_Data_Access_Indication> rank => -2
                                 | <Null_Call_Clause> rank => -3
                                 | <Dynamic_Result_Sets_Characteristic> rank => -4
                                 | <NAME> <External_Routine_Name> rank => -5
<Alter_Routine_Behavior> ::= <RESTRICT> rank => 0
<Drop_Routine_Statement> ::= <DROP> <Specific_Routine_Designator> <Drop_Behavior> rank => 0
<Gen2730> ::= <AS> <ASSIGNMENT> rank => 0
<Gen2730_Maybe> ::= <Gen2730> rank => 0
<Gen2730_Maybe> ::= rank => -1
<User_Defined_Cast_Definition> ::= <CREATE> <CAST> <Left_Paren> <Source_Data_Type> <AS> <Target_Data_Type> <Right_Paren> <WITH> <Cast_Function> <Gen2730_Maybe> rank => 0
<Cast_Function> ::= <Specific_Routine_Designator> rank => 0
<Source_Data_Type> ::= <Data_Type> rank => 0
<Target_Data_Type> ::= <Data_Type> rank => 0
<Drop_User_Defined_Cast_Statement> ::= <DROP> <CAST> <Left_Paren> <Source_Data_Type> <AS> <Target_Data_Type> <Right_Paren> <Drop_Behavior> rank => 0
<User_Defined_Ordering_Definition> ::= <CREATE> <ORDERING> <FOR> <Schema_Resolved_User_Defined_Type_Name> <Ordering_Form> rank => 0
<Ordering_Form> ::= <Equals_Ordering_Form> rank => 0
                  | <Full_Ordering_Form> rank => -1
<Equals_Ordering_Form> ::= <EQUALS> <ONLY> <BY> <Ordering_Category> rank => 0
<Full_Ordering_Form> ::= <ORDER> <FULL> <BY> <Ordering_Category> rank => 0
<Ordering_Category> ::= <Relative_Category> rank => 0
                      | <Map_Category> rank => -1
                      | <State_Category> rank => -2
<Relative_Category> ::= <RELATIVE> <WITH> <Relative_Function_Specification> rank => 0
<Map_Category> ::= <MAP> <WITH> <Map_Function_Specification> rank => 0
<Specific_Name_Maybe> ::= <Specific_Name> rank => 0
<Specific_Name_Maybe> ::= rank => -1
<State_Category> ::= <STATE> <Specific_Name_Maybe> rank => 0
<Relative_Function_Specification> ::= <Specific_Routine_Designator> rank => 0
<Map_Function_Specification> ::= <Specific_Routine_Designator> rank => 0
<Drop_User_Defined_Ordering_Statement> ::= <DROP> <ORDERING> <FOR> <Schema_Resolved_User_Defined_Type_Name> <Drop_Behavior> rank => 0
<Gen2754> ::= <TRANSFORM> rank => 0
            | <TRANSFORMS> rank => -1
<Transform_Group_Many> ::= <Transform_Group>+ rank => 0
<Transform_Definition> ::= <CREATE> <Gen2754> <FOR> <Schema_Resolved_User_Defined_Type_Name> <Transform_Group_Many> rank => 0
<Transform_Group> ::= <Group_Name> <Left_Paren> <Transform_Element_List> <Right_Paren> rank => 0
<Group_Name> ::= <Identifier> rank => 0
<Gen2760> ::= <Comma> <Transform_Element> rank => 0
<Gen2760_Maybe> ::= <Gen2760> rank => 0
<Gen2760_Maybe> ::= rank => -1
<Transform_Element_List> ::= <Transform_Element> <Gen2760_Maybe> rank => 0
<Transform_Element> ::= <To_Sql> rank => 0
                      | <From_Sql> rank => -1
<To_Sql> ::= <TO> <SQL> <WITH> <To_Sql_Function> rank => 0
<From_Sql> ::= <FROM> <SQL> <WITH> <From_Sql_Function> rank => 0
<To_Sql_Function> ::= <Specific_Routine_Designator> rank => 0
<From_Sql_Function> ::= <Specific_Routine_Designator> rank => 0
<Gen2770> ::= <TRANSFORM> rank => 0
            | <TRANSFORMS> rank => -1
<Alter_Group_Many> ::= <Alter_Group>+ rank => 0
<Alter_Transform_Statement> ::= <ALTER> <Gen2770> <FOR> <Schema_Resolved_User_Defined_Type_Name> <Alter_Group_Many> rank => 0
<Alter_Group> ::= <Group_Name> <Left_Paren> <Alter_Transform_Action_List> <Right_Paren> rank => 0
<Gen2775> ::= <Comma> <Alter_Transform_Action> rank => 0
<Gen2775_Any> ::= <Gen2775>* rank => 0
<Alter_Transform_Action_List> ::= <Alter_Transform_Action> <Gen2775_Any> rank => 0
<Alter_Transform_Action> ::= <Add_Transform_Element_List> rank => 0
                           | <Drop_Transform_Element_List> rank => -1
<Add_Transform_Element_List> ::= <ADD> <Left_Paren> <Transform_Element_List> <Right_Paren> rank => 0
<Gen2781> ::= <Comma> <Transform_Kind> rank => 0
<Gen2781_Maybe> ::= <Gen2781> rank => 0
<Gen2781_Maybe> ::= rank => -1
<Drop_Transform_Element_List> ::= <DROP> <Left_Paren> <Transform_Kind> <Gen2781_Maybe> <Drop_Behavior> <Right_Paren> rank => 0
<Transform_Kind> ::= <TO> <SQL> rank => 0
                   | <FROM> <SQL> rank => -1
<Gen2787> ::= <TRANSFORM> rank => 0
            | <TRANSFORMS> rank => -1
<Drop_Transform_Statement> ::= <DROP> <Gen2787> <Transforms_To_Be_Dropped> <FOR> <Schema_Resolved_User_Defined_Type_Name> <Drop_Behavior> rank => 0
<Transforms_To_Be_Dropped> ::= <ALL> rank => 0
                             | <Transform_Group_Element> rank => -1
<Transform_Group_Element> ::= <Group_Name> rank => 0
<Sequence_Generator_Options_Maybe> ::= <Sequence_Generator_Options> rank => 0
<Sequence_Generator_Options_Maybe> ::= rank => -1
<Sequence_Generator_Definition> ::= <CREATE> <SEQUENCE> <Sequence_Generator_Name> <Sequence_Generator_Options_Maybe> rank => 0
<Sequence_Generator_Option_Many> ::= <Sequence_Generator_Option>+ rank => 0
<Sequence_Generator_Options> ::= <Sequence_Generator_Option_Many> rank => 0
<Sequence_Generator_Option> ::= <Sequence_Generator_Data_Type_Option> rank => 0
                              | <Common_Sequence_Generator_Options> rank => -1
<Common_Sequence_Generator_Option_Many> ::= <Common_Sequence_Generator_Option>+ rank => 0
<Common_Sequence_Generator_Options> ::= <Common_Sequence_Generator_Option_Many> rank => 0
<Common_Sequence_Generator_Option> ::= <Sequence_Generator_Start_With_Option> rank => 0
                                     | <Basic_Sequence_Generator_Option> rank => -1
<Basic_Sequence_Generator_Option> ::= <Sequence_Generator_Increment_By_Option> rank => 0
                                    | <Sequence_Generator_Maxvalue_Option> rank => -1
                                    | <Sequence_Generator_Minvalue_Option> rank => -2
                                    | <Sequence_Generator_Cycle_Option> rank => -3
<Sequence_Generator_Data_Type_Option> ::= <AS> <Data_Type> rank => 0
<Sequence_Generator_Start_With_Option> ::= <START> <WITH> <Sequence_Generator_Start_Value> rank => 0
<Sequence_Generator_Start_Value> ::= <Signed_Numeric_Literal> rank => 0
<Sequence_Generator_Increment_By_Option> ::= <INCREMENT> <BY> <Sequence_Generator_Increment> rank => 0
<Sequence_Generator_Increment> ::= <Signed_Numeric_Literal> rank => 0
<Sequence_Generator_Maxvalue_Option> ::= <MAXVALUE> <Sequence_Generator_Max_Value> rank => 0
                                       | <NO> <MAXVALUE> rank => -1
<Sequence_Generator_Max_Value> ::= <Signed_Numeric_Literal> rank => 0
<Sequence_Generator_Minvalue_Option> ::= <MINVALUE> <Sequence_Generator_Min_Value> rank => 0
                                       | <NO> <MINVALUE> rank => -1
<Sequence_Generator_Min_Value> ::= <Signed_Numeric_Literal> rank => 0
<Sequence_Generator_Cycle_Option> ::= <CYCLE> rank => 0
                                    | <NO> <CYCLE> rank => -1
<Alter_Sequence_Generator_Statement> ::= <ALTER> <SEQUENCE> <Sequence_Generator_Name> <Alter_Sequence_Generator_Options> rank => 0
<Alter_Sequence_Generator_Option_Many> ::= <Alter_Sequence_Generator_Option>+ rank => 0
<Alter_Sequence_Generator_Options> ::= <Alter_Sequence_Generator_Option_Many> rank => 0
<Alter_Sequence_Generator_Option> ::= <Alter_Sequence_Generator_Restart_Option> rank => 0
                                    | <Basic_Sequence_Generator_Option> rank => -1
<Alter_Sequence_Generator_Restart_Option> ::= <RESTART> <WITH> <Sequence_Generator_Restart_Value> rank => 0
<Sequence_Generator_Restart_Value> ::= <Signed_Numeric_Literal> rank => 0
<Drop_Sequence_Generator_Statement> ::= <DROP> <SEQUENCE> <Sequence_Generator_Name> <Drop_Behavior> rank => 0
<Grant_Statement> ::= <Grant_Privilege_Statement> rank => 0
                    | <Grant_Role_Statement> rank => -1
<Gen2831> ::= <Comma> <Grantee> rank => 0
<Gen2831_Any> ::= <Gen2831>* rank => 0
<Gen2833> ::= <WITH> <HIERARCHY> <OPTION> rank => 0
<Gen2833_Maybe> ::= <Gen2833> rank => 0
<Gen2833_Maybe> ::= rank => -1
<Gen2836> ::= <WITH> <GRANT> <OPTION> rank => 0
<Gen2836_Maybe> ::= <Gen2836> rank => 0
<Gen2836_Maybe> ::= rank => -1
<Gen2839> ::= <GRANTED> <BY> <Grantor> rank => 0
<Gen2839_Maybe> ::= <Gen2839> rank => 0
<Gen2839_Maybe> ::= rank => -1
<Grant_Privilege_Statement> ::= <GRANT> <Privileges> <TO> <Grantee> <Gen2831_Any> <Gen2833_Maybe> <Gen2836_Maybe> <Gen2839_Maybe> rank => 0
<Privileges> ::= <Object_Privileges> <ON> <Object_Name> rank => 0
<Table_Maybe> ::= <TABLE> rank => 0
<Table_Maybe> ::= rank => -1
<Object_Name> ::= <Table_Maybe> <Table_Name> rank => 0
                | <DOMAIN> <Domain_Name> rank => -1
                | <COLLATION> <Collation_Name> rank => -2
                | <CHARACTER> <SET> <Character_Set_Name> rank => -3
                | <TRANSLATION> <Transliteration_Name> rank => -4
                | <TYPE> <Schema_Resolved_User_Defined_Type_Name> rank => -5
                | <SEQUENCE> <Sequence_Generator_Name> rank => -6
                | <Specific_Routine_Designator> rank => -7
<Gen2854> ::= <Comma> <Action> rank => 0
<Gen2854_Any> ::= <Gen2854>* rank => 0
<Object_Privileges> ::= <ALL> <PRIVILEGES> rank => 0
                      | <Action> <Gen2854_Any> rank => -1
<Gen2858> ::= <Left_Paren> <Privilege_Column_List> <Right_Paren> rank => 0
<Gen2858_Maybe> ::= <Gen2858> rank => 0
<Gen2858_Maybe> ::= rank => -1
<Gen2861> ::= <Left_Paren> <Privilege_Column_List> <Right_Paren> rank => 0
<Gen2861_Maybe> ::= <Gen2861> rank => 0
<Gen2861_Maybe> ::= rank => -1
<Gen2864> ::= <Left_Paren> <Privilege_Column_List> <Right_Paren> rank => 0
<Gen2864_Maybe> ::= <Gen2864> rank => 0
<Gen2864_Maybe> ::= rank => -1
<Action> ::= <SELECT> rank => 0
           | <SELECT> <Left_Paren> <Privilege_Column_List> <Right_Paren> rank => -1
           | <SELECT> <Left_Paren> <Privilege_Method_List> <Right_Paren> rank => -2
           | <DELETE> rank => -3
           | <INSERT> <Gen2858_Maybe> rank => -4
           | <UPDATE> <Gen2861_Maybe> rank => -5
           | <REFERENCES> <Gen2864_Maybe> rank => -6
           | <USAGE> rank => -7
           | <TRIGGER> rank => -8
           | <UNDER> rank => -9
           | <EXECUTE> rank => -10
<Gen2878> ::= <Comma> <Specific_Routine_Designator> rank => 0
<Gen2878_Any> ::= <Gen2878>* rank => 0
<Privilege_Method_List> ::= <Specific_Routine_Designator> <Gen2878_Any> rank => 0
<Privilege_Column_List> ::= <Column_Name_List> rank => 0
<Grantee> ::= <PUBLIC> rank => 0
            | <Authorization_Identifier> rank => -1
<Grantor> ::= <CURRENT_USER> rank => 0
            | <CURRENT_ROLE> rank => -1
<Gen2886> ::= <WITH> <ADMIN> <Grantor> rank => 0
<Gen2886_Maybe> ::= <Gen2886> rank => 0
<Gen2886_Maybe> ::= rank => -1
<Role_Definition> ::= <CREATE> <ROLE> <Role_Name> <Gen2886_Maybe> rank => 0
<Gen2890> ::= <Comma> <Role_Granted> rank => 0
<Gen2890_Any> ::= <Gen2890>* rank => 0
<Gen2892> ::= <Comma> <Grantee> rank => 0
<Gen2892_Any> ::= <Gen2892>* rank => 0
<Gen2894> ::= <WITH> <ADMIN> <OPTION> rank => 0
<Gen2894_Maybe> ::= <Gen2894> rank => 0
<Gen2894_Maybe> ::= rank => -1
<Gen2897> ::= <GRANTED> <BY> <Grantor> rank => 0
<Gen2897_Maybe> ::= <Gen2897> rank => 0
<Gen2897_Maybe> ::= rank => -1
<Grant_Role_Statement> ::= <GRANT> <Role_Granted> <Gen2890_Any> <TO> <Grantee> <Gen2892_Any> <Gen2894_Maybe> <Gen2897_Maybe> rank => 0
<Role_Granted> ::= <Role_Name> rank => 0
<Drop_Role_Statement> ::= <DROP> <ROLE> <Role_Name> rank => 0
<Revoke_Statement> ::= <Revoke_Privilege_Statement> rank => 0
                     | <Revoke_Role_Statement> rank => -1
<Revoke_Option_Extension_Maybe> ::= <Revoke_Option_Extension> rank => 0
<Revoke_Option_Extension_Maybe> ::= rank => -1
<Gen2907> ::= <Comma> <Grantee> rank => 0
<Gen2907_Any> ::= <Gen2907>* rank => 0
<Gen2909> ::= <GRANTED> <BY> <Grantor> rank => 0
<Gen2909_Maybe> ::= <Gen2909> rank => 0
<Gen2909_Maybe> ::= rank => -1
<Revoke_Privilege_Statement> ::= <REVOKE> <Revoke_Option_Extension_Maybe> <Privileges> <FROM> <Grantee> <Gen2907_Any> <Gen2909_Maybe> <Drop_Behavior> rank => 0
<Revoke_Option_Extension> ::= <GRANT> <OPTION> <FOR> rank => 0
                            | <HIERARCHY> <OPTION> <FOR> rank => -1
<Gen2915> ::= <ADMIN> <OPTION> <FOR> rank => 0
<Gen2915_Maybe> ::= <Gen2915> rank => 0
<Gen2915_Maybe> ::= rank => -1
<Gen2918> ::= <Comma> <Role_Revoked> rank => 0
<Gen2918_Any> ::= <Gen2918>* rank => 0
<Gen2920> ::= <Comma> <Grantee> rank => 0
<Gen2920_Any> ::= <Gen2920>* rank => 0
<Gen2922> ::= <GRANTED> <BY> <Grantor> rank => 0
<Gen2922_Maybe> ::= <Gen2922> rank => 0
<Gen2922_Maybe> ::= rank => -1
<Revoke_Role_Statement> ::= <REVOKE> <Gen2915_Maybe> <Role_Revoked> <Gen2918_Any> <FROM> <Grantee> <Gen2920_Any> <Gen2922_Maybe> <Drop_Behavior> rank => 0
<Role_Revoked> ::= <Role_Name> rank => 0
<Module_Path_Specification_Maybe> ::= <Module_Path_Specification> rank => 0
<Module_Path_Specification_Maybe> ::= rank => -1
<Module_Transform_Group_Specification_Maybe> ::= <Module_Transform_Group_Specification> rank => 0
<Module_Transform_Group_Specification_Maybe> ::= rank => -1
<Module_Collations_Maybe> ::= <Module_Collations> rank => 0
<Module_Collations_Maybe> ::= rank => -1
<Temporary_Table_Declaration_Any> ::= <Temporary_Table_Declaration>* rank => 0
<Module_Contents_Many> ::= <Module_Contents>+ rank => 0
<SQL_Client_Module_Definition> ::= <Module_Name_Clause> <Language_Clause> <Module_Authorization_Clause> <Module_Path_Specification_Maybe> <Module_Transform_Group_Specification_Maybe> <Module_Collations_Maybe> <Temporary_Table_Declaration_Any> <Module_Contents_Many> rank => 0
<Gen2936> ::= <ONLY> rank => 0
            | <AND> <DYNAMIC> rank => -1
<Gen2938> ::= <FOR> <STATIC> <Gen2936> rank => 0
<Gen2938_Maybe> ::= <Gen2938> rank => 0
<Gen2938_Maybe> ::= rank => -1
<Gen2941> ::= <ONLY> rank => 0
            | <AND> <DYNAMIC> rank => -1
<Gen2943> ::= <FOR> <STATIC> <Gen2941> rank => 0
<Gen2943_Maybe> ::= <Gen2943> rank => 0
<Gen2943_Maybe> ::= rank => -1
<Module_Authorization_Clause> ::= <SCHEMA> <Schema_Name> rank => 0
                                | <AUTHORIZATION> <Module_Authorization_Identifier> <Gen2938_Maybe> rank => -1
                                | <SCHEMA> <Schema_Name> <AUTHORIZATION> <Module_Authorization_Identifier> <Gen2943_Maybe> rank => -2
<Module_Authorization_Identifier> ::= <Authorization_Identifier> rank => 0
<Module_Path_Specification> ::= <Path_Specification> rank => 0
<Module_Transform_Group_Specification> ::= <Transform_Group_Specification> rank => 0
<Module_Collation_Specification_Many> ::= <Module_Collation_Specification>+ rank => 0
<Module_Collations> ::= <Module_Collation_Specification_Many> rank => 0
<Gen2954> ::= <FOR> <Character_Set_Specification_List> rank => 0
<Gen2954_Maybe> ::= <Gen2954> rank => 0
<Gen2954_Maybe> ::= rank => -1
<Module_Collation_Specification> ::= <COLLATION> <Collation_Name> <Gen2954_Maybe> rank => 0
<Gen2958> ::= <Comma> <Character_Set_Specification> rank => 0
<Gen2958_Any> ::= <Gen2958>* rank => 0
<Character_Set_Specification_List> ::= <Character_Set_Specification> <Gen2958_Any> rank => 0
<Module_Contents> ::= <Declare_Cursor> rank => 0
                    | <Dynamic_Declare_Cursor> rank => -1
                    | <Externally_Invoked_Procedure> rank => -2
<SQL_Client_Module_Name_Maybe> ::= <SQL_Client_Module_Name> rank => 0
<SQL_Client_Module_Name_Maybe> ::= rank => -1
<Module_Character_Set_Specification_Maybe> ::= <Module_Character_Set_Specification> rank => 0
<Module_Character_Set_Specification_Maybe> ::= rank => -1
<Module_Name_Clause> ::= <MODULE> <SQL_Client_Module_Name_Maybe> <Module_Character_Set_Specification_Maybe> rank => 0
<Module_Character_Set_Specification> ::= <NAMES> <ARE> <Character_Set_Specification> rank => 0
<Externally_Invoked_Procedure> ::= <PROCEDURE> <Procedure_Name> <Host_Parameter_Declaration_List> <Semicolon> <SQL_Procedure_Statement> <Semicolon> rank => 0
<Gen2971> ::= <Comma> <Host_Parameter_Declaration> rank => 0
<Gen2971_Any> ::= <Gen2971>* rank => 0
<Host_Parameter_Declaration_List> ::= <Left_Paren> <Host_Parameter_Declaration> <Gen2971_Any> <Right_Paren> rank => 0
<Host_Parameter_Declaration> ::= <Host_Parameter_Name> <Host_Parameter_Data_Type> rank => 0
                               | <Status_Parameter> rank => -1
<Host_Parameter_Data_Type> ::= <Data_Type> <Locator_Indication_Maybe> rank => 0
<Status_Parameter> ::= <SQLSTATE> rank => 0
<SQL_Procedure_Statement> ::= <SQL_Executable_Statement> rank => 0
<SQL_Executable_Statement> ::= <SQL_Schema_Statement> rank => 0
                             | <SQL_Data_Statement> rank => -1
                             | <SQL_Control_Statement> rank => -2
                             | <SQL_Transaction_Statement> rank => -3
                             | <SQL_Connection_Statement> rank => -4
                             | <SQL_Session_Statement> rank => -5
                             | <SQL_Diagnostics_Statement> rank => -6
                             | <SQL_Dynamic_Statement> rank => -7
<SQL_Schema_Statement> ::= <SQL_Schema_Definition_Statement> rank => 0
                         | <SQL_Schema_Manipulation_Statement> rank => -1
<SQL_Schema_Definition_Statement> ::= <Schema_Definition> rank => 0
                                    | <Table_Definition> rank => -1
                                    | <View_Definition> rank => -2
                                    | <SQL_Invoked_Routine> rank => -3
                                    | <Grant_Statement> rank => -4
                                    | <Role_Definition> rank => -5
                                    | <Domain_Definition> rank => -6
                                    | <Character_Set_Definition> rank => -7
                                    | <Collation_Definition> rank => -8
                                    | <Transliteration_Definition> rank => -9
                                    | <Assertion_Definition> rank => -10
                                    | <Trigger_Definition> rank => -11
                                    | <User_Defined_Type_Definition> rank => -12
                                    | <User_Defined_Cast_Definition> rank => -13
                                    | <User_Defined_Ordering_Definition> rank => -14
                                    | <Transform_Definition> rank => -15
                                    | <Sequence_Generator_Definition> rank => -16
<SQL_Schema_Manipulation_Statement> ::= <Drop_Schema_Statement> rank => 0
                                      | <Alter_Table_Statement> rank => -1
                                      | <Drop_Table_Statement> rank => -2
                                      | <Drop_View_Statement> rank => -3
                                      | <Alter_Routine_Statement> rank => -4
                                      | <Drop_Routine_Statement> rank => -5
                                      | <Drop_User_Defined_Cast_Statement> rank => -6
                                      | <Revoke_Statement> rank => -7
                                      | <Drop_Role_Statement> rank => -8
                                      | <Alter_Domain_Statement> rank => -9
                                      | <Drop_Domain_Statement> rank => -10
                                      | <Drop_Character_Set_Statement> rank => -11
                                      | <Drop_Collation_Statement> rank => -12
                                      | <Drop_Transliteration_Statement> rank => -13
                                      | <Drop_Assertion_Statement> rank => -14
                                      | <Drop_Trigger_Statement> rank => -15
                                      | <Alter_Type_Statement> rank => -16
                                      | <Drop_Data_Type_Statement> rank => -17
                                      | <Drop_User_Defined_Ordering_Statement> rank => -18
                                      | <Alter_Transform_Statement> rank => -19
                                      | <Drop_Transform_Statement> rank => -20
                                      | <Alter_Sequence_Generator_Statement> rank => -21
                                      | <Drop_Sequence_Generator_Statement> rank => -22
<SQL_Data_Statement> ::= <Open_Statement> rank => 0
                       | <Fetch_Statement> rank => -1
                       | <Close_Statement> rank => -2
                       | <Select_Statement_Single_Row> rank => -3
                       | <Free_Locator_Statement> rank => -4
                       | <Hold_Locator_Statement> rank => -5
                       | <SQL_Data_Change_Statement> rank => -6
<SQL_Data_Change_Statement> ::= <Delete_Statement_Positioned> rank => 0
                              | <Delete_Statement_Searched> rank => -1
                              | <Insert_Statement> rank => -2
                              | <Update_Statement_Positioned> rank => -3
                              | <Update_Statement_Searched> rank => -4
                              | <Merge_Statement> rank => -5
<SQL_Control_Statement> ::= <Call_Statement> rank => 0
                          | <Return_Statement> rank => -1
<SQL_Transaction_Statement> ::= <Start_Transaction_Statement> rank => 0
                              | <Set_Transaction_Statement> rank => -1
                              | <Set_Constraints_Mode_Statement> rank => -2
                              | <Savepoint_Statement> rank => -3
                              | <Release_Savepoint_Statement> rank => -4
                              | <Commit_Statement> rank => -5
                              | <Rollback_Statement> rank => -6
<SQL_Connection_Statement> ::= <Connect_Statement> rank => 0
                             | <Set_Connection_Statement> rank => -1
                             | <Disconnect_Statement> rank => -2
<SQL_Session_Statement> ::= <Set_Session_User_Identifier_Statement> rank => 0
                          | <Set_Role_Statement> rank => -1
                          | <Set_Local_Time_Zone_Statement> rank => -2
                          | <Set_Session_Characteristics_Statement> rank => -3
                          | <Set_Catalog_Statement> rank => -4
                          | <Set_Schema_Statement> rank => -5
                          | <Set_Names_Statement> rank => -6
                          | <Set_Path_Statement> rank => -7
                          | <Set_Transform_Group_Statement> rank => -8
                          | <Set_Session_Collation_Statement> rank => -9
<SQL_Diagnostics_Statement> ::= <Get_Diagnostics_Statement> rank => 0
<SQL_Dynamic_Statement> ::= <System_Descriptor_Statement> rank => 0
                          | <Prepare_Statement> rank => -1
                          | <Deallocate_Prepared_Statement> rank => -2
                          | <Describe_Statement> rank => -3
                          | <Execute_Statement> rank => -4
                          | <Execute_Immediate_Statement> rank => -5
                          | <SQL_Dynamic_Data_Statement> rank => -6
<SQL_Dynamic_Data_Statement> ::= <Allocate_Cursor_Statement> rank => 0
                               | <Dynamic_Open_Statement> rank => -1
                               | <Dynamic_Fetch_Statement> rank => -2
                               | <Dynamic_Close_Statement> rank => -3
                               | <Dynamic_Delete_Statement_Positioned> rank => -4
                               | <Dynamic_Update_Statement_Positioned> rank => -5
<System_Descriptor_Statement> ::= <Allocate_Descriptor_Statement> rank => 0
                                | <Deallocate_Descriptor_Statement> rank => -1
                                | <Set_Descriptor_Statement> rank => -2
                                | <Get_Descriptor_Statement> rank => -3
<Cursor_Sensitivity_Maybe> ::= <Cursor_Sensitivity> rank => 0
<Cursor_Sensitivity_Maybe> ::= rank => -1
<Cursor_Scrollability_Maybe> ::= <Cursor_Scrollability> rank => 0
<Cursor_Scrollability_Maybe> ::= rank => -1
<Cursor_Holdability_Maybe> ::= <Cursor_Holdability> rank => 0
<Cursor_Holdability_Maybe> ::= rank => -1
<Cursor_Returnability_Maybe> ::= <Cursor_Returnability> rank => 0
<Cursor_Returnability_Maybe> ::= rank => -1
<Declare_Cursor> ::= <DECLARE> <Cursor_Name> <Cursor_Sensitivity_Maybe> <Cursor_Scrollability_Maybe> <CURSOR> <Cursor_Holdability_Maybe> <Cursor_Returnability_Maybe> <FOR> <Cursor_Specification> rank => 0
<Cursor_Sensitivity> ::= <SENSITIVE> rank => 0
                       | <INSENSITIVE> rank => -1
                       | <ASENSITIVE> rank => -2
<Cursor_Scrollability> ::= <SCROLL> rank => 0
                         | <NO> <SCROLL> rank => -1
<Cursor_Holdability> ::= <WITH> <HOLD> rank => 0
                       | <WITHOUT> <HOLD> rank => -1
<Cursor_Returnability> ::= <WITH> <RETURN> rank => 0
                         | <WITHOUT> <RETURN> rank => -1
<Updatability_Clause_Maybe> ::= <Updatability_Clause> rank => 0
<Updatability_Clause_Maybe> ::= rank => -1
<Cursor_Specification> ::= <Query_Expression> <Order_By_Clause_Maybe> <Updatability_Clause_Maybe> rank => 0
<Gen3103> ::= <OF> <Column_Name_List> rank => 0
<Gen3103_Maybe> ::= <Gen3103> rank => 0
<Gen3103_Maybe> ::= rank => -1
<Gen3106> ::= <READ> <ONLY> rank => 0
            | <UPDATE> <Gen3103_Maybe> rank => -1
<Updatability_Clause> ::= <FOR> <Gen3106> rank => 0
<Order_By_Clause> ::= <ORDER> <BY> <Sort_Specification_List> rank => 0
<Open_Statement> ::= <OPEN> <Cursor_Name> rank => 0
<Fetch_Orientation_Maybe> ::= <Fetch_Orientation> rank => 0
<Fetch_Orientation_Maybe> ::= rank => -1
<Gen3113> ::= <Fetch_Orientation_Maybe> <FROM> rank => 0
<Gen3113_Maybe> ::= <Gen3113> rank => 0
<Gen3113_Maybe> ::= rank => -1
<Fetch_Statement> ::= <FETCH> <Gen3113_Maybe> <Cursor_Name> <INTO> <Fetch_Target_List> rank => 0
<Gen3117> ::= <ABSOLUTE> rank => 0
            | <RELATIVE> rank => -1
<Fetch_Orientation> ::= <NEXT> rank => 0
                      | <PRIOR> rank => -1
                      | <FIRST> rank => -2
                      | <LAST> rank => -3
                      | <Gen3117> <Simple_Value_Specification> rank => -4
<Gen3124> ::= <Comma> <Target_Specification> rank => 0
<Gen3124_Any> ::= <Gen3124>* rank => 0
<Fetch_Target_List> ::= <Target_Specification> <Gen3124_Any> rank => 0
<Close_Statement> ::= <CLOSE> <Cursor_Name> rank => 0
<Select_Statement_Single_Row> ::= <SELECT> <Set_Quantifier_Maybe> <Select_List> <INTO> <Select_Target_List> <Table_Expression> rank => 0
<Gen3129> ::= <Comma> <Target_Specification> rank => 0
<Gen3129_Any> ::= <Gen3129>* rank => 0
<Select_Target_List> ::= <Target_Specification> <Gen3129_Any> rank => 0
<Delete_Statement_Positioned> ::= <DELETE> <FROM> <Target_Table> <WHERE> <CURRENT> <OF> <Cursor_Name> rank => 0
<Target_Table> ::= <Table_Name> rank => 0
                 | <ONLY> <Left_Paren> <Table_Name> <Right_Paren> rank => -1
<Gen3135> ::= <WHERE> <Search_Condition> rank => 0
<Gen3135_Maybe> ::= <Gen3135> rank => 0
<Gen3135_Maybe> ::= rank => -1
<Delete_Statement_Searched> ::= <DELETE> <FROM> <Target_Table> <Gen3135_Maybe> rank => 0
<Insert_Statement> ::= <INSERT> <INTO> <Insertion_Target> <Insert_Columns_And_Source> rank => 0
<Insertion_Target> ::= <Table_Name> rank => 0
<Insert_Columns_And_Source> ::= <From_Subquery> rank => 0
                              | <From_Constructor> rank => -1
                              | <From_Default> rank => -2
<Gen3144> ::= <Left_Paren> <Insert_Column_List> <Right_Paren> rank => 0
<Gen3144_Maybe> ::= <Gen3144> rank => 0
<Gen3144_Maybe> ::= rank => -1
<Override_Clause_Maybe> ::= <Override_Clause> rank => 0
<Override_Clause_Maybe> ::= rank => -1
<From_Subquery> ::= <Gen3144_Maybe> <Override_Clause_Maybe> <Query_Expression> rank => 0
<Gen3150> ::= <Left_Paren> <Insert_Column_List> <Right_Paren> rank => 0
<Gen3150_Maybe> ::= <Gen3150> rank => 0
<Gen3150_Maybe> ::= rank => -1
<From_Constructor> ::= <Gen3150_Maybe> <Override_Clause_Maybe> <Contextually_Typed_Table_Value_Constructor> rank => 0
<Override_Clause> ::= <OVERRIDING> <USER> <VALUE> rank => 0
                    | <OVERRIDING> <SYSTEM> <VALUE> rank => -1
<From_Default> ::= <DEFAULT> <VALUES> rank => 0
<Insert_Column_List> ::= <Column_Name_List> rank => 0
<Gen3158> ::= <As_Maybe> <Merge_Correlation_Name> rank => 0
<Gen3158_Maybe> ::= <Gen3158> rank => 0
<Gen3158_Maybe> ::= rank => -1
<Merge_Statement> ::= <MERGE> <INTO> <Target_Table> <Gen3158_Maybe> <USING> <Table_Reference> <ON> <Search_Condition> <Merge_Operation_Specification> rank => 0
<Merge_Correlation_Name> ::= <Correlation_Name> rank => 0
<Merge_When_Clause_Many> ::= <Merge_When_Clause>+ rank => 0
<Merge_Operation_Specification> ::= <Merge_When_Clause_Many> rank => 0
<Merge_When_Clause> ::= <Merge_When_Matched_Clause> rank => 0
                      | <Merge_When_Not_Matched_Clause> rank => -1
<Merge_When_Matched_Clause> ::= <WHEN> <MATCHED> <THEN> <Merge_Update_Specification> rank => 0
<Merge_When_Not_Matched_Clause> ::= <WHEN> <NOT> <MATCHED> <THEN> <Merge_Insert_Specification> rank => 0
<Merge_Update_Specification> ::= <UPDATE> <SET> <Set_Clause_List> rank => 0
<Gen3170> ::= <Left_Paren> <Insert_Column_List> <Right_Paren> rank => 0
<Gen3170_Maybe> ::= <Gen3170> rank => 0
<Gen3170_Maybe> ::= rank => -1
<Merge_Insert_Specification> ::= <INSERT> <Gen3170_Maybe> <Override_Clause_Maybe> <VALUES> <Merge_Insert_Value_List> rank => 0
<Gen3174> ::= <Comma> <Merge_Insert_Value_Element> rank => 0
<Gen3174_Any> ::= <Gen3174>* rank => 0
<Merge_Insert_Value_List> ::= <Left_Paren> <Merge_Insert_Value_Element> <Gen3174_Any> <Right_Paren> rank => 0
<Merge_Insert_Value_Element> ::= <Value_Expression> rank => 0
                               | <Contextually_Typed_Value_Specification> rank => -1
<Update_Statement_Positioned> ::= <UPDATE> <Target_Table> <SET> <Set_Clause_List> <WHERE> <CURRENT> <OF> <Cursor_Name> rank => 0
<Gen3180> ::= <WHERE> <Search_Condition> rank => 0
<Gen3180_Maybe> ::= <Gen3180> rank => 0
<Gen3180_Maybe> ::= rank => -1
<Update_Statement_Searched> ::= <UPDATE> <Target_Table> <SET> <Set_Clause_List> <Gen3180_Maybe> rank => 0
<Gen3184> ::= <Comma> <Set_Clause> rank => 0
<Gen3184_Any> ::= <Gen3184>* rank => 0
<Set_Clause_List> ::= <Set_Clause> <Gen3184_Any> rank => 0
<Set_Clause> ::= <Multiple_Column_Assignment> rank => 0
               | <Set_Target> <Equals_Operator> <Update_Source> rank => -1
<Set_Target> ::= <Update_Target> rank => 0
               | <Mutated_Set_Clause> rank => -1
<Multiple_Column_Assignment> ::= <Set_Target_List> <Equals_Operator> <Assigned_Row> rank => 0
<Gen3192> ::= <Comma> <Set_Target> rank => 0
<Gen3192_Any> ::= <Gen3192>* rank => 0
<Set_Target_List> ::= <Left_Paren> <Set_Target> <Gen3192_Any> <Right_Paren> rank => 0
<Assigned_Row> ::= <Contextually_Typed_Row_Value_Expression> rank => 0
<Update_Target> ::= <Object_Column> rank => 0
                  | <Object_Column> <Left_Bracket_Or_Trigraph> <Simple_Value_Specification> <Right_Bracket_Or_Trigraph> rank => -1
<Object_Column> ::= <Column_Name> rank => 0
<Mutated_Set_Clause> ::= <Mutated_Target> <Period> <Method_Name> rank => 0
<Mutated_Target> ::= <Object_Column> rank => 0
                   | <Mutated_Set_Clause> rank => -1
<Update_Source> ::= <Value_Expression> rank => 0
                  | <Contextually_Typed_Value_Specification> rank => -1
<Gen3204> ::= <ON> <COMMIT> <Table_Commit_Action> <ROWS> rank => 0
<Gen3204_Maybe> ::= <Gen3204> rank => 0
<Gen3204_Maybe> ::= rank => -1
<Temporary_Table_Declaration> ::= <DECLARE> <LOCAL> <TEMPORARY> <TABLE> <Table_Name> <Table_Element_List> <Gen3204_Maybe> rank => 0
<Gen3208> ::= <Comma> <Locator_Reference> rank => 0
<Gen3208_Any> ::= <Gen3208>* rank => 0
<Free_Locator_Statement> ::= <FREE> <LOCATOR> <Locator_Reference> <Gen3208_Any> rank => 0
<Locator_Reference> ::= <Host_Parameter_Name> rank => 0
                      | <Embedded_Variable_Name> rank => -1
<Gen3213> ::= <Comma> <Locator_Reference> rank => 0
<Gen3213_Any> ::= <Gen3213>* rank => 0
<Hold_Locator_Statement> ::= <HOLD> <LOCATOR> <Locator_Reference> <Gen3213_Any> rank => 0
<Call_Statement> ::= <CALL> <Routine_Invocation> rank => 0
<Return_Statement> ::= <RETURN> <Return_Value> rank => 0
<Return_Value> ::= <Value_Expression> rank => 0
                 | <NULL> rank => -1
<Gen3220> ::= <Comma> <Transaction_Mode> rank => 0
<Gen3220_Any> ::= <Gen3220>* rank => 0
<Gen3222> ::= <Transaction_Mode> <Gen3220_Any> rank => 0
<Gen3222_Maybe> ::= <Gen3222> rank => 0
<Gen3222_Maybe> ::= rank => -1
<Start_Transaction_Statement> ::= <START> <TRANSACTION> <Gen3222_Maybe> rank => 0
<Transaction_Mode> ::= <Isolation_Level> rank => 0
                     | <Transaction_Access_Mode> rank => -1
                     | <Diagnostics_Size> rank => -2
<Transaction_Access_Mode> ::= <READ> <ONLY> rank => 0
                            | <READ> <WRITE> rank => -1
<Isolation_Level> ::= <ISOLATION> <LEVEL> <Level_Of_Isolation> rank => 0
<Level_Of_Isolation> ::= <READ> <UNCOMMITTED> rank => 0
                       | <READ> <COMMITTED> rank => -1
                       | <REPEATABLE> <READ> rank => -2
                       | <SERIALIZABLE> rank => -3
<Diagnostics_Size> ::= <DIAGNOSTICS> <SIZE> <Number_Of_Conditions> rank => 0
<Number_Of_Conditions> ::= <Simple_Value_Specification> rank => 0
<Local_Maybe> ::= <LOCAL> rank => 0
<Local_Maybe> ::= rank => -1
<Set_Transaction_Statement> ::= <SET> <Local_Maybe> <Transaction_Characteristics> rank => 0
<Gen3241> ::= <Comma> <Transaction_Mode> rank => 0
<Gen3241_Any> ::= <Gen3241>* rank => 0
<Transaction_Characteristics> ::= <TRANSACTION> <Transaction_Mode> <Gen3241_Any> rank => 0
<Gen3244> ::= <DEFERRED> rank => 0
            | <IMMEDIATE> rank => -1
<Set_Constraints_Mode_Statement> ::= <SET> <CONSTRAINTS> <Constraint_Name_List> <Gen3244> rank => 0
<Gen3247> ::= <Comma> <Constraint_Name> rank => 0
<Gen3247_Any> ::= <Gen3247>* rank => 0
<Constraint_Name_List> ::= <ALL> rank => 0
                         | <Constraint_Name> <Gen3247_Any> rank => -1
<Savepoint_Statement> ::= <SAVEPOINT> <Savepoint_Specifier> rank => 0
<Savepoint_Specifier> ::= <Savepoint_Name> rank => 0
<Release_Savepoint_Statement> ::= <RELEASE> <SAVEPOINT> <Savepoint_Specifier> rank => 0
<Work_Maybe> ::= <WORK> rank => 0
<Work_Maybe> ::= rank => -1
<No_Maybe> ::= <NO> rank => 0
<No_Maybe> ::= rank => -1
<Gen3258> ::= <AND> <No_Maybe> <CHAIN> rank => 0
<Gen3258_Maybe> ::= <Gen3258> rank => 0
<Gen3258_Maybe> ::= rank => -1
<Commit_Statement> ::= <COMMIT> <Work_Maybe> <Gen3258_Maybe> rank => 0
<Gen3262> ::= <AND> <No_Maybe> <CHAIN> rank => 0
<Gen3262_Maybe> ::= <Gen3262> rank => 0
<Gen3262_Maybe> ::= rank => -1
<Savepoint_Clause_Maybe> ::= <Savepoint_Clause> rank => 0
<Savepoint_Clause_Maybe> ::= rank => -1
<Rollback_Statement> ::= <ROLLBACK> <Work_Maybe> <Gen3262_Maybe> <Savepoint_Clause_Maybe> rank => 0
<Savepoint_Clause> ::= <TO> <SAVEPOINT> <Savepoint_Specifier> rank => 0
<Connect_Statement> ::= <CONNECT> <TO> <Connection_Target> rank => 0
<Gen3270> ::= <AS> <Connection_Name> rank => 0
<Gen3270_Maybe> ::= <Gen3270> rank => 0
<Gen3270_Maybe> ::= rank => -1
<Gen3273> ::= <USER> <Connection_User_Name> rank => 0
<Gen3273_Maybe> ::= <Gen3273> rank => 0
<Gen3273_Maybe> ::= rank => -1
<Connection_Target> ::= <Sql_Server_Name> <Gen3270_Maybe> <Gen3273_Maybe> rank => 0
                      | <DEFAULT> rank => -1
<Set_Connection_Statement> ::= <SET> <CONNECTION> <Connection_Object> rank => 0
<Connection_Object> ::= <DEFAULT> rank => 0
                      | <Connection_Name> rank => -1
<Disconnect_Statement> ::= <DISCONNECT> <Disconnect_Object> rank => 0
<Disconnect_Object> ::= <Connection_Object> rank => 0
                      | <ALL> rank => -1
                      | <CURRENT> rank => -2
<Set_Session_Characteristics_Statement> ::= <SET> <SESSION> <CHARACTERISTICS> <AS> <Session_Characteristic_List> rank => 0
<Gen3286> ::= <Comma> <Session_Characteristic> rank => 0
<Gen3286_Any> ::= <Gen3286>* rank => 0
<Session_Characteristic_List> ::= <Session_Characteristic> <Gen3286_Any> rank => 0
<Session_Characteristic> ::= <Transaction_Characteristics> rank => 0
<Set_Session_User_Identifier_Statement> ::= <SET> <SESSION> <AUTHORIZATION> <Value_Specification> rank => 0
<Set_Role_Statement> ::= <SET> <ROLE> <Role_Specification> rank => 0
<Role_Specification> ::= <Value_Specification> rank => 0
                       | <NONE> rank => -1
<Set_Local_Time_Zone_Statement> ::= <SET> <TIME> <ZONE> <Set_Time_Zone_Value> rank => 0
<Set_Time_Zone_Value> ::= <Interval_Value_Expression> rank => 0
                        | <LOCAL> rank => -1
<Set_Catalog_Statement> ::= <SET> <Catalog_Name_Characteristic> rank => 0
<Catalog_Name_Characteristic> ::= <CATALOG> <Value_Specification> rank => 0
<Set_Schema_Statement> ::= <SET> <Schema_Name_Characteristic> rank => 0
<Schema_Name_Characteristic> ::= <SCHEMA> <Value_Specification> rank => 0
<Set_Names_Statement> ::= <SET> <Character_Set_Name_Characteristic> rank => 0
<Character_Set_Name_Characteristic> ::= <NAMES> <Value_Specification> rank => 0
<Set_Path_Statement> ::= <SET> <SQL_Path_Characteristic> rank => 0
<SQL_Path_Characteristic> ::= <PATH> <Value_Specification> rank => 0
<Set_Transform_Group_Statement> ::= <SET> <Transform_Group_Characteristic> rank => 0
<Transform_Group_Characteristic> ::= <DEFAULT> <TRANSFORM> <GROUP> <Value_Specification> rank => 0
                                   | <TRANSFORM> <GROUP> <FOR> <TYPE> <Path_Resolved_User_Defined_Type_Name> <Value_Specification> rank => -1
<Gen3308> ::= <FOR> <Character_Set_Specification_List> rank => 0
<Gen3308_Maybe> ::= <Gen3308> rank => 0
<Gen3308_Maybe> ::= rank => -1
<Gen3311> ::= <FOR> <Character_Set_Specification_List> rank => 0
<Gen3311_Maybe> ::= <Gen3311> rank => 0
<Gen3311_Maybe> ::= rank => -1
<Set_Session_Collation_Statement> ::= <SET> <COLLATION> <Collation_Specification> <Gen3308_Maybe> rank => 0
                                    | <SET> <NO> <COLLATION> <Gen3311_Maybe> rank => -1
<Gen3316> ::= <Comma> <Character_Set_Specification> rank => 0
<Gen3316_Any> ::= <Gen3316>* rank => 0
<Character_Set_Specification_List> ::= <Character_Set_Specification> <Gen3316_Any> rank => -1
<Collation_Specification> ::= <Value_Specification> rank => 0
<SQL_Maybe> ::= <SQL> rank => 0
<SQL_Maybe> ::= rank => -1
<Gen3322> ::= <WITH> <MAX> <Occurrences> rank => 0
<Gen3322_Maybe> ::= <Gen3322> rank => 0
<Gen3322_Maybe> ::= rank => -1
<Allocate_Descriptor_Statement> ::= <ALLOCATE> <SQL_Maybe> <DESCRIPTOR> <Descriptor_Name> <Gen3322_Maybe> rank => 0
<Occurrences> ::= <Simple_Value_Specification> rank => 0
<Deallocate_Descriptor_Statement> ::= <DEALLOCATE> <SQL_Maybe> <DESCRIPTOR> <Descriptor_Name> rank => 0
<Get_Descriptor_Statement> ::= <GET> <SQL_Maybe> <DESCRIPTOR> <Descriptor_Name> <Get_Descriptor_Information> rank => 0
<Gen3329> ::= <Comma> <Get_Header_Information> rank => 0
<Gen3329_Any> ::= <Gen3329>* rank => 0
<Gen3331> ::= <Comma> <Get_Item_Information> rank => 0
<Gen3331_Any> ::= <Gen3331>* rank => 0
<Get_Descriptor_Information> ::= <Get_Header_Information> <Gen3329_Any> rank => 0
                               | <VALUE> <Item_Number> <Get_Item_Information> <Gen3331_Any> rank => -1
<Get_Header_Information> ::= <Simple_Target_Specification_1> <Equals_Operator> <Header_Item_Name> rank => 0
<Header_Item_Name> ::= <COUNT> rank => 0
                     | <KEY_TYPE> rank => -1
                     | <DYNAMIC_FUNCTION> rank => -2
                     | <DYNAMIC_FUNCTION_CODE> rank => -3
                     | <TOP_LEVEL_COUNT> rank => -4
<Get_Item_Information> ::= <Simple_Target_Specification_2> <Equals_Operator> <Descriptor_Item_Name> rank => 0
<Item_Number> ::= <Simple_Value_Specification> rank => 0
<Simple_Target_Specification_1> ::= <Simple_Target_Specification> rank => 0
<Simple_Target_Specification_2> ::= <Simple_Target_Specification> rank => 0
<Descriptor_Item_Name> ::= <CARDINALITY> rank => 0
                         | <CHARACTER_SET_CATALOG> rank => -1
                         | <CHARACTER_SET_NAME> rank => -2
                         | <CHARACTER_SET_SCHEMA> rank => -3
                         | <COLLATION_CATALOG> rank => -4
                         | <COLLATION_NAME> rank => -5
                         | <COLLATION_SCHEMA> rank => -6
                         | <DATA> rank => -7
                         | <DATETIME_INTERVAL_CODE> rank => -8
                         | <DATETIME_INTERVAL_PRECISION> rank => -9
                         | <DEGREE> rank => -10
                         | <INDICATOR> rank => -11
                         | <KEY_MEMBER> rank => -12
                         | <LENGTH> rank => -13
                         | <LEVEL> rank => -14
                         | <NAME> rank => -15
                         | <NULLABLE> rank => -16
                         | <OCTET_LENGTH> rank => -17
                         | <PARAMETER_MODE> rank => -18
                         | <PARAMETER_ORDINAL_POSITION> rank => -19
                         | <PARAMETER_SPECIFIC_CATALOG> rank => -20
                         | <PARAMETER_SPECIFIC_NAME> rank => -21
                         | <PARAMETER_SPECIFIC_SCHEMA> rank => -22
                         | <PRECISION> rank => -23
                         | <RETURNED_CARDINALITY> rank => -24
                         | <RETURNED_LENGTH> rank => -25
                         | <RETURNED_OCTET_LENGTH> rank => -26
                         | <SCALE> rank => -27
                         | <SCOPE_CATALOG> rank => -28
                         | <SCOPE_NAME> rank => -29
                         | <SCOPE_SCHEMA> rank => -30
                         | <TYPE> rank => -31
                         | <UNNAMED> rank => -32
                         | <USER_DEFINED_TYPE_CATALOG> rank => -33
                         | <USER_DEFINED_TYPE_NAME> rank => -34
                         | <USER_DEFINED_TYPE_SCHEMA> rank => -35
                         | <USER_DEFINED_TYPE_CODE> rank => -36
<Set_Descriptor_Statement> ::= <SET> <SQL_Maybe> <DESCRIPTOR> <Descriptor_Name> <Set_Descriptor_Information> rank => 0
<Gen3383> ::= <Comma> <Set_Header_Information> rank => 0
<Gen3383_Any> ::= <Gen3383>* rank => 0
<Gen3385> ::= <Comma> <Set_Item_Information> rank => 0
<Gen3385_Any> ::= <Gen3385>* rank => 0
<Set_Descriptor_Information> ::= <Set_Header_Information> <Gen3383_Any> rank => 0
                               | <VALUE> <Item_Number> <Set_Item_Information> <Gen3385_Any> rank => -1
<Set_Header_Information> ::= <Header_Item_Name> <Equals_Operator> <Simple_Value_Specification_1> rank => 0
<Set_Item_Information> ::= <Descriptor_Item_Name> <Equals_Operator> <Simple_Value_Specification_2> rank => 0
<Simple_Value_Specification_1> ::= <Simple_Value_Specification> rank => 0
<Simple_Value_Specification_2> ::= <Simple_Value_Specification> rank => 0
<Attributes_Specification_Maybe> ::= <Attributes_Specification> rank => 0
<Attributes_Specification_Maybe> ::= rank => -1
<Prepare_Statement> ::= <PREPARE> <SQL_Statement_Name> <Attributes_Specification_Maybe> <FROM> <SQL_Statement_Variable> rank => 0
<Attributes_Specification> ::= <ATTRIBUTES> <Attributes_Variable> rank => 0
<Attributes_Variable> ::= <Simple_Value_Specification> rank => 0
<SQL_Statement_Variable> ::= <Simple_Value_Specification> rank => 0
<Preparable_Statement> ::= <Preparable_SQL_Data_Statement> rank => 0
                         | <Preparable_SQL_Schema_Statement> rank => -1
                         | <Preparable_SQL_Transaction_Statement> rank => -2
                         | <Preparable_SQL_Control_Statement> rank => -3
                         | <Preparable_SQL_Session_Statement> rank => -4
<Preparable_SQL_Data_Statement> ::= <Delete_Statement_Searched> rank => 0
                                  | <Dynamic_Single_Row_Select_Statement> rank => -1
                                  | <Insert_Statement> rank => -2
                                  | <Dynamic_Select_Statement> rank => -3
                                  | <Update_Statement_Searched> rank => -4
                                  | <Merge_Statement> rank => -5
                                  | <Preparable_Dynamic_Delete_Statement_Positioned> rank => -6
                                  | <Preparable_Dynamic_Update_Statement_Positioned> rank => -7
<Preparable_SQL_Schema_Statement> ::= <SQL_Schema_Statement> rank => 0
<Preparable_SQL_Transaction_Statement> ::= <SQL_Transaction_Statement> rank => 0
<Preparable_SQL_Control_Statement> ::= <SQL_Control_Statement> rank => 0
<Preparable_SQL_Session_Statement> ::= <SQL_Session_Statement> rank => 0
<Dynamic_Select_Statement> ::= <Cursor_Specification> rank => 0
<Cursor_Attribute_Many> ::= <Cursor_Attribute>+ rank => 0
<Cursor_Attributes> ::= <Cursor_Attribute_Many> rank => 0
<Cursor_Attribute> ::= <Cursor_Sensitivity> rank => 0
                     | <Cursor_Scrollability> rank => -1
                     | <Cursor_Holdability> rank => -2
                     | <Cursor_Returnability> rank => -3
<Deallocate_Prepared_Statement> ::= <DEALLOCATE> <PREPARE> <SQL_Statement_Name> rank => 0
<Describe_Statement> ::= <Describe_Input_Statement> rank => 0
                       | <Describe_Output_Statement> rank => -1
<Nesting_Option_Maybe> ::= <Nesting_Option> rank => 0
<Nesting_Option_Maybe> ::= rank => -1
<Describe_Input_Statement> ::= <DESCRIBE> <INPUT> <SQL_Statement_Name> <Using_Descriptor> <Nesting_Option_Maybe> rank => 0
<Output_Maybe> ::= <OUTPUT> rank => 0
<Output_Maybe> ::= rank => -1
<Describe_Output_Statement> ::= <DESCRIBE> <Output_Maybe> <Described_Object> <Using_Descriptor> <Nesting_Option_Maybe> rank => 0
<Nesting_Option> ::= <WITH> <NESTING> rank => 0
                   | <WITHOUT> <NESTING> rank => -1
<Using_Descriptor> ::= <USING> <SQL_Maybe> <DESCRIPTOR> <Descriptor_Name> rank => 0
<Described_Object> ::= <SQL_Statement_Name> rank => 0
                     | <CURSOR> <Extended_Cursor_Name> <STRUCTURE> rank => -1
<Input_Using_Clause> ::= <Using_Arguments> rank => 0
                       | <Using_Input_Descriptor> rank => -1
<Gen3439> ::= <Comma> <Using_Argument> rank => 0
<Gen3439_Any> ::= <Gen3439>* rank => 0
<Using_Arguments> ::= <USING> <Using_Argument> <Gen3439_Any> rank => 0
<Using_Argument> ::= <General_Value_Specification> rank => 0
<Using_Input_Descriptor> ::= <Using_Descriptor> rank => 0
<Output_Using_Clause> ::= <Into_Arguments> rank => 0
                        | <Into_Descriptor> rank => -1
<Gen3446> ::= <Comma> <Into_Argument> rank => 0
<Gen3446_Any> ::= <Gen3446>* rank => 0
<Into_Arguments> ::= <INTO> <Into_Argument> <Gen3446_Any> rank => 0
<Into_Argument> ::= <Target_Specification> rank => 0
<Into_Descriptor> ::= <INTO> <SQL_Maybe> <DESCRIPTOR> <Descriptor_Name> rank => 0
<Result_Using_Clause_Maybe> ::= <Result_Using_Clause> rank => 0
<Result_Using_Clause_Maybe> ::= rank => -1
<Parameter_Using_Clause_Maybe> ::= <Parameter_Using_Clause> rank => 0
<Parameter_Using_Clause_Maybe> ::= rank => -1
<Execute_Statement> ::= <EXECUTE> <SQL_Statement_Name> <Result_Using_Clause_Maybe> <Parameter_Using_Clause_Maybe> rank => 0
<Result_Using_Clause> ::= <Output_Using_Clause> rank => 0
<Parameter_Using_Clause> ::= <Input_Using_Clause> rank => 0
<Execute_Immediate_Statement> ::= <EXECUTE> <IMMEDIATE> <SQL_Statement_Variable> rank => 0
<Dynamic_Declare_Cursor> ::= <DECLARE> <Cursor_Name> <Cursor_Sensitivity_Maybe> <Cursor_Scrollability_Maybe> <CURSOR> <Cursor_Holdability_Maybe> <Cursor_Returnability_Maybe> <FOR> <Statement_Name> rank => 0
<Allocate_Cursor_Statement> ::= <ALLOCATE> <Extended_Cursor_Name> <Cursor_Intent> rank => 0
<Cursor_Intent> ::= <Statement_Cursor> rank => 0
                  | <Result_Set_Cursor> rank => -1
<Statement_Cursor> ::= <Cursor_Sensitivity_Maybe> <Cursor_Scrollability_Maybe> <CURSOR> <Cursor_Holdability_Maybe> <Cursor_Returnability_Maybe> <FOR> <Extended_Statement_Name> rank => 0
<Result_Set_Cursor> ::= <FOR> <PROCEDURE> <Specific_Routine_Designator> rank => 0
<Input_Using_Clause_Maybe> ::= <Input_Using_Clause> rank => 0
<Input_Using_Clause_Maybe> ::= rank => -1
<Dynamic_Open_Statement> ::= <OPEN> <Dynamic_Cursor_Name> <Input_Using_Clause_Maybe> rank => 0
<Gen3468> ::= <Fetch_Orientation_Maybe> <FROM> rank => 0
<Gen3468_Maybe> ::= <Gen3468> rank => 0
<Gen3468_Maybe> ::= rank => -1
<Dynamic_Fetch_Statement> ::= <FETCH> <Gen3468_Maybe> <Dynamic_Cursor_Name> <Output_Using_Clause> rank => 0
<Dynamic_Single_Row_Select_Statement> ::= <Query_Specification> rank => 0
<Dynamic_Close_Statement> ::= <CLOSE> <Dynamic_Cursor_Name> rank => 0
<Dynamic_Delete_Statement_Positioned> ::= <DELETE> <FROM> <Target_Table> <WHERE> <CURRENT> <OF> <Dynamic_Cursor_Name> rank => 0
<Dynamic_Update_Statement_Positioned> ::= <UPDATE> <Target_Table> <SET> <Set_Clause_List> <WHERE> <CURRENT> <OF> <Dynamic_Cursor_Name> rank => 0
<Gen3476> ::= <FROM> <Target_Table> rank => 0
<Gen3476_Maybe> ::= <Gen3476> rank => 0
<Gen3476_Maybe> ::= rank => -1
<Preparable_Dynamic_Delete_Statement_Positioned> ::= <DELETE> <Gen3476_Maybe> <WHERE> <CURRENT> <OF> <Scope_Option_Maybe> <Cursor_Name> rank => 0
<Target_Table_Maybe> ::= <Target_Table> rank => 0
<Target_Table_Maybe> ::= rank => -1
<Preparable_Dynamic_Update_Statement_Positioned> ::= <UPDATE> <Target_Table_Maybe> <SET> <Set_Clause_List> <WHERE> <CURRENT> <OF> <Scope_Option_Maybe> <Cursor_Name> rank => 0
<Embedded_SQL_Host_Program> ::= <Embedded_SQL_Ada_Program> rank => 0
                              | <Embedded_SQL_C_Program> rank => -1
                              | <Embedded_SQL_Cobol_Program> rank => -2
                              | <Embedded_SQL_Fortran_Program> rank => -3
                              | <Embedded_SQL_Mumps_Program> rank => -4
                              | <Embedded_SQL_Pascal_Program> rank => -5
                              | <Embedded_SQL_Pl_I_Program> rank => -6
<SQL_Terminator_Maybe> ::= <SQL_Terminator> rank => 0
<SQL_Terminator_Maybe> ::= rank => -1
<Embedded_SQL_Statement> ::= <SQL_Prefix> <Statement_Or_Declaration> <SQL_Terminator_Maybe> rank => 0
<Statement_Or_Declaration> ::= <Declare_Cursor> rank => 0
                             | <Dynamic_Declare_Cursor> rank => -1
                             | <Temporary_Table_Declaration> rank => -2
                             | <Embedded_Authorization_Declaration> rank => -3
                             | <Embedded_Path_Specification> rank => -4
                             | <Embedded_Transform_Group_Specification> rank => -5
                             | <Embedded_Collation_Specification> rank => -6
                             | <Embedded_Exception_Declaration> rank => -7
                             | <SQL_Procedure_Statement> rank => -8
<SQL_Prefix> ::= <EXEC> <SQL> rank => 0
               | <Ampersand> <SQL> <Left_Paren> rank => -1
<SQL_Terminator> ::= <Lex374> rank => 0
                   | <Semicolon> rank => -1
                   | <Right_Paren> rank => -2
<Embedded_Authorization_Declaration> ::= <DECLARE> <Embedded_Authorization_Clause> rank => 0
<Gen3508> ::= <ONLY> rank => 0
            | <AND> <DYNAMIC> rank => -1
<Gen3510> ::= <FOR> <STATIC> <Gen3508> rank => 0
<Gen3510_Maybe> ::= <Gen3510> rank => 0
<Gen3510_Maybe> ::= rank => -1
<Gen3513> ::= <ONLY> rank => 0
            | <AND> <DYNAMIC> rank => -1
<Gen3515> ::= <FOR> <STATIC> <Gen3513> rank => 0
<Gen3515_Maybe> ::= <Gen3515> rank => 0
<Gen3515_Maybe> ::= rank => -1
<Embedded_Authorization_Clause> ::= <SCHEMA> <Schema_Name> rank => 0
                                  | <AUTHORIZATION> <Embedded_Authorization_Identifier> <Gen3510_Maybe> rank => -1
                                  | <SCHEMA> <Schema_Name> <AUTHORIZATION> <Embedded_Authorization_Identifier> <Gen3515_Maybe> rank => -2
<Embedded_Authorization_Identifier> ::= <Module_Authorization_Identifier> rank => 0
<Embedded_Path_Specification> ::= <Path_Specification> rank => 0
<Embedded_Transform_Group_Specification> ::= <Transform_Group_Specification> rank => 0
<Embedded_Collation_Specification> ::= <Module_Collations> rank => 0
<Embedded_Character_Set_Declaration_Maybe> ::= <Embedded_Character_Set_Declaration> rank => 0
<Embedded_Character_Set_Declaration_Maybe> ::= rank => -1
<Host_Variable_Definition_Any> ::= <Host_Variable_Definition>* rank => 0
<Embedded_SQL_Declare_Section> ::= <Embedded_SQL_Begin_Declare> <Embedded_Character_Set_Declaration_Maybe> <Host_Variable_Definition_Any> <Embedded_SQL_End_Declare> rank => 0
                                 | <Embedded_SQL_Mumps_Declare> rank => -1
<Embedded_Character_Set_Declaration> ::= <SQL> <NAMES> <ARE> <Character_Set_Specification> rank => 0
<Embedded_SQL_Begin_Declare> ::= <SQL_Prefix> <BEGIN> <DECLARE> <SECTION> <SQL_Terminator_Maybe> rank => 0
<Embedded_SQL_End_Declare> ::= <SQL_Prefix> <END> <DECLARE> <SECTION> <SQL_Terminator_Maybe> rank => 0
<Embedded_SQL_Mumps_Declare> ::= <SQL_Prefix> <BEGIN> <DECLARE> <SECTION> <Embedded_Character_Set_Declaration_Maybe> <Host_Variable_Definition_Any> <END> <DECLARE> <SECTION> <SQL_Terminator> rank => 0
<Host_Variable_Definition> ::= <Ada_Variable_Definition> rank => 0
                             | <C_Variable_Definition> rank => -1
                             | <Cobol_Variable_Definition> rank => -2
                             | <Fortran_Variable_Definition> rank => -3
                             | <Mumps_Variable_Definition> rank => -4
                             | <Pascal_Variable_Definition> rank => -5
                             | <Pl_I_Variable_Definition> rank => -6
<Embedded_Variable_Name> ::= <Colon> <Host_Identifier> rank => 0
<Host_Identifier> ::= <Ada_Host_Identifier> rank => 0
                    | <C_Host_Identifier> rank => -1
                    | <Cobol_Host_Identifier> rank => -2
                    | <Fortran_Host_Identifier> rank => -3
                    | <Mumps_Host_Identifier> rank => -4
                    | <Pascal_Host_Identifier> rank => -5
                    | <Pl_I_Host_Identifier> rank => -6
<Embedded_Exception_Declaration> ::= <WHENEVER> <Condition> <Condition_Action> rank => 0
<Condition> ::= <SQL_Condition> rank => 0
<Gen3551> ::= <Comma> <Sqlstate_Subclass_Value> rank => 0
<Gen3551_Maybe> ::= <Gen3551> rank => 0
<Gen3551_Maybe> ::= rank => -1
<Gen3554> ::= <Sqlstate_Class_Value> <Gen3551_Maybe> rank => 0
<SQL_Condition> ::= <Major_Category> rank => 0
                  | <SQLSTATE> <Gen3554> rank => -1
                  | <CONSTRAINT> <Constraint_Name> rank => -2
<Major_Category> ::= <SQLEXCEPTION> rank => 0
                   | <SQLWARNING> rank => -1
                   | <NOT> <FOUND> rank => -2
<Sqlstate_Class_Value> ::= <Sqlstate_Char> <Sqlstate_Char> rank => 0
<Sqlstate_Subclass_Value> ::= <Sqlstate_Char> <Sqlstate_Char> <Sqlstate_Char> rank => 0
<Sqlstate_Char_L0> ~ <Simple_Latin_Upper_Case_Letter_L0>
                     | <Digit_L0>
<Sqlstate_Char> ~ <Sqlstate_Char_L0>
<Condition_Action> ::= <CONTINUE> rank => 0
                     | <Go_To> rank => -1
<Gen3568> ::= <GOTO> rank => 0
            | <GO> <TO> rank => -1
<Go_To> ::= <Gen3568> <Goto_Target> rank => 0
<Goto_Target> ::= <Unsigned_Integer> rank => 0
<Embedded_SQL_Ada_Program> ::= <EXEC> <SQL> rank => 0
<Gen3573> ::= <Comma> <Ada_Host_Identifier> rank => 0
<Gen3573_Any> ::= <Gen3573>* rank => 0
<Ada_Initial_Value_Maybe> ::= <Ada_Initial_Value> rank => 0
<Ada_Initial_Value_Maybe> ::= rank => -1
<Ada_Variable_Definition> ::= <Ada_Host_Identifier> <Gen3573_Any> <Colon> <Ada_Type_Specification> <Ada_Initial_Value_Maybe> rank => 0
<Character_Representation_Many> ::= <Character_Representation>+ rank => 0
<Ada_Initial_Value> ::= <Ada_Assignment_Operator> <Character_Representation_Many> rank => 0
<Ada_Assignment_Operator> ::= <Colon> <Equals_Operator> rank => 0
<Ada_Host_Identifier> ~ <Host_Identifier_L0>
<Ada_Type_Specification> ::= <Ada_Qualified_Type_Specification> rank => 0
                           | <Ada_Unqualified_Type_Specification> rank => -1
                           | <Ada_Derived_Type_Specification> rank => -2
<Is_Maybe> ::= <IS> rank => 0
<Is_Maybe> ::= rank => -1
<Gen3587> ::= <CHARACTER> <SET> <Is_Maybe> <Character_Set_Specification> rank => 0
<Gen3587_Maybe> ::= <Gen3587> rank => 0
<Gen3587_Maybe> ::= rank => -1
<Ada_Qualified_Type_Specification> ::= <Lex579> <Period> <CHAR> <Gen3587_Maybe> <Left_Paren> <Lex580> <Double_Period> <Length> <Right_Paren> rank => 0
                                     | <Lex579> <Period> <SMALLINT> rank => -1
                                     | <Lex579> <Period> <INT> rank => -2
                                     | <Lex579> <Period> <BIGINT> rank => -3
                                     | <Lex579> <Period> <REAL> rank => -4
                                     | <Lex579> <Period> <DOUBLE_PRECISION> rank => -5
                                     | <Lex579> <Period> <BOOLEAN> rank => -6
                                     | <Lex579> <Period> <SQLSTATE_TYPE> rank => -7
                                     | <Lex579> <Period> <INDICATOR_TYPE> rank => -8
<Ada_Unqualified_Type_Specification> ::= <CHAR> <Left_Paren> <Lex580> <Double_Period> <Length> <Right_Paren> rank => 0
                                       | <SMALLINT> rank => -1
                                       | <INT> rank => -2
                                       | <BIGINT> rank => -3
                                       | <REAL> rank => -4
                                       | <DOUBLE_PRECISION> rank => -5
                                       | <BOOLEAN> rank => -6
                                       | <SQLSTATE_TYPE> rank => -7
                                       | <INDICATOR_TYPE> rank => -8
<Ada_Derived_Type_Specification> ::= <Ada_Clob_Variable> rank => 0
                                   | <Ada_Clob_Locator_Variable> rank => -1
                                   | <Ada_Blob_Variable> rank => -2
                                   | <Ada_Blob_Locator_Variable> rank => -3
                                   | <Ada_User_Defined_Type_Variable> rank => -4
                                   | <Ada_User_Defined_Type_Locator_Variable> rank => -5
                                   | <Ada_Ref_Variable> rank => -6
                                   | <Ada_Array_Locator_Variable> rank => -7
                                   | <Ada_Multiset_Locator_Variable> rank => -8
<Gen3617> ::= <CHARACTER> <SET> <Is_Maybe> <Character_Set_Specification> rank => 0
<Gen3617_Maybe> ::= <Gen3617> rank => 0
<Gen3617_Maybe> ::= rank => -1
<Ada_Clob_Variable> ::= <SQL> <TYPE> <IS> <CLOB> <Left_Paren> <Large_Object_Length> <Right_Paren> <Gen3617_Maybe> rank => 0
<Ada_Clob_Locator_Variable> ::= <SQL> <TYPE> <IS> <CLOB> <AS> <LOCATOR> rank => 0
<Ada_Blob_Variable> ::= <SQL> <TYPE> <IS> <BLOB> <Left_Paren> <Large_Object_Length> <Right_Paren> rank => 0
<Ada_Blob_Locator_Variable> ::= <SQL> <TYPE> <IS> <BLOB> <AS> <LOCATOR> rank => 0
<Ada_User_Defined_Type_Variable> ::= <SQL> <TYPE> <IS> <Path_Resolved_User_Defined_Type_Name> <AS> <Predefined_Type> rank => 0
<Ada_User_Defined_Type_Locator_Variable> ::= <SQL> <TYPE> <IS> <Path_Resolved_User_Defined_Type_Name> <AS> <LOCATOR> rank => 0
<Ada_Ref_Variable> ::= <SQL> <TYPE> <IS> <Reference_Type> rank => 0
<Ada_Array_Locator_Variable> ::= <SQL> <TYPE> <IS> <Array_Type> <AS> <LOCATOR> rank => 0
<Ada_Multiset_Locator_Variable> ::= <SQL> <TYPE> <IS> <Multiset_Type> <AS> <LOCATOR> rank => 0
<Embedded_SQL_C_Program> ::= <EXEC> <SQL> rank => 0
<C_Storage_Class_Maybe> ::= <C_Storage_Class> rank => 0
<C_Storage_Class_Maybe> ::= rank => -1
<C_Class_Modifier_Maybe> ::= <C_Class_Modifier> rank => 0
<C_Class_Modifier_Maybe> ::= rank => -1
<C_Variable_Definition> ::= <C_Storage_Class_Maybe> <C_Class_Modifier_Maybe> <C_Variable_Specification> <Semicolon> rank => 0
<C_Variable_Specification> ::= <C_Numeric_Variable> rank => 0
                             | <C_Character_Variable> rank => -1
                             | <C_Derived_Variable> rank => -2
<C_Storage_Class> ::= <auto> rank => 0
                    | <extern> rank => -1
                    | <static> rank => -2
<C_Class_Modifier> ::= <const> rank => 0
                     | <volatile> rank => -1
<Gen3643> ::= <long> <long> rank => 0
            | <long> rank => -1
            | <short> rank => -2
            | <float> rank => -3
            | <double> rank => -4
<C_Initial_Value_Maybe> ::= <C_Initial_Value> rank => 0
<C_Initial_Value_Maybe> ::= rank => -1
<Gen3650> ::= <Comma> <C_Host_Identifier> <C_Initial_Value_Maybe> rank => 0
<Gen3650_Any> ::= <Gen3650>* rank => 0
<C_Numeric_Variable> ::= <Gen3643> <C_Host_Identifier> <C_Initial_Value_Maybe> <Gen3650_Any> rank => 0
<Gen3653> ::= <CHARACTER> <SET> <Is_Maybe> <Character_Set_Specification> rank => 0
<Gen3653_Maybe> ::= <Gen3653> rank => 0
<Gen3653_Maybe> ::= rank => -1
<Gen3656> ::= <Comma> <C_Host_Identifier> <C_Array_Specification> <C_Initial_Value_Maybe> rank => 0
<Gen3656_Any> ::= <Gen3656>* rank => 0
<C_Character_Variable> ::= <C_Character_Type> <Gen3653_Maybe> <C_Host_Identifier> <C_Array_Specification> <C_Initial_Value_Maybe> <Gen3656_Any> rank => 0
<C_Character_Type> ::= <char> rank => 0
                     | <unsigned> <char> rank => -1
                     | <unsigned> <short> rank => -2
<C_Array_Specification> ::= <Left_Bracket> <Length> <Right_Bracket> rank => 0
<C_Host_Identifier> ~ <Host_Identifier_L0>
<C_Derived_Variable> ::= <C_Varchar_Variable> rank => 0
                       | <C_Nchar_Variable> rank => -1
                       | <C_Nchar_Varying_Variable> rank => -2
                       | <C_Clob_Variable> rank => -3
                       | <C_Nclob_Variable> rank => -4
                       | <C_Blob_Variable> rank => -5
                       | <C_User_Defined_Type_Variable> rank => -6
                       | <C_Clob_Locator_Variable> rank => -7
                       | <C_Blob_Locator_Variable> rank => -8
                       | <C_Array_Locator_Variable> rank => -9
                       | <C_Multiset_Locator_Variable> rank => -10
                       | <C_User_Defined_Type_Locator_Variable> rank => -11
                       | <C_Ref_Variable> rank => -12
<Gen3677> ::= <CHARACTER> <SET> <Is_Maybe> <Character_Set_Specification> rank => 0
<Gen3677_Maybe> ::= <Gen3677> rank => 0
<Gen3677_Maybe> ::= rank => -1
<Gen3680> ::= <Comma> <C_Host_Identifier> <C_Array_Specification> <C_Initial_Value_Maybe> rank => 0
<Gen3680_Any> ::= <Gen3680>* rank => 0
<C_Varchar_Variable> ::= <VARCHAR> <Gen3677_Maybe> <C_Host_Identifier> <C_Array_Specification> <C_Initial_Value_Maybe> <Gen3680_Any> rank => 0
<Gen3683> ::= <CHARACTER> <SET> <Is_Maybe> <Character_Set_Specification> rank => 0
<Gen3683_Maybe> ::= <Gen3683> rank => 0
<Gen3683_Maybe> ::= rank => -1
<Gen3686> ::= <Comma> <C_Host_Identifier> <C_Array_Specification> <C_Initial_Value_Maybe> rank => 0
<Gen3686_Any> ::= <Gen3686>* rank => 0
<C_Nchar_Variable> ::= <NCHAR> <Gen3683_Maybe> <C_Host_Identifier> <C_Array_Specification> <C_Initial_Value_Maybe> <Gen3686_Any> rank => 0
<Gen3689> ::= <CHARACTER> <SET> <Is_Maybe> <Character_Set_Specification> rank => 0
<Gen3689_Maybe> ::= <Gen3689> rank => 0
<Gen3689_Maybe> ::= rank => -1
<Gen3692> ::= <Comma> <C_Host_Identifier> <C_Array_Specification> <C_Initial_Value_Maybe> rank => 0
<Gen3692_Any> ::= <Gen3692>* rank => 0
<C_Nchar_Varying_Variable> ::= <NCHAR> <VARYING> <Gen3689_Maybe> <C_Host_Identifier> <C_Array_Specification> <C_Initial_Value_Maybe> <Gen3692_Any> rank => 0
<Gen3695> ::= <CHARACTER> <SET> <Is_Maybe> <Character_Set_Specification> rank => 0
<Gen3695_Maybe> ::= <Gen3695> rank => 0
<Gen3695_Maybe> ::= rank => -1
<Gen3698> ::= <Comma> <C_Host_Identifier> <C_Initial_Value_Maybe> rank => 0
<Gen3698_Any> ::= <Gen3698>* rank => 0
<C_Clob_Variable> ::= <SQL> <TYPE> <IS> <CLOB> <Left_Paren> <Large_Object_Length> <Right_Paren> <Gen3695_Maybe> <C_Host_Identifier> <C_Initial_Value_Maybe> <Gen3698_Any> rank => 0
<Gen3701> ::= <CHARACTER> <SET> <Is_Maybe> <Character_Set_Specification> rank => 0
<Gen3701_Maybe> ::= <Gen3701> rank => 0
<Gen3701_Maybe> ::= rank => -1
<Gen3704> ::= <Comma> <C_Host_Identifier> <C_Initial_Value_Maybe> rank => 0
<Gen3704_Any> ::= <Gen3704>* rank => 0
<C_Nclob_Variable> ::= <SQL> <TYPE> <IS> <NCLOB> <Left_Paren> <Large_Object_Length> <Right_Paren> <Gen3701_Maybe> <C_Host_Identifier> <C_Initial_Value_Maybe> <Gen3704_Any> rank => 0
<Gen3707> ::= <Comma> <C_Host_Identifier> <C_Initial_Value_Maybe> rank => 0
<Gen3707_Any> ::= <Gen3707>* rank => 0
<C_User_Defined_Type_Variable> ::= <SQL> <TYPE> <IS> <Path_Resolved_User_Defined_Type_Name> <AS> <Predefined_Type> <C_Host_Identifier> <C_Initial_Value_Maybe> <Gen3707_Any> rank => 0
<Gen3710> ::= <Comma> <C_Host_Identifier> <C_Initial_Value_Maybe> rank => 0
<Gen3710_Any> ::= <Gen3710>* rank => 0
<C_Blob_Variable> ::= <SQL> <TYPE> <IS> <BLOB> <Left_Paren> <Large_Object_Length> <Right_Paren> <C_Host_Identifier> <C_Initial_Value_Maybe> <Gen3710_Any> rank => 0
<Gen3713> ::= <Comma> <C_Host_Identifier> <C_Initial_Value_Maybe> rank => 0
<Gen3713_Any> ::= <Gen3713>* rank => 0
<C_Clob_Locator_Variable> ::= <SQL> <TYPE> <IS> <CLOB> <AS> <LOCATOR> <C_Host_Identifier> <C_Initial_Value_Maybe> <Gen3713_Any> rank => 0
<Gen3716> ::= <Comma> <C_Host_Identifier> <C_Initial_Value_Maybe> rank => 0
<Gen3716_Any> ::= <Gen3716>* rank => 0
<C_Blob_Locator_Variable> ::= <SQL> <TYPE> <IS> <BLOB> <AS> <LOCATOR> <C_Host_Identifier> <C_Initial_Value_Maybe> <Gen3716_Any> rank => 0
<Gen3719> ::= <Comma> <C_Host_Identifier> <C_Initial_Value_Maybe> rank => 0
<Gen3719_Any> ::= <Gen3719>* rank => 0
<C_Array_Locator_Variable> ::= <SQL> <TYPE> <IS> <Array_Type> <AS> <LOCATOR> <C_Host_Identifier> <C_Initial_Value_Maybe> <Gen3719_Any> rank => 0
<Gen3722> ::= <Comma> <C_Host_Identifier> <C_Initial_Value_Maybe> rank => 0
<Gen3722_Any> ::= <Gen3722>* rank => 0
<C_Multiset_Locator_Variable> ::= <SQL> <TYPE> <IS> <Multiset_Type> <AS> <LOCATOR> <C_Host_Identifier> <C_Initial_Value_Maybe> <Gen3722_Any> rank => 0
<Gen3725> ::= <Comma> <C_Host_Identifier> <C_Initial_Value_Maybe> rank => 0
<Gen3725_Any> ::= <Gen3725>* rank => 0
<C_User_Defined_Type_Locator_Variable> ::= <SQL> <TYPE> <IS> <Path_Resolved_User_Defined_Type_Name> <AS> <LOCATOR> <C_Host_Identifier> <C_Initial_Value_Maybe> <Gen3725_Any> rank => 0
<C_Ref_Variable> ::= <SQL> <TYPE> <IS> <Reference_Type> rank => 0
<C_Initial_Value> ::= <Equals_Operator> <Character_Representation_Many> rank => 0
<Embedded_SQL_Cobol_Program> ::= <EXEC> <SQL> rank => 0
<Cobol_Host_Identifier> ~ <Host_Identifier_L0>
<Gen3732> ::= <Lex595> rank => 0
            | <Lex596> rank => -1
<Character_Representation_Any> ::= <Character_Representation>* rank => 0
<Cobol_Variable_Definition> ::= <Gen3732> <Cobol_Host_Identifier> <Cobol_Type_Specification> <Character_Representation_Any> <Period> rank => 0
<Cobol_Type_Specification> ::= <Cobol_Character_Type> rank => 0
                             | <Cobol_National_Character_Type> rank => -1
                             | <Cobol_Numeric_Type> rank => -2
                             | <Cobol_Integer_Type> rank => -3
                             | <Cobol_Derived_Type_Specification> rank => -4
<Cobol_Derived_Type_Specification> ::= <Cobol_Clob_Variable> rank => 0
                                     | <Cobol_Nclob_Variable> rank => -1
                                     | <Cobol_Blob_Variable> rank => -2
                                     | <Cobol_User_Defined_Type_Variable> rank => -3
                                     | <Cobol_Clob_Locator_Variable> rank => -4
                                     | <Cobol_Blob_Locator_Variable> rank => -5
                                     | <Cobol_Array_Locator_Variable> rank => -6
                                     | <Cobol_Multiset_Locator_Variable> rank => -7
                                     | <Cobol_User_Defined_Type_Locator_Variable> rank => -8
                                     | <Cobol_Ref_Variable> rank => -9
<Gen3751> ::= <CHARACTER> <SET> <Is_Maybe> <Character_Set_Specification> rank => 0
<Gen3751_Maybe> ::= <Gen3751> rank => 0
<Gen3751_Maybe> ::= rank => -1
<Gen3754> ::= <PIC> rank => 0
            | <PICTURE> rank => -1
<Gen3756> ::= <Left_Paren> <Length> <Right_Paren> rank => 0
<Gen3756_Maybe> ::= <Gen3756> rank => 0
<Gen3756_Maybe> ::= rank => -1
<Gen3759> ::= <X> <Gen3756_Maybe> rank => 0
<Gen3759_Many> ::= <Gen3759>+ rank => 0
<Cobol_Character_Type> ::= <Gen3751_Maybe> <Gen3754> <Is_Maybe> <Gen3759_Many> rank => 0
<Gen3762> ::= <CHARACTER> <SET> <Is_Maybe> <Character_Set_Specification> rank => 0
<Gen3762_Maybe> ::= <Gen3762> rank => 0
<Gen3762_Maybe> ::= rank => -1
<Gen3765> ::= <PIC> rank => 0
            | <PICTURE> rank => -1
<Gen3767> ::= <Left_Paren> <Length> <Right_Paren> rank => 0
<Gen3767_Maybe> ::= <Gen3767> rank => 0
<Gen3767_Maybe> ::= rank => -1
<Gen3770> ::= <N> <Gen3767_Maybe> rank => 0
<Gen3770_Many> ::= <Gen3770>+ rank => 0
<Cobol_National_Character_Type> ::= <Gen3762_Maybe> <Gen3765> <Is_Maybe> <Gen3770_Many> rank => 0
<Gen3773> ::= <USAGE> <Is_Maybe> rank => 0
<Gen3773_Maybe> ::= <Gen3773> rank => 0
<Gen3773_Maybe> ::= rank => -1
<Gen3776> ::= <CHARACTER> <SET> <Is_Maybe> <Character_Set_Specification> rank => 0
<Gen3776_Maybe> ::= <Gen3776> rank => 0
<Gen3776_Maybe> ::= rank => -1
<Cobol_Clob_Variable> ::= <Gen3773_Maybe> <SQL> <TYPE> <IS> <CLOB> <Left_Paren> <Large_Object_Length> <Right_Paren> <Gen3776_Maybe> rank => 0
<Gen3780> ::= <USAGE> <Is_Maybe> rank => 0
<Gen3780_Maybe> ::= <Gen3780> rank => 0
<Gen3780_Maybe> ::= rank => -1
<Gen3783> ::= <CHARACTER> <SET> <Is_Maybe> <Character_Set_Specification> rank => 0
<Gen3783_Maybe> ::= <Gen3783> rank => 0
<Gen3783_Maybe> ::= rank => -1
<Cobol_Nclob_Variable> ::= <Gen3780_Maybe> <SQL> <TYPE> <IS> <NCLOB> <Left_Paren> <Large_Object_Length> <Right_Paren> <Gen3783_Maybe> rank => 0
<Gen3787> ::= <USAGE> <Is_Maybe> rank => 0
<Gen3787_Maybe> ::= <Gen3787> rank => 0
<Gen3787_Maybe> ::= rank => -1
<Cobol_Blob_Variable> ::= <Gen3787_Maybe> <SQL> <TYPE> <IS> <BLOB> <Left_Paren> <Large_Object_Length> <Right_Paren> rank => 0
<Gen3791> ::= <USAGE> <Is_Maybe> rank => 0
<Gen3791_Maybe> ::= <Gen3791> rank => 0
<Gen3791_Maybe> ::= rank => -1
<Cobol_User_Defined_Type_Variable> ::= <Gen3791_Maybe> <SQL> <TYPE> <IS> <Path_Resolved_User_Defined_Type_Name> <AS> <Predefined_Type> rank => 0
<Gen3795> ::= <USAGE> <Is_Maybe> rank => 0
<Gen3795_Maybe> ::= <Gen3795> rank => 0
<Gen3795_Maybe> ::= rank => -1
<Cobol_Clob_Locator_Variable> ::= <Gen3795_Maybe> <SQL> <TYPE> <IS> <CLOB> <AS> <LOCATOR> rank => 0
<Gen3799> ::= <USAGE> <Is_Maybe> rank => 0
<Gen3799_Maybe> ::= <Gen3799> rank => 0
<Gen3799_Maybe> ::= rank => -1
<Cobol_Blob_Locator_Variable> ::= <Gen3799_Maybe> <SQL> <TYPE> <IS> <BLOB> <AS> <LOCATOR> rank => 0
<Gen3803> ::= <USAGE> <Is_Maybe> rank => 0
<Gen3803_Maybe> ::= <Gen3803> rank => 0
<Gen3803_Maybe> ::= rank => -1
<Cobol_Array_Locator_Variable> ::= <Gen3803_Maybe> <SQL> <TYPE> <IS> <Array_Type> <AS> <LOCATOR> rank => 0
<Gen3807> ::= <USAGE> <Is_Maybe> rank => 0
<Gen3807_Maybe> ::= <Gen3807> rank => 0
<Gen3807_Maybe> ::= rank => -1
<Cobol_Multiset_Locator_Variable> ::= <Gen3807_Maybe> <SQL> <TYPE> <IS> <Multiset_Type> <AS> <LOCATOR> rank => 0
<Gen3811> ::= <USAGE> <Is_Maybe> rank => 0
<Gen3811_Maybe> ::= <Gen3811> rank => 0
<Gen3811_Maybe> ::= rank => -1
<Cobol_User_Defined_Type_Locator_Variable> ::= <Gen3811_Maybe> <SQL> <TYPE> <IS> <Path_Resolved_User_Defined_Type_Name> <AS> <LOCATOR> rank => 0
<Gen3815> ::= <USAGE> <Is_Maybe> rank => 0
<Gen3815_Maybe> ::= <Gen3815> rank => 0
<Gen3815_Maybe> ::= rank => -1
<Cobol_Ref_Variable> ::= <Gen3815_Maybe> <SQL> <TYPE> <IS> <Reference_Type> rank => 0
<Gen3819> ::= <PIC> rank => 0
            | <PICTURE> rank => -1
<Gen3821> ::= <USAGE> <Is_Maybe> rank => 0
<Gen3821_Maybe> ::= <Gen3821> rank => 0
<Gen3821_Maybe> ::= rank => -1
<Cobol_Numeric_Type> ::= <Gen3819> <Is_Maybe> <S> <Cobol_Nines_Specification> <Gen3821_Maybe> <DISPLAY> <SIGN> <LEADING> <SEPARATE> rank => 0
<Cobol_Nines_Maybe> ::= <Cobol_Nines> rank => 0
<Cobol_Nines_Maybe> ::= rank => -1
<Gen3827> ::= <V> <Cobol_Nines_Maybe> rank => 0
<Gen3827_Maybe> ::= <Gen3827> rank => 0
<Gen3827_Maybe> ::= rank => -1
<Cobol_Nines_Specification> ::= <Cobol_Nines> <Gen3827_Maybe> rank => 0
                              | <V> <Cobol_Nines> rank => -1
<Cobol_Integer_Type> ::= <Cobol_Binary_Integer> rank => 0
<Gen3833> ::= <PIC> rank => 0
            | <PICTURE> rank => -1
<Gen3835> ::= <USAGE> <Is_Maybe> rank => 0
<Gen3835_Maybe> ::= <Gen3835> rank => 0
<Gen3835_Maybe> ::= rank => -1
<Cobol_Binary_Integer> ::= <Gen3833> <Is_Maybe> <S> <Cobol_Nines> <Gen3835_Maybe> <BINARY> rank => 0
<Gen3839> ::= <Left_Paren> <Length> <Right_Paren> rank => 0
<Gen3839_Maybe> ::= <Gen3839> rank => 0
<Gen3839_Maybe> ::= rank => -1
<Gen3842> ::= <Lex605> <Gen3839_Maybe> rank => 0
<Gen3842_Many> ::= <Gen3842>+ rank => 0
<Cobol_Nines> ::= <Gen3842_Many> rank => 0
<Embedded_SQL_Fortran_Program> ::= <EXEC> <SQL> rank => 0
<Fortran_Host_Identifier> ~ <Host_Identifier_L0>
<Gen3847> ::= <Comma> <Fortran_Host_Identifier> rank => 0
<Gen3847_Any> ::= <Gen3847>* rank => 0
<Fortran_Variable_Definition> ::= <Fortran_Type_Specification> <Fortran_Host_Identifier> <Gen3847_Any> rank => 0
<Gen3850> ::= <Asterisk> <Length> rank => 0
<Gen3850_Maybe> ::= <Gen3850> rank => 0
<Gen3850_Maybe> ::= rank => -1
<Gen3853> ::= <CHARACTER> <SET> <Is_Maybe> <Character_Set_Specification> rank => 0
<Gen3853_Maybe> ::= <Gen3853> rank => 0
<Gen3853_Maybe> ::= rank => -1
<Gen3856> ::= <Lex607_Many> rank => 0
<Gen3856> ::= rank => -1
<Gen3858> ::= <Asterisk> <Length> rank => 0
<Gen3858_Maybe> ::= <Gen3858> rank => 0
<Gen3858_Maybe> ::= rank => -1
<Gen3861> ::= <CHARACTER> <SET> <Is_Maybe> <Character_Set_Specification> rank => 0
<Gen3861_Maybe> ::= <Gen3861> rank => 0
<Gen3861_Maybe> ::= rank => -1
<Fortran_Type_Specification> ::= <CHARACTER> <Gen3850_Maybe> <Gen3853_Maybe> rank => 0
                               | <CHARACTER> <KIND> <Equals_Operator> <Lex607> <Gen3856> <Gen3858_Maybe> <Gen3861_Maybe> rank => -1
                               | <INTEGER> rank => -2
                               | <REAL> rank => -3
                               | <DOUBLE> <PRECISION> rank => -4
                               | <LOGICAL> rank => -5
                               | <Fortran_Derived_Type_Specification> rank => -6
<Fortran_Derived_Type_Specification> ::= <Fortran_Clob_Variable> rank => 0
                                       | <Fortran_Blob_Variable> rank => -1
                                       | <Fortran_User_Defined_Type_Variable> rank => -2
                                       | <Fortran_Clob_Locator_Variable> rank => -3
                                       | <Fortran_Blob_Locator_Variable> rank => -4
                                       | <Fortran_User_Defined_Type_Locator_Variable> rank => -5
                                       | <Fortran_Array_Locator_Variable> rank => -6
                                       | <Fortran_Multiset_Locator_Variable> rank => -7
                                       | <Fortran_Ref_Variable> rank => -8
<Gen3880> ::= <CHARACTER> <SET> <Is_Maybe> <Character_Set_Specification> rank => 0
<Gen3880_Maybe> ::= <Gen3880> rank => 0
<Gen3880_Maybe> ::= rank => -1
<Fortran_Clob_Variable> ::= <SQL> <TYPE> <IS> <CLOB> <Left_Paren> <Large_Object_Length> <Right_Paren> <Gen3880_Maybe> rank => 0
<Fortran_Blob_Variable> ::= <SQL> <TYPE> <IS> <BLOB> <Left_Paren> <Large_Object_Length> <Right_Paren> rank => 0
<Fortran_User_Defined_Type_Variable> ::= <SQL> <TYPE> <IS> <Path_Resolved_User_Defined_Type_Name> <AS> <Predefined_Type> rank => 0
<Fortran_Clob_Locator_Variable> ::= <SQL> <TYPE> <IS> <CLOB> <AS> <LOCATOR> rank => 0
<Fortran_Blob_Locator_Variable> ::= <SQL> <TYPE> <IS> <BLOB> <AS> <LOCATOR> rank => 0
<Fortran_User_Defined_Type_Locator_Variable> ::= <SQL> <TYPE> <IS> <Path_Resolved_User_Defined_Type_Name> <AS> <LOCATOR> rank => 0
<Fortran_Array_Locator_Variable> ::= <SQL> <TYPE> <IS> <Array_Type> <AS> <LOCATOR> rank => 0
<Fortran_Multiset_Locator_Variable> ::= <SQL> <TYPE> <IS> <Multiset_Type> <AS> <LOCATOR> rank => 0
<Fortran_Ref_Variable> ::= <SQL> <TYPE> <IS> <Reference_Type> rank => 0
<Embedded_SQL_Mumps_Program> ::= <EXEC> <SQL> rank => 0
<Mumps_Variable_Definition> ::= <Mumps_Numeric_Variable> <Semicolon> rank => 0
                              | <Mumps_Character_Variable> <Semicolon> rank => -1
                              | <Mumps_Derived_Type_Specification> <Semicolon> rank => -2
<Mumps_Host_Identifier> ~ <Host_Identifier_L0>
<Gen3897> ::= <Comma> <Mumps_Host_Identifier> <Mumps_Length_Specification> rank => 0
<Gen3897_Any> ::= <Gen3897>* rank => 0
<Mumps_Character_Variable> ::= <VARCHAR> <Mumps_Host_Identifier> <Mumps_Length_Specification> <Gen3897_Any> rank => 0
<Mumps_Length_Specification> ::= <Left_Paren> <Length> <Right_Paren> rank => 0
<Gen3901> ::= <Comma> <Mumps_Host_Identifier> rank => 0
<Gen3901_Any> ::= <Gen3901>* rank => 0
<Mumps_Numeric_Variable> ::= <Mumps_Type_Specification> <Mumps_Host_Identifier> <Gen3901_Any> rank => 0
<Gen3904> ::= <Comma> <Scale> rank => 0
<Gen3904_Maybe> ::= <Gen3904> rank => 0
<Gen3904_Maybe> ::= rank => -1
<Gen3907> ::= <Left_Paren> <Precision> <Gen3904_Maybe> <Right_Paren> rank => 0
<Gen3907_Maybe> ::= <Gen3907> rank => 0
<Gen3907_Maybe> ::= rank => -1
<Mumps_Type_Specification> ::= <INT> rank => 0
                             | <DEC> <Gen3907_Maybe> rank => -1
                             | <REAL> rank => -2
<Mumps_Derived_Type_Specification> ::= <Mumps_Clob_Variable> rank => 0
                                     | <Mumps_Blob_Variable> rank => -1
                                     | <Mumps_User_Defined_Type_Variable> rank => -2
                                     | <Mumps_Clob_Locator_Variable> rank => -3
                                     | <Mumps_Blob_Locator_Variable> rank => -4
                                     | <Mumps_User_Defined_Type_Locator_Variable> rank => -5
                                     | <Mumps_Array_Locator_Variable> rank => -6
                                     | <Mumps_Multiset_Locator_Variable> rank => -7
                                     | <Mumps_Ref_Variable> rank => -8
<Gen3922> ::= <CHARACTER> <SET> <Is_Maybe> <Character_Set_Specification> rank => 0
<Gen3922_Maybe> ::= <Gen3922> rank => 0
<Gen3922_Maybe> ::= rank => -1
<Mumps_Clob_Variable> ::= <SQL> <TYPE> <IS> <CLOB> <Left_Paren> <Large_Object_Length> <Right_Paren> <Gen3922_Maybe> rank => 0
<Mumps_Blob_Variable> ::= <SQL> <TYPE> <IS> <BLOB> <Left_Paren> <Large_Object_Length> <Right_Paren> rank => 0
<Mumps_User_Defined_Type_Variable> ::= <SQL> <TYPE> <IS> <Path_Resolved_User_Defined_Type_Name> <AS> <Predefined_Type> rank => 0
<Mumps_Clob_Locator_Variable> ::= <SQL> <TYPE> <IS> <CLOB> <AS> <LOCATOR> rank => 0
<Mumps_Blob_Locator_Variable> ::= <SQL> <TYPE> <IS> <BLOB> <AS> <LOCATOR> rank => 0
<Mumps_User_Defined_Type_Locator_Variable> ::= <SQL> <TYPE> <IS> <Path_Resolved_User_Defined_Type_Name> <AS> <LOCATOR> rank => 0
<Mumps_Array_Locator_Variable> ::= <SQL> <TYPE> <IS> <Array_Type> <AS> <LOCATOR> rank => 0
<Mumps_Multiset_Locator_Variable> ::= <SQL> <TYPE> <IS> <Multiset_Type> <AS> <LOCATOR> rank => 0
<Mumps_Ref_Variable> ::= <SQL> <TYPE> <IS> <Reference_Type> rank => 0
<Embedded_SQL_Pascal_Program> ::= <EXEC> <SQL> rank => 0
<Pascal_Host_Identifier> ~ <Host_Identifier_L0>
<Gen3936> ::= <Comma> <Pascal_Host_Identifier> rank => 0
<Gen3936_Any> ::= <Gen3936>* rank => 0
<Pascal_Variable_Definition> ::= <Pascal_Host_Identifier> <Gen3936_Any> <Colon> <Pascal_Type_Specification> <Semicolon> rank => 0
<Gen3939> ::= <CHARACTER> <SET> <Is_Maybe> <Character_Set_Specification> rank => 0
<Gen3939_Maybe> ::= <Gen3939> rank => 0
<Gen3939_Maybe> ::= rank => -1
<Gen3942> ::= <CHARACTER> <SET> <Is_Maybe> <Character_Set_Specification> rank => 0
<Gen3942_Maybe> ::= <Gen3942> rank => 0
<Gen3942_Maybe> ::= rank => -1
<Pascal_Type_Specification> ::= <PACKED> <ARRAY> <Left_Bracket> <Lex580> <Double_Period> <Length> <Right_Bracket> <OF> <CHAR> <Gen3939_Maybe> rank => 0
                              | <INTEGER> rank => -1
                              | <REAL> rank => -2
                              | <CHAR> <Gen3942_Maybe> rank => -3
                              | <BOOLEAN> rank => -4
                              | <Pascal_Derived_Type_Specification> rank => -5
<Pascal_Derived_Type_Specification> ::= <Pascal_Clob_Variable> rank => 0
                                      | <Pascal_Blob_Variable> rank => -1
                                      | <Pascal_User_Defined_Type_Variable> rank => -2
                                      | <Pascal_Clob_Locator_Variable> rank => -3
                                      | <Pascal_Blob_Locator_Variable> rank => -4
                                      | <Pascal_User_Defined_Type_Locator_Variable> rank => -5
                                      | <Pascal_Array_Locator_Variable> rank => -6
                                      | <Pascal_Multiset_Locator_Variable> rank => -7
                                      | <Pascal_Ref_Variable> rank => -8
<Gen3960> ::= <CHARACTER> <SET> <Is_Maybe> <Character_Set_Specification> rank => 0
<Gen3960_Maybe> ::= <Gen3960> rank => 0
<Gen3960_Maybe> ::= rank => -1
<Pascal_Clob_Variable> ::= <SQL> <TYPE> <IS> <CLOB> <Left_Paren> <Large_Object_Length> <Right_Paren> <Gen3960_Maybe> rank => 0
<Pascal_Blob_Variable> ::= <SQL> <TYPE> <IS> <BLOB> <Left_Paren> <Large_Object_Length> <Right_Paren> rank => 0
<Pascal_Clob_Locator_Variable> ::= <SQL> <TYPE> <IS> <CLOB> <AS> <LOCATOR> rank => 0
<Pascal_User_Defined_Type_Variable> ::= <SQL> <TYPE> <IS> <Path_Resolved_User_Defined_Type_Name> <AS> <Predefined_Type> rank => 0
<Pascal_Blob_Locator_Variable> ::= <SQL> <TYPE> <IS> <BLOB> <AS> <LOCATOR> rank => 0
<Pascal_User_Defined_Type_Locator_Variable> ::= <SQL> <TYPE> <IS> <Path_Resolved_User_Defined_Type_Name> <AS> <LOCATOR> rank => 0
<Pascal_Array_Locator_Variable> ::= <SQL> <TYPE> <IS> <Array_Type> <AS> <LOCATOR> rank => 0
<Pascal_Multiset_Locator_Variable> ::= <SQL> <TYPE> <IS> <Multiset_Type> <AS> <LOCATOR> rank => 0
<Pascal_Ref_Variable> ::= <SQL> <TYPE> <IS> <Reference_Type> rank => 0
<Embedded_SQL_Pl_I_Program> ::= <EXEC> <SQL> rank => 0
<Pl_I_Host_Identifier> ~ <Host_Identifier_L0>
<Gen3974> ::= <DCL> rank => 0
            | <DECLARE> rank => -1
<Gen3976> ::= <Comma> <Pl_I_Host_Identifier> rank => 0
<Gen3976_Any> ::= <Gen3976>* rank => 0
<Pl_I_Variable_Definition> ::= <Gen3974> <Pl_I_Host_Identifier> <Left_Paren> <Pl_I_Host_Identifier> <Gen3976_Any> <Right_Paren> <Pl_I_Type_Specification> <Character_Representation_Any> <Semicolon> rank => 0
<Gen3979> ::= <CHAR> rank => 0
            | <CHARACTER> rank => -1
<Varying_Maybe> ::= <VARYING> rank => 0
<Varying_Maybe> ::= rank => -1
<Gen3983> ::= <CHARACTER> <SET> <Is_Maybe> <Character_Set_Specification> rank => 0
<Gen3983_Maybe> ::= <Gen3983> rank => 0
<Gen3983_Maybe> ::= rank => -1
<Gen3986> ::= <Comma> <Scale> rank => 0
<Gen3986_Maybe> ::= <Gen3986> rank => 0
<Gen3986_Maybe> ::= rank => -1
<Gen3989> ::= <Left_Paren> <Precision> <Right_Paren> rank => 0
<Gen3989_Maybe> ::= <Gen3989> rank => 0
<Gen3989_Maybe> ::= rank => -1
<Pl_I_Type_Specification> ::= <Gen3979> <Varying_Maybe> <Left_Paren> <Length> <Right_Paren> <Gen3983_Maybe> rank => 0
                            | <Pl_I_Type_Fixed_Decimal> <Left_Paren> <Precision> <Gen3986_Maybe> <Right_Paren> rank => -1
                            | <Pl_I_Type_Fixed_Binary> <Gen3989_Maybe> rank => -2
                            | <Pl_I_Type_Float_Binary> <Left_Paren> <Precision> <Right_Paren> rank => -3
                            | <Pl_I_Derived_Type_Specification> rank => -4
<Pl_I_Derived_Type_Specification> ::= <Pl_I_Clob_Variable> rank => 0
                                    | <Pl_I_Blob_Variable> rank => -1
                                    | <Pl_I_User_Defined_Type_Variable> rank => -2
                                    | <Pl_I_Clob_Locator_Variable> rank => -3
                                    | <Pl_I_Blob_Locator_Variable> rank => -4
                                    | <Pl_I_User_Defined_Type_Locator_Variable> rank => -5
                                    | <Pl_I_Array_Locator_Variable> rank => -6
                                    | <Pl_I_Multiset_Locator_Variable> rank => -7
                                    | <Pl_I_Ref_Variable> rank => -8
<Gen4006> ::= <CHARACTER> <SET> <Is_Maybe> <Character_Set_Specification> rank => 0
<Gen4006_Maybe> ::= <Gen4006> rank => 0
<Gen4006_Maybe> ::= rank => -1
<Pl_I_Clob_Variable> ::= <SQL> <TYPE> <IS> <CLOB> <Left_Paren> <Large_Object_Length> <Right_Paren> <Gen4006_Maybe> rank => 0
<Pl_I_Blob_Variable> ::= <SQL> <TYPE> <IS> <BLOB> <Left_Paren> <Large_Object_Length> <Right_Paren> rank => 0
<Pl_I_User_Defined_Type_Variable> ::= <SQL> <TYPE> <IS> <Path_Resolved_User_Defined_Type_Name> <AS> <Predefined_Type> rank => 0
<Pl_I_Clob_Locator_Variable> ::= <SQL> <TYPE> <IS> <CLOB> <AS> <LOCATOR> rank => 0
<Pl_I_Blob_Locator_Variable> ::= <SQL> <TYPE> <IS> <BLOB> <AS> <LOCATOR> rank => 0
<Pl_I_User_Defined_Type_Locator_Variable> ::= <SQL> <TYPE> <IS> <Path_Resolved_User_Defined_Type_Name> <AS> <LOCATOR> rank => 0
<Pl_I_Array_Locator_Variable> ::= <SQL> <TYPE> <IS> <Array_Type> <AS> <LOCATOR> rank => 0
<Pl_I_Multiset_Locator_Variable> ::= <SQL> <TYPE> <IS> <Multiset_Type> <AS> <LOCATOR> rank => 0
<Pl_I_Ref_Variable> ::= <SQL> <TYPE> <IS> <Reference_Type> rank => 0
<Gen4018> ::= <DEC> rank => 0
            | <DECIMAL> rank => -1
<Gen4020> ::= <DEC> rank => 0
            | <DECIMAL> rank => -1
<Pl_I_Type_Fixed_Decimal> ::= <Gen4018> <FIXED> rank => 0
                            | <FIXED> <Gen4020> rank => -1
<Gen4024> ::= <BIN> rank => 0
            | <BINARY> rank => -1
<Gen4026> ::= <BIN> rank => 0
            | <BINARY> rank => -1
<Pl_I_Type_Fixed_Binary> ::= <Gen4024> <FIXED> rank => 0
                           | <FIXED> <Gen4026> rank => -1
<Gen4030> ::= <BIN> rank => 0
            | <BINARY> rank => -1
<Gen4032> ::= <BIN> rank => 0
            | <BINARY> rank => -1
<Pl_I_Type_Float_Binary> ::= <Gen4030> <FLOAT> rank => 0
                           | <FLOAT> <Gen4032> rank => -1
<Direct_SQL_Statement> ::= <Directly_Executable_Statement> <Semicolon> rank => 0
<Directly_Executable_Statement> ::= <Direct_SQL_Data_Statement> rank => 0
                                  | <SQL_Schema_Statement> rank => -1
                                  | <SQL_Transaction_Statement> rank => -2
                                  | <SQL_Connection_Statement> rank => -3
                                  | <SQL_Session_Statement> rank => -4
<Direct_SQL_Data_Statement> ::= <Delete_Statement_Searched> rank => 0
                              | <Direct_Select_Statement_Multiple_Rows> rank => -1
                              | <Insert_Statement> rank => -2
                              | <Update_Statement_Searched> rank => -3
                              | <Merge_Statement> rank => -4
                              | <Temporary_Table_Declaration> rank => -5
<Direct_Select_Statement_Multiple_Rows> ::= <Cursor_Specification> rank => 0
<Get_Diagnostics_Statement> ::= <GET> <DIAGNOSTICS> <SQL_Diagnostics_Information> rank => 0
<SQL_Diagnostics_Information> ::= <Statement_Information> rank => 0
                                | <Condition_Information> rank => -1
<Gen4052> ::= <Comma> <Statement_Information_Item> rank => 0
<Gen4052_Any> ::= <Gen4052>* rank => 0
<Statement_Information> ::= <Statement_Information_Item> <Gen4052_Any> rank => 0
<Statement_Information_Item> ::= <Simple_Target_Specification> <Equals_Operator> <Statement_Information_Item_Name> rank => 0
<Statement_Information_Item_Name> ::= <NUMBER> rank => 0
                                    | <MORE> rank => -1
                                    | <COMMAND_FUNCTION> rank => -2
                                    | <COMMAND_FUNCTION_CODE> rank => -3
                                    | <DYNAMIC_FUNCTION> rank => -4
                                    | <DYNAMIC_FUNCTION_CODE> rank => -5
                                    | <ROW_COUNT> rank => -6
                                    | <TRANSACTIONS_COMMITTED> rank => -7
                                    | <TRANSACTIONS_ROLLED_BACK> rank => -8
                                    | <TRANSACTION_ACTIVE> rank => -9
<Gen4066> ::= <EXCEPTION> rank => 0
            | <CONDITION> rank => -1
<Gen4068> ::= <Comma> <Condition_Information_Item> rank => 0
<Gen4068_Any> ::= <Gen4068>* rank => 0
<Condition_Information> ::= <Gen4066> <Condition_Number> <Condition_Information_Item> <Gen4068_Any> rank => 0
<Condition_Information_Item> ::= <Simple_Target_Specification> <Equals_Operator> <Condition_Information_Item_Name> rank => 0
<Condition_Information_Item_Name> ::= <CATALOG_NAME> rank => 0
                                    | <CLASS_ORIGIN> rank => -1
                                    | <COLUMN_NAME> rank => -2
                                    | <CONDITION_NUMBER> rank => -3
                                    | <CONNECTION_NAME> rank => -4
                                    | <CONSTRAINT_CATALOG> rank => -5
                                    | <CONSTRAINT_NAME> rank => -6
                                    | <CONSTRAINT_SCHEMA> rank => -7
                                    | <CURSOR_NAME> rank => -8
                                    | <MESSAGE_LENGTH> rank => -9
                                    | <MESSAGE_OCTET_LENGTH> rank => -10
                                    | <MESSAGE_TEXT> rank => -11
                                    | <PARAMETER_MODE> rank => -12
                                    | <PARAMETER_NAME> rank => -13
                                    | <PARAMETER_ORDINAL_POSITION> rank => -14
                                    | <RETURNED_SQLSTATE> rank => -15
                                    | <ROUTINE_CATALOG> rank => -16
                                    | <ROUTINE_NAME> rank => -17
                                    | <ROUTINE_SCHEMA> rank => -18
                                    | <SCHEMA_NAME> rank => -19
                                    | <SERVER_NAME> rank => -20
                                    | <SPECIFIC_NAME> rank => -21
                                    | <SUBCLASS_ORIGIN> rank => -22
                                    | <TABLE_NAME> rank => -23
                                    | <TRIGGER_CATALOG> rank => -24
                                    | <TRIGGER_NAME> rank => -25
                                    | <TRIGGER_SCHEMA> rank => -26
<Condition_Number> ::= <Simple_Value_Specification> rank => 0
<A> ~ 'A':i
<ABS> ~ 'ABS':i
<ABSOLUTE> ~ 'ABSOLUTE':i
<ACTION> ~ 'ACTION':i
<ADA> ~ 'ADA':i
:lexeme ~ <ADD> priority => 1
<ADD> ~ 'ADD':i
<ADMIN> ~ 'ADMIN':i
<AFTER> ~ 'AFTER':i
:lexeme ~ <ALL> priority => 1
<ALL> ~ 'ALL':i
:lexeme ~ <ALLOCATE> priority => 1
<ALLOCATE> ~ 'ALLOCATE':i
:lexeme ~ <ALTER> priority => 1
<ALTER> ~ 'ALTER':i
<ALWAYS> ~ 'ALWAYS':i
:lexeme ~ <AND> priority => 1
<AND> ~ 'AND':i
:lexeme ~ <ANY> priority => 1
<ANY> ~ 'ANY':i
:lexeme ~ <ARE> priority => 1
<ARE> ~ 'ARE':i
:lexeme ~ <ARRAY> priority => 1
<ARRAY> ~ 'ARRAY':i
:lexeme ~ <AS> priority => 1
<AS> ~ 'AS':i
<ASC> ~ 'ASC':i
:lexeme ~ <ASENSITIVE> priority => 1
<ASENSITIVE> ~ 'ASENSITIVE':i
<ASSERTION> ~ 'ASSERTION':i
<ASSIGNMENT> ~ 'ASSIGNMENT':i
:lexeme ~ <ASYMMETRIC> priority => 1
<ASYMMETRIC> ~ 'ASYMMETRIC':i
:lexeme ~ <AT> priority => 1
<AT> ~ 'AT':i
:lexeme ~ <ATOMIC> priority => 1
<ATOMIC> ~ 'ATOMIC':i
<ATTRIBUTE> ~ 'ATTRIBUTE':i
<ATTRIBUTES> ~ 'ATTRIBUTES':i
:lexeme ~ <AUTHORIZATION> priority => 1
<AUTHORIZATION> ~ 'AUTHORIZATION':i
<AVG> ~ 'AVG':i
<B> ~ 'B':i
<BEFORE> ~ 'BEFORE':i
:lexeme ~ <BEGIN> priority => 1
<BEGIN> ~ 'BEGIN':i
<BERNOULLI> ~ 'BERNOULLI':i
:lexeme ~ <BETWEEN> priority => 1
<BETWEEN> ~ 'BETWEEN':i
:lexeme ~ <BIGINT> priority => 1
<BIGINT> ~ 'BIGINT':i
<BIN> ~ 'BIN':i
:lexeme ~ <BINARY> priority => 1
<BINARY> ~ 'BINARY':i
:lexeme ~ <BLOB> priority => 1
<BLOB> ~ 'BLOB':i
:lexeme ~ <BOOLEAN> priority => 1
<BOOLEAN> ~ 'BOOLEAN':i
:lexeme ~ <BOTH> priority => 1
<BOTH> ~ 'BOTH':i
<BREADTH> ~ 'BREADTH':i
:lexeme ~ <BY> priority => 1
<BY> ~ 'BY':i
<C> ~ 'C':i
:lexeme ~ <CALL> priority => 1
<CALL> ~ 'CALL':i
:lexeme ~ <CALLED> priority => 1
<CALLED> ~ 'CALLED':i
<CARDINALITY> ~ 'CARDINALITY':i
<CASCADE> ~ 'CASCADE':i
:lexeme ~ <CASCADED> priority => 1
<CASCADED> ~ 'CASCADED':i
:lexeme ~ <CASE> priority => 1
<CASE> ~ 'CASE':i
:lexeme ~ <CAST> priority => 1
<CAST> ~ 'CAST':i
<CATALOG> ~ 'CATALOG':i
<CATALOG_NAME> ~ 'CATALOG_NAME':i
<CEIL> ~ 'CEIL':i
<CEILING> ~ 'CEILING':i
<CHAIN> ~ 'CHAIN':i
:lexeme ~ <CHAR> priority => 1
<CHAR> ~ 'CHAR':i
:lexeme ~ <CHARACTER> priority => 1
<CHARACTER> ~ 'CHARACTER':i
<CHARACTERISTICS> ~ 'CHARACTERISTICS':i
<CHARACTERS> ~ 'CHARACTERS':i
<CHARACTER_LENGTH> ~ 'CHARACTER_LENGTH':i
<CHARACTER_SET_CATALOG> ~ 'CHARACTER_SET_CATALOG':i
<CHARACTER_SET_NAME> ~ 'CHARACTER_SET_NAME':i
<CHARACTER_SET_SCHEMA> ~ 'CHARACTER_SET_SCHEMA':i
<CHAR_LENGTH> ~ 'CHAR_LENGTH':i
:lexeme ~ <CHECK> priority => 1
<CHECK> ~ 'CHECK':i
<CHECKED> ~ 'CHECKED':i
<CLASS_ORIGIN> ~ 'CLASS_ORIGIN':i
:lexeme ~ <CLOB> priority => 1
<CLOB> ~ 'CLOB':i
:lexeme ~ <CLOSE> priority => 1
<CLOSE> ~ 'CLOSE':i
<COALESCE> ~ 'COALESCE':i
<COBOL> ~ 'COBOL':i
<CODE_UNITS> ~ 'CODE_UNITS':i
:lexeme ~ <COLLATE> priority => 1
<COLLATE> ~ 'COLLATE':i
<COLLATION> ~ 'COLLATION':i
<COLLATION_CATALOG> ~ 'COLLATION_CATALOG':i
<COLLATION_NAME> ~ 'COLLATION_NAME':i
<COLLATION_SCHEMA> ~ 'COLLATION_SCHEMA':i
<COLLECT> ~ 'COLLECT':i
:lexeme ~ <COLUMN> priority => 1
<COLUMN> ~ 'COLUMN':i
<COLUMN_NAME> ~ 'COLUMN_NAME':i
<COMMAND_FUNCTION> ~ 'COMMAND_FUNCTION':i
<COMMAND_FUNCTION_CODE> ~ 'COMMAND_FUNCTION_CODE':i
:lexeme ~ <COMMIT> priority => 1
<COMMIT> ~ 'COMMIT':i
<COMMITTED> ~ 'COMMITTED':i
<CONDITION> ~ 'CONDITION':i
<CONDITION_NUMBER> ~ 'CONDITION_NUMBER':i
:lexeme ~ <CONNECT> priority => 1
<CONNECT> ~ 'CONNECT':i
<CONNECTION> ~ 'CONNECTION':i
<CONNECTION_NAME> ~ 'CONNECTION_NAME':i
:lexeme ~ <CONSTRAINT> priority => 1
<CONSTRAINT> ~ 'CONSTRAINT':i
<CONSTRAINTS> ~ 'CONSTRAINTS':i
<CONSTRAINT_CATALOG> ~ 'CONSTRAINT_CATALOG':i
<CONSTRAINT_NAME> ~ 'CONSTRAINT_NAME':i
<CONSTRAINT_SCHEMA> ~ 'CONSTRAINT_SCHEMA':i
<CONSTRUCTOR> ~ 'CONSTRUCTOR':i
<CONSTRUCTORS> ~ 'CONSTRUCTORS':i
<CONTAINS> ~ 'CONTAINS':i
:lexeme ~ <CONTINUE> priority => 1
<CONTINUE> ~ 'CONTINUE':i
<CONVERT> ~ 'CONVERT':i
<CORR> ~ 'CORR':i
:lexeme ~ <CORRESPONDING> priority => 1
<CORRESPONDING> ~ 'CORRESPONDING':i
<COUNT> ~ 'COUNT':i
<COVAR_POP> ~ 'COVAR_POP':i
<COVAR_SAMP> ~ 'COVAR_SAMP':i
:lexeme ~ <CREATE> priority => 1
<CREATE> ~ 'CREATE':i
:lexeme ~ <CROSS> priority => 1
<CROSS> ~ 'CROSS':i
:lexeme ~ <CUBE> priority => 1
<CUBE> ~ 'CUBE':i
<CUME_DIST> ~ 'CUME_DIST':i
:lexeme ~ <CURRENT> priority => 1
<CURRENT> ~ 'CURRENT':i
<CURRENT_COLLATION> ~ 'CURRENT_COLLATION':i
:lexeme ~ <CURRENT_DATE> priority => 1
<CURRENT_DATE> ~ 'CURRENT_DATE':i
:lexeme ~ <CURRENT_DEFAULT_TRANSFORM_GROUP> priority => 1
<CURRENT_DEFAULT_TRANSFORM_GROUP> ~ 'CURRENT_DEFAULT_TRANSFORM_GROUP':i
:lexeme ~ <CURRENT_PATH> priority => 1
<CURRENT_PATH> ~ 'CURRENT_PATH':i
:lexeme ~ <CURRENT_ROLE> priority => 1
<CURRENT_ROLE> ~ 'CURRENT_ROLE':i
:lexeme ~ <CURRENT_TIME> priority => 1
<CURRENT_TIME> ~ 'CURRENT_TIME':i
:lexeme ~ <CURRENT_TIMESTAMP> priority => 1
<CURRENT_TIMESTAMP> ~ 'CURRENT_TIMESTAMP':i
:lexeme ~ <CURRENT_TRANSFORM_GROUP_FOR_TYPE> priority => 1
<CURRENT_TRANSFORM_GROUP_FOR_TYPE> ~ 'CURRENT_TRANSFORM_GROUP_FOR_TYPE':i
:lexeme ~ <CURRENT_USER> priority => 1
<CURRENT_USER> ~ 'CURRENT_USER':i
:lexeme ~ <CURSOR> priority => 1
<CURSOR> ~ 'CURSOR':i
<CURSOR_NAME> ~ 'CURSOR_NAME':i
:lexeme ~ <CYCLE> priority => 1
<CYCLE> ~ 'CYCLE':i
<D> ~ 'D':i
<DATA> ~ 'DATA':i
:lexeme ~ <DATE> priority => 1
<DATE> ~ 'DATE':i
<DATETIME_INTERVAL_CODE> ~ 'DATETIME_INTERVAL_CODE':i
<DATETIME_INTERVAL_PRECISION> ~ 'DATETIME_INTERVAL_PRECISION':i
:lexeme ~ <DAY> priority => 1
<DAY> ~ 'DAY':i
<DCL> ~ 'DCL':i
:lexeme ~ <DEALLOCATE> priority => 1
<DEALLOCATE> ~ 'DEALLOCATE':i
:lexeme ~ <DEC> priority => 1
<DEC> ~ 'DEC':i
:lexeme ~ <DECIMAL> priority => 1
<DECIMAL> ~ 'DECIMAL':i
:lexeme ~ <DECLARE> priority => 1
<DECLARE> ~ 'DECLARE':i
:lexeme ~ <DEFAULT> priority => 1
<DEFAULT> ~ 'DEFAULT':i
<DEFAULTS> ~ 'DEFAULTS':i
<DEFERRABLE> ~ 'DEFERRABLE':i
<DEFERRED> ~ 'DEFERRED':i
<DEFINED> ~ 'DEFINED':i
<DEFINER> ~ 'DEFINER':i
<DEGREE> ~ 'DEGREE':i
:lexeme ~ <DELETE> priority => 1
<DELETE> ~ 'DELETE':i
<DENSE_RANK> ~ 'DENSE_RANK':i
<DEPTH> ~ 'DEPTH':i
:lexeme ~ <DEREF> priority => 1
<DEREF> ~ 'DEREF':i
<DERIVED> ~ 'DERIVED':i
<DESC> ~ 'DESC':i
:lexeme ~ <DESCRIBE> priority => 1
<DESCRIBE> ~ 'DESCRIBE':i
<DESCRIPTOR> ~ 'DESCRIPTOR':i
:lexeme ~ <DETERMINISTIC> priority => 1
<DETERMINISTIC> ~ 'DETERMINISTIC':i
<DIAGNOSTICS> ~ 'DIAGNOSTICS':i
:lexeme ~ <DISCONNECT> priority => 1
<DISCONNECT> ~ 'DISCONNECT':i
<DISPATCH> ~ 'DISPATCH':i
<DISPLAY> ~ 'DISPLAY':i
:lexeme ~ <DISTINCT> priority => 1
<DISTINCT> ~ 'DISTINCT':i
<DOMAIN> ~ 'DOMAIN':i
:lexeme ~ <DOUBLE> priority => 1
<DOUBLE> ~ 'DOUBLE':i
<DOUBLE_PRECISION> ~ 'DOUBLE_PRECISION':i
:lexeme ~ <DROP> priority => 1
<DROP> ~ 'DROP':i
:lexeme ~ <DYNAMIC> priority => 1
<DYNAMIC> ~ 'DYNAMIC':i
<DYNAMIC_FUNCTION> ~ 'DYNAMIC_FUNCTION':i
<DYNAMIC_FUNCTION_CODE> ~ 'DYNAMIC_FUNCTION_CODE':i
<E> ~ 'E':i
:lexeme ~ <EACH> priority => 1
<EACH> ~ 'EACH':i
:lexeme ~ <ELEMENT> priority => 1
<ELEMENT> ~ 'ELEMENT':i
:lexeme ~ <ELSE> priority => 1
<ELSE> ~ 'ELSE':i
:lexeme ~ <END> priority => 1
<END> ~ 'END':i
<EQUALS> ~ 'EQUALS':i
:lexeme ~ <ESCAPE> priority => 1
<ESCAPE> ~ 'ESCAPE':i
<EVERY> ~ 'EVERY':i
:lexeme ~ <EXCEPT> priority => 1
<EXCEPT> ~ 'EXCEPT':i
<EXCEPTION> ~ 'EXCEPTION':i
<EXCLUDE> ~ 'EXCLUDE':i
<EXCLUDING> ~ 'EXCLUDING':i
:lexeme ~ <EXEC> priority => 1
<EXEC> ~ 'EXEC':i
:lexeme ~ <EXECUTE> priority => 1
<EXECUTE> ~ 'EXECUTE':i
:lexeme ~ <EXISTS> priority => 1
<EXISTS> ~ 'EXISTS':i
<EXP> ~ 'EXP':i
:lexeme ~ <EXTERNAL> priority => 1
<EXTERNAL> ~ 'EXTERNAL':i
<EXTRACT> ~ 'EXTRACT':i
<F> ~ 'F':i
:lexeme ~ <FALSE> priority => 1
<FALSE> ~ 'FALSE':i
:lexeme ~ <FETCH> priority => 1
<FETCH> ~ 'FETCH':i
:lexeme ~ <FILTER> priority => 1
<FILTER> ~ 'FILTER':i
<FINAL> ~ 'FINAL':i
<FIRST> ~ 'FIRST':i
<FIXED> ~ 'FIXED':i
:lexeme ~ <FLOAT> priority => 1
<FLOAT> ~ 'FLOAT':i
<FLOOR> ~ 'FLOOR':i
<FOLLOWING> ~ 'FOLLOWING':i
:lexeme ~ <FOR> priority => 1
<FOR> ~ 'FOR':i
:lexeme ~ <FOREIGN> priority => 1
<FOREIGN> ~ 'FOREIGN':i
<FORTRAN> ~ 'FORTRAN':i
<FOUND> ~ 'FOUND':i
:lexeme ~ <FREE> priority => 1
<FREE> ~ 'FREE':i
:lexeme ~ <FROM> priority => 1
<FROM> ~ 'FROM':i
:lexeme ~ <FULL> priority => 1
<FULL> ~ 'FULL':i
:lexeme ~ <FUNCTION> priority => 1
<FUNCTION> ~ 'FUNCTION':i
<FUSION> ~ 'FUSION':i
<G> ~ 'G':i
<GENERAL> ~ 'GENERAL':i
<GENERATED> ~ 'GENERATED':i
:lexeme ~ <GET> priority => 1
<GET> ~ 'GET':i
:lexeme ~ <GLOBAL> priority => 1
<GLOBAL> ~ 'GLOBAL':i
<GO> ~ 'GO':i
<GOTO> ~ 'GOTO':i
:lexeme ~ <GRANT> priority => 1
<GRANT> ~ 'GRANT':i
<GRANTED> ~ 'GRANTED':i
:lexeme ~ <GROUP> priority => 1
<GROUP> ~ 'GROUP':i
:lexeme ~ <GROUPING> priority => 1
<GROUPING> ~ 'GROUPING':i
:lexeme ~ <HAVING> priority => 1
<HAVING> ~ 'HAVING':i
<HIERARCHY> ~ 'HIERARCHY':i
:lexeme ~ <HOLD> priority => 1
<HOLD> ~ 'HOLD':i
:lexeme ~ <HOUR> priority => 1
<HOUR> ~ 'HOUR':i
:lexeme ~ <IDENTITY> priority => 1
<IDENTITY> ~ 'IDENTITY':i
:lexeme ~ <IMMEDIATE> priority => 1
<IMMEDIATE> ~ 'IMMEDIATE':i
<IMPLEMENTATION> ~ 'IMPLEMENTATION':i
:lexeme ~ <IN> priority => 1
<IN> ~ 'IN':i
<INCLUDING> ~ 'INCLUDING':i
<INCREMENT> ~ 'INCREMENT':i
:lexeme ~ <INDICATOR> priority => 1
<INDICATOR> ~ 'INDICATOR':i
<INDICATOR_TYPE> ~ 'INDICATOR_TYPE':i
<INITIALLY> ~ 'INITIALLY':i
:lexeme ~ <INNER> priority => 1
<INNER> ~ 'INNER':i
:lexeme ~ <INOUT> priority => 1
<INOUT> ~ 'INOUT':i
:lexeme ~ <INPUT> priority => 1
<INPUT> ~ 'INPUT':i
:lexeme ~ <INSENSITIVE> priority => 1
<INSENSITIVE> ~ 'INSENSITIVE':i
:lexeme ~ <INSERT> priority => 1
<INSERT> ~ 'INSERT':i
<INSTANCE> ~ 'INSTANCE':i
<INSTANTIABLE> ~ 'INSTANTIABLE':i
:lexeme ~ <INT> priority => 1
<INT> ~ 'INT':i
:lexeme ~ <INTEGER> priority => 1
<INTEGER> ~ 'INTEGER':i
:lexeme ~ <INTERSECT> priority => 1
<INTERSECT> ~ 'INTERSECT':i
<INTERSECTION> ~ 'INTERSECTION':i
:lexeme ~ <INTERVAL> priority => 1
<INTERVAL> ~ 'INTERVAL':i
:lexeme ~ <INTO> priority => 1
<INTO> ~ 'INTO':i
<INVOKER> ~ 'INVOKER':i
:lexeme ~ <IS> priority => 1
<IS> ~ 'IS':i
:lexeme ~ <ISOLATION> priority => 1
<ISOLATION> ~ 'ISOLATION':i
:lexeme ~ <JOIN> priority => 1
<JOIN> ~ 'JOIN':i
<K> ~ 'K':i
<KEY> ~ 'KEY':i
<KEY_MEMBER> ~ 'KEY_MEMBER':i
<KEY_TYPE> ~ 'KEY_TYPE':i
<KIND> ~ 'KIND':i
:lexeme ~ <LANGUAGE> priority => 1
<LANGUAGE> ~ 'LANGUAGE':i
:lexeme ~ <LARGE> priority => 1
<LARGE> ~ 'LARGE':i
<LAST> ~ 'LAST':i
:lexeme ~ <LATERAL> priority => 1
<LATERAL> ~ 'LATERAL':i
:lexeme ~ <LEADING> priority => 1
<LEADING> ~ 'LEADING':i
:lexeme ~ <LEFT> priority => 1
<LEFT> ~ 'LEFT':i
<LENGTH> ~ 'LENGTH':i
<LEVEL> ~ 'LEVEL':i
:lexeme ~ <LIKE> priority => 1
<LIKE> ~ 'LIKE':i
<LN> ~ 'LN':i
:lexeme ~ <LOCAL> priority => 1
<LOCAL> ~ 'LOCAL':i
:lexeme ~ <LOCALTIME> priority => 1
<LOCALTIME> ~ 'LOCALTIME':i
:lexeme ~ <LOCALTIMESTAMP> priority => 1
<LOCALTIMESTAMP> ~ 'LOCALTIMESTAMP':i
<LOCATOR> ~ 'LOCATOR':i
<LOGICAL> ~ 'LOGICAL':i
<LOWER> ~ 'LOWER':i
<Lex001> ~ [A-Z]
<Lex002> ~ [a-z]
<Lex003> ~ [0-9]
<Lex004> ~ [\s]
<Lex005> ~ '"'
<Lex006> ~ '%'
<Lex007> ~ '&'
<Lex008> ~ [']
<Lex009> ~ '('
<Lex010> ~ ')'
<Lex011> ~ '*'
<Lex012> ~ '+'
<Lex013> ~ ','
<Lex014> ~ '-'
<Lex015> ~ '.'
<Lex016> ~ '/'
<Lex017> ~ ':'
<Lex018> ~ ';'
<Lex019> ~ '<'
<Lex020> ~ '='
<Lex021> ~ '>'
<Lex022> ~ '?'
<Lex023> ~ '['
<Lex024> ~ '??('
<Lex025> ~ ']'
<Lex026> ~ '??)'
<Lex027> ~ '^'
<Lex029> ~ '|'
<Lex030> ~ '{'
<Lex031> ~ '}'
<Lex032> ~ 'K':i
<Lex033> ~ 'M':i
<Lex034> ~ 'G':i
<Lex035> ~ '"'
<Lex036> ~ '"'
<Lex037> ~ 'U':i
<Lex038> ~ '&'
<Lex039> ~ '"'
<Lex040> ~ '"'
<Lex042> ~ [']
<Lex043> ~ [']
<Lex044> ~ [a-fA-f0-9]
<Lex045> ~ '+'
<Lex046> ~ [\s\S]
<Lex047> ~ [^"]
<Lex048> ~ '"'
<Lex049> ~ '""'
:lexeme ~ <Lex374> priority => 1
<Lex374> ~ 'END-EXEC'
:lexeme ~ <Lex472> priority => 1
<Lex472> ~ 'REGR_R2'
<Lex545> ~ [^']
<Lex546> ~ [\x{5c}]
<Lex547> ~ [']
<Lex548> ~ [']
<Lex549> ~ [']
<Lex550> ~ 'N':i
<Lex551> ~ 'U':i
<Lex563_Many> ~ [\d]+
<Lex564> ~ 'E':i
<Lex565_Many> ~ [^\s,;:()]+
<Lex566> ~ '('
<Lex567> ~ ')'
<Lex568> ~ 'MODULE':i
<Lex569> ~ 'MODULE':i
<Lex571> ~ 'MODULE':i
<Lex572> ~ [^\[\]()|\^\-+*_%?{\\]
<Lex573> ~ [\x{5c}]
<Lex574> ~ [\[\]()|\^\-+*_%?{\\]
<Lex579> ~ 'Interfaces.SQL'
<Lex580> ~ '1'
<Lex595> ~ '01'
<Lex596> ~ '77'
<Lex605> ~ '9'
<Lex607> ~ [0-9]
<Lex607_Many> ~ [0-9]*
<M> ~ 'M':i
<MAP> ~ 'MAP':i
:lexeme ~ <MATCH> priority => 1
<MATCH> ~ 'MATCH':i
<MATCHED> ~ 'MATCHED':i
<MAX> ~ 'MAX':i
<MAXVALUE> ~ 'MAXVALUE':i
:lexeme ~ <MEMBER> priority => 1
<MEMBER> ~ 'MEMBER':i
:lexeme ~ <MERGE> priority => 1
<MERGE> ~ 'MERGE':i
<MESSAGE_LENGTH> ~ 'MESSAGE_LENGTH':i
<MESSAGE_OCTET_LENGTH> ~ 'MESSAGE_OCTET_LENGTH':i
<MESSAGE_TEXT> ~ 'MESSAGE_TEXT':i
:lexeme ~ <METHOD> priority => 1
<METHOD> ~ 'METHOD':i
<MIN> ~ 'MIN':i
:lexeme ~ <MINUTE> priority => 1
<MINUTE> ~ 'MINUTE':i
<MINVALUE> ~ 'MINVALUE':i
<MOD> ~ 'MOD':i
:lexeme ~ <MODIFIES> priority => 1
<MODIFIES> ~ 'MODIFIES':i
:lexeme ~ <MODULE> priority => 1
<MODULE> ~ 'MODULE':i
:lexeme ~ <MONTH> priority => 1
<MONTH> ~ 'MONTH':i
<MORE> ~ 'MORE':i
:lexeme ~ <MULTISET> priority => 1
<MULTISET> ~ 'MULTISET':i
<MUMPS> ~ 'MUMPS':i
<N> ~ 'N':i
<NAME> ~ 'NAME':i
<NAMES> ~ 'NAMES':i
:lexeme ~ <NATIONAL> priority => 1
<NATIONAL> ~ 'NATIONAL':i
:lexeme ~ <NATURAL> priority => 1
<NATURAL> ~ 'NATURAL':i
:lexeme ~ <NCHAR> priority => 1
<NCHAR> ~ 'NCHAR':i
:lexeme ~ <NCLOB> priority => 1
<NCLOB> ~ 'NCLOB':i
<NESTING> ~ 'NESTING':i
:lexeme ~ <NEW> priority => 1
<NEW> ~ 'NEW':i
<NEXT> ~ 'NEXT':i
:lexeme ~ <NO> priority => 1
<NO> ~ 'NO':i
:lexeme ~ <NONE> priority => 1
<NONE> ~ 'NONE':i
<NORMALIZE> ~ 'NORMALIZE':i
<NORMALIZED> ~ 'NORMALIZED':i
:lexeme ~ <NOT> priority => 1
<NOT> ~ 'NOT':i
:lexeme ~ <NULL> priority => 1
<NULL> ~ 'NULL':i
<NULLABLE> ~ 'NULLABLE':i
<NULLIF> ~ 'NULLIF':i
<NULLS> ~ 'NULLS':i
<NUMBER> ~ 'NUMBER':i
:lexeme ~ <NUMERIC> priority => 1
<NUMERIC> ~ 'NUMERIC':i
<OBJECT> ~ 'OBJECT':i
<OCTETS> ~ 'OCTETS':i
<OCTET_LENGTH> ~ 'OCTET_LENGTH':i
:lexeme ~ <OF> priority => 1
<OF> ~ 'OF':i
:lexeme ~ <OLD> priority => 1
<OLD> ~ 'OLD':i
:lexeme ~ <ON> priority => 1
<ON> ~ 'ON':i
:lexeme ~ <ONLY> priority => 1
<ONLY> ~ 'ONLY':i
:lexeme ~ <OPEN> priority => 1
<OPEN> ~ 'OPEN':i
<OPTION> ~ 'OPTION':i
<OPTIONS> ~ 'OPTIONS':i
:lexeme ~ <OR> priority => 1
<OR> ~ 'OR':i
:lexeme ~ <ORDER> priority => 1
<ORDER> ~ 'ORDER':i
<ORDERING> ~ 'ORDERING':i
<ORDINALITY> ~ 'ORDINALITY':i
<OTHERS> ~ 'OTHERS':i
:lexeme ~ <OUT> priority => 1
<OUT> ~ 'OUT':i
:lexeme ~ <OUTER> priority => 1
<OUTER> ~ 'OUTER':i
:lexeme ~ <OUTPUT> priority => 1
<OUTPUT> ~ 'OUTPUT':i
:lexeme ~ <OVER> priority => 1
<OVER> ~ 'OVER':i
:lexeme ~ <OVERLAPS> priority => 1
<OVERLAPS> ~ 'OVERLAPS':i
<OVERLAY> ~ 'OVERLAY':i
<OVERRIDING> ~ 'OVERRIDING':i
<PACKED> ~ 'PACKED':i
<PAD> ~ 'PAD':i
:lexeme ~ <PARAMETER> priority => 1
<PARAMETER> ~ 'PARAMETER':i
<PARAMETER_MODE> ~ 'PARAMETER_MODE':i
<PARAMETER_NAME> ~ 'PARAMETER_NAME':i
<PARAMETER_ORDINAL_POSITION> ~ 'PARAMETER_ORDINAL_POSITION':i
<PARAMETER_SPECIFIC_CATALOG> ~ 'PARAMETER_SPECIFIC_CATALOG':i
<PARAMETER_SPECIFIC_NAME> ~ 'PARAMETER_SPECIFIC_NAME':i
<PARAMETER_SPECIFIC_SCHEMA> ~ 'PARAMETER_SPECIFIC_SCHEMA':i
<PARTIAL> ~ 'PARTIAL':i
:lexeme ~ <PARTITION> priority => 1
<PARTITION> ~ 'PARTITION':i
<PASCAL> ~ 'PASCAL':i
<PATH> ~ 'PATH':i
<PERCENTILE_CONT> ~ 'PERCENTILE_CONT':i
<PERCENTILE_DISC> ~ 'PERCENTILE_DISC':i
<PERCENT_RANK> ~ 'PERCENT_RANK':i
<PIC> ~ 'PIC':i
<PICTURE> ~ 'PICTURE':i
<PLACING> ~ 'PLACING':i
<PLI> ~ 'PLI':i
<POSITION> ~ 'POSITION':i
<POWER> ~ 'POWER':i
<PRECEDING> ~ 'PRECEDING':i
:lexeme ~ <PRECISION> priority => 1
<PRECISION> ~ 'PRECISION':i
:lexeme ~ <PREPARE> priority => 1
<PREPARE> ~ 'PREPARE':i
<PRESERVE> ~ 'PRESERVE':i
:lexeme ~ <PRIMARY> priority => 1
<PRIMARY> ~ 'PRIMARY':i
<PRIOR> ~ 'PRIOR':i
<PRIVILEGES> ~ 'PRIVILEGES':i
:lexeme ~ <PROCEDURE> priority => 1
<PROCEDURE> ~ 'PROCEDURE':i
<PUBLIC> ~ 'PUBLIC':i
:lexeme ~ <RANGE> priority => 1
<RANGE> ~ 'RANGE':i
<RANK> ~ 'RANK':i
<READ> ~ 'READ':i
:lexeme ~ <READS> priority => 1
<READS> ~ 'READS':i
:lexeme ~ <REAL> priority => 1
<REAL> ~ 'REAL':i
:lexeme ~ <RECURSIVE> priority => 1
<RECURSIVE> ~ 'RECURSIVE':i
:lexeme ~ <REF> priority => 1
<REF> ~ 'REF':i
:lexeme ~ <REFERENCES> priority => 1
<REFERENCES> ~ 'REFERENCES':i
:lexeme ~ <REFERENCING> priority => 1
<REFERENCING> ~ 'REFERENCING':i
:lexeme ~ <REGR_AVGX> priority => 1
<REGR_AVGX> ~ 'REGR_AVGX':i
:lexeme ~ <REGR_AVGY> priority => 1
<REGR_AVGY> ~ 'REGR_AVGY':i
:lexeme ~ <REGR_COUNT> priority => 1
<REGR_COUNT> ~ 'REGR_COUNT':i
:lexeme ~ <REGR_INTERCEPT> priority => 1
<REGR_INTERCEPT> ~ 'REGR_INTERCEPT':i
:lexeme ~ <REGR_SLOPE> priority => 1
<REGR_SLOPE> ~ 'REGR_SLOPE':i
:lexeme ~ <REGR_SXX> priority => 1
<REGR_SXX> ~ 'REGR_SXX':i
:lexeme ~ <REGR_SXY> priority => 1
<REGR_SXY> ~ 'REGR_SXY':i
:lexeme ~ <REGR_SYY> priority => 1
<REGR_SYY> ~ 'REGR_SYY':i
<RELATIVE> ~ 'RELATIVE':i
:lexeme ~ <RELEASE> priority => 1
<RELEASE> ~ 'RELEASE':i
<REPEATABLE> ~ 'REPEATABLE':i
<RESTART> ~ 'RESTART':i
<RESTRICT> ~ 'RESTRICT':i
:lexeme ~ <RESULT> priority => 1
<RESULT> ~ 'RESULT':i
:lexeme ~ <RETURN> priority => 1
<RETURN> ~ 'RETURN':i
<RETURNED_CARDINALITY> ~ 'RETURNED_CARDINALITY':i
<RETURNED_LENGTH> ~ 'RETURNED_LENGTH':i
<RETURNED_OCTET_LENGTH> ~ 'RETURNED_OCTET_LENGTH':i
<RETURNED_SQLSTATE> ~ 'RETURNED_SQLSTATE':i
:lexeme ~ <RETURNS> priority => 1
<RETURNS> ~ 'RETURNS':i
:lexeme ~ <REVOKE> priority => 1
<REVOKE> ~ 'REVOKE':i
:lexeme ~ <RIGHT> priority => 1
<RIGHT> ~ 'RIGHT':i
<ROLE> ~ 'ROLE':i
:lexeme ~ <ROLLBACK> priority => 1
<ROLLBACK> ~ 'ROLLBACK':i
:lexeme ~ <ROLLUP> priority => 1
<ROLLUP> ~ 'ROLLUP':i
<ROUTINE> ~ 'ROUTINE':i
<ROUTINE_CATALOG> ~ 'ROUTINE_CATALOG':i
<ROUTINE_NAME> ~ 'ROUTINE_NAME':i
<ROUTINE_SCHEMA> ~ 'ROUTINE_SCHEMA':i
:lexeme ~ <ROW> priority => 1
<ROW> ~ 'ROW':i
:lexeme ~ <ROWS> priority => 1
<ROWS> ~ 'ROWS':i
<ROW_COUNT> ~ 'ROW_COUNT':i
<ROW_NUMBER> ~ 'ROW_NUMBER':i
<S> ~ 'S':i
:lexeme ~ <SAVEPOINT> priority => 1
<SAVEPOINT> ~ 'SAVEPOINT':i
<SCALE> ~ 'SCALE':i
<SCHEMA> ~ 'SCHEMA':i
<SCHEMA_NAME> ~ 'SCHEMA_NAME':i
<SCOPE> ~ 'SCOPE':i
<SCOPE_CATALOG> ~ 'SCOPE_CATALOG':i
<SCOPE_NAME> ~ 'SCOPE_NAME':i
<SCOPE_SCHEMA> ~ 'SCOPE_SCHEMA':i
:lexeme ~ <SCROLL> priority => 1
<SCROLL> ~ 'SCROLL':i
:lexeme ~ <SEARCH> priority => 1
<SEARCH> ~ 'SEARCH':i
:lexeme ~ <SECOND> priority => 1
<SECOND> ~ 'SECOND':i
<SECTION> ~ 'SECTION':i
<SECURITY> ~ 'SECURITY':i
:lexeme ~ <SELECT> priority => 1
<SELECT> ~ 'SELECT':i
<SELF> ~ 'SELF':i
:lexeme ~ <SENSITIVE> priority => 1
<SENSITIVE> ~ 'SENSITIVE':i
<SEPARATE> ~ 'SEPARATE':i
<SEQUENCE> ~ 'SEQUENCE':i
<SERIALIZABLE> ~ 'SERIALIZABLE':i
<SERVER_NAME> ~ 'SERVER_NAME':i
<SESSION> ~ 'SESSION':i
:lexeme ~ <SESSION_USER> priority => 1
<SESSION_USER> ~ 'SESSION_USER':i
:lexeme ~ <SET> priority => 1
<SET> ~ 'SET':i
<SETS> ~ 'SETS':i
<SIGN> ~ 'SIGN':i
:lexeme ~ <SIMILAR> priority => 1
<SIMILAR> ~ 'SIMILAR':i
<SIMPLE> ~ 'SIMPLE':i
<SIZE> ~ 'SIZE':i
:lexeme ~ <SMALLINT> priority => 1
<SMALLINT> ~ 'SMALLINT':i
:lexeme ~ <SOME> priority => 1
<SOME> ~ 'SOME':i
<SOURCE> ~ 'SOURCE':i
<SPACE> ~ 'SPACE':i
:lexeme ~ <SPECIFIC> priority => 1
<SPECIFIC> ~ 'SPECIFIC':i
:lexeme ~ <SPECIFICTYPE> priority => 1
<SPECIFICTYPE> ~ 'SPECIFICTYPE':i
<SPECIFIC_NAME> ~ 'SPECIFIC_NAME':i
:lexeme ~ <SQL> priority => 1
<SQL> ~ 'SQL':i
:lexeme ~ <SQLEXCEPTION> priority => 1
<SQLEXCEPTION> ~ 'SQLEXCEPTION':i
:lexeme ~ <SQLSTATE> priority => 1
<SQLSTATE> ~ 'SQLSTATE':i
<SQLSTATE_TYPE> ~ 'SQLSTATE_TYPE':i
:lexeme ~ <SQLWARNING> priority => 1
<SQLWARNING> ~ 'SQLWARNING':i
<SQRT> ~ 'SQRT':i
:lexeme ~ <START> priority => 1
<START> ~ 'START':i
<STATE> ~ 'STATE':i
<STATEMENT> ~ 'STATEMENT':i
:lexeme ~ <STATIC> priority => 1
<STATIC> ~ 'STATIC':i
<STDDEV_POP> ~ 'STDDEV_POP':i
<STDDEV_SAMP> ~ 'STDDEV_SAMP':i
<STRUCTURE> ~ 'STRUCTURE':i
<STYLE> ~ 'STYLE':i
<SUBCLASS_ORIGIN> ~ 'SUBCLASS_ORIGIN':i
:lexeme ~ <SUBMULTISET> priority => 1
<SUBMULTISET> ~ 'SUBMULTISET':i
<SUBSTRING> ~ 'SUBSTRING':i
<SUM> ~ 'SUM':i
:lexeme ~ <SYMMETRIC> priority => 1
<SYMMETRIC> ~ 'SYMMETRIC':i
:lexeme ~ <SYSTEM> priority => 1
<SYSTEM> ~ 'SYSTEM':i
:lexeme ~ <SYSTEM_USER> priority => 1
<SYSTEM_USER> ~ 'SYSTEM_USER':i
:lexeme ~ <TABLE> priority => 1
<TABLE> ~ 'TABLE':i
<TABLESAMPLE> ~ 'TABLESAMPLE':i
<TABLE_NAME> ~ 'TABLE_NAME':i
<TEMPORARY> ~ 'TEMPORARY':i
:lexeme ~ <THEN> priority => 1
<THEN> ~ 'THEN':i
<TIES> ~ 'TIES':i
:lexeme ~ <TIME> priority => 1
<TIME> ~ 'TIME':i
:lexeme ~ <TIMESTAMP> priority => 1
<TIMESTAMP> ~ 'TIMESTAMP':i
:lexeme ~ <TIMEZONE_HOUR> priority => 1
<TIMEZONE_HOUR> ~ 'TIMEZONE_HOUR':i
:lexeme ~ <TIMEZONE_MINUTE> priority => 1
<TIMEZONE_MINUTE> ~ 'TIMEZONE_MINUTE':i
:lexeme ~ <TO> priority => 1
<TO> ~ 'TO':i
<TOP_LEVEL_COUNT> ~ 'TOP_LEVEL_COUNT':i
:lexeme ~ <TRAILING> priority => 1
<TRAILING> ~ 'TRAILING':i
<TRANSACTION> ~ 'TRANSACTION':i
<TRANSACTIONS_COMMITTED> ~ 'TRANSACTIONS_COMMITTED':i
<TRANSACTIONS_ROLLED_BACK> ~ 'TRANSACTIONS_ROLLED_BACK':i
<TRANSACTION_ACTIVE> ~ 'TRANSACTION_ACTIVE':i
<TRANSFORM> ~ 'TRANSFORM':i
<TRANSFORMS> ~ 'TRANSFORMS':i
<TRANSLATE> ~ 'TRANSLATE':i
:lexeme ~ <TRANSLATION> priority => 1
<TRANSLATION> ~ 'TRANSLATION':i
:lexeme ~ <TREAT> priority => 1
<TREAT> ~ 'TREAT':i
:lexeme ~ <TRIGGER> priority => 1
<TRIGGER> ~ 'TRIGGER':i
<TRIGGER_CATALOG> ~ 'TRIGGER_CATALOG':i
<TRIGGER_NAME> ~ 'TRIGGER_NAME':i
<TRIGGER_SCHEMA> ~ 'TRIGGER_SCHEMA':i
<TRIM> ~ 'TRIM':i
:lexeme ~ <TRUE> priority => 1
<TRUE> ~ 'TRUE':i
<TYPE> ~ 'TYPE':i
:lexeme ~ <UESCAPE> priority => 1
<UESCAPE> ~ 'UESCAPE':i
<UNBOUNDED> ~ 'UNBOUNDED':i
<UNCOMMITTED> ~ 'UNCOMMITTED':i
<UNDER> ~ 'UNDER':i
:lexeme ~ <UNION> priority => 1
<UNION> ~ 'UNION':i
:lexeme ~ <UNIQUE> priority => 1
<UNIQUE> ~ 'UNIQUE':i
:lexeme ~ <UNKNOWN> priority => 1
<UNKNOWN> ~ 'UNKNOWN':i
<UNNAMED> ~ 'UNNAMED':i
:lexeme ~ <UNNEST> priority => 1
<UNNEST> ~ 'UNNEST':i
:lexeme ~ <UPDATE> priority => 1
<UPDATE> ~ 'UPDATE':i
:lexeme ~ <UPPER> priority => 1
<UPPER> ~ 'UPPER':i
<USAGE> ~ 'USAGE':i
:lexeme ~ <USER> priority => 1
<USER> ~ 'USER':i
<USER_DEFINED_TYPE_CATALOG> ~ 'USER_DEFINED_TYPE_CATALOG':i
<USER_DEFINED_TYPE_CODE> ~ 'USER_DEFINED_TYPE_CODE':i
<USER_DEFINED_TYPE_NAME> ~ 'USER_DEFINED_TYPE_NAME':i
<USER_DEFINED_TYPE_SCHEMA> ~ 'USER_DEFINED_TYPE_SCHEMA':i
:lexeme ~ <USING> priority => 1
<USING> ~ 'USING':i
<V> ~ 'V':i
:lexeme ~ <VALUE> priority => 1
<VALUE> ~ 'VALUE':i
:lexeme ~ <VALUES> priority => 1
<VALUES> ~ 'VALUES':i
:lexeme ~ <VARCHAR> priority => 1
<VARCHAR> ~ 'VARCHAR':i
:lexeme ~ <VARYING> priority => 1
<VARYING> ~ 'VARYING':i
:lexeme ~ <VAR_POP> priority => 1
<VAR_POP> ~ 'VAR_POP':i
:lexeme ~ <VAR_SAMP> priority => 1
<VAR_SAMP> ~ 'VAR_SAMP':i
<VIEW> ~ 'VIEW':i
:lexeme ~ <WHEN> priority => 1
<WHEN> ~ 'WHEN':i
:lexeme ~ <WHENEVER> priority => 1
<WHENEVER> ~ 'WHENEVER':i
:lexeme ~ <WHERE> priority => 1
<WHERE> ~ 'WHERE':i
:lexeme ~ <WIDTH_BUCKET> priority => 1
<WIDTH_BUCKET> ~ 'WIDTH_BUCKET':i
:lexeme ~ <WINDOW> priority => 1
<WINDOW> ~ 'WINDOW':i
:lexeme ~ <WITH> priority => 1
<WITH> ~ 'WITH':i
:lexeme ~ <WITHIN> priority => 1
<WITHIN> ~ 'WITHIN':i
:lexeme ~ <WITHOUT> priority => 1
<WITHOUT> ~ 'WITHOUT':i
<WORK> ~ 'WORK':i
<WRITE> ~ 'WRITE':i
<X> ~ 'X':i
:lexeme ~ <YEAR> priority => 1
<YEAR> ~ 'YEAR':i
<ZONE> ~ 'ZONE':i
<_> ~ '_':i
<a> ~ 'a'
<auto> ~ 'auto'
<b> ~ 'b'
<c> ~ 'c'
<char> ~ 'char'
<const> ~ 'const'
<d> ~ 'd'
<double> ~ 'double'
<e> ~ 'e'
<extern> ~ 'extern'
<f> ~ 'f'
<float> ~ 'float'
<long> ~ 'long'
<short> ~ 'short'
<static> ~ 'static'
<unsigned> ~ 'unsigned'
<volatile> ~ 'volatile'

_WS ~ [\s]+
<space any L0> ~ _WS
<Discard_L0> ~ <space any L0>

_COMMENT_EVERYYHERE_START ~ '--'
_COMMENT_EVERYYHERE_END ~ [^\n]*
_COMMENT ~ _COMMENT_EVERYYHERE_START _COMMENT_EVERYYHERE_END
<SQL style comment L0> ~ _COMMENT
<Discard_L0> ~ <SQL style comment L0>

############################################################################
# Discard of a C comment, c.f. https://gist.github.com/jeffreykegler/5015057
############################################################################
<C style comment L0> ~ '/*' <comment interior> '*/'
<comment interior> ~
    <optional non stars>
    <optional star prefixed segments>
    <optional pre final stars>
<optional non stars> ~ [^*]*
<optional star prefixed segments> ~ <star prefixed segment>*
<star prefixed segment> ~ <stars> [^/*] <optional star free text>
<stars> ~ [*]+
<optional star free text> ~ [^*]*
<optional pre final stars> ~ [*]*
<Discard_L0> ~ <C style comment L0>

<discard> ~ <Discard_L0>
:discard ~ <discard>

