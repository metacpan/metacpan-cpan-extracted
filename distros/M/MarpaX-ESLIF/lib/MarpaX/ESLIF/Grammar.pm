use strict;
use warnings FATAL => 'all';

package MarpaX::ESLIF::Grammar;

# ABSTRACT: MarpaX::ESLIF's grammar

our $AUTHORITY = 'cpan:JDDPAUSE'; # AUTHORITY

our $VERSION = '3.0.14'; # VERSION


#
# Tiny wrapper on MarpaX::ESLIF::Grammar->new, that is using the instance as void *.
# Could have been writen in the XS itself, but I feel it is more comprehensible like
# this.
#
sub new {
    my $class = shift;
    my $eslif = shift;

    my $self = $class->_new($eslif->_getInstance, @_);
    return $self
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MarpaX::ESLIF::Grammar - MarpaX::ESLIF's grammar

=head1 VERSION

version 3.0.14

=head1 SYNOPSIS

  use MarpaX::ESLIF;

  my $eslif = MarpaX::ESLIF->new();
  my $data = do { local $/; <DATA> };
  my $eslifGrammar = MarpaX::ESLIF::Grammar->new($eslif, $data);

  __DATA__
  #
  # This is an example of a calculator grammar
  #
  :start   ::= Expression
  :default ::=             action        => do_op
                           symbol-action => do_symbol
                           free-action   => do_free     # Supported but useless
  :desc    ::= 'Calculator'
  :discard ::= whitespaces event  => discard_whitespaces$
  :discard ::= comment     event  => discard_comment$

  event ^Number = predicted Number
  event Number$ = completed Number
  Number   ::= NUMBER   action => ::shift

  event Expression$ = completed Expression
  event ^Expression = predicted Expression
  Expression ::=
      Number                                           action => do_int
      | '(' Expression ')'              assoc => group action => ::copy[1]
     ||     Expression '**' Expression  assoc => right
     ||     Expression  '*' Expression
      |     Expression  '/' Expression
     ||     Expression  '+' Expression
      |     Expression  '-' Expression

  whitespaces ::= WHITESPACES
  comment ::= /(?:(?:(?:\/\/)(?:[^\n]*)(?:\n|\z))|(?:(?:\/\*)(?:(?:[^\*]+|\*(?!\/))*)(?:\*\/)))/u

  :lexeme ::= NUMBER pause => before event => ^NUMBER
  :lexeme ::= NUMBER pause => after  event => NUMBER$

  :desc      ~ 'Calculator Tokens'
  NUMBER     ~ /[\d]+/   name => 'NUMBER Lexeme'
  WHITESPACES ~ [\s]+    name => 'WHITESPACES Lexeme'

As many grammars as wanted can be created using the same MarpaX::ESLIF parent. After creating a MarpaX::ESLIF::Grammar instance, the user can use the C<parse()> method to have an immediate parse value, or create a L<MarpaX::ESLIF::Recognizer> instance to control the parse.

=head1 DESCRIPTION

MarpaX::ESLIF::Grammar is the second step after getting a MarpaX::ESLIF instance.

=head1 METHODS

=head2 MarpaX::ESLIF::Grammar->new($eslif, $grammar, $encoding)

   my $eslifGrammar = MarpaX::ESLIF::Grammar->new($eslif, $data);

Returns a grammar instance, noted C<$eslifGrammar> later. Parameters are:

=over

=item C<$eslif>

MarpaX::ESLIF object instance. Required.

=item C<$grammar>

A scalar containing the grammar. Required.

=item C<$encoding>

A scalar containing the grammar encoding. Optional.

Encoding will always be guessed if not given.

=back

=head2 $eslifGrammar->ngrammar()

  printf "Number of sub-grammars: %d\n", $eslifGrammar->ngrammar;

Returns the number of sub-grammars.

A grammar can have multiple I<sub-grammars>, identified by a level. Internally this is a I<sparse> array of grammars, and it is legal that a level is not defined.

=head2 $eslifGrammar->currentLevel()

  printf "Current indice: %d\n", $eslifGrammar->currentLevel;

Returns the current level, which is always the first indice that have a defined sub-grammar.

=head2 $eslifGrammar->currentDescription()

  printf "Current description: %s\n", $eslifGrammar->currentDescription;

Returns the description of the current level, with the same encoding as found in the grammar. This correspong to the C<:desc> meta-symbol in a grammar.

=head2 $eslifGrammar->descriptionByLevel($level)

  printf "Level 1 description: %s\n", $eslifGrammar->descriptionByLevel(1);

Returns the description of the grammar at indice C<$level>, with the same encoding as found in the grammar.

=head2 $eslifGrammar->currentRuleIds

  printf "Current Rule Ids: %s\n", join(' ', @{$eslifGrammar->currentRuleIds});

Returns the list of rule identifiers of the current grammar, as a reference to an array of integers.

I<Rule identifiers are integers that uniquely identify a rule>.

=head2 $eslifGrammar->ruleIdsByLevel($level)

  printf "Level 1 Rule Ids: %s\n", join(' ', @{$eslifGrammar->ruleIdsByLevel(1)});

Returns the list of rule identifiers at indice C<$level>, as a reference to an array of integers.

=head2 $eslifGrammar->currentSymbolIds

  printf "Current Symbol Ids: %s\n", join(' ', @{$eslifGrammar->currentSymbolIds});

Returns the list of symbol identifiers at current level, as a reference to an array of integers.

=head2 $eslifGrammar->symbolIdsByLevel($level)

  printf "Level 1 Symbol Ids: %s\n", join(' ', @{$eslifGrammar->symbolIdsByLevel(1)});

Returns the list of symbol identifiers at indice C<$level>, as a reference to an array of integers.

=head2 $eslifGrammar->currentProperties

  use Data::Dumper; printf "Current Properties: %s\n", Dumper($eslifGrammar->currentProperties);

Returns the current grammar properties as an instance of <MarpaX::ESLIF::Grammar::Properties>.

=head2 $eslifGrammar->propertiesByLevel($level)

  use Data::Dumper; printf "Properties at level %d: %s\n", $level, Dumper($eslifGrammar->propertiesByLevel($level));

Returns the grammar properties at level C<$level> as an instance of <MarpaX::ESLIF::Grammar::Properties>.

=head2 $eslifGrammar->currentRuleProperties($ruleId)

  use Data::Dumper; printf "Current Rule Properties: %s\n", Dumper($eslifGrammar->currentRuleProperties($ruleId));

Returns the rule number C<$ruleId> properties as an instance of C<MarpaX::ESLIF::Grammar::Rule::Properties>.

=head2 $eslifGrammar->rulePropertiesByLevel($level, $ruleId)

  use Data::Dumper; printf "Rule Properties at level %d: %s\n", $level, Dumper($eslifGrammar->currentRuleProperties($ruleId));

Returns the rule number C<$ruleId> properties at grammar level C<$level> as an instance of C<MarpaX::ESLIF::Grammar::Rule::Properties>.

=head2 $eslifGrammar->currentSymbolProperties($symbolId)

  use Data::Dumper; printf "Current Symbol Properties: %s\n", Dumper($eslifGrammar->currentSymbolProperties($symbolId));

Returns the symbol number C<$symbolId> properties as an instance of C<MarpaX::ESLIF::Grammar::Symbol::Properties>.

=head2 $eslifGrammar->symbolPropertiesByLevel($level, $symbolId)

  use Data::Dumper; printf "Symbol Properties at level %d: %s\n", $level, Dumper($eslifGrammar->currentSymbolProperties($symbolId));

Returns the symbol number C<$symbolId> properties at grammar level C<$level> as an instance of C<MarpaX::ESLIF::Grammar::Symbol::Properties>.

=head2 $eslifGrammar->ruleDisplay($ruleId)

  printf "Rules display:\n\t%s\n", join("\n\t", map { $eslifGrammar->ruleDisplay($_) } @{$eslifGrammar->currentRuleIds});

Returns the name of a rule identified by its rule ID C<$ruleId>.

=head2 $eslifGrammar->symbolDisplay($symbolId)

  printf "Symbols display:\n\t%s\n", join("\n\t", map { $eslifGrammar->symbolDisplay($_) } @{$eslifGrammar->currentSymbolIds});

Returns the name of a rule identified by its rule ID C<$ruleId>.

=head2 $eslifGrammar->ruleShow($ruleId)

  printf "Rules shows:\n\t%s\n", join("\n\t", map { $eslifGrammar->ruleShow($_) } @{$eslifGrammar->currentRuleIds});

Returns the description of a rule identified by its rule ID C<$ruleId>.

=head2 $eslifGrammar->ruleDisplayByLevel($level, $ruleId)

  printf "Level 1 Rule display:\n\t%s\n", join("\n\t", map { $eslifGrammar->ruleDisplayByLevel(1, $_) } @{$eslifGrammar->ruleIdsByLevel(1)});

Returns the name of a rule at a specificed indice C<$level> identified by its rule ID C<$ruleId>. This correspond to the C<name> adverb, if present, else a default naming applies.

=head2 $eslifGrammar->symbolDisplayByLevel($level, $symbolId)

  printf "Level 1 Symbol display:\n\t%s\n", join("\n\t", map { $eslifGrammar->symbolDisplayByLevel(1, $_) } @{$eslifGrammar->symbolIdsByLevel(1)});

Returns the name of a symbol at a specificed indice C<$level> identified by its symbol ID C<$symbolId>. This correspond to the C<name> adverb, if present, else a default naming applies.

=head2 $eslifGrammar->ruleShowByLevel($level, $ruleId)

  printf "Level 1 Rules shows:\n\t%s\n", join("\n\t", map { $eslifGrammar->ruleShowByLevel(1, $_) } @{$eslifGrammar->ruleIdsByLevel(1)});

Returns the description of a rule at a specified indice C<$level>, identified by its rule ID C<$ruleId>.

=head2 $eslifGrammar->show()

  printf "Description of current grammar: %s\n", $eslifGrammar->show();

Returns the description of current grammar.

=head2 $eslifGrammar->showByLevel($level)

  printf "Level 1 grammar description: %s\n", $eslifGrammar->showByLevel(1);

Returns the description of the grammar at indice C<$level>.

=head2 $eslifGrammar->parse($recognizerInterface, $valueInterface)

  my $recognizerInterface = MyRecognizer->new();
  my $valueInterface      = MyValue->new();
  if ($eslifGrammar->parse($recognizerInterface, $valueInterface)) {
    printf "Parse result: %s\n", $valueInterface->getResult;
  }

Short version of input validation and valuation, that will never give back control to the user until the end or a failure. No event is possible when using this method. If this method returns true, then it is guaranteed that the result is in C<$valueInterface->getResult()>.

Please refer to L<MarpaX::ESLIF::Recognizer::Interface> and L<MarpaX::ESLIF::Value::Interface> for the C<$recognizerInterface> and C<$valueInterface> required parameters.

=head1 SEE ALSO

L<MarpaX::ESLIF::Recognizer::Interface>, L<MarpaX::ESLIF::Recognizer::Interface>, L<MarpaX::ESLIF::Value::Interface>, L<MarpaX::ESLIF::Grammar::Properties>, L<MarpaX::ESLIF::Grammar::Rule::Properties>, L<MarpaX::ESLIF::Grammar::Symbol::Properties>

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
