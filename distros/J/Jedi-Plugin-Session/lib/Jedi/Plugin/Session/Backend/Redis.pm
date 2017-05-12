#
# This file is part of Jedi-Plugin-Session
#
# This software is copyright (c) 2013 by celogeek <me@celogeek.com>.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package Jedi::Plugin::Session::Backend::Redis;

# ABSTRACT: Backend storage for Redis

use strict;
use warnings;
our $VERSION = '0.05';    # VERSION
use Time::Duration::Parse;
use Sereal qw/encode_sereal decode_sereal/;
use Redis;
use Moo;

has 'config' => (
    is      => 'ro',
    default => sub { {} },
    coerce  => sub { ref $_[0] eq 'HASH' ? $_[0] : {} }
);

has 'expires_in' => (
    is      => 'ro',
    default => sub { 3 * 3600 },
    coerce  => sub { parse_duration( $_[0] ) }
);

has 'prefix' => (
    is      => 'rw',
    default => sub {''},
    coerce  => sub {
        my $val = shift;
        return 'jedi_session_' if !defined $val || !length $val;
        return 'jedi_session_' . $val . '_';
    }
);

has '_redis' => ( is => 'lazy' );

sub _build__redis {
    my ($self) = @_;
    return Redis->new( %{ $self->config } );
}

## no critic (NamingConventions::ProhibitAmbiguousNames)
sub get {
    my ( $self, $uuid ) = @_;
    return if !defined $uuid;
    my $session = $self->_redis->get( $self->prefix . $uuid );
    if ( defined $session ) {
        return if !eval { $session = decode_sereal($session); 1 };
    }
    return $session;
}

sub set {
    my ( $self, $uuid, $value ) = @_;
    return if !defined $uuid;
    my $session = encode_sereal($value);
    $self->_redis->set( $self->prefix . $uuid, $session );
    $self->_redis->expire( $self->prefix . $uuid, $self->expires_in );
    return 1;
}

1;

__END__

=pod

=head1 NAME

Jedi::Plugin::Session::Backend::Redis - Backend storage for Redis

=head1 VERSION

version 0.05

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/celogeek/perl-jedi-plugin-session/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

celogeek <me@celogeek.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by celogeek <me@celogeek.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
