package DustyDB::Meta::Attribute;
our $VERSION = '0.06';

use Moose::Role;

use Scalar::Util qw( blessed );

=head1 NAME

DustyDB::Meta::Attribute - Moose meta-class for DustyDB::Record attributes

=head1 VERSION

version 0.06

=head1 DESCRIPTION

For any model class (one that uses L<DustyDB::Object> and does L<DustyDB::Record>), all the attributes will be given this Moose meta-class role. These attributes are used to help with encoding and decoding types that might not be easily stored directly within L<DBM::Deep>.

=head1 ATTRIBUTES

=head2 encode

This is a subroutine used to transform a Perl object into a something else you want to store. Since we use L<DBM::Deep> to store the objects, this can be much more flexible than just a scalar. 

Be careful, though, not to store a hash with a C<class_name> key or very bad things might happen.

This subroutine should expect the decoded value in C<$_> and return whatever value should be stored.

=cut

has encode => (
    is => 'rw',
    isa => 'CodeRef',
    required => 1,
    default => sub { sub { $_ } },
);

=head2 decode

This is a subroutine used to transform the previously encoded and stored "thing" into the object that is stored in the column.

This subroutine should expect the encoded value in C<$_> and return whatever value should be loaded into the model attribute.

=cut

has decode => (
    is => 'rw',
    isa => 'CodeRef',
    required => 1,
    default => sub { sub { $_ } },
);

=head1 METHODS

=head2 perform_encode

This is a helper method to make sure that encoding is performed properly.

=cut

sub perform_encode {
    my ($attr, $value) = @_;

    local $_ = $value;
    return $attr->encode->($value);
}

=head2 perform_decode

This is a helper method to make sure that decoding is performed properly.

=cut

sub perform_decode {
    my ($attr, $value) = @_;

    local $_ = $value;
    return $attr->decode->($value);
}


1;