package Fey::Role::SQL::Cloneable;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.43';

use MooseX::Role::Parameterized 1.00;

parameter 'real_class' => ( isa => 'Moose::Meta::Class' );

# Yeah, I could've used MooseX::Clone, but avoiding the meta-API at
# runtime makes this all much faster. Of course, it's probably the
# root of all evil. OTOH, it's encapsulated in a role, so we can
# always replace it with an actual use of MX::Clone easily enough.
role {
    my $p     = shift;
    my %extra = @_;

    my @array_attr;
    my @hash_attr;

    # XXX - hack to allow Fey::Role::SetOperation to get Cloneable
    # applied to the real consuming class.
    my $meta = $p->real_class() ? $p->real_class() : $extra{consumer};

    for my $attr ( grep { $_->has_type_constraint() }
        $meta->get_all_attributes() ) {
        my $type = $attr->type_constraint();

        if ( $type->is_a_type_of('ArrayRef') ) {
            push @array_attr, $attr->name();
        }
        elsif ( $type->is_a_type_of('HashRef') ) {
            push @hash_attr, $attr->name();
        }
    }

    method clone => sub {
        my $self = shift;

        my $clone = bless { %{$self} }, ref $self;

        for my $name (@array_attr) {
            $clone->{$name} = [ @{ $self->{$name} } ];
        }

        for my $name (@hash_attr) {
            $clone->{$name} = { %{ $self->{$name} } };
        }

        return $clone;
    };
};

1;

# ABSTRACT: Adds a just-deep-enough clone() method to SQL objects

__END__

=pod

=head1 NAME

Fey::Role::SQL::Cloneable - Adds a just-deep-enough clone() method to SQL objects

=head1 VERSION

version 0.43

=head1 SYNOPSIS

  use Moose 2.1200;

  with 'Fey::Role::SQL::Cloneable';

=head1 DESCRIPTION

Classes which do this role have a C<clone()> method which does a
just-deep-enough clone of the object.

=head1 METHODS

This role provides the following methods:

=head2 $query->clone()

Returns a new object which is a clone of the original.

=head1 BUGS

See L<Fey> for details on how to report bugs.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 - 2015 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
