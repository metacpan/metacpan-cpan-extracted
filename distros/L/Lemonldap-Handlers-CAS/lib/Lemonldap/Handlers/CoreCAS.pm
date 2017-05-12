package Lemonldap::Handlers::CoreCAS;
use strict;

#A retirer en prod
use Data::Dumper;
our ( @ISA, $VERSION, @EXPORTS );
$VERSION = '3.1.0';
our $VERSION_LEMONLDAP = "3.1.0";
our $VERSION_INTERNAL  = "3.1.0";

sub locationRules {
    my %param = @_;

    # first retrieve session
    my $id       = $param{'id'};
    my $config   = $param{'config'};
    my $uri      = $param{'uri'};
    my $host     = $param{'host'};
    my $target   = $param{'target'};
    my $_session = $param{'session'};

#my $_session = Lemonldap::Handlers::Session->get ('id' => $id ,
#                                                          'config' => $config)# ;

    #if (keys(%{$_session}) == 0){
    #return 0;
    #}

    my $_trust = Lemonldap::Handlers::Policy->get(
        'session'    => $_session,
        'parameters' => \%param
    );
    my $result   = $_trust->{profil};
    my $response = $_trust->{response};
    my $h        = {
        dn             => $_session->{dn},
        uid            => $_session->{uid},
        string         => $_trust->{profil},
        response       => $_trust->{response},
        clientIPAdress => $_session->{clientIPAdress},
        SessExpTime    => $_session->{SessExpTime}
    };

    return $h;
}

package Lemonldap::Handlers::Session;
use Data::Dumper;

sub get {
    my $class  = shift;
    my %_param = @_;
    $_param{config}->{'SESSIONSTOREPLUGIN'} = 'Lemonldap::Handlers::Memsession'
      unless $_param{config}->{'SESSIONSTOREPLUGIN'};
    my $api = $_param{config}->{'SESSIONSTOREPLUGIN'};
    eval "use $api;";
    my $html = $api->get(%_param);

    #    bless $session, $class;

    return $html;
}

package Lemonldap::Handlers::Policy;

sub get {
    my $class  = shift;
    my %_param = @_;
    $_param{parameters}->{config}->{'PLUGINPOLICY'} =
      'Lemonldap::Handlers::MatrixPolicy'
      unless $_param{parameters}->{config}->{'PLUGINPOLICY'};
    my $api = $_param{parameters}->{config}->{'PLUGINPOLICY'};
    eval "use $api;";
    my $trust = $api->get(%_param);

    #  bless $trust , $class;
    return $trust;
}

1;
