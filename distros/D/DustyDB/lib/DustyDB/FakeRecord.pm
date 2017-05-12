package DustyDB::FakeRecord;
our $VERSION = '0.06';

use Moose;

=head1 NAME

DustyDB::FakeRecord - helper class for dealing with deferred loading

=head1 VERSION

version 0.06

=head1 DESCRIPTION

Do not use this class yourself. Everything you need to use this is done for you.

This class is used to provide deferred loading of FK objects. Essentially, if you link from one model to another in a stored attribute, this class is used to make sure we we don't load that other class until we need it. This prevents recursion during loads (which is kind of a bug, but this works around this bug too) and prevents us from having to load a whole bunch of records we might not use.

=head1 ATTRIBUTE

=head2 model

This is the model that should be used to retrieve the actual object when it needs to be vivified.

=cut

has model => (
    is => 'rw',
    isa => 'DustyDB::Model',
    required => 1,
);

=head2 class_name

This is the class name of the model that will be vivified.

=cut

has class_name => (
    is => 'rw',
    isa => 'ClassName',
    required => 1,
);

=head2 key

This is the key-value pairs needed to load the object during vivification.

=cut

has key => (
    is => 'rw',
    isa => 'HashRef',
    required => 1,
);

=head1 METHODS

=head2 isa

We implement a custom C<isa> to keep L<Moose> from complaining when we try to store something that isn't the same type as the object we need to store.

=cut

sub isa {
    my ($self, $other_class_name) = @_;

    if (ref $self) {
        return $self->class_name->isa($other_class_name);
    }
    else {
        return $self->SUPER::isa($other_class_name);
    }
}

=head2 vivify

This is used to load the object on demand.

=cut

sub vivify {
    my $self = shift;
    return $self->model->load( %{ $self->key } );
}

1;