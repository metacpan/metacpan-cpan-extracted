use utf8;

package JSON::API::v1::Error;
our $VERSION = '0.002';
use Moose;
use namespace::autoclean;

# ABSTRACT: A JSON API object according to jsonapi.org v1 specification

has id => (
    is        => 'ro',
    isa       => 'Str',
    predicate => 'has_id',
);

has status => (
    is        => 'ro',
    isa       => 'Int',          # TODO: HTTP::Status type
    predicate => 'has_status',
);

has code => (
    is        => 'ro',
    isa       => 'Str',
    predicate => 'has_code',
);

has title => (
    is        => 'ro',
    isa       => 'Str',
    predicate => 'has_title',
);

has detail => (
    is        => 'ro',
    isa       => 'Defined',
    predicate => 'has_detail',
);

has source => (
    is        => 'ro',
    isa       => 'Defined',
    predicate => 'has_source',
);

sub TO_JSON {
    my $self = shift;

    my %rv;
    foreach (qw(id status code title detail source links)) {
        my $has = 'has_' . $_;
        if ($self->$has) {
            $rv{$_} = $self->$_;
        }
    }
    $rv{meta} = $self->meta_object if $self->has_meta_object;

    return \%rv;
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

JSON::API::v1::Error - A JSON API object according to jsonapi.org v1 specification

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
