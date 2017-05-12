package Lemonldap::Handlers::ValidateCAS;
use strict;

#####  use ######
use Apache2::URI();
use Apache2::Const;
use Apache2::Connection;
use Apache2::ServerUtil ();
use MIME::Base64;
use LWP::UserAgent;
use Lemonldap::Handlers::MemsessionCAS;
use Lemonldap::Config::Parameters;
use Lemonldap::Config::Initparam;
use Lemonldap::Handlers::Utilities;
use Lemonldap::Handlers::CoreCAS;
use Apache2::Log();
use Apache2::ServerRec();
use CGI ':cgi-lib';
use CGI::Cookie;
use Crypt::CBC;
use URI::Escape;
use Template;
use Sys::Hostname;

#A retirer en prod
use Data::Dumper;
#### common declaration #######
our ( @ISA, $VERSION, @EXPORTS );
$VERSION = '4.0.0';
our $VERSION_LEMONLDAP = "3.1.0";
our $VERSION_INTERNAL  = "3.1.0";

####
####
#### my declaration #########
my %CONFIG;
my %CLIENT;
my $SAVE_MHURI;
my $NOM;
my $UA;
@ISA = qw(LWP::UserAgent );
my $ID_COLLECTED;
my $__STACK;
my %STACK;
my $ID_SAVE;
my $s = Apache2::ServerUtil->server;

### this anonymous function will be call when child dead , it will delete berkeley db file
my $cleanup = sub {
    my $s       = Apache2::ServerUtil->server;
    my $srv_cfg = $s->dir_config;

    my $vhosts = 0;
    my $path_other;
    for ( my $ser = $s->next ; $ser ; $ser = $ser->next ) {
        $vhosts++;
        $path_other = $ser->dir_config('cachedbpath') unless $path_other;

    }

    my $path = $srv_cfg->{'cachedbpath'} || $path_other;
    unlink "$path/$$.db" if $path;

};

Apache2::ServerUtil->server->push_handlers( PerlChildExitHandler => $cleanup );

