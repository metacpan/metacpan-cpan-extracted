package KiokuX::Model::Role::Annotations::Annotation;
use Moose::Role;

use namespace::clean;

with qw(KiokuX::Model::Role::Annotations::Annotation::API);

has subject => (
    isa => "Str|Object",
	reader => "_subject",
    required => 1,
);

sub subject { shift->_subject } # fucking role attributes

# ex: set sw=4 et:

__PACKAGE__

__END__

=pod

=head1 NAME

KiokuX::Model::Role::Annotations::Annotation - a role for annotation objects

=head1 SYNOPSIS

    package MyAnnotation;
    use Moose;

    with qw(KiokuX::Model::Role::Annotations::Annotation);



    # to create an annotation:
    MyAnnotation->new( subject => $object );

=head1 DESCRIPTION

This role implements the abstract
L<KiokuX::Model::Role::Annotations::Annotation::API> role (which requires just
a C<subject> method to return the key object), using an attribute.

=head1 ATTRIBUTES

=over 4

=item subject

A string or an object.

Required.

=back

