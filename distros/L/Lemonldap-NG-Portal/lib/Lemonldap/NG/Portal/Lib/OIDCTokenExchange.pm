package Lemonldap::NG::Portal::Lib::OIDCTokenExchange;

use strict;
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_SENDRESPONSE
  PE_OK
);
use Mouse;

extends 'Lemonldap::NG::Portal::Main::Plugin';

our $VERSION = '2.20.0';

# INTERFACE
use constant hook => { oidcGotTokenExchange => 'tokenExchange' };

has oidc => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        $_[0]
          ->p->loadedModules->{'Lemonldap::NG::Portal::Issuer::OpenIDConnect'};
    }
);

sub init { 1 }

# MAIN METHOD
#
# Important note: only PE_OK and PE_RESPONSE are used here because:
#  - oidcGotTokenExchange only accept PE_SENDRESPONSE has positive response
#  - PE_OK permits to continue to check other plugins
sub tokenExchange {
    my ( $self, $req, $rp ) = @_;

    unless ( $self->oidc ) {
        $self->logger->error('Authentication is not OIDC, aborting');
        return PE_OK;
    }

    $self->logger->debug("Matrix Refresh Token exchange for $rp");

    # 1. Validate request
    #
    # Note that client_id and grant_type value are verified by
    # ::/lib::OpenIDConnect

    my $clientId     = $req->param('client_id');       # already validated
    my $subjectToken = $req->param('subject_token');
    unless ($subjectToken) {
        $self->userLogger->error('Token exchange called without subject_token');
        return PE_OK;
    }

    # Even if these fields are required in Oauth2, it seems that it is not
    # required by Keycloak..

    my @types;
    foreach my $name (qw(subject_token_type requested_token_type)) {
        my $val = $req->param($name);
        if ($val) {
            unless ($val =~ s/^urn:ietf:params:oauth:token-type://
                and $val =~ /^(?:(?:refresh|access|id)_token|saml[12])$/ )
            {
                $self->logger->info(
                    "Malformed $name: " . $req->param('subject_token_type') );
                return PE_OK;
            }
        }
        push @types, $val;
    }

    # 2. Check for audience and authorization
    my $targetClientId = $req->param('audience');
    my $target         = { audience => $req->param('audience') // undef, };
    if ( $target->{audience} ) {
        if ( $target->{audience} eq $clientId ) {
            $target->{rp} = $rp;
        }
        else {
            my ($res) = grep {
                $self->oidc->rpOptions->{$_}->{oidcRPMetaDataOptionsClientID}
                  eq $targetClientId
            } keys %{ $self->oidc->rpOptions };
            $target->{rp} = $res;
        }
    }
    else {
        $target->{rp} = $rp;
    }

    unless ( $self->validateAudience( $req, $rp, $target, $types[1] ) ) {
        $self->logger->debug( ref($self) . " refused to validate audience" );
        return PE_OK;
    }

    # 3. Use subclass getUid() to get user ID
    my $uid = $self->getUid( $req, $rp, $subjectToken, $types[0] );
    return PE_OK unless $uid;

    # 4. Create refresh_token

    my $opts = { $self->oidc->_storeOpts() };

    # 3.1. Create a new refresh_token if missing
    $req->user($uid);
    $req->steps( [
            'getUser',        'setAuthSessionInfo',
            'setSessionInfo', $self->p->groupsAndMacros,
            'setLocalGroups'
        ]
    );
    if ( my $error = $self->p->process($req) ) {
        if ( $error == PE_OK ) {
            $self->userLogger->warn(
                    'Token exchange requested for an invalid user ('
                  . $req->{user}
                  . ")" );
        }
        $self->logger->error("Unable to find user $uid");
        return PE_OK;
    }

    my $refreshToken = $self->oidc->newRefreshToken(
        $rp,
        {
            %{ $req->sessionInfo },
            scope     => $req->param('scope') || 'openid',
            client_id => $target->{audience}
              || $self->oidc->rpOptions->{$rp}->{oidcRPMetaDataOptionsClientID},
            _session_uid => $uid,
            grant_type   => $req->param('grant_type'),
        },
    );
    unless ($refreshToken) {
        return PE_OK;
    }

    # 5. Use normal method to create new access_token from refresh_token
    #
    # TODO: remote may want a refresh_token

    my $res = $self->oidc->_handleRefreshTokenGrant( $req, $target->{rp} || $rp,
        $refreshToken->id, $targetClientId );

    # Insert refresh_token in response
    my $tmp = JSON::from_json( $res->[2]->[0] );
    $tmp->{refresh_token} = $refreshToken->id;
    $res->[2]->[0] = JSON::to_json($tmp);

    $req->response($res);

    return PE_SENDRESPONSE;
}

1;
__END__

=pod

=encoding utf8

=head1 NAME

Lemonldap::NG::Portal::Lib::OIDCTokenExchange - Base class for building OpenID
Connect token exchange systems.

=head1 SYNOPSIS

  use Mouse
  extends 'Lemonldap::NG::Portal::Lib::OIDCTokenExchange';
  
  sub validateAudience {
    my ( $self, $req, $rp, $target, $requestedTokenType ) = @_;
    #
    # verify and update if needed:
    # * $target->{audience}
    # * $target->{rp}
    #
    return 1;
  }
  
  sub getUid {
    my ( $self, $req, $rp, $subjectToken, $subjectTokenType ) = @_;
    #
    # verify subjectToken
    #
    return 1;
  }

=head1 DESCRIPTION

When L<Lemonldap::NG|https://lemonldap-ng.org> detects a
L<Oauth2 token exchange|https://datatracker.ietf.org/doc/html/rfc8693> request,
it searches for a plugin able to respond. If no one returns a valid response,
it rejects the requests.

B<Lemonldap::NG::Portal::Lib::OIDCTokenExchange> permits one to build such
plugin by just writing two methods. Of course you need then to load the module
for example using L<Enabling custom plugin|https://lemonldap-ng.org/documentation/latest/plugincustom.html#enabling-your-plugin>.

=head2 Methods to write

=head3 validateAudience

The goal of C<validateAudience()> is to validate the requested B<audience>.

If a non-null value is returned, then the request is accepted and Lemonldap::NG
will build new C<access_token>, C<id_token> and C<refresh_token> using the
values included into C<$target> hash.

If a null value is returned, Lemonldap::NG will try the next plugin.

Parameters:

=over

=item * B<$req>, the L<Lemonldap::NG::Portal::Main::Request> object

=item * B<$rp>, the internal LLNG name of the Relying Party which pushed the request

=item * B<$target>, a hash value with 2 keys:

=over

=item * B<audience>, the requested audience

=item * B<rp>: if B<Lemonldap::NG> found a known Relying Party which Client-ID
matches with requested audience, its name is put here, else this value is
undefined.

=back

This value can be modified inside C<validateAudience> and will be used to generate
the new C<access_token>.

=item * B<$requestedTokenType>, the type of the requested token. This value is always
one of:

=over

=item * B<access_token>

=item * B<refresh_token>

=item * B<id_token>

=item * B<saml1>

=item * B<saml2>

=item * I<undef>

=back

=back

=head3 getUid

C<getUid()> is a boolean method to validate the token given in the request.

If a non-null value is returned, then the request is accepted. Else Lemonldap::NG
will try the next plugin.

Parameters:

=over

=item * B<$req>, the L<Lemonldap::NG::Portal::Main::Request> object

=item * B<$rp>, the internal LLNG name of the Relying Party which pushed the request

=item * B<$subjectToken>, the token given in the request

=item * B<$subjectTokenType>, the type of the given token. This value is always
one of:

=over

=item * B<access_token>

=item * B<refresh_token>

=item * B<id_token>

=item * B<saml1>

=item * B<saml2>

=item * I<undef>

=back

=back

=head1 AUTHORS

=over

=item * LemonLDAP::NG team L<http://lemonldap-ng.org/team>

=back

=head1 BUG REPORT

Use OW2 system to report bug or ask for features:
L<https://gitlab.ow2.org/lemonldap-ng/lemonldap-ng/issues>

=head1 DOWNLOAD

Lemonldap::NG is available at
L<https://lemonldap-ng.org/download>

=head1 COPYRIGHT AND LICENSE

See COPYING file for details.

This library is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2, or (at your option)
any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see L<http://www.gnu.org/licenses/>.

=cut
