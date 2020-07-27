use utf8;

package JSON::API::v1::MetaObject;
our $VERSION = '0.002';
use Moose;
use namespace::autoclean;

# ABSTRACT: A JSON API Meta object according to jsonapi v1 specification

has members => (
    is      => 'ro',
    isa     => 'HashRef',
    traits  => ['Hash'],
    lazy    => 1,
    default => sub { {} },
    handles => {
        has_member       => 'exists',
        get_member       => 'get',
        set_member       => 'set',
        add_member       => 'set',
        clear_member     => 'delete',
        get_member_names => 'keys',
    },
);

sub TO_JSON {
    my $self = shift;

    my %rv;
    foreach ($self->get_member_names) {
        $rv{$_} = $self->get_member($_);
    }
    return \%rv;
}

with qw(
    JSON::API::v1::Roles::TO_JSON
);


__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

JSON::API::v1::MetaObject - A JSON API Meta object according to jsonapi v1 specification

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
