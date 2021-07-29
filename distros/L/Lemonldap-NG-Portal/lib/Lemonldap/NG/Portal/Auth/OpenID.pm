package Lemonldap::NG::Portal::Auth::OpenID;

use strict;
use Mouse;
use Lemonldap::NG::Common::FormEncode;
use Lemonldap::NG::Common::Regexp;
use Lemonldap::NG::Common::UserAgent;
use Cache::FileCache;
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_BADCREDENTIALS
  PE_BADPARTNER
  PE_ERROR
  PE_FIRSTACCESS
  PE_OK
  PE_REDIRECT
);

our $VERSION = '2.0.12';

extends 'Lemonldap::NG::Portal::Main::Auth';

# PROPERTIES

has secret => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        return $_[0]->conf->{openIdSecret}
          || $_[0]->conf->{cipher}->encrypt(0);
    }
);

has listIsWhite => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        ( $_[0]->conf->{openIdIDPList} =~ /^(\d);/ )[0] + 0;
    }
);

has idpList => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        Lemonldap::NG::Common::Regexp::reDomainsToHost(
            ( $_[0]->conf->{openIdIDPList} =~ /^\d;(.*)$/ )[0] );
    }
);

has ua => (
    is      => 'rw',
    lazy    => 1,
    builder => sub {

        # TODO : LWP options to use a proxy for example
        my $ua = Lemonldap::NG::Common::UserAgent->new( $_[0]->{conf} );
        return $ua;
    }
);

# INITIALIZATION

sub init {
    my $self = shift;

    eval { require Net::OpenID::Consumer };
    if ($@) {
        $self->error("Unable to load Net::OpenID::Server: $@");
        return 0;
    }
    return 1;
}

# RUNNING METHODS

sub extractFormInfo {
    my ( $self, $req ) = @_;
    $req->data->{csr} = Net::OpenID::Consumer->new(
        ua    => $self->ua(),
        cache => $self->p->HANDLER->tsv->{refLocalStorage}
          || Cache::FileCache->new,
        args            => $req,
        consumer_secret => $self->conf->{openIdSecret},
        required_root   => $self->conf->{portal},
    );

    my ( $url, $openid );

    # 1. If no openid element has been detected
    $openid = $req->param('openid');
    return PE_FIRSTACCESS
      unless ( $url = $req->param('openid_identifier') or $openid );

    # 2. Check OpenID responses
    if ($openid) {
        my $csr = $req->data->{csr};

        # Remote error
        unless ( $csr->is_server_response() ) {
            $self->userLogger->info('No OpenID valid message found');
            return PE_BADCREDENTIALS;
        }

        # If confirmation is needed
        if ( my $setup_url = $csr->user_setup_url ) {
            $self->userLogger->info('OpenID confirmation needed');
            $req->urldc($setup_url);
            return PE_REDIRECT;
        }

        # Check if user has refused to share his authentication
        elsif ( $csr->user_cancel() ) {
            $self->userLogger->info('OpenID request cancelled by user');
            return PE_FIRSTACCESS;
        }

        # TODO: check verified identity
        elsif ( $req->data->{vident} = $csr->verified_identity ) {
            $req->user( $req->data->{vident}->url() );
            $self->userLogger->notice(
                "OpenID good authentication for $req->{user}");
            $req->{mustRedirect} = 1;
            return PE_OK;
        }

        # Other errors
        else {
            $self->logger->error( 'OpenID error: ' . $csr->err );
            return PE_ERROR;
        }
    }

    # 3. Check if an OpenID url has been submitted
    else {
        my $tmp = $url;
        $tmp =~ m#^https?://(.*?)/#;
        if ( $tmp =~ $self->idpList xor $self->listIsWhite ) {
            $self->userLogger->warn("$url is forbidden for openID exchange");
            return PE_BADPARTNER;
        }
        my $claimed_identity = $req->data->{csr}->claimed_identity($url);

        # Check if url is valid
        unless ($claimed_identity) {
            $self->userLogger->warn( 'OpenID error : ' . $req->{csr}->err() );
            return PE_BADCREDENTIALS;
        }

        # Build the redirection
        $self->logger->debug("OpenID redirection to $url");
        my $req_url   = $req->data->{_url};
        my $check_url = $claimed_identity->check_url(
            return_to => $self->conf->{portal}
              . '?openid=1&'
              . (
                $req_url
                ? build_urlencoded( url => $req_url )
                : ''
              ),
            trust_root     => $self->conf->{portal},
            delayed_return => 1,
        );

        # If UserDB uses OpenID, add "OpenID Simple Registration Extension"
        # compatible fields
        if ( $self->p->getModule( $req, 'user' ) eq 'OpenID' ) {
            my ( @r, @o );
            my %vars = (
                %{ $self->conf->{exportedVars} },
                %{ $self->conf->{openIdExportedVars} }
            );
            while ( my ( $v, $k ) = each %vars ) {
                if ( $k =~ Lemonldap::NG::Common::Regexp::OPENIDSREGATTR() ) {
                    if   ( $v =~ s/^!// ) { push @r, $k }
                    else                  { push @o, $k }
                }
                else {
                    $self->logger->warn(
qq'Unknown "OpenID Simple Registration Extension" field name: $k'
                    );
                }
            }
            my @tmp;
            push @tmp, 'openid.sreg.required' => join( ',', @r ) if (@r);
            push @tmp, 'openid.sreg.optional' => join( ',', @o ) if (@o);
            OpenID::util::push_url_arg( \$check_url, @tmp ) if (@tmp);
        }
        $req->urldc($check_url);
        return PE_REDIRECT;
    }
}

sub authenticate {
    return PE_OK;
}

sub setAuthSessionInfo {
    my ( $self, $req ) = @_;
    $req->{sessionInfo}->{authenticationLevel} =
      $self->conf->{openIdAuthnLevel};
    return PE_OK;
}

sub authLogout {
    return PE_OK;
}

sub getDisplayType {
    return "openidform";
}

1;
