use strict;
use warnings FATAL => 'all';

package MarpaX::ESLIF::Grammar::Properties;

# ABSTRACT: ESLIF Grammar Properties

our $AUTHORITY = 'cpan:JDDPAUSE'; # AUTHORITY

our $VERSION = '3.0.14'; # VERSION


#
# old-style perl - getters only in java style
#


sub new {
    my ($pkg, %args) = @_;
    #
    # This should be called ONLY by the XS, and we know what we do
    #
    return bless { level               => $args{level},
                   maxLevel            => $args{maxLevel},
                   description         => $args{description},
                   latm                => $args{latm},
                   defaultSymbolAction => $args{defaultSymbolAction},
                   defaultRuleAction   => $args{defaultRuleAction},
                   startId             => $args{startId},
                   discardId           => $args{discardId},
                   symbolIds           => $args{symbolIds},
                   ruleIds             => $args{ruleIds}
                   }, $pkg
}

#
# Explicit getters - XS and this file are in sync, fallbacks to undef value if not
#


sub getLevel {
  my ($self) = @_;

  return $self->{level}
}


sub getMaxLevel {
  my ($self) = @_;

  return $self->{maxLevel}
}


sub getDescription {
  my ($self) = @_;

  return $self->{description}
}


sub isLatm {
  my ($self) = @_;

  return $self->{latm}
}


sub getLatm {
  goto &isLatm
}


sub getDefaultSymbolAction {
  my ($self) = @_;

  return $self->{defaultSymbolAction}
}


sub getDefaultRuleAction {
  my ($self) = @_;

  return $self->{defaultRuleAction}
}


sub getStartId {
  my ($self) = @_;

  return $self->{startId}
}


sub getDiscardId {
  my ($self) = @_;

  return $self->{discardId}
}


sub getSymbolIds {
  my ($self) = @_;

  return $self->{symbolIds}
}


sub getRuleIds {
  my ($self) = @_;

  return $self->{ruleIds}
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MarpaX::ESLIF::Grammar::Properties - ESLIF Grammar Properties

=head1 VERSION

version 3.0.14

=head1 SYNOPSIS

  use MarpaX::ESLIF;

  my $eslif = MarpaX::ESLIF->new();
  my $data = do { local $/; <DATA> };
  my $eslifGrammar = MarpaX::ESLIF::Grammar->new($eslif, $data);
  my $grammarProperties = $eslifGrammar->currentProperties;
  my $grammarPropertiesByLevel = $eslifGrammar->propertiesByLevel(0);

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

=head1 DESCRIPTION

ESLIF Grammar Properties.

Calls to grammar's currentProperties() or propertiesByLevel() methods outputs an instance of this class.

=head1 METHODS

=head2 MarpaX::ESLIF::Grammar::Properties->new(%args)

Creation of an ESLIFGrammarProperties instance, noted C<$self> afterwards. C<%args> is a hash that should contain:

=over

=item level

Grammar level

=item maxLevel

Maximum grammar level

=item description

Grammar description

=item latm

Grammar is in LATM (Longest Accepted Token Mode) ?

=item defaultSymbolAction

Grammar default symbol action

=item defaultRuleAction

Grammar default rule action

=item startId

Start symbol Id

=item discardId

Discard symbol Id

=item symbolIds

Symbol Ids (array reference)

=item ruleIds

Rule Ids (array reference)

=back

=head2 $self->getLevel

Returns grammar's level

=head2 $self->getMaxLevel

Returns maximum grammar's level

=head2 $self->getDescription

Returns grammar's description

=head2 $self->isLatm

Returns a boolean that indicates if this grammar is in the LATM (Longest Acceptable Token Mode) or not

=head2 $self->getLatm

Alias to isLatm()

=head2 $self->getDefaultSymbolAction

Returns grammar's default symbol action, never null

=head2 $self->getDefaultRuleAction

Returns grammar's default rule action, can be null

=head2 $self->getStartId

Returns grammar's start symbol id, always >= 0

=head2 $self->getDiscardId

Returns grammar's discard symbol id, < 0 if none.

=head2 $self->getSymbolIds

Returns a reference to a list of symbol identifiers

=head2 $self->getRuleIds

Returns a reference to a list of rule identifiers

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
