package Meta::Grapher::Moose::Renderer::Test;
use namespace::autoclean;
use Moose;

with 'Meta::Grapher::Moose::Role::Renderer';

has recorded_nodes_added_to_graph => (
    is      => 'ro',
    isa     => 'ArrayRef[HashRef]',
    default => sub { [] },
);

sub nodes_for_comparison {
    my $self = shift;
    return [
        sort { ( $a->{label} cmp $b->{label} ) || ( $a->{id} cmp $b->{id} ) }
            @{ $self->recorded_nodes_added_to_graph }
    ];
}

has recorded_edges_added_to_graph => (
    is      => 'ro',
    isa     => 'ArrayRef[HashRef]',
    default => sub { [] },
);

sub edges_for_comparison {
    my $self = shift;
    return [ sort { "$a->{from} - $a->{to}" cmp "$b->{from} - $b->{to}" }
            @{ $self->recorded_edges_added_to_graph } ];
}

sub add_package {
    my $self = shift;
    my %p    = @_;

    push @{ $self->recorded_nodes_added_to_graph }, \%p;

    return;
}

sub add_edge {
    my $self = shift;
    my %p    = @_;

    push @{ $self->recorded_edges_added_to_graph }, \%p;

    return;
}

sub render {
    return;
}

__PACKAGE__->meta->make_immutable;

1;
