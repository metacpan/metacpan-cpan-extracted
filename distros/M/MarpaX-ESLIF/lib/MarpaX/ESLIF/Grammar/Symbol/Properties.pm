use strict;
use warnings FATAL => 'all';

package MarpaX::ESLIF::Grammar::Symbol::Properties;

# ABSTRACT: ESLIF Grammar Symbol Properties

our $AUTHORITY = 'cpan:JDDPAUSE'; # AUTHORITY

our $VERSION = '3.0.14'; # VERSION


#
# old-style perl - getters only in java style
#
sub new {
    my ($pkg, %args) = @_;

    my $self = {
        'type'                       => $args{type},
        'start'                      => $args{start},
        'discard'                    => $args{discard},
        'discardRhs'                 => $args{discardRhs},
        'lhs'                        => $args{lhs},
        'top'                        => $args{top},
        'id'                         => $args{id},
        'description'                => $args{description},
        'eventBefore'                => $args{eventBefore},
        'eventBeforeInitialState'    => $args{eventBeforeInitialState},
        'eventAfter'                 => $args{eventAfter},
        'eventAfterInitialState'     => $args{eventAfterInitialState},
        'eventPredicted'             => $args{eventPredicted},
        'eventPredictedInitialState' => $args{eventPredictedInitialState},
        'eventNulled'                => $args{eventNulled},
        'eventNulledInitialState'    => $args{eventNulledInitialState},
        'eventCompleted'             => $args{eventCompleted},
        'eventCompletedInitialState' => $args{eventCompletedInitialState},
        'discardEvent'               => $args{discardEvent},
        'discardEventInitialState'   => $args{discardEventInitialState},
        'lookupResolvedLeveli'       => $args{lookupResolvedLeveli},
        'priority'                   => $args{priority},
        'nullableAction'             => $args{nullableAction},
        'propertyBitSet'             => $args{propertyBitSet},
        'eventBitSet'                => $args{eventBitSet},
        'symbolAction'               => $args{symbolAction},
        'ifAction'                   => $args{ifAction}
    };

    return bless $self, $pkg
}


sub getType {
    my ($self) = @_;

    return $self->{type}
}


sub isStart {
    my ($self) = @_;

    return $self->{start}
}


sub getStart {
    goto &isStart
}


sub isDiscard {
    my ($self) = @_;

    return $self->{discard}
}


sub getDiscard {
    goto &isDiscard
}


sub isDiscardRhs {
    my ($self) = @_;

    return $self->{discardRhs}
}


sub getDiscardRhs {
    goto &isDiscardRhs
}


sub isLhs {
    my ($self) = @_;

    return $self->{lhs}
}


sub getLhs {
    goto &isLhs
}


sub isTop {
    my ($self) = @_;

    return $self->{top}
}


sub getTop {
    goto &isTop
}


sub getId {
    my ($self) = @_;

    return $self->{id}
}


sub getDescription {
    my ($self) = @_;

    return $self->{description}
}


sub getEventBefore {
    my ($self) = @_;

    return $self->{eventBefore}
}


sub isEventBeforeInitialState {
    my ($self) = @_;

    return $self->{eventBeforeInitialState}
}


sub getEventBeforeInitialState {
    goto &isEventBeforeInitialState
}


sub getEventAfter {
    my ($self) = @_;

    return $self->{eventAfter}
}


sub isEventAfterInitialState {
    my ($self) = @_;

    return $self->{eventAfterInitialState}
}


sub getEventAfterInitialState {
    goto &isEventAfterInitialState
}


sub getEventPredicted {
    my ($self) = @_;

    return $self->{eventPredicted}
}


sub isEventPredictedInitialState {
    my ($self) = @_;

    return $self->{eventPredictedInitialState}
}


sub getEventPredictedInitialState {
    goto &isEventPredictedInitialState
}


sub getEventNulled {
    my ($self) = @_;

    return $self->{eventNulled}
}


sub isEventNulledInitialState {
    my ($self) = @_;

    return $self->{eventNulledInitialState}
}


sub getEventNulledInitialState {
    goto &isEventNulledInitialState
}


sub getEventCompleted {
    my ($self) = @_;

    return $self->{eventCompleted}
}


sub isEventCompletedInitialState {
    my ($self) = @_;

    return $self->{eventCompletedInitialState}
}


