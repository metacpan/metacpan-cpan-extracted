#
# This file is part of Jedi-Plugin-Session
#
# This software is copyright (c) 2013 by celogeek <me@celogeek.com>.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package Jedi::Plugin::Session::Backend::Memory;

# ABSTRACT: Backend storage for Memory

use strict;
use warnings;
our $VERSION = '0.05';    # VERSION
use Time::Duration::Parse;
use Cache::LRU::WithExpires;
use Moo;

has '_cache' => ( is => 'lazy' );

sub _build__cache {
    return Cache::LRU::WithExpires->new;
}

has 'expires_in' => (
    is      => 'ro',
    default => sub { 3 * 3600 },
    coerce  => sub { parse_duration( $_[0] ) }
);

## no critic (NamingConventions::ProhibitAmbiguousNames)
sub get {
    my ( $self, $uuid ) = @_;
    return if !defined $uuid;

    return $self->_cache->get($uuid);
}

sub set {
    my ( $self, $uuid, $value ) = @_;
    return if !defined $uuid;
    $self->_cache->set( $uuid, $value, $self->expires_in );
    return 1;
}

1;

__END__

=pod

=head1 NAME

Jedi::Plugin::Session::Backend::Memory - Backend storage for Memory

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
