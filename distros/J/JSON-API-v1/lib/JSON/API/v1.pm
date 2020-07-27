use utf8;

package JSON::API::v1;
our $VERSION = '0.002';
use Moose;
use namespace::autoclean;
use Carp qw(croak);
use List::Util qw(uniq);

our @CARP_NOT = qw(Class::MOP::Method::Wrapped);

# ABSTRACT: A JSON API object according to jsonapi.org v1 specification

has data => (
    is        => 'ro',
    isa       => 'ArrayRef[JSON::API::v1::Resource]',
    traits    => ['Array'],
    lazy      => 1,
    default   => sub { [] },
    reader    => '_data',
    handles   => { add_data => 'push', has_data => 'count',  data => 'uniq' },
);

has is_set => (
    is        => 'ro',
    isa       => 'Bool',
    lazy      => 1,
    default   => 0,
    predicate => 'has_is_set',
    writer    => '_is_set',
);

has errors => (
    is        => 'ro',
    isa       => 'ArrayRef[JSON::API::v1::Error]',
    traits    => ['Array'],
    lazy      => 1,
    default   => sub { [] },
    handles   => { add_error => 'push', has_errors => 'count' },
);

has jsonapi => (
    is        => 'ro',
    isa       => 'Defined',
    predicate => 'has_jsonapi',
);

has included => (
    is        => 'ro',
    isa       => 'ArrayRef[JSON::API::v1::Resource]',
    traits    => ['Array'],
    lazy      => 1,
    default   => sub { [] },
    reader    => '_included',
    handles => {
        add_included => 'push',
        has_included => 'count',
        included     => 'uniq'
    },
);

around BUILDARGS => sub {
    my ($orig, $self, %args) = @_;

    foreach (qw(data included errors)) {
        if (exists $args{$_} && defined $args{$_} && blessed($args{$_})) {
            $args{$_} = [ $args{$_} ];
        }
    }
    if (exists $args{data} && @{ $args{data} } > 1) {
        if (exists $args{is_set} && !$args{is_set}) {
            croak(
                "You are entering a set of data and telling me you are not a"
                . " set, this is incorrect!");
        }
        $args{is_set} = 1 unless exists $args{is_set};
    }
    return $self->$orig(%args);

};

around add_data => sub {
    my ($orig, $self, @data) = @_;

    if ($self->has_is_set) {
        if (!$self->is_set && $self->has_data) {
            croak("Unable to add data, this isn't a set!");
        }
        return $self->$orig(@data);
    }
    $self->_is_set(1);
    return $self->$orig(@data);
};

around included => sub {
    my ($orig, $self) = @_;
    return $self->_assert_uniq('included', $orig);
};

sub _assert_uniq {
    my ($self, $type, $orig) = @_;

    my @rv = $self->$orig;
    my @check = uniq map { { id => $_->id, type => $_->type } } @rv;
    if (@check == @rv) {
        return \@rv;
    }
    croak("Duplicate ID and type are found for $type");
}

around data => sub {
    my ($orig, $self) = @_;
    return $self->_assert_uniq('data', $orig);
};

sub as_data_object {
    my $self = shift;

    croak("You called me as a data object, but I'm in an error state!")
        if $self->has_errors;

    my %rv;

    if ($self->has_data) {
        $rv{data} = $self->is_set ? $self->data : $self->data->[0];
    }
    elsif ($self->is_set) {
        $rv{data} = [],
    }
    else {
        $rv{data} = undef;
    }

    $rv{included} = $self->included if $self->has_included;
    $rv{jsonapi} = $self->jsonapi if $self->has_jsonapi;

    return \%rv;
}

sub as_error_object {
    my $self = shift;

    croak("You called me as an error object, but I'm not in an error state!")
        unless $self->has_errors;

    return { errors => $self->errors };
}

sub TO_JSON {
    my $self = shift;

    return $self->as_error_object if $self->has_errors;
    return $self->as_data_object;

}

with qw(
    JSON::API::v1::Roles::TO_JSON
    JSON::API::v1::Roles::MetaObject
    JSON::API::v1::Roles::Links
);

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

JSON::API::v1 - A JSON API object according to jsonapi.org v1 specification

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    use JSON::API::v1;

    my $object = JSON::API::v1->new(
        data => JSON::API::v1::Resource->new(
            ...
        );
    );

    $object->add_error(JSON::API::v1::Error->new(...));

    $object->add_relationship(JSON::API::v1::Error->new(...));

=head1 DESCRIPTION

This module attempts to make a Moose object behave like a JSON API object as
defined by L<jsonapi.org>. This object adheres to the v1 specification

=head1 ATTRIBUTES

=head2 data

This data object is there a L<JSON::API::v1::Resource> lives.

=head2 errors

This becomes an array ref of L<JSON::API::v1::Error> once you start
adding errors to this object object via C<add_error>.

=head2 included

This becomes an array ref of L<JSON::API::v1::Resource> once you start
adding additional resources to this object object via C<add_included>.

=head2 is_set

This is to tell the object it is a set and you can add data to it via
C<add_data>. It will in turn JSON-y-fi the data to an array of the data you've
added. If you don't set this via the constructer, please read the documentation
of L<JSON::API::v1/add_data>

=head1 METHODS

=head2 add_data

You can add individual L<JSON::API::v1::Resource> objects to the
toplevel object. If you have not set is_set the first call to this function
will assume you're adding data and thus want to be a set.

=head2 add_error

You can add individual L<JSON::API::v1::Error> objects to the
toplevel object.

=head2 add_included

You can add individual L<JSON::API::v1::Resource> objects to the
toplevel object.

=head1 AUTHOR

Wesley Schwengle <waterkip@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Wesley Schwengle.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