sub handler {
    my $r = shift;

    # URL des pages d'erreur a ne pas traiter
    if ( $r->uri =~ /^\/LemonErrorPages/ ) {
        return DECLINED;
    }
    ########################
    ##  log initialization
    ########################
    my $log = $r->log;
    my $messagelog;
    my $cache2file;
    my $APACHE_CODE;

# Url a ne pas traiter meme sans conf
# exemple
#   PerlSetVar ExcludeRegex
#(?i)(\.smi|\.swf|\.vrml|\.ico|\.tif|\.gif|\.jpg|\.jpeg|\.js|\.css|\.jpeg|\.png|\.avi|ajaxaction|pngbehavior\.jsp)

    my $regex = $r->dir_config('excluderegex');
    if ( defined $regex ) {
        $log->debug("REGEXP : $regex\n");
        my $uri_input = $r->uri;
        if ( $uri_input =~ /$regex/o ) {
            $log->debug("$uri_input : EXCLUDED\n");
            return DECLINED;
        }
    }

    ########################
    ## collect httpd param
    ########################
    $ID_COLLECTED = '';
    my $con = $r->dir_config();

    $log->info($messagelog);

    my $in_process = $r->dir_config('handlerid');
    if ( $CONFIG{$in_process} ) {
        $log->info(
"$CONFIG{$in_process}->{HANDLERID} XML $CONFIG{$in_process}->{XML} config already in use"
        );
        $ID_COLLECTED = $in_process;
    }
    else {
        my $conf =
          &Lemonldap::Config::Initparam::init_param_httpd( $log, $con );

        #Domain insensible a la casse
        $conf->{DOMAIN} = lc( $conf->{DOMAIN} );

        #/Domain insensible a la casse
        $ID_COLLECTED = $conf->{HANDLERID};
        $CONFIG{$ID_COLLECTED} = $conf;

        ### I will try  retieve HANDLERID from  httpd conf
        if ($ID_COLLECTED) {
            $NOM        = $ID_COLLECTED;
            $messagelog =
"$NOM Phase : handler initialization LOAD HANDLERID httpd.conf:$CONFIG{$ID_COLLECTED}->{HANDLERID} : succeded";
        }
        else {

# I don't find anything for this handler in order to make link with XLM conf section
            $messagelog =
"$NOM: Phase : handler initialization LOAD HANDLERID httpd.conf:failed";
        }
        $log->info($messagelog);

        ############################################

        #  my $ref = $CONFIG{$ID_COLLECTED}->{HANDLERID};
        #   $ref =~  s/\/.+// ;
        $log->info(
"$CONFIG{$ID_COLLECTED}->{HANDLERID}: Phase : handler initialization LOAD XML file $CONFIG{$ID_COLLECTED}->{CONFIGFILE} and $CONFIG{$ID_COLLECTED}->{CONFIGDBPATH}"
        );
        $log->info(
"$CONFIG{$ID_COLLECTED}->{HANDLERID}: domain matched $CONFIG{$ID_COLLECTED}->{DOMAIN}"
        );
        if ( defined( $CONFIG{$ID_COLLECTED}->{CONFIGFILE} ) ) {

            #  my $ref = $CONFIG{$ID_COLLECTED}->{HANDLERID};
            #   $ref =~  s/\/.+// ;
            $log->info(
"$CONFIG{$ID_COLLECTED}->{HANDLERID}: Phase : handler initialization LOAD XML file $CONFIG{$ID_COLLECTED}->{CONFIGFILE} and $CONFIG{$ID_COLLECTED}->{CONFIGDBPATH}"
            );
            $log->info(
"$CONFIG{$ID_COLLECTED}->{HANDLERID}: domain matched $CONFIG{$ID_COLLECTED}->{DOMAIN}"
            );
            $conf =
              &Lemonldap::Config::Initparam::init_param_xml(
                $CONFIG{$ID_COLLECTED} );
            $log->info("$conf->{message}");
        }
        else {
            $conf = {};
        }
        my $c =
          &Lemonldap::Config::Initparam::merge( $CONFIG{$ID_COLLECTED}, $conf );
        $CONFIG{$ID_COLLECTED} = $c;

#  $CONFIG{$ID_COLLECTED}->{KEYIPC} .= "$$.db" if   ($CONFIG{$ID_COLLECTED}->{KEYIPC});

    }

#############################Test de CONFIG####################################
#################################################################################

    ## now I save the context of handler
    $log->info("$CONFIG{$ID_COLLECTED}->{HANDLERID} end of initialization");

    ## addon  for FASTPATTERNS
    if ( ( $CONFIG{$ID_COLLECTED}->{FASTPATTERNS} )
        && !( $CONFIG{$ID_COLLECTED}->{ANONYMOUSFUNC} ) )
    {
        my $sub =
          &Lemonldap::Config::Initparam::built_functionics(
            $CONFIG{$ID_COLLECTED}->{FASTPATTERNS} );
        $CONFIG{$ID_COLLECTED}->{ANONYMOUSFUNC_SRC} = $sub;
        $CONFIG{$ID_COLLECTED}->{ANONYMOUSFUNC}     = eval "$sub";
        $log->info(
"$CONFIG{$ID_COLLECTED}->{HANDLERID}: Phase : FASTPATTERNS TABLE  LOADED : $sub"
        );
    }

    ## addon for multihoming
    if ( ( $CONFIG{$ID_COLLECTED}->{MULTIHOMING} )
        && !( $CONFIG{$ID_COLLECTED}->{SELECTOR} ) )
    {
        my $sub = $CONFIG{$ID_COLLECTED}->{SUB};
        $CONFIG{$ID_COLLECTED}->{SELECTOR_SRC} = $sub;
        $CONFIG{$ID_COLLECTED}->{SELECTOR}     = eval "$sub";
    }

    ################

    ##
    foreach ( keys %{ $CONFIG{$ID_COLLECTED} } ) {
        if ( $_ ne "ENCRYPTIONKEY" ) {
            $log->info("$ID_COLLECTED:$_  => $CONFIG{$ID_COLLECTED}->{$_}");
        }
    }

    ##### end of initialization
    ##### begin  process request
    my $uri     = $r->uri;
    my %param   = Vars();
    my $ticket  = $param{'ticket'};
    my $service = $param{'service'};
    ( my $t_service ) = $service =~ /:\/\/(.+)/;
    $t_service = "/" . $t_service;
    $log->info(
        "$CONFIG{$ID_COLLECTED}->{HANDLERID} :service   requested: $t_service");

    ####  multihoming
    my $MHURI;
    if ( $CONFIG{$ID_COLLECTED}->{MH} ) {

        $MHURI = $CONFIG{$ID_COLLECTED}->{SELECTOR}->($t_service);

        # Stop  process  if no multihosting
        if ( ( $MHURI eq '1' ) || ( !($MHURI) ) ) {
            $log->warn(
"$CONFIG{$ID_COLLECTED}->{HANDLERID} :multihoming failed for  $t_service"
            );
            return DECLINED;
        }

        # load combo config
        ### I switch the context#
        my $old_collected = $ID_COLLECTED;
        $ID_COLLECTED = $MHURI;

        $log->info(
            "$CONFIG{$old_collected}->{HANDLERID} :SWITCH CONFIG $MHURI" );
        if ( $CONFIG{$ID_COLLECTED}->{XML} ) {
            $log->info(
"$CONFIG{$ID_COLLECTED}->{HANDLERID} :MULTIHOMING already in use "
            );
        }
        else {
            my $c =
              &Lemonldap::Config::Initparam::mergeMH( $CONFIG{$old_collected},
                $MHURI );
            $CONFIG{$ID_COLLECTED} = $c;
        }

        $log->info("$CONFIG{$ID_COLLECTED}->{HANDLERID} :MULTIHOMING ON");
    }

    #########################
    #####  for developper ###
    if ( ( $uri =~ /_lemonldap_internal/i ) && ( $con->get('internaldebug') ) )
    {

        $r->content_type('text/html');
        $r->print(<<END);
      <html>
<head><title>lemonldap websso  and CAS server</title></head>
<body>
<h1>Lemonldap websso ans CAS  internal table</h1>
<p>

END

        foreach ( keys %CONFIG ) {
            $r->print("$_<br>\n");
        }
        $r->print("<hr>\n");
        my $tmp = $CONFIG{$ID_COLLECTED};
        $r->print("<h3>$ID_COLLECTED on $$</H3>\n");

        foreach ( keys %$tmp ) {
            if ( ref $tmp->{$_} ) {
                my $t = ref $tmp->{$_};
                $r->print("$_ => $t  reference<br>\n");
            }
            else {
                $r->print("$_ => $tmp->{$_}<br>\n");
            }

        }
        $r->print("</body></html>");

        return OK;
    }

    if (   ( $CONFIG{$ID_COLLECTED}->{FASTPATTERNS} )
        && ( $CONFIG{$ID_COLLECTED}->{ANONYMOUSFUNC}->($uri) eq 'OK' ) )
    {
        $log->info(
"$CONFIG{$ID_COLLECTED}->{HANDLERID} :uri FASTPATTERNS matched: $uri"
        );
        return DECLINED;
    }
    $APACHE_CODE = DECLINED;

    if ( $CONFIG{$ID_COLLECTED}->{ENABLELWP} ) {
        $UA = __PACKAGE__->new;
        $UA->agent( join "/", __PACKAGE__, $VERSION );
        $log->info(
            "$CONFIG{$ID_COLLECTED}->{HANDLERID}:  Build-in proxy actived");
        $r->handler("perl-script");
        $r->push_handlers( PerlHandler => \&proxy_handler );
    }

    ### before to enter in protected area
    ###
 #    return $APACHE_CODE if ( $CONFIG{$ID_COLLECTED}->{DISABLEACCESSCONTROL} );

    ### raz cache level 1
    # is this area protected
    # configuration check
    #

    # collect ticket and service

    $ticket =~ s/ST-//;

    ( my $serveursession, my $principalsession ) =
      Lemonldap::Handlers::MemsessionCAS->get(
        'id'     => $ticket,
        'config' => $CONFIG{$ID_COLLECTED}
      );
 my $servicevalid = $serveursession->{service};
    my $user         = $serveursession->{username};
    my $response;
    my $ok;
    my $cont;
    if ( $servicevalid and $serveursession->{VALID} eq 'TRUE' ) {
        $ok = 1;
    }

    if  ( $CONFIG{$ID_COLLECTED}->{DISABLEACCESSCONTROL} )   {
        $ok=1;
        $cont = 1;
    }
# mes modif  
    

else {

################  verif sur les habiliatation   #############
        my $controle = &Lemonldap::Handlers::CoreCAS::locationRules(
            config  => $CONFIG{$ID_COLLECTED},
            session => $principalsession
        );
        if ( ( !$controle == 0 ) and ( defined $controle->{string} ) ) {
            $cont = 1;
        }
    }
    if (( $ok == 1 )  and ($cont ==1 )) {
        $log->info(
"$CONFIG{$ID_COLLECTED}->{HANDLERID}:$user -- $servicevalid ACCEPTED"
        );
#####   if cas  1 ####
        if ( $uri !~ /validate/i ) {
            $response = "yes\n";
            $response .= "$user\n";
        }
        else {    # cas v2
            $response =
              "<cas:serviceResponse xmlns:cas='http://www.yale.edu/tp/cas'>\n";
            $response .= "\t<cas:authenticationSuccess>\n";
            $response .= "\t\t<cas:user>$user</cas:user>\n";
            $response .= "\t</cas:authenticationSuccess>\n";
            $response .= "</cas:serviceResponse>\n";
        }

        $r->content_type('text/html');
        $r->print;
        $r->print($response);

    }
    else {

        #delivrer reponse non
        $log->info(
            "$CONFIG{$ID_COLLECTED}->{HANDLERID}:$user -- $servicevalid REJETED"
        );

        if ( $uri !~ /validate/i ) {
            $response = "no\n\n";
        }
        else {    # cas v2
            $response =
              "<cas:serviceResponse xmlns:cas='http://www.yale.edu/tp/cas'>\n";
            $response .=
              "\t<cas:authenticationFailure code=\"INVALID_TICKET\">\n";
            $response .= "\t\tTicket ST-$ticket not found\n";
            $response .= "\t</cas:authenticationFailure>\n";
            $response .= "</cas:serviceResponse>\n";
        }

        $r->content_type('text/html');
        $r->print;
        $r->print($response);
    }

    return OK;
}

