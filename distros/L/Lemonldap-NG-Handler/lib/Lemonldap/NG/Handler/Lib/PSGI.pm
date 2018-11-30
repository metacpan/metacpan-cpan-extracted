package Lemonldap::NG::Handler::Lib::PSGI;

#use 5.10.0;
use Mouse;

#use Lemonldap::NG::Handler::Main qw(:jailSharedVars);

our $VERSION = '2.0.0';

has protection => ( is => 'rw', isa => 'Str' );
has rule       => ( is => 'rw', isa => 'Str' );
has api        => ( is => 'rw', isa => 'Str' );

## @method boolean init($args)
# Initalize main handler
sub init {
    my ( $self, $args ) = @_;
    eval { $self->api->init($args) };
    if ( $@ and not( $self->{protection} and $self->{protection} eq 'none' ) ) {
        $self->error($@);
        return 0;
    }
    unless ( $self->api->checkConf($self)
        or $self->{protection} eq 'none' )
    {
        $self->error(
            "Unable to protect this server ($Lemonldap::NG::Common::Conf::msg)"
        );
        return 0;
    }
    eval { $self->portal( $self->api->tsv->{portal}->() ) };
    my $rule =
      $self->{protection} || $self->api->localConfig->{protection} || '';
    $self->rule(
        $rule eq 'authenticate' ? 1 : $rule eq 'manager' ? '' : $rule );
    return 1;
}

## @methodi void _run()
# Check if protecton is activated then return a code ref that will launch
# _authAndTrace() if protection in on or handler() else
#@return code-ref
sub _run {
    my $self = shift;

    # Override _run() only if protection != 'none'
    if ( !$self->rule or $self->rule ne 'none' ) {
        $self->logger->debug('PSGI app is protected');

        # Handle requests
        # Developers, be careful: Only this part is executed at each request
        return sub {
            return $self->_authAndTrace(
                Lemonldap::NG::Common::PSGI::Request->new( $_[0] ) );
        };
    }

    else {
        $self->logger->debug('PSGI app is not protected');

        # Check if main handler initialization has been done
        unless ( $self->api->tsv ) {
            $self->logger->debug('Checking conf');
            eval { $self->api->checkConf() };
            $self->logger->error($@) if ($@);
        }

        # Handle unprotected requests
        return sub {
            my $req = Lemonldap::NG::Common::PSGI::Request->new( $_[0] );
            my $res = $self->handler($req);
            push @{ $res->[1] }, @{ $req->{respHeaders} };
            return $res;
        };
    }
}

sub status {
    my ( $class, $args ) = @_;
    $args //= {};
    my $self = $class->new($args);
    $self->init($args);

    # Check if main handler initialization has been done
    unless ( %{ $self->api->tsv } ) {
        eval { $self->api->checkConf() };
        $self->logger->error($@) if ($@);
    }
    return sub {
        my $req = Lemonldap::NG::Common::PSGI::Request->new( $_[0] );
        $self->api->status($req);
        return [ 200, [ @{ $req->{respHeaders} } ], [ $req->{respBody} ] ];
    };
}

sub reload {
    my ( $class, $args ) = @_;
    $args //= {};
    my $self = $class->new($args);
    $self->init($args);

    # Check if main handler initialization has been done
    unless ( %{ $self->api->tsv } ) {
        eval { $self->api->checkConf() };
        $self->logger->error($@) if ($@);
    }
    return sub {
        my $req = Lemonldap::NG::Common::PSGI::Request->new( $_[0] );
        $self->api->reload($req);
        return [ 200, [ @{ $req->{respHeaders} } ], [ $req->{respBody} ] ];
    };
}

## @method private PSGI-Response _authAndTrace($req)
# Launch $self->api::run() and then handler() if
# response is 200.
sub _authAndTrace {
    my ( $self, $req, $noCall ) = @_;

    # TODO: handle types
    my $type = $self->api->checkType($req);
    if ( my $t = $req->env->{VHOSTTYPE} ) {
        $type = $t;
    }
    my $tmp = $self->api;
    $tmp =~ s/::\w+$/::/;
    $type = $tmp . $type;
    eval "require $type";
    die $@ if ($@);
    my ( $res, $session ) = $type->run( $req, $self->{rule} );
    $self->portal( $type->tsv->{portal}->() );
    $req->userData($session) if ($session);

    if ( $res < 300 ) {
        if ($noCall) {
            return [ $res, $req->{respHeaders}, [] ];
        }
        else {
            $self->logger->debug('User authenticated, calling handler()');
            $res = $self->handler($req);

            # Insert respHeaders in response only if not already set
            my %hdr1 = @{ $res->[1] };
            my %hdr2 = @{ $req->{respHeaders} };
            foreach ( keys %hdr2 ) {
                unless ( $hdr1{$_} and $hdr2{$_} eq $hdr1{$_} ) {
                    push @{ $res->[1] }, ( $_ => $hdr2{$_} );
                }
            }
        }
        return $res;
    }
    elsif ( $res < 400 ) {
        return [ $res, $req->{respHeaders}, [] ];
    }
    else {
        my %h = $req->{respHeaders} ? @{ $req->{respHeaders} } : ();
        my $s = $type->tsv->{portal}->() . "/lmerror/$res";
        $s =
            '<html><head><title>Redirection</title></head><body>'
          . qq{<script type="text/javascript">window.location='$s'</script>}
          . '<h1>Please wait</h1>'
          . qq{<p>An error occurs, you're going to be redirected to <a href="$s">$s</a>.</p>}
          . '</body></html>';
        $h{'Content-Type'}   = 'text/html';
        $h{'Content-Length'} = length $s;
        return [ $res, [%h], [$s] ];
    }
}

## @method hashRef user()
# @return hash of user data
sub user {
    my ( $self, $req ) = @_;
    return $req->userData
      || { $Lemonldap::NG::Handler::Main::tsv->{whatToTrace}
          || _whatToTrace => 'anonymous' };
}

## @method string userId()
# @return user identifier to log
sub userId {
    my ( $self, $req ) = @_;
    return $req->userData->{ $Lemonldap::NG::Handler::Main::tsv->{whatToTrace}
          || '_whatToTrace' }
      || 'anonymous';
}

## @method boolean group(string group)
# @param $group name of the Lemonldap::NG group to test
# @return boolean : true if user is in this group
sub group {
    my ( $self, $req, $group ) = @_;
    return () unless ( $req->userData->{groups} );
    return ( $req->userData->{groups} =~ /\b$group\b/ );
}

## @method PSGI::Response sendError($req,$err,$code)
# Add user di to $err before calling Lemonldap::NG::Common::PSGI::sendError()
# @param $req Lemonldap::NG::Common::PSGI::Request
# @param $err String to push
# @code int HTTP error code (default to 500)
sub sendError {
    my ( $self, $req, $err, $code ) = @_;
    $err ||= $req->error;
    $self->userLogger->warn( '[' . $self->userId($req) . "] $err" );
    return $self->Lemonldap::NG::Common::PSGI::sendError( $req, $err, $code );
}

1;
