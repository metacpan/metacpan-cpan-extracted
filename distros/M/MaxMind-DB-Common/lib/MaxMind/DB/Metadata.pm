package MaxMind::DB::Metadata;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.040001';

use Moo;
use MaxMind::DB::Types qw( ArrayRefOfStr Epoch HashRefOfStr Int Str );
use MooX::StrictConstructor;

with 'MaxMind::DB::Role::Debugs';

{
    my %metadata = (
        binary_format_major_version => Int,
        binary_format_minor_version => Int,
        build_epoch                 => Epoch,
        database_type               => Str,
        description                 => HashRefOfStr,
        ip_version                  => Int,
        node_count                  => Int,
        record_size                 => Int,
    );

    for my $attr ( keys %metadata ) {
        has $attr => (
            is       => 'ro',
            isa      => $metadata{$attr},
            required => 1,
        );
    }
}

has languages => (
    is      => 'ro',
    isa     => ArrayRefOfStr,
    default => sub { [] },
);

sub metadata_to_encode {
    my $self = shift;

    my %metadata;
    foreach my $attr ( $self->meta()->get_all_attributes() ) {
        my $method = $attr->name;
        $metadata{$method} = $self->$method;
    }

    return \%metadata;
}

sub debug_dump {
    my $self = shift;

    $self->_debug_newline();

    $self->_debug_message('Metadata:');
    my $version = join '.',
        $self->binary_format_major_version(),
        $self->binary_format_minor_version();
    $self->_debug_string( '  Binary format version', $version );

    require DateTime;
    $self->_debug_string(
        '  Build epoch',
        $self->build_epoch() . ' ('
            . DateTime->from_epoch( epoch => $self->build_epoch() ) . ')'
    );

    $self->_debug_string( '  Database type', $self->database_type() );

    my $description = $self->description();
    for my $locale ( sort keys %{$description} ) {
        $self->_debug_string(
            "  Description [$locale]",
            $description->{$locale}
        );
    }

    $self->_debug_string( '  IP version',            $self->ip_version() );
    $self->_debug_string( '  Node count',            $self->node_count() );
    $self->_debug_string( '  Record size (in bits)', $self->record_size() );
    $self->_debug_string(
        '  Languages', join ', ',
        @{ $self->languages() }
    );

    return;
}

__PACKAGE__->meta()->make_immutable();

1;

#ABSTRACT: A class for metadata related to a MaxMind DB database

__END__

=pod

=head1 NAME

MaxMind::DB::Metadata - A class for metadata related to a MaxMind DB database

=head1 VERSION

version 0.040001

=head1 SYNOPSIS

    my $reader = MaxMind::DB::Reader->new( file => $path );
    my $metadata = $reader->metadata();

    print $metadata->description()->{en};

=head1 DESCRIPTION

This class provides an API for representing the metadata of a MaxMind DB
database. See http://maxmind.github.io/MaxMind-DB/ for the official format
spec.

=for test_synopsis my $path;

=head1 API

This class provides methods for each metadata attribute in a database.

=head2 $metadata->binary_format_major_version()

Returns the binary format major version number.

=head2 $metadata->binary_format_minor_version()

Returns the binary format minor version number.

=head2 $metadata->build_epoch()

Returns the database's build timestamp as an epoch value.

=head2 $metadata->database_type()

Returns a string indicating the database's type.

=head2 $metadata->languages()

Returns an arrayref of locale codes indicating what languages this database
has information for.

=head2 $metadata->description()

Returns a hashref of descriptions. The keys should be locale codes like "en"
or "pt-BR" and the values are the description in that language.

=head2 $metadata->ip_version()

Returns a 4 or 6 indicating what type of IP addresses this database can be
used to look up.

=head2 $metadata->node_count()

Returns the number of nodes in the database's search tree.

=head2 $metadata->record_size()

Returns the record size for nodes in the database's search tree.

=head1 AUTHORS

=over 4

=item *

Dave Rolsky <drolsky@maxmind.com>

=item *

Olaf Alders <oalders@maxmind.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by MaxMind, Inc..

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
