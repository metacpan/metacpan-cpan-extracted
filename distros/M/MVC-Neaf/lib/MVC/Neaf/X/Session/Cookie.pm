package MVC::Neaf::X::Session::Cookie;

use strict;
use warnings;
our $VERSION = '0.2701';

=head1 NAME

MVC::Neaf::X::Session::Cookie - Stateless cookie-based session for Neaf

=head1 DESCRIPTION

Use this module as a session handler in a Neaf app.

The session data is stored within user's cookies without encryption.
However, it is signed with a key only known to the application owner.
So the session can be read, but not tampered with.

Please take these concern into account, or better use server-side storage.

=head1 METHODS

=cut

use MVC::Neaf::Util qw( encode_b64 decode_b64 );
use Digest::SHA qw( hmac_sha224 );

use parent qw( MVC::Neaf::X::Session::Base );

=head2 new( %options )

%options may include:

=over

=item * key (required) - a secret text string used to sign session data.
This should be the same throughout the application.

=item * hmac_function - HMAC to be used, default is hmac_sha224_base64

=back

=cut

sub new {
    my ($class, %opt) = @_;

    $opt{key} or $class->my_croak( "key option is required" );

    $opt{hmac_function} ||= sub { encode_b64( hmac_sha224( @_ ) ) };

    return $class->SUPER::new( %opt );
};

=head2 store( $id, $data )

Create a cookie from $data hash. Given $id is ignored.

=cut

sub store {
    my ($self, $id, $data) = @_;

    # TODO 0.90 Make universal HMAC mechanism for ALL cookies
    my $str = encode_b64($data);
    $str =~ s/\s//gs;
    $str .= "~".$self->get_expire;
    my $sum = $self->{hmac_function}->( $str, $self->{key} );

    return { id => "$str~$sum" };
};

=head2 fetch

Restore session data from cookie.

=cut

sub fetch {
    my ($self, $id) = @_;

    my ($str, $time, $key) = split /~/, $id, 3;

    return unless $key;
    return unless $self->{hmac_function}->( "$str~$time", $self->{key} ) eq $key;

    return { strfy => decode_b64($str), expire => $time };
};

=head2 get_session_id

Replaced by a stub - we'll generate ID from data anyway.

=cut

sub get_session_id { return 'Cookie Session Need No Id' };

=head1 LICENSE AND COPYRIGHT

This module is part of L<MVC::Neaf> suite.

Copyright 2016-2019 Konstantin S. Uvarin C<khedin@cpan.org>.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut

1;
