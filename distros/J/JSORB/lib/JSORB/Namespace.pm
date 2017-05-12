package JSORB::Namespace;
use Moose;
use MooseX::AttributeHelpers;

use Set::Object 'set';

our $VERSION   = '0.04';
our $AUTHORITY = 'cpan:STEVAN';

extends 'JSORB::Core::Element';

has 'elements' => (
    is      => 'ro',
    isa     => 'ArrayRef[JSORB::Namespace]',
    default => sub { [] },
    trigger => sub {
        my $self = shift;
        $_->_set_parent($self)
            foreach @{ $self->elements };
        $self->_clear_element_map
            if $self->_element_map_is_initialized;
    }
);

has '_element_map' => (
    metaclass => 'Collection::Hash',
    init_arg  => undef,
    is        => 'ro',
    isa       => 'HashRef[JSORB::Namespace]',
    lazy      => 1,
    predicate => '_element_map_is_initialized',
    clearer   => '_clear_element_map',
    default   => sub {
        my $self = shift;
        return +{
            map { $_->name => $_ } @{ $self->elements }
        }
    },
    provides  => {
        'get' => 'get_element_by_name',
    }
);

sub add_element {
    my ($self, $element) = @_;
    (blessed $element && $element->isa('JSORB::Namespace'))
        || confess "Bad element -> $element";
    push @{ $self->elements } => $element;
    $element->_set_parent($self);
    $self->_element_map->{ $element->name } = $element;
}

sub merge_with {
    my ($self, $other) = @_;
    ($self->name eq $other->name)
        || confess "You can only merge items with the same name";

    my %other    = %{ $other->_element_map };
    my @elements = do {
        map {
            $_->merge_with( delete $other{ $_->name } || return $_ )
        } @{ $self->elements }
    }, values %other;

    $self->meta->name->new(
        name     => $self->name,
        elements => \@elements,
        (inner())
    );
}

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

=pod

=head1 NAME

JSORB::Namespace - A JSORB namespace

=head1 DESCRIPTION

A JSORB Namespace is basically a container for storing other 
namespaces and/or interfaces (see L<JSORB::Interface>).

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Stevan Little E<lt>stevan.little@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2010 Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
