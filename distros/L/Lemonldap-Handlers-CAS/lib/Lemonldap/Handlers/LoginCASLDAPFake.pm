package Lemonldap::Handlers::LoginCASLDAPFake;

use strict;
use warnings;

use Lemonldap::Config::Parameters;
use Lemonldap::Portal::Standard;
use Apache2::Const qw(DONE FORBIDDEN OK SERVER_ERROR REDIRECT);
use Apache2::Log();
use APR::Table;
use Apache2::RequestRec ();
use Apache2::ServerRec();
use Data::Dumper;
use Template;
use URI::Escape;
use CGI ':cgi-lib';
use Apache::Session::Memorycached;
use MIME::Base64;
use Encode qw(encode);
#use Lemonldap::Portal::Session;
use Net::LDAP::Entry;
use IO::File;
our $VERSION = '3.1.0';

my $client_addr;
my $sessCacheRefreshPeriod;
my $log;
my $dump;
my $html;
my $Stack_User;

#my $UserAttributes;
my $Major;
my $MyApplicationXmlFile;
my $MyDomain;
my $LoginPage;
my $RedirectPage;
my $Parameters;
my $Conf_Domain;
my $Login_Url;
my $Cookie_Name;

#my $ipCheck;
#my $inactivityTimeout;
my $Ldap_Server;
my $Ldap_Branch_People;
my $Ldap_Dn_Manager;
my $Ldap_Pass_Manager;
my $Ldap_Port;
my @attrs;
my $Ldap_Search_Bases;
my @base;
my $MemcachedServer;
my $CookieName;
my $line_session;
my $_username;

#my $InactivityTimeout;
#my $Encryptionkey;
my $page_html;
my $Menu;
my $Messages = {
    1 =>
      'Votre connexion a expir&eacute; vous devez vous authentifier de nouveau',
    2 =>
'Les champs &quot;Identifiant&quot; et &quot;Mot de passe&quot doivent &ecirc;tre remplis',
    3 => 'Wrong directory manager account or password',
    4 => 'n\'a pas &eacute;t&eacute; trouv&eacute; dans l\'annuaire',
    5 => 'Mot de passe erron&eacute;',
    6 =>
'Votre adresse IP a &eacute;t&eacute; modifi&eacute;. Vous devez vous authentifier de nouveau',
    7 => 'Serveral Entries found on ldap server for this user',
    8 => 'Bad connection to ldap server',
};

sub my_none {
    return 0;
}

sub my_entry {
}

sub my_credential {

}

sub My_Session {
    my $self     = shift;

    my %session;

    my $entry = $self->{entry};

  $self->{dn}             = $entry->dn();

my @T = ('uid',
          'cn',
          'mail',
         'fonction',
         'affectation',
         'personaltitle',
         'departement',
	  'grade',
	  'fonction',
	  );
	for( @T ) {
	  $session{"$_"} = $entry->get_value("$_") ;
         }
$self->{infosession} = \%session;

}

