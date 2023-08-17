package Hadoop::Oozie::DelegationTokenContainer;
$Hadoop::Oozie::DelegationTokenContainer::VERSION = '0.002';
use strict;
use warnings;

use Carp;
use MIME::Base64 qw( encode_base64url );

use Hadoop::IO::DelegationToken::Reader qw(
    parseTokenStorageStream
    vlong
);

use namespace::clean;

sub new_from_file {
    my ($class, $file) = @_;

    open my $fh, '<', $file or croak "Can't open $file for reading: $!";
    binmode($fh);

    return bless parseTokenStorageStream( $fh ), $class;
}

sub tokens { return keys %{ shift->{token} }; }

sub base64token_for {
    my ( $self, $query ) = @_;

    my $token = $self->token_for($query);
    return encode_base64url(
        join '',
        map vlong(length) . $_,
        map $token->{$_},
        qw( identifier password kind service )
    );
}

sub token_for {
    my ( $self, $query ) = @_;
    croak "Query can't be empty" if !defined $query || !length $query;

    # pick the first matching key if given an non-existing key
    my $key = exists $self->{token}{$query}
        ? $query
        : ( grep /$query/, sort keys %{ $self->{token} } )[0];

    croak "No token found for '$query'" if !defined $key;
    my $token = $self->{token}{$key};
    return $token;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Hadoop::Oozie::DelegationTokenContainer

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    use Hadoop::Oozie::DelegationTokenContainer;

    my $container = Hadoop::Oozie::DelegationTokenContainer->new_from_file( $ENV{HADOOP_TOKEN_FILE_LOCATION} );
    my $token = $container->base64token_for( 'WEBHDFS' );

=head1 DESCRIPTION

Hadoop::Oozie::DelegationTokenContainer parses token container files
produced by Hadoop, and can produce the base64 tokens used in REST
queries.

=head1 NAME

Hadoop::Oozie::DelegationTokenContainer - Perl interface to Hadoop delegation token

=head1 METHODS

=head2 base64token_for

    my $token = $container->base64token_for( $query );

Return the base64-encoded delegation token for the given query.

If the string is not an exact match for a token name, return the first
token which name matches the query.

=head2 new_from_file

    my $container = Hadoop::Oozie::DelegationTokenContainer->new_from_file( $file );

Parse the content of C<$file> and return a
Hadoop::Oozie::DelegationTokenContainer object.

=head2 token_for

=head2 tokens

    my @tokens = $container->tokens;

Return the list of tokens in the container.

=head1 AUTHORS

=over 4

=item *

Philippe Bruhat

=item *

Somesh Malviya

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Booking.com.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