sub getEventCompletedInitialState {
    goto &isEventCompletedInitialState
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


sub getLookupResolvedLeveli {
    my ($self) = @_;

    return $self->{lookupResolvedLeveli}
}


sub getPriority {
    my ($self) = @_;

    return $self->{priority}
}


sub getNullableAction {
    my ($self) = @_;

    return $self->{nullableAction}
}


sub getPropertyBitSet {
    my ($self) = @_;

    return $self->{propertyBitSet}
}


sub getEventBitSet {
    my ($self) = @_;

    return $self->{eventBitSet}
}


sub getSymbolAction {
    my ($self) = @_;

    return $self->{symbolAction}
}


sub getIfAction {
    my ($self) = @_;

    return $self->{ifAction}
}

__END__

=pod

=encoding UTF-8

=head1 NAME

MarpaX::ESLIF::Grammar::Symbol::Properties - ESLIF Grammar Symbol Properties

=head1 VERSION

version 3.0.14

=head1 SYNOPSIS

  use MarpaX::ESLIF;

  my $eslif = MarpaX::ESLIF->new();
  my $data = do { local $/; <DATA> };
  my $eslifGrammar = MarpaX::ESLIF::Grammar->new($eslif, $data);
  my $symbolProperties = $eslifGrammar->symbolProperties(0);
  my $symbolPropertiesByLevel = $eslifGrammar->symbolPropertiesByLevel(0, 0);

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

=head2 $self->getType

Returns the type, c.f. L<MarpaX::ESLIF::Symbol::Type>

=head2 $self->isStart

Returns if this is the start symbol

=head2 $self->getStart

Returns if this is the start symbol

Alias to isStart()

=head2 $self->isDiscard

Returns if this is the discard symbol

=head2 $self->getDiscard

Returns if this is the discard symbol

Alias to isDiscard()

=head2 $self->isDiscardRhs

Returns if this is a RHS of a discard rule

=head2 $self->isDiscardRhs

Returns if this is a RHS of a discard rule

Alias to isDiscardRhs()

=head2 $self->isLhs

Returns if this is an LHS

=head2 $self->getLhs

Returns if this is an LHS

Alias to isLhs()

=head2 $self->isTop

Returns if this is the first symbol of the grammar

=head2 $self->getTop

Returns if this is the first symbol of the grammar

Alias to isTop()

=head2 $self->getId

Returns the id

=head2 $self->getDescription

Returns the description

=head2 $self->getEventBefore

Returns the event before name, null if there is none

=head2 $self->isEventBeforeInitialState

Returns if the event before initial state is on, meaningless if there is no event before

=head2 $self->getEventBeforeInitialState

Returns if the event before initial state is on, meaningless if there is no event before

Alias to isEventBeforeInitialState()

=head2 $self->getEventAfter

Returns the event after name, null if there is none

=head2 $self->isEventAfterInitialState

Returns if the event after initial state is on, meaningless if there is no event after

=head2 $self->getEventAfterInitialState

Returns if the event after initial state is on, meaningless if there is no event after

Alias to isEventAfterInitialState()

=head2 $self->getEventPredicted

Returns the event predicted name, null if there is none

=head2 $self->isEventPredictedInitialState

Returns if the event predicted initial state is on, meaningless if there is no prediction event

=head2 $self->getEventPredictedInitialState

Returns if the event predicted initial state is on, meaningless if there is no prediction event

Alias to isEventPredictedInitialState()

=head2 $self->getEventNulled

Returns the null event name, null if there is none - used internally for ":discard[on]" and ":discard[off]" in particular

=head2 $self->isEventNulledInitialState

Returns the nulled event initial state, meaningless if there is nulled event

=head2 $self->getEventNulledInitialState

Returns the nulled event initial state, meaningless if there is nulled event

Alias isEventNulledInitialState()

=head2 $self->getEventCompleted

Returns the completion event name, null if there is none

=head2 $self->isEventCompletedInitialState

Returns the completion event initial state, meaningless if there is no completion event

=head2 $self->getEventCompletedInitialState

Returns the completion event initial state, meaningless if there is no completion event

Alias to isEventCompletedInitialState()

=head2 $self->getDiscardEvent

Returns the discard event, null if there is none

=head2 $self->isDiscardEventInitialState

Returns the discard event initial state, meaningless if there is no discard event

=head2 $self->isDiscardEventInitialState

Returns the discard event initial state, meaningless if there is no discard event

Alias to isDiscardEventInitialState()

=head2 $self->getLookupResolvedLeveli

Returns the grammar level to which it is resolved, can be different to the grammar used when this is a lexeme

=head2 $self->getPriority

Returns the symbol priority

=head2 $self->getNullableAction

Returns the nullable action, null if there is none

=head2 $self->getPropertyBitSet

Returns the low-level properties (combination of MarpaX::ESLIF::Symbol::PropertyBitSet values)

=head2 $self->getEventBitSet

Returns the low-level events (combination of MarpaX::ESLIF::Symbol::EventBitSet values)

=head2 $self->getSymbolAction

Returns the symbol specific action, null if there is none

=head2 $self->getIfAction

Returns the symbol if action, null if there is none

=head1 DESCRIPTION

ESLIF Grammar Symbol Properties.

Calls to grammar's currentSymbolProperties() or symbolPropertiesByLevel() methods outputs an instance of this class.

=head1 SEE ALSO

L<MarpaX::ESLIF::Symbol::Type>, L<MarpaX::ESLIF::Symbol::PropertyBitSet>, L<MarpaX::ESLIF::Symbol::EventBitSet>

1;

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
