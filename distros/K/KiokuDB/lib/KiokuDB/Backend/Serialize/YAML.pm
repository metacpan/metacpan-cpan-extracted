package KiokuDB::Backend::Serialize::YAML;
BEGIN {
  $KiokuDB::Backend::Serialize::YAML::AUTHORITY = 'cpan:NUFFIN';
}
$KiokuDB::Backend::Serialize::YAML::VERSION = '0.57';
use Moose::Role;
# ABSTRACT: YAML::XS based serialization of KiokuDB::Entry objects.

use IO::Handle;

use YAML::XS 0.30 qw(Load Dump);

use namespace::clean -except => 'meta';

with qw(
    KiokuDB::Backend::Serialize
    KiokuDB::Backend::Role::UnicodeSafe
    KiokuDB::Backend::TypeMap::Default::Storable
);

sub serialize {
    my ( $self, $entry ) = @_;

    my $clone = $entry->clone;

    $clone->clear_prev;
    $clone->root( $entry->root );

    Dump($clone);
}

sub deserialize {
    my ( $self, $blob ) = @_;

    return Load($blob);
}

sub serialize_to_stream {
    my ( $self, $fh, $entry ) = @_;
    $fh->print( $self->serialize($entry) );
}

has _deserialize_buffer => (
    isa => "ScalarRef",
    is  => "ro",
    default => sub { my $x = ''; \$x },
);

sub deserialize_from_stream {
    my ( $self, $fh ) = @_;

    local $_;
    local $/ = "\n";

    my $buf = $self->_deserialize_buffer;

    while ( <$fh> ) {
        if ( /^---/ and length($$buf) ) {
            my @data = $self->deserialize($$buf);
            $$buf = $_;
            return @data;
        } else {
            $$buf .= $_;
        }
    }

    if ( length $$buf ) {
        my @data = $self->deserialize($$buf);
        $$buf = '';
        return @data;
    } else {
        return;
    }
}

__PACKAGE__

__END__

=pod

=encoding UTF-8

=head1 NAME

KiokuDB::Backend::Serialize::YAML - YAML::XS based serialization of KiokuDB::Entry objects.

=head1 VERSION

version 0.57

=head1 SYNOPSIS

    package MyBackend;
    use Moose;

    with qw(KiokuDB::Backend::Serialize::YAML);

=head1 DESCRIPTION

L<KiokuDB::Backend::Serialize::Delegate> is preferred to using this directly.

=head1 METHODS

=over 4

=item serialize $entry

Calls L<YAML::XS::Dump>

=item deserialize $str

Calls L<YAML::XS::Load>

=item serialize_to_stream $fh, $entry

Serializes the entry and prints to the file handle.

=item deserialize_from_stream $fh

Reads until a YAML document boundry is reached, and then deserializes the
current buffer.

=back

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Yuval Kogman, Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
