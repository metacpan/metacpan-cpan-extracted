=head1 NAME

GOBO::Labeled

=head1 SYNOPSIS

=head1 DESCRIPTION

A role for any kind of entity that can have a human-readable label
attached: both primary label and alternate labels (GOBO::Synonym)

For genes the primary label is a symbol. For GOBO::TermNode objects
(units in an ontology) it is the class name

=head2 TBD

Is this over-abstraction? This could be simply mixed in with Node

=cut

package GOBO::Labeled;
use Moose::Role;
use GOBO::Synonym;

has label => (is => 'rw', isa => 'Str'); # TODO -- delegate to primary synonym?
has description => (is => 'rw', isa => 'Str');
has synonyms => ( is=>'rw', isa=>'ArrayRef[GOBO::Synonym]');

sub add_synonyms {
    my $self = shift;
    if (!$self->synonyms) {
        $self->synonyms([]);
    }
    push(@{$self->synonyms},
         map { ref($_) ? $_ : new GOBO::Synonym(label=>$_) } @_);
    return;
}

sub add_synonym {
    my $self = shift;
    $self->add_synonyms(@_);
}

1;

