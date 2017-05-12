package Lemonldap::NG::Handler::PSGI::Base;

use 5.10.0;
use Mouse;
use Lemonldap::NG::Handler::SharedConf qw(:tsv :variables :jailSharedVars);

our $VERSION = '1.9.6';

has protection => ( is => 'rw', isa => 'Str' );
has rule       => ( is => 'rw', isa => 'Str' );

has subhandler => (
    is      => 'rw',
    default => 'Lemonldap::NG::Handler::SharedConf'
);

## @method boolean init($args)
# Initalize main handler
sub init {
    my ( $self, $args ) = @_;
    eval { $self->subhandler->init($self) };
    if ( $@ and not $self->{protection} eq 'none' ) {
        $self->error($@);
        return 0;
    }
    unless ( $self->subhandler->checkConf($self)
        or $self->{protection} eq 'none' )
    {
        $self->error(
            "Unable to protect this app ($Lemonldap::NG::Common::Conf::msg)");
        return 0;
    }
    eval { $self->portal( $tsv->{portal}->() ) };
    my $rule = $self->{protection} || $localConfig->{protection} || '';
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
    if ( $self->rule ne 'none' ) {
        $self->lmLog( 'PSGI app is protected', 'debug' );

        # Handle requests
        # Developers, be careful: Only this part is executed at each request
        return sub {
            return $self->_authAndTrace(
                Lemonldap::NG::Common::PSGI::Request->new( $_[0] ) );
        };
    }

    else {
        $self->lmLog( 'PSGI app is not protected', 'debug' );

        # Check if main handler initialization has been done
        unless (%$tsv) {
            $self->lmLog( 'Checking conf', 'debug' );
            eval { $self->subhandler->checkConf() };
            $self->lmLog( $@, 'error' ) if ($@);
        }

        # Handle unprotected requests
        return sub {
            my $req = Lemonldap::NG::Common::PSGI::Request->new( $_[0] );
            my $res = $self->handler($req);
            push @{ $res->[1] }, %{ $req->{respHeaders} };
            return $res;
        };
    }
}

sub status {
    my ( $class, $args ) = @_;
    $args //= {};
    my $self = $class->new($args);

    # Check if main handler initialization has been done
    unless (%$tsv) {
        return $self->abort( $self->error ) unless ( $self->init($args) );
    }
    return sub {
        my $req = Lemonldap::NG::Common::PSGI::Request->new( $_[0] );
        Lemonldap::NG::Handler::API->newRequest($req);
        $self->subhandler->status();
        return [ 200, [ %{ $req->{respHeaders} } ], [ $req->{respBody} ] ];
    };
}

sub reload {
    my ( $class, $args ) = @_;
    $args //= {};
    my $self = $class->new($args);

    # Check if main handler initialization has been done
    unless (%$tsv) {
        return $self->abort( $self->error ) unless ( $self->init($args) );
    }
    return sub {
        my $req = Lemonldap::NG::Common::PSGI::Request->new( $_[0] );
        Lemonldap::NG::Handler::API->newRequest($req);
        $self->subhandler->reload();
        return [ 200, [ %{ $req->{respHeaders} } ], [ $req->{respBody} ] ];
    };
}

## @method private PSGI-Response _authAndTrace($req)
# Launch Lemonldap::NG::Handler::SharedConf::run() and then handler() if
# response is 200.
sub _authAndTrace {
    my ( $self, $req ) = @_;
    Lemonldap::NG::Handler::API->newRequest($req);
    my $res = $self->subhandler->run( $self->{rule} );
    $self->portal( $tsv->{portal}->() );
    $req->userData($datas) if ($datas);

    if ( $res < 300 ) {
        $self->lmLog( 'User authenticated, calling handler()', 'debug' );
        $res = $self->handler($req);
        push @{ $res->[1] }, %{ $req->{respHeaders} };
        return $res;
    }
    elsif ( $res < 400 ) {
        return [ $res, [ %{ $req->{respHeaders} } ], [] ];
    }
    else {
        my %h = $req->{respHeaders} ? %{ $req->{respHeaders} } : ();
        my $s = $tsv->{portal}->() . "?lmError=$res";
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
# @return hash of user datas
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
    $err = '[' . $self->userId($req) . "] $err";
    return $self->Lemonldap::NG::Common::PSGI::sendError( $req, $err, $code );
}

1;
