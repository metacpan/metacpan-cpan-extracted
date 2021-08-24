package Lemonldap::NG::Common::Apache::Session::REST;

use strict;
use Lemonldap::NG::Common::UserAgent;
use Lemonldap::NG::Common::Apache::Session::Generate::SHA256;
use JSON qw(from_json to_json);

our $VERSION = '2.0.5';

our @ISA = qw(Lemonldap::NG::Common::Apache::Session::Generate::SHA256);

# PUBLIC INTERFACE

# Constructor for Perl TIE mechanism. See perltie(3) for more.
sub TIEHASH {
    my ( $class, $session_id, $args ) = @_;
    die "baseUrl argument is required"
      unless ( $args and $args->{baseUrl} );
    my $self = {
        data     => { _session_id => $session_id },
        modified => 0,
    };
    foreach (
        qw(baseUrl user password realm localStorage localStorageOptions lwpOpts lwpSslOpts kind)
      )
    {
        $self->{$_} = $args->{$_};
    }
    bless $self, $class;

    if ( defined $session_id && $session_id ) {
        die "unexistant session $session_id"
          unless ( $self->get($session_id) );
    }
    elsif ( $args->{setId} ) {
        $self->{data}->{_session_id} = $args->{setId};
        $self->newSession;
    }
    else {
        die "unable to create session"
          unless ( $self->newSession() );
    }
    return $self;
}

sub FETCH {
    my $self = shift;
    my $key  = shift;
    return $self->{data}->{$key};
}

sub STORE {
    my $self  = shift;
    my $key   = shift;
    my $value = shift;

    $self->{data}->{$key} = $value;
    $self->{modified} = 1;
    return $value;
}

sub DELETE {
    my $self = shift;
    my $key  = shift;

    $self->{modified} = 1;

    delete $self->{data}->{$key};
}

sub CLEAR {
    my $self = shift;

    $self->{modified} = 1;

    $self->{data} = {};
}

sub EXISTS {
    my $self = shift;
    my $key  = shift;
    return exists $self->{data}->{$key};
}

sub FIRSTKEY {
    my $self  = shift;
    my $reset = keys %{ $self->{data} };
    return each %{ $self->{data} };
}

sub NEXTKEY {
    my $self = shift;
    return each %{ $self->{data} };
}

sub DESTROY {
    my $self = shift;
    $self->save;
}

