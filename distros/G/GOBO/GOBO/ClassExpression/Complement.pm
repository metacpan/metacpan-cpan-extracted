package GOBO::ClassExpression::Complement;
use Moose;
use strict;
extends 'GOBO::ClassExpression::BooleanExpression';

sub operator { ' NOT ' }
sub operator_symbol { '-' }

=head1 NAME

GOBO::ClassExpression::Complement

=head1 SYNOPSIS

=head1 DESCRIPTION

An GOBO::ClassExpression::BooleanExpression in which the set operator is one of complement.

=head2 OWL Mapping

equivalent to complementOf

=cut

1; 
