#
# This file is part of Jedi-Plugin-Session
#
# This software is copyright (c) 2013 by celogeek <me@celogeek.com>.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package Jedi::Plugin::Session::Role;

# ABSTRACT: imported method for Jedi::Plugin::Session

use strict;
use warnings;
our $VERSION = '0.05';    # VERSION
use Digest::SHA1 qw/sha1_base64/;
use CGI::Cookie;

my @_BASE64 = ( 0 .. 9, 'a' .. 'z', 'A' .. 'Z', '_', '-' );

sub _get_random_base64 {
    my ($count) = @_;
    return join( '', map { @_BASE64[ int( rand(64) ) ] } 1 .. $count );
}

sub Jedi::Request::session_get {
    my ( $self, @params ) = @_;
    return $self->{'Jedi::Plugin::Session::get'}->( $self, @params );
}

sub Jedi::Request::session_set {
    my ( $self, @params ) = @_;
    return $self->{'Jedi::Plugin::Session::set'}->( $self, @params );
}

use Moo::Role;

has '_jedi_session' => ( is => 'lazy' );

before jedi_app => sub {
    my ($app) = @_;
    $app->_jedi_session;    #init session
    $app->get( qr{.*}x, $app->can('jedi_session_setup') );
    $app->post( qr{.*}x, $app->can('jedi_session_setup') );
    return;
};

sub jedi_session_setup {
    my ( $self, $request, $response ) = @_;

    # get UUID from session
    my ($uuid) = @{ $request->cookies->{jedi_session} // [] };

    if ( !defined $uuid ) {
        $uuid = _get_random_base64(12);

        # session save UUID
        my $cookie = CGI::Cookie->new(
            -name    => 'jedi_session',
            -value   => $uuid,
            -expires => '+24M'
        );
        $response->push_header( 'Set-Cookie', $cookie );
    }

    my $full_uuid = sha1_base64(
        join(
            '_',
            grep {defined} (
                $uuid, $request->remote_address,
                $request->env->{HTTP_USER_AGENT}
            )
        )
    );
    $request->{'Jedi::Plugin::Session::UUID'} = $full_uuid;
    $request->{'Jedi::Plugin::Session::get'}
        = sub { $self->_jedi_session->get($full_uuid) };
    $request->{'Jedi::Plugin::Session::set'} = sub {
        my ( undef, $value ) = @_;
        $self->_jedi_session->set( $full_uuid, $value );
    };

    return 1;
}

1;

__END__

=pod

=head1 NAME

Jedi::Plugin::Session::Role - imported method for Jedi::Plugin::Session

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
