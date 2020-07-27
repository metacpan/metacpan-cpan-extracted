use utf8;

package JSON::API::v1::Attribute;
our $VERSION = '0.002';
use Moose;
use namespace::autoclean;
use Carp qw(croak);
use List::Util qw(any);

our @CARP_NOT;

# ABSTRACT: A JSON API Attribute object according to jsonapi v1 specification

has attributes => (
    is      => 'ro',
    isa     => 'HashRef',
    traits  => ['Hash'],
    lazy    => 1,
    default => sub { {} },
    handles => {
        has_attribute       => 'exists',
        get_attribute       => 'get',
        set_attribute       => 'set',
        add_attribute       => 'set',
        clear_attribute     => 'delete',
        get_attribute_names => 'keys',
    },
);

sub TO_JSON {
    my $self = shift;

    my %rv;
    foreach ($self->get_attribute_names) {
        $rv{$_} = $self->get_attribute($_);
    }
    return \%rv;
}

my @forbidden = qw(links relationships);

sub _assert_attribute_name {
    my ($self, $key) = @_;
    if (any { $_ eq ($key // '') } @forbidden) {
        local @CARP_NOT = qw(
            Class::MOP::Method::Wrapped
        );
        croak("Unable to use reserved keyword '$key'!");
    }
}

around set_attribute => sub {
    my ($orig, $self, $key, @rest) = @_;
    $self->_assert_attribute_name($key);
    return $self->$orig($key, @rest);
};

around get_attribute => sub {
    my ($orig, $self, $key) = @_;
    $self->_assert_attribute_name($key);
    return $self->$orig($key);
};

with qw(
    JSON::API::v1::Roles::TO_JSON
);


__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

JSON::API::v1::Attribute - A JSON API Attribute object according to jsonapi v1 specification

=head1 VERSION

version 0.002

=head1 SYNOPSIS

=head1 DESCRIPTION

This module attempts to make a Moose object behave like a JSON API object as
defined by L<jsonapi.org>. This object adheres to the v1 specification

=head1 ATTRIBUTES

=head1 METHODS

=head1 AUTHOR

Wesley Schwengle <waterkip@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Wesley Schwengle.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