sub ua {
    my ($self) = @_;
    return $self->{ua} if ( $self->{ua} );
    my $ua = Lemonldap::NG::Common::UserAgent->new(
        { lwpOpts => $self->{lwpOpts}, lwpSslOpts => $self->{lwpSslOpts} } );
    if ( $self->{user} ) {
        my $url  = $self->{baseUrl};
        my $port = ( $url =~ /^https/ ? 443 : 80 );
        $url =~ s#https?://([^/]*).*$#$1#;
        $port = $1 if ( $url =~ s/:(\d+)$// );
        $ua->credentials( "$url:$port", $self->{realm},
            $self->{user}, $self->{password} );
    }
    return $self->{ua} = $ua;
}

sub getJson {
    my $self = shift;
    my $id   = shift;
    my $resp = $self->ua->get(
        $self->base
          . $id
          . ( $self->{kind} ne 'SSO' ? "?kind=$self->{kind}" : '' ),
        @_
    );
    if ( $resp->is_success ) {
        my $res;
        eval { $res = from_json( $resp->content, { allow_nonref => 1 } ) };
        if ($@) {
            print STDERR "Unable to decode session: $@\n";
            return 0;
        }
        return $res;
    }
    elsif ( $resp->status_line =~ /400/ ) {
        return 0;
    }
    else {
        print STDERR 'REST server returns: ' . $resp->status_line . "\n";
        return 0;
    }
}

sub base {
    my ($self) = @_;
    $self->{baseUrl} =~ s#/*$#/#;
    return $self->{baseUrl};
}

## @method hashRef get(string id)
# @param $id Apache::Session session ID.
# @return User data
sub get {
    my $self = shift;
    my $id   = shift;

    # Check cache
    if ( $self->{localStorage} && $self->cache->get("rest$id") ) {
        return $self->{data} = $self->cache->get("rest$id");
    }

    # No cache, use REST and set cache
    my $res = $self->getJson($id) or return 0;
    $self->{data} = $res;

    $self->cache->set( "rest$id", $self->{data} ) if $self->{localStorage};

    return $self->{data};
}

## @method hashRef newSession()
# Build a new Apache::Session session.
# @return User data (just the session ID)
sub newSession {
    my $self = shift;
    $self->generate unless ( $self->{data}->{_session_id} );
    $self->{data}->{_utime} = time;

    #my $req = HTTP::Request->new( POST => $self->base );
    #$req->content( to_json( { _utime => time } ) );
    #$req->header( 'Content-Type' => 'application/json' );
    #my $resp = $self->ua->request($req);
    #if ( $resp->is_success ) {
    #    my $res;
    #    eval { $res = from_json( $resp->content, { allow_nonref => 1 } ) };
    #    if ( $@ or !$res->{result} ) {
    #        die "Unable to create session: bad REST response $@";
    #    }
    #    $self->{data} = $res->{session};
    #}
    #else {
    #    die "REST server returns " . $resp->status_line;
    #}

    ## Set cache
    #if ( $self->{localStorage} ) {
    #    my $id = "rest" . $self->{data}->{_session_id};
    #    if ( $self->cache->get($id) ) {
    #        $self->cache->remove($id);
    #    }
    #    $self->cache->set( $id, $self->{data} );
    #}

    return $self->{data};
}

## @method boolean save()
# Save user data if modified.
sub save {
    my $self = shift;
    return unless ( $self->{modified} );

    # Update session in cache
    if ( $self->{localStorage} ) {
        my $id = "rest" . $self->{data}->{_session_id};
        if ( $self->cache->get($id) ) {
            $self->cache->remove($id);
        }
        $self->cache->set( $id, $self->{data} );
    }

    # REST
    my $req =
      HTTP::Request->new( PUT => $self->base . $self->{data}->{_session_id} );
    eval {
        $self->{data}->{__secret} =
          Lemonldap::NG::Handler::Main->tsv->{cipher}->encrypt(time);
    };
    print STDERR "$@\n" if ($@);
    my $content = to_json( $self->{data} );
    $req->content($content);
    delete $self->{data}->{__secret};
    $req->header( 'Content-Type'   => 'application/json' );
    $req->header( 'Content-Length' => length($content) );
    my $resp = $self->ua->request($req);

    if ( $resp->is_success ) {
        my $res;
        eval { $res = from_json( $resp->content, { allow_nonref => 1 } ) };
        if ($@) {
            die "Bad REST response: $@";
        }
        return $res;
    }
    else {
        print STDERR "REST server returns " . $resp->status_line;
        return;
    }
}

## @method boolean delete()
# Deletes the current session.
sub delete {
    my $self = shift;

    # Remove session from cache
    if ( $self->{localStorage} ) {
        my $id = "rest" . $self->{data}->{_session_id};
        if ( $self->cache->get($id) ) {
            $self->cache->remove($id);
        }
    }

    # REST
    my $req = HTTP::Request->new(
        DELETE => $self->base . $self->{data}->{_session_id} );
    $req->header( 'Content-Type' => 'application/json' );
    my $resp = $self->ua->request($req);
    return ( $resp->is_success ? 1 : 0 );
}

sub searchOn {
    my ( $class, $args, $selectField, $value, @fields ) = @_;
    return $class->_getAll( "all=1&search=$selectField,$value",
        $args, ( @fields ? \@fields : () ) );
}

## @method get_key_from_all_sessions()
# Not documented.
sub get_key_from_all_sessions() {
    my ( $class, $args, $data ) = @_;
    my $res = $class->_getAll( 'all=1', $args, $data );
    return unless $res;

    if ( ref($data) eq 'CODE' ) {
        my $r;
        foreach my $k ( keys %$res ) {
            my $tmp = &$data( $res->{$k}, $k );
            $r->{$k} = $tmp if ( defined($tmp) );
        }
        $res = $r;
    }
    return $res;
}

sub _getAll {
    my ( $class, $query, $args, $data ) = @_;
    my $self = bless {}, $class;
    foreach (qw(baseUrl user password realm lwpOpts lwpSslOpts kind)) {
        $self->{$_} = $args->{$_};
    }
    $self->{data} = { data => ( ref($data) eq 'CODE' ? undef : $data ) };
    die('baseUrl is required') unless ( $self->{baseUrl} );
    my $req = HTTP::Request->new( POST => $self->base . "?$query" );
    eval {
        $self->{data}->{__secret} =
          Lemonldap::NG::Handler::Main->tsv->{cipher}->encrypt(time);
    };
    print STDERR "$@\n" if ($@);
    my $content = to_json( $self->{data} );
    $req->content($content);
    $req->header( 'Content-Length' => length($content) );
    delete $self->{data}->{__secret};
    $req->header( 'Content-Type' => 'application/json' );
    my $resp = $self->ua->request($req);

    if ( $resp->is_success ) {
        my $res;
        eval { $res = from_json( $resp->content, { allow_nonref => 1 } ) };
        if ($@) {
            die "Bad REST response: $@";
        }
        return $res;
    }
    else {
        print STDERR "REST server returns " . $resp->status_line . "\n";
        return;
    }
}

sub cache {
    my $self = shift;

    return $self->{cache} if $self->{cache};

    my $module = $self->{localStorage};
    eval "use $module;";
    $self->{cache} = $module->new( $self->{localStorageOptions} );

    return $self->{cache};
}

1;
__END__

=head1 NAME

=encoding utf8

Lemonldap::NG::Common::Apache::Session::REST - Perl extension written to
access to Lemonldap::NG Web-SSO sessions via REST.

=head1 DESCRIPTION

Lemonldap::NG::Common::Conf provides a simple interface to access to
Lemonldap::NG Web-SSO configuration. It is used by L<Lemonldap::NG::Handler>,
L<Lemonldap::NG::Portal> and L<Lemonldap::NG::Manager>.

Lemonldap::NG::Common::Apache::Session::REST used with
L<Lemonldap::NG::Portal> provides the ability to access to
Lemonldap::NG sessions via REST: the portal act as a proxy to access to the
real Apache::Session module (see HTML documentation for more)

=head1 PARAMETERS

=over

=item baseUrl (required): remote LLNG portal

=item realm, user and password (optional): AuthBasic parameters if needed

=item lwpOpts: L<LWP::UserAgent> options (hash ref)

=item lwpSlsOpts: L<LWP::UserAgent> SSL options (will be given to LWP::UserAgent
constructor in parameter C<ssl_opts>

=back

=head1 SEE ALSO

L<http://lemonldap-ng.org/>, L<Lemonldap::NG::Portal>, L<Apache::Session>,
L<LWP::UserAgent>

=head1 AUTHORS

=over

=item LemonLDAP::NG team L<http://lemonldap-ng.org/team>

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