sub handler {
    my $r = shift;
    my $Stack_User;
    $log = $r->log;
    ###  1 tester le TGT  cookie
    my $entete2 = $r->headers_in();

    #Recuperation du Cookie
    my $idx_tmp      = $entete2->{'Cookie'};
    my $local_cookie = "CASTGC";
    my @tab          = split /;/, $idx_tmp;
    my $cookie;
    my $idrecup;
    my @base;
    foreach (@tab) {
        if (/$local_cookie=([^; ]+)/) {
            $cookie = $_;
        }
    }
    if ($cookie) {
        ($idrecup) = $cookie =~ /TGT-(.+)/;
    }

    if ( $Stack_User->{'AlreadyCreated'} ) {
        undef $Stack_User->{'error'};
    }
    else {
        $log                  = $r->log;
        $MyApplicationXmlFile = $r->dir_config('ConfigFile');
        $MyDomain             = lc( $r->dir_config('Domain') );
        $LoginPage            = $r->dir_config('LoginPage');
        $Major                = $r->dir_config('Organization');
        if ( !defined($Major) ) {
            $Major = "authz_headers";
        }
        $Parameters =
          Lemonldap::Config::Parameters->new( file => $MyApplicationXmlFile, );
        $Conf_Domain = $Parameters->getDomain($MyDomain);
        $Login_Url   = $Conf_Domain->{Portal};
        $Cookie_Name = $Conf_Domain->{Cookie};
        $page_html   = $Conf_Domain->{LoginCASPage};

################  enlevver ca ################

##############################################
        if ( !$html ) {
            my $file;
            open( $file, "<$page_html" );
            local $/;
            $/    = '';
            $html = <$file>;
            close $file;
        }

        $Ldap_Server        = $Conf_Domain->{ldap_server};
        $Ldap_Branch_People = $Conf_Domain->{ldap_branch_people};
        $Ldap_Dn_Manager    = $Conf_Domain->{DnManager};
        $Ldap_Pass_Manager  = $Conf_Domain->{passwordManager};
        $Ldap_Port          = $Conf_Domain->{ldap_port};
        $Ldap_Search_Bases  = $Ldap_Branch_People;
        if ( defined( $r->dir_config('LdapSearchBases') ) ) {
            $Ldap_Search_Bases =
              $r->dir_config('LdapSearchBases') . ":" . $Ldap_Search_Bases;
        }
        @base = split( /\s*:\s*/, $Ldap_Search_Bases );
        $MemcachedServer =
          $Parameters->formateLineHash(
            $Parameters->findParagraph( 'session', 'memcached' )
              ->{SessionParams} );
        $CookieName = $Conf_Domain->{Cookie};
        my $_username;
        $line_session = $Conf_Domain->{DefinitionSession};
        $Stack_User   = Lemonldap::Portal::Standard->new(
            'msg'            => $Messages,
            'setSessionInfo' => \&My_Session,
        );

        $Stack_User->{'AlreadyCreated'} = "true";
        $Stack_User->{line_session} = $line_session;

    }
    # compatibilité encore meilleure  avec lemonldap
    if (!$idrecup) {
    my $lemon_cookie = $CookieName;
    foreach (@tab) {
        if (/$lemon_cookie=([^; ]+)/) {
            $cookie = $_;
        }
    }
    if ($cookie) {
      ($idrecup) = ~ /=(.+)/;
	}
    }


    
    
    
    if ($idrecup) {    ## test itupon memcached
        my %_it;
        tie %_it, 'Apache::Session::Memorycached', $idrecup, $MemcachedServer;
        if ( $_it{username} ) {    # il n existe pas :
            $_username = $_it{username};
        }
        untie %_it;
    }

    my $UrlCode;
    my $UrlDecode;
    my $Erreur;
    my %Params = Vars;
    my $param_it;
    my $buf;
    my $l = Dumper( \%Params );
    my $Retour;
    my $service = $Params{service};

###
    undef $_username if $Params{renew} eq 'true';    ## force re-sign
    if ( defined $_username ) {
        my $service = $Params{service};

        $MemcachedServer->{timeout} = '30';
        $l = Dumper($MemcachedServer);

###########  ticket service ######################
        my %ticket;
        tie %ticket, 'Apache::Session::Memorycached', undef, $MemcachedServer;
        $ticket{service}   = $service;
        $ticket{principal} = $idrecup;
        $ticket{username}  = $_username;
        my $idt = $ticket{'_session_id'};
        untie %ticket;
##########################################################################
        my $redirection = uri_unescape($service);

        if ($redirection) {
            $redirection .= "?ticket=ST-" . $idt;
            print CGI::header( -Refresh => '0; URL=' . $redirection, );
            return DONE;
        }

    }
    if ( $Params{'gateway'} eq 'true' ) {
        my $redirection = uri_unescape($service);
        print CGI::header( -Refresh => '0; URL=' . $redirection, );
        return DONE;
    }

    $Retour = $Stack_User->process(
        'param'  => \%Params,
        'server' => $Ldap_Server,
        'base'   => \@base,
    );
    my $Message = '';
    if ($Retour) {
        $Message = $Retour->message;
        $Erreur  = $Retour->error;
    }
    print STDERR "MOTPASSE $Message\n";
###########################################
    if ( !$Erreur ) {
##  on regarde si it existe
        if ( $Retour->{it} ) {
            ### on le retrouve sur le serveur de session
            my $it_l = $Retour->{it};
            my %_it;

            tie %_it, 'Apache::Session::Memorycached', $it_l, $MemcachedServer;
            if ( !$_it{STATUS} ) {    # il n existe pas :
                $Message .= "<br>$it_l Probleme de login ticket CAS\n";
                $Erreur = 21;
            }
            else {
                if ( $_it{STATUS} ne 'RESERVED' ) {  # il existe mais it pris  :
                    $Message .=
                      "<br> Probleme de ticket login CAS deja utilise \n";
                    $Erreur = 22;
                }
            }
            $_it{username} = 'USED';
            untie %_it;
            delete $Retour->{it};
        }
    }
#########################################################################

    if ($Erreur) {
        if ( !$Retour->{it} ) {

            #generer it token et le reserver
            $MemcachedServer->{timeout} = '60';
            my %_it;
            tie %_it, 'Apache::Session::Memorycached', undef, $MemcachedServer;
            $_it{STATUS} = 'RESERVED';
            $param_it = $_it{'_session_id'};
            untie %_it;
        }
        else { $param_it = $Retour->{it}; }

        if ( $Erreur == 3 ) {

            # Wrong directory manager account or password
            $log->error( "LemonLDAP: " . $Message );
            return Apache2::Const::SERVER_ERROR;
        }
        if ( $Erreur == 4 || $Erreur == 5 ) {

          # If bad login or password, refresh the login page with no information
            $log->info( "LemonLDAP: " . $Message );

            #$Message = 'Authentification echou&eacute;e';
        }

        # Login Page sending
        my $Identifiant = $Retour->user;
        my $secret      = $Retour->secret;
        ( $UrlCode, $UrlDecode ) = $Stack_User->getAllRedirection;
        if ( $Retour->{CAS} ) {
            $UrlDecode = $Retour->{service};
        }
        my $html_ok = $html;
        $html_ok =~ s/%user%/$Identifiant/g;
        $html_ok =~ s/%secret%/$secret/g;
        $html_ok =~ s/%message%/$Message/g;
        $html_ok =~ s/%urldc%/$UrlDecode/g;
        $html_ok =~ s/%urlc%/$UrlCode/g;
        $html_ok =~ s/%it%/$param_it/g;
        $r->content_type('text/html');
        $r->print;
        $r->print($html_ok);
        return DONE;
########## ici page en cas d erreur #############
    }
    else {

        # Sending Redirect to Generic

        my $MyHashSession = $Retour->infoSession;
        my $l             = Dumper($MyHashSession);
###############################################################
        my $idTGT;
        my $service = $Retour->{service};
############ TGT ticket ############################"
###########  ticket service ######################
        my %Session;
        delete $MemcachedServer->{timeout};
        tie %Session, 'Apache::Session::Memorycached', undef, $MemcachedServer;
        $Session{init_service} = $service;
        $Session{username}     = $Retour->user;
        $idTGT                 = $Session{'_session_id'};

        foreach ( keys %{$MyHashSession} ) {
            $Session{$_} = $MyHashSession->{$_} if $MyHashSession->{$_};
        }
        untie %Session;

###########  ticket service ######################
        my %ticket;
        $MemcachedServer->{timeout} = '30';
        $l = Dumper($MemcachedServer);
        tie %ticket, 'Apache::Session::Memorycached', undef, $MemcachedServer;

        $ticket{service}  = $service;
        $ticket{username} = $Retour->user;
        my $idt = $ticket{'_session_id'};
        $ticket{principal} = $idTGT;
        untie %ticket;
##########################################################################
        my $pathlemon  = "/";
        my $pathCookie = "/cas";
        my $dotdomain  = "." . $MyDomain;

        $log->info(
            "Set-Cookie: -name   => $CookieName  -value  => $idt -domain => "
              . ".$dotdomain -path   => $pathCookie" );
        my $CASCookie = CGI::cookie(
            -name   => "CASTGC",
            -value  => "TGT-" . $idTGT,
            -domain => $dotdomain,
            -path   => $pathCookie,
        );

        my $LemonCookie = CGI::cookie(
            -name   => $CookieName,
            -value  => $idTGT,
            -domain => $dotdomain,
            -path   => $pathlemon,
        );

        my $redirection = $Retour->CASservice;
        $redirection = uri_unescape($redirection);

        if ($redirection) {
            $redirection .= "?ticket=ST-" . $idt;
            print CGI::header(
                -Refresh => '0; URL=' . $redirection,
                -cookie  => [ $LemonCookie, $CASCookie ]
            );
            return DONE;
        }

        else {
            $r->content_type('text/html');
            $r->headers_out->add( 'Set-Cookie' => $LemonCookie );
            $r->headers_out->add( 'Set-Cookie' => $CASCookie );
            $redirection="/cas/logged.html";
	    print CGI::header(
                -Refresh => '0; URL='.$redirection,
                -cookie  => [ $LemonCookie, $CASCookie ]
	    );
            return DONE;
        }
    }

}
1;
