package Lemonldap::NG::Portal::Plugins::FindUser;

use strict;
use Mouse;
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_OK
  PE_NOTOKEN
  PE_FIRSTACCESS
  PE_TOKENEXPIRED
);

our $VERSION = '2.0.14';

extends qw(
  Lemonldap::NG::Portal::Main::Plugin
  Lemonldap::NG::Portal::Lib::_tokenRule
);

# INITIALIZATION
has ott => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        my $ott =
          $_[0]->{p}->loadModule('Lemonldap::NG::Portal::Lib::OneTimeToken');
        $ott->timeout( $_[0]->{conf}->{formTimeout} );
        return $ott;
    }
);

sub init {
    my ($self) = @_;
    ( my $imp = grep /::Plugins::Impersonation$/, $self->p->enabledPlugins )
      ? $self->addUnauthRoute( finduser => 'provideUser', ['POST'] )
      ->addAuthRoute(
        finduser => 'provideUser',
        ['POST']
      )    # Allow findUser with reAuth
      : $self->logger->warn('FindUser plugin enabled without Impersonation');
    $self->logger->warn('FindUser plugin enabled without searching attribute')
      unless keys %{ $self->conf->{findUserSearchingAttributes} };

    return 1;
}

# RUNNING METHOD
sub provideUser {
    my ( $self, $req ) = @_;
    my $error;

    # Check token
    if ( $self->ottRule->( $req, {} ) ) {
        if ( my $token = $req->param('token') ) {
            unless ( $self->ott->getToken($token) ) {
                $self->userLogger->warn(
                    'FindUser called with an expired/bad token');
                $error = PE_TOKENEXPIRED;
            }
        }
        else {
            $self->userLogger->warn('FindUser called without token');
            $error = PE_NOTOKEN;
        }
    }
    return $self->_sendResult( $req, $error ) if $error;

    $req->steps( ['findUser'] );
    $req->data->{findUserChoice} = $self->conf->{authChoiceFindUser};
    if ( $error = $self->p->process($req) ) {
        $self->logger->debug("Process returned error: $error");
        return $self->_sendResult( $req, $error );
    }
    return $self->_sendResult($req);
}

sub retreiveFindUserParams {
    my ( $self, $req ) = @_;
    my ( $searching, $excluding, @required ) = ( [], [], () );

    $self->logger->debug("FindUser: reading parameters...");
    @$searching = map {
        my ( $key, $value, $null ) = split '#', $_;
        $key =~ s/^(?:\d+_)?//;
        my $param  = $req->params($key) // '';
        my @values = grep s/^(?:\d+_)?//,
          split( $self->conf->{multiValuesSeparator},
            $self->conf->{findUserSearchingAttributes}->{$_} || '' );
        my $select  = scalar @values > 1 && not scalar @values % 2;
        my %values  = @values if $select;
        my $defined = length $param;
        my $regex   = '^(?:' . join( '|', keys %values ) . ')$';
        my $checked =
            $select
          ? $param =~ /$regex/
          : $param =~ /$self->{conf}->{findUserControl}/;
        push @required, $key unless $null;

        # For <select>, accept only set values or empty if allowed
        if ( $defined && $checked ) {
            $self->logger->debug("Append searching parameter: $key => $param");
            { key => $key, value => $param };
        }
        else {
            if ($defined) {
                my $warn =
                  "Parameter $key has been rejected by findUserControl: ";
                $warn .= $select ? $regex : $self->conf->{findUserControl};
                $self->logger->warn($warn);
            }
            ();
        }
    } sort keys %{ $self->conf->{findUserSearchingAttributes} };

    if ( scalar @required ) {
        my $test = 0;
        foreach my $ref (@$searching) {
            foreach (@required) {
                $test++ if $ref->{key} eq $_;
            }
        }
        unless ( scalar @required == $test ) {
            $self->logger->warn( 'A required parameter is missing ('
                  . join( '|', @required )
                  . ')' );
            $searching = [];
        }
    }

    if ( scalar @$searching
        && keys %{ $self->conf->{findUserExcludingAttributes} } )
    {
        $self->logger->debug("FindUser: reading excluding parameters...");
        @$excluding = map {
            my $key = $_;
            map {
                $self->logger->debug("Push excluding parameter: $key => $_");
                {    # Allow multivalued excluding parameters
                    key   => $key,
                    value => $_
                }
              } split $self->conf->{multiValuesSeparator},
              $self->conf->{findUserExcludingAttributes}->{$_};
        } sort keys %{ $self->conf->{findUserExcludingAttributes} };
    }

    return ( $searching, $excluding );
}

sub buildForm {
    my $self = shift;
    my ( $fields, @required ) = ( [], () );

    $self->logger->debug('Building array ref with searching fields...');
    @$fields =
      map {
        my ( $key, $value, $null ) = split '#', $_;
        my @values = split $self->conf->{multiValuesSeparator},
          $self->conf->{findUserSearchingAttributes}->{$_} || $key;
        $key =~ s/^(?:\d+_)?//;
        push @required, $key unless $null;
        my $nbr = scalar @values;
        if ( $nbr > 1 ) {
            if ( $nbr % 2 ) { () }
            else {
                my %hash    = @values;
                my $choices = [];
                $nbr /= 2;
                $self->logger->debug(
                    "Building $key with type 'select' and $nbr entries...");
                @$choices = map {
                    my $k = $_;
                    $k =~ s/^(?:\d+_)?//;
                    { key => $k, value => $hash{$_} }
                } sort keys %hash;
                {
                    select  => 1,
                    key     => $key,
                    value   => $value ? $value : $key,
                    choices => $choices,
                    null    => $null
                };
            }
        }
        else {
            {
                select => 0,
                key    => $key,
                value  => $values[0],
                null   => $null
            };
        }
      } sort keys %{ $self->conf->{findUserSearchingAttributes} };
    $self->logger->debug('Mandatory field(s) required') if scalar @required;

    return ( $fields, scalar @required );
}

sub _sendResult {
    my ( $self, $req, $error ) = @_;

    eval { $self->p->_authentication->setSecurity($req) };
    my $res =
      $error
      ? {
        user  => '',
        error => $error,
      }
      : {
        result => 1,
        user   => ( $req->data->{findUser} ? $req->data->{findUser} : '' )
      };
    $res = {
        %$res,
        ( $req->token   ? ( token   => $req->token )   : () ),
        ( $req->captcha ? ( captcha => $req->captcha ) : () )
    };
    $error ||= PE_FIRSTACCESS;

    return $req->wantJSON
      ? $self->p->sendJSONresponse( $req, $res )
      : $self->p->do( $req, [ sub { $error } ] );
}

1;
