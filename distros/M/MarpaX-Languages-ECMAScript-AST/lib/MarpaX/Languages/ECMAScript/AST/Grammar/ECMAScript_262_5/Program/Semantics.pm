use strict;
use warnings FATAL => 'all';

package MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::Program::Semantics;
use MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::Lexical::StringLiteral;

our $StringLiteral = MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::Lexical::StringLiteral->new();
our $StringLiteralImpl = MarpaX::Languages::ECMAScript::AST::Impl->new($StringLiteral->grammar_option(), $StringLiteral->recce_option());

# ABSTRACT: ECMAScript 262, Edition 5, lexical expressions grammar actions

our $VERSION = '0.020'; # VERSION

use constant AST => 'MarpaX::Languages::ECMAScript::AST';


sub new {
    my $class = shift;
    my $self = {};
    bless($self, $class);
    return $self;
}


sub valuesAndRuleId {
  my $self = shift;

  #
  # Note: we do not include Marpa explicitely: this is done in one unique
  # place, i.e. Impl.pm.
  #
  my $ruleId = $Marpa::R2::Context::rule;
  #
  # Note: $Marpa::R2::Context::grammar->rule($ruleId) returns an array
  #
  if (! defined($self->{ruleId2Lhs}->[$ruleId])) {
    my ($lhs, @rhs) = $Marpa::R2::Context::grammar->rule($ruleId);
    $self->{ruleId2Lhs}->[$ruleId] = $lhs;
    $self->{ruleId2Rhs}->[$ruleId] = \@rhs;;
  }
  return {values => [ @_ ], ruleId => $ruleId, lhs => $self->{ruleId2Lhs}->[$ruleId], rhs => $self->{ruleId2Rhs}->[$ruleId]};
}


sub StringLiteral {
    my ($self, $lexemeActionValuep) = @_;

    #
    # StringLiteral is already in the good lexeme value format: [start,length,value]
    #
    # We just re-evaluate the value. Per def there is no need to eval, the lexeme
    # got matched.
    #
    $lexemeActionValuep->[2] = $StringLiteral->parse($lexemeActionValuep->[2], $StringLiteralImpl)->value($StringLiteralImpl);

    return $lexemeActionValuep;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::Program::Semantics - ECMAScript 262, Edition 5, lexical expressions grammar actions

=head1 VERSION

version 0.020

=head1 DESCRIPTION

This modules give the actions associated to ECMAScript_262_5 lexical expressions grammar.

=head1 SUBROUTINES/METHODS

=head2 new($class)

Instantiate a new object.

=head2 valuesAndRuleId($self, @values)

Default G1 action: a hash with the following keys:

=over

=item ruleId

G1 rule Id

=item values

Reference to an array containing the values

=back

=head2 StringLiteral($self, $lexemeActionValuep)

StringLiteral action.

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
