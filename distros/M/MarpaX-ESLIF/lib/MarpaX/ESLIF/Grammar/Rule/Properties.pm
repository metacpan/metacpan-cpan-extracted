use strict;
use warnings FATAL => 'all';

package MarpaX::ESLIF::Grammar::Rule::Properties;

# ABSTRACT: ESLIF Grammar Rule Properties

our $AUTHORITY = 'cpan:JDDPAUSE'; # AUTHORITY

our $VERSION = '3.0.14'; # VERSION


#
# old-style perl - getters only in java style
#
sub new {
    my ($pkg, %args) = @_;

    my $self = {
        'id'                       => $args{id},
        'description'              => $args{description},
        'show'                     => $args{show},
        'lhsId'                    => $args{lhsId},
        'separatorId'              => $args{separatorId},
        'rhsIds'                   => $args{rhsIds},
        'skipIndices'              => $args{skipIndices},
        'exceptionId'              => $args{exceptionId},
        'action'                   => $args{action},
        'discardEvent'             => $args{discardEvent},
        'discardEventInitialState' => $args{discardEventInitialState},
        'rank'                     => $args{rank},
        'nullRanksHigh'            => $args{nullRanksHigh},
        'sequence'                 => $args{sequence},
        'proper'                   => $args{proper},
        'minimum'                  => $args{minimum},
        'internal'                 => $args{internal},
        'propertyBitSet'           => $args{propertyBitSet},
        'hideseparator'            => $args{hideseparator}
    };

    return bless $self, $pkg
}


sub getId {
    my ($self) = @_;

    return $self->{id}
}


sub getDescription {
    my ($self) = @_;

    return $self->{description}
}


sub getShow {
    my ($self) = @_;

    return $self->{show}
}


sub getLhsId {
    my ($self) = @_;

    return $self->{lhsId}
}


sub getSeparatorId {
    my ($self) = @_;

    return $self->{separatorId}
}


sub getRhsIds {
    my ($self) = @_;

    return $self->{rhsIds}
}


sub getSkipIndices {
    my ($self) = @_;

    return $self->{skipIndices}
}


sub getExceptionId {
    my ($self) = @_;

    return $self->{exceptionId}
}


sub getAction {
    my ($self) = @_;

    return $self->{action}
}


sub getDiscardEvent {
    my ($self) = @_;

    return $self->{discardEvent}
}


sub isDiscardEventInitialState {
    my ($self) = @_;

    return $self->{discardEventInitialState}
}


sub getDiscardEventInitialState {
    goto &isDiscardEventInitialState
}


sub getRank {
    my ($self) = @_;

    return $self->{rank}
}


sub isNullRanksHigh {
    my ($self) = @_;

    return $self->{nullRanksHigh}
}


sub getNullRanksHigh {
    goto &isNullRanksHigh
}


sub isSequence {
    my ($self) = @_;

    return $self->{sequence}
}


sub getSequence {
    goto &isSequence
}


sub isProper {
    my ($self) = @_;

    return $self->{proper}
}


sub getProper {
    goto &isProper
}


sub getMinimum {
    my ($self) = @_;

    return $self->{minimum}
}


sub isInternal {
    my ($self) = @_;

    return $self->{internal}
}


sub getInternal {
    goto &isInternal
}


sub getPropertyBitSet {
    my ($self) = @_;

    return $self->{propertyBitSet}
}


sub isHideseparator {
    my ($self) = @_;

    return $self->{hideseparator}
}


sub getHideseparator {
    goto &isHideseparator
}

__END__

=pod

=encoding UTF-8

=head1 NAME

MarpaX::ESLIF::Grammar::Rule::Properties - ESLIF Grammar Rule Properties

=head1 VERSION

version 3.0.14

=head1 SYNOPSIS

  use MarpaX::ESLIF;

  my $eslif = MarpaX::ESLIF->new();
  my $data = do { local $/; <DATA> };
  my $eslifGrammar = MarpaX::ESLIF::Grammar->new($eslif, $data);
  my $ruleProperties = $eslifGrammar->ruleProperties(0);
  my $rulePropertiesByLevel = $eslifGrammar->rulePropertiesByLevel(0, 0);

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

=head2 $self->getId

Returns Rule's id (always >= 0)

=head2 $self->getDescription

Returns Rule's description (auto-generated if there is not "name" keyword in the grammar)

=head2 $self->getShow

Returns Rule's show

=head2 $self->getLhsId

Returns Rule's LHS symbol id (always >= 0)

=head2 $self->getSeparatorId

Returns Rule's separator symbol id (< 0 if the rule is not a sequence)

=head2 $self->getRhsIds

Returns Rule's RHS ids (none for a null rule or a sequence)

=head2 $self->getSkipIndices

Returns Rule's RHS skip indices (none for a null rule)

=head2 $self->getExceptionId

Returns Rule's exception id (< 0 if there is no exception)

=head2 $self->getAction

Returns Rule's action (null if none)

=head2 $self->getDiscardEvent

Returns Rule's discard event name (only when LHS is ":discard" and "event" keyword is present)

=head2 $self->isDiscardEventInitialState

Returns Rule's discard initial state is on ?

=head2 $self->getDiscardEventInitialState

Returns Rule's discard initial state is on ?

Alias to isDiscardEventInitialState()

=head2 $self->getRank

Returns Rule's rank (defaults to 0)

=head2 $self->isNullRanksHigh

Returns Rule rank high when it is a nullable ?

=head2 $self->getNullRanksHigh

Returns Rule rank high when it is a nullable ?

Alias to isNullRanksHigh()

=head2 $self->isSequence

Returns Rule is a sequence ?

=head2 $self->getSequence

Returns Rule is a sequence ?

Alias to isSequence()

=head2 $self->isProper

Returns Rule's separation is proper ? (meaningful only when it is sequence)

=head2 $self->getProper

Returns Rule's separation is proper ? (meaningful only when it is sequence)

Alias to isProper()

=head2 $self->getMinimum

Returns Rule's minimum number of RHS (meaningful only when rule is a sequence)

=head2 $self->isInternal

Returns Rule is internal ? (possible only when there is the loosen operator "||")

=head2 $self->getInternal

Returns Rule is internal ? (possible only when there is the loosen operator "||")

Alias to isInternal()

=head2 $self->getPropertyBitSet

Returns Rule's low-level property bits (combination of MarpaX::ESLIF::Grammar::Rule::PropertyBitSet values)

=head2 $self->isHideseparator

Returns Hide separator in action callback ? (meaningful only when rule is a sequence)

=head2 $self->getHideseparator

Returns Hide separator in action callback ? (meaningful only when rule is a sequence)

Alias to isHideseparator()

=head1 DESCRIPTION

ESLIF Grammar Rule Properties.

Calls to grammar's currentRuleProperties() or rulePropertiesByLevel() methods outputs an instance of this class.

=head1 SEE ALSO

L<MarpaX::ESLIF::Rule::PropertyBitSet>

1;

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
