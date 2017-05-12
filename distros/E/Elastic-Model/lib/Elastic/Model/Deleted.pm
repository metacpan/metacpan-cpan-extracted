package Elastic::Model::Deleted;
$Elastic::Model::Deleted::VERSION = '0.52';
use Moose;
use strict;
use warnings;
use Carp;
use namespace::autoclean;

#===================================
has 'uid' => (
#===================================
    is       => 'ro',
    isa      => 'Elastic::Model::UID',
    required => 1,
);

#===================================
sub _can_inflate     {0}
sub _inflate_doc     { }
sub has_been_deleted {1}
#===================================

our $AUTOLOAD;

#===================================
sub AUTOLOAD {
#===================================
    my $self = shift;
    my $uid  = $self->uid;
    croak
        sprintf(
        "Object type (%s) with ID (%s) in index (%s) has been deleted",
        $uid->type, $uid->id, $uid->index );
}

__PACKAGE__->meta->make_immutable;

1;

=pod

=encoding UTF-8

=head1 NAME

Elastic::Model::Deleted - A class to represent deleted doc objects which are still in scope

=head1 VERSION

version 0.52

=head1 DESCRIPTION

When an object in scope is deleted, it is reblessed into
Elastic::Model::Deleted, which throws an error if any method other than
those listed below are called.

For instance:

    $user = $domain->get( user => 1 );
    $user->delete;
    print $user->name;
    # throws error

=head1 ATTRIBUTES

=head2 uid

    $uid = $deleted_doc->uid

The original UID of the deleted doc.

=head1 METHODS

=head2 has_been_deleted()

    1 == $deleted->has_been_deleted()

Returns true without checking Elasticsearch. This method is provided
so that it can be called in an L<Elastic::Model::Role::Doc/on_conflict>
handler.

Also see L<Elastic::Model::Role::Doc/has_been_deleted()>.

=head1 AUTHOR

Clinton Gormley <drtech@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Clinton Gormley.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: A class to represent deleted doc objects which are still in scope