###########################################################
# _lemonldap_internal  handler                            #
# add at your url /_lemonldap_internal                    #
# eg : http://appli1.demo.net/_lemonldap_internal         #
# in order to dump the internal config of apache children #
# add ?id=handler append another config handler on output #
#                                                         #
###########################################################

############################
#                          #
# end  _lemonldap_internal #
# handler                  #
#                          #
############################

1;

###############################
###  fin etape 1
##############################

=pod

=head1 NAME

Lemonldap::Handlers::CAS - Perl extension for Lemonldap webSSO

=head1 SYNOPSIS

  use Lemonldap::Handlers::Validate   ### Validate service ticket 
  use Lemonldap::Handlers::LoginCASFake  ###  Fake login : user must be egal to password (like CAS server demo) 
  use Lemonldap::Handlers::LogoutCAS ### logout SSO
  
=head1 DESCRIPTION
  
  Lemonldap is a  Reverse-proxy webSSO  and CAS (Central Authentification Service) is an another websso from Yales university .
  CAS acts like Authentification service NOT for authorization service .
  
  These modules give the capacity at a lemonldap to become CAS server.
  So ,  an user will be  authenticate on CAS server AND on lemonldap.
  Then the service ticket is send to serviceValidate the lemonldap can retrieve  all session for user and process to authorization like a lemonldap .
  
