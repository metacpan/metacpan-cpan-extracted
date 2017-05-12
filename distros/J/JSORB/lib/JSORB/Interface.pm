package JSORB::Interface;
use Moose;
use MooseX::AttributeHelpers;

use Set::Object 'set';

use JSORB::Procedure;
use JSORB::Method;

our $VERSION   = '0.04';
our $AUTHORITY = 'cpan:STEVAN';

extends 'JSORB::Namespace';

has 'procedures' => (
    is      => 'ro',
    isa     => 'ArrayRef[JSORB::Procedure]',   
    default => sub { [] },
    trigger => sub {
        my $self = shift;
        $_->_set_parent($self)
            foreach @{ $self->procedures };
        $self->_clear_procedure_map
            if $self->_procedure_map_is_initialized;
    }
);

has '_procedure_map' => (
    metaclass => 'Collection::Hash',
    is        => 'ro',
    isa       => 'HashRef[JSORB::Procedure]', 
    lazy      => 1,  
    predicate => '_procedure_map_is_initialized',
    clearer   => '_clear_procedure_map',
    default   => sub {
        my $self = shift;
        return +{
            map { $_->name => $_ } @{ $self->procedures }
        }
    },
    provides  => {
        'get' => 'get_procedure_by_name',
    }
);

sub add_procedure {
    my ($self, $procedure) = @_;
    (blessed $procedure && $procedure->isa('JSORB::Procedure'))
        || confess "Bad procedure -> $procedure";
    push @{ $self->procedures } => $procedure;
    $procedure->_set_parent($self);
    $self->_procedure_map->{ $procedure->name } = $procedure;
}

augment 'merge_with' => sub {
    my ($self, $other) = @_;
    return 'procedures' => [
        set( @{ $self->procedures } )->union(
            set( @{ $other->procedures } )
        )->members
    ];
};

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

=pod

=head1 NAME

JSORB::Interface - A JSORB Interface

=head1 DESCRIPTION

A JSORB Interface is where you place your methods and procedures, 
it is a subclass of JSORB::Namespace.

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
