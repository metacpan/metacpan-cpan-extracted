package Lemonldap::NG::Common::Logger::Loki;

use strict;
use JSON;
use Lemonldap::NG::Common::UserAgent;
use Sys::Hostname;
use Time::HiRes qw(time);

our $VERSION = '2.21.0';

sub new {
    my ( $class, $conf, %args ) = @_;
    my $self  = bless {}, $class;
    my $level = $conf->{logLevel} || 'info';
    $self->{url} = $conf->{lokiUrl} || 'http://localhost:3100/loki/api/v1/push';
    $self->{label}         = $conf->{lokiLabel} || 'llng';
    $self->{ua}            = Lemonldap::NG::Common::UserAgent->new($conf);
    $self->{j}             = JSON->new->canonical;
    $self->{instance}      = $conf->{lokiInstance} || hostname;
    $self->{env}           = $conf->{lokiEnv}      || 'prod';
    $self->{tenant}        = $conf->{lokiTenant};
    $self->{authorization} = $conf->{lokiAuthorization};
    $self->{tenantHeader}  = $conf->{lokiTenantHeader} || 'X-Scope-OrgID';
    $self->{service} =
      $args{user}
      ? ( $conf->{lokiUserService} || 'auth' )
      : ( $conf->{lokiService} || 'llng' );
    my $show = 1;

    foreach (qw(error warn notice info debug)) {
        if ($show) {
            my $name = $_;
            eval "sub $_ {shift->log('$name', \@_)}";
            die $@ if ($@);
        }
        else {
            eval qq'sub $_ {1}';
        }
        $show = 0 if ( $level eq $_ );
    }
    die "Unknown logLevel $level" if $show;
    return $self;
}

sub log {
    my ( $self, $level, $message ) = @_;
    my $logEntry = {
        streams => [ {
                stream => {
                    job      => $self->{label},
                    instance => $self->{instance},
                    level    => $level,
                    env      => $self->{env},
                    service  => $self->{service},
                },
                values =>
                  [ [ sprintf( "%19d", time * 1000000000 ), $message ] ],
            },
        ],
    };
    my $req = HTTP::Request->new(
        POST => $self->{url},
        [
            'Content-Type' => 'application/json',
            (
                $self->{authorization}
                ? ( 'Authorization' => $self->{authorization} )
                : ()
            ),
            (
                $self->{tenant} ? ( $self->{tenantHeader} => $self->{tenant} )
                : ()
            )
        ],
        $self->{j}->encode($logEntry)
    );
    my $response = $self->{ua}->request($req);
    unless ( $response->is_success ) {
        print STDERR "Unable to push log to loki\nMessage: $message\nResponse: "
          . $response->status_line . "\n";
    }
}

1;