=head1 Compatibility with CAS protocol.

Lemonldap manages those parameters :

=over 4

=item  service

=item  renew 

=item  gateway

=back


=head1 INSTALLATION

 You must have an lemonldap websso installed (see doc on lemonldap.objectweb.org)  

 Configures your Apache like this :   
   
  <virtualhost 192.168.204.100>
  servername authen.demo.net
  loglevel debug
  documentroot /usr/local/apache2/htdocs
  alias /portal /usr/local/monapache/portal/
  ErrorLog logs/error_log
  <location /cas/login>
  setHandler modperl
  perlresponsehandler Lemonldap::Handlers::LoginCASFake
  PerlSetVar Domain demo.net
  PerlSetVar Configfile /usr/local/monapache/conf/application.xml
  PerlOptions +GlobalRequest
  </location>
  <location /cas/serviceValidate>
  setHandler modperl
  perlresponsehandler Lemonldap::Handlers::ValidateCAS
  PerlSetVar Domain demo.net
  PerlSetVar HandlerID validate
  PerlSetVar Configfile /usr/local/monapache/conf/application.xml
  PerlOptions +GlobalRequest
  </location>
  <location /cas/logout>
  setHandler modperl
  perlresponsehandler Lemonldap::Handlers::LogoutCAS
  PerlSetVar Domain demo.net
  PerlSetVar Configfile /usr/local/monapache/conf/application.xml
  PerlOptions +GlobalRequest
  </location>
  </virtualhost>

 YOU CAN MIXED lemonldap handler et CAS server 
  
  Your application.xml is like this 
    <domain    id="demo.net"
           Cookie="lemondemo"
           Sessionstore="memcached"
           portal= "http://authen.demo.net/portail/accueil.pl"
           LoginCASPage="/tmp/login.htmlcas"
           LogoutCASPage="/tmp/logout.htmlcas"
           LoginPage="/tmp/login.html"
           ldap_server="192.168.247.30"
           ldap_branch_people="ou=personnes,dc=demo,dc=net"    
         >
         <handler 
                id="validate"
                MultiHoming="pied,tete" 
              />
        <handler id="pied"
             MotifIn="/192.168.204.108\/caspied"
             applcode= "mail"
             pluginpolicy="Lemonldap::Handlers::RowPolicy"
          />
         <handler id="tete"
             MotifIn="/192.168.204.108\/castete"
             disableaccessControl="1"
          />
#### here normal lemonldap application ##### 
        <handler 
                id="appli1" 
                applcode= "APT"
                pluginpolicy="Lemonldap::Handlers::RowPolicy"
                enableLWP="1"
                basepub="http://myappli.demo.net"
                basepriv="http://www.eyrolles.com"
                >
        </handler>

   etc..

    Put your login.html and logout.cas in the good directory (here /tmp) and the right name (here /tmp/login.htmlcas ) 

    See the caspied and castete php examples  (basic and standard CAS  application) 
    
=head1 NOTES 

=over 4

=item   Lemonldapcas is just an emulation of CAS server , use the real CAS server if you have only CAS application .

=item  Lemonldap provides CAS version 1 and version 2 protocol ,if your location of validation  contents the word 'Validate' (eg serviceValidation)  the hanlder will use CAS version 2 overwise  (eg service) it's CAS version 1

=item  Lemonlap DOESN'T provide 'proxycas' service (in process) .
  
=item  Lemonldap shares its sessions  with other lemonldap (unlike CAS server) .

=item  YOU MUST use HTTPS (by mod_ssl) in your apache server 

=back

=head2 EXPORT

None by default.



=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.



=head1 AUTHOR

root, E<lt>germanlinux@yahoo.frE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by germanlinux at yahoo.fr

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.


=cut


