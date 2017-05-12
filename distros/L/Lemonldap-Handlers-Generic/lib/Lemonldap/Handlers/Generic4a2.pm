package Lemonldap::Handlers::Generic4a2;
use strict;

#####  use ######
use Apache2::URI();
use Apache2::Const;
use Apache2::Connection;
use Apache2::ServerUtil ();
use MIME::Base64;
use LWP::UserAgent;
use Lemonldap::Config::Parameters;
use Lemonldap::Config::Initparam;
use Lemonldap::Handlers::Utilities;
use Lemonldap::Handlers::Core;
use Apache2::Log();
use Apache2::ServerRec();
use CGI ':cgi-lib';
use CGI::Cookie;
use Crypt::CBC;
use URI::Escape;
use Template;
use Sys::Hostname;
#A retirer en prod
#use Data::Dumper;
#### common declaration #######
our( @ISA, $VERSION, @EXPORTS );
$VERSION = '3.5.8';
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


    my $regex = $r->dir_config('excluderegex') ;  
    if (defined $regex) {
        $log->debug("REGEXP : $regex\n");
        my $uri_input = $r->uri;
        if ($uri_input=~ /$regex/o) {
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
        my $conf = &Lemonldap::Config::Initparam::init_param_httpd($log,$con);
#Domain insensible a la casse 		 
$conf->{DOMAIN} = lc($conf->{DOMAIN});

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
        if ( defined ($CONFIG{$ID_COLLECTED}->{CONFIGFILE}) )
        {
            #  my $ref = $CONFIG{$ID_COLLECTED}->{HANDLERID};
            #   $ref =~  s/\/.+// ;
            $log->info("$CONFIG{$ID_COLLECTED}->{HANDLERID}: Phase : handler initialization LOAD XML file $CONFIG{$ID_COLLECTED}->{CONFIGFILE} and $CONFIG{$ID_COLLECTED}->{CONFIGDBPATH}");
            $log->info("$CONFIG{$ID_COLLECTED}->{HANDLERID}: domain matched $CONFIG{$ID_COLLECTED}->{DOMAIN}" );
            $conf = &Lemonldap::Config::Initparam::init_param_xml( $CONFIG{$ID_COLLECTED});
            $log->info("$conf->{message}");
        }else
        {
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
          &Lemonldap::Config::Initparam::built_functionics
          ( $CONFIG{$ID_COLLECTED}->{FASTPATTERNS} );
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
    my $uri = $r->uri;

    $log->info("$CONFIG{$ID_COLLECTED}->{HANDLERID} :uri  requested: $uri");

    ####  multihoming 
    my $MHURI;
    if ( $CONFIG{$ID_COLLECTED}->{MH} ) {
        $MHURI = $CONFIG{$ID_COLLECTED}->{SELECTOR}->($uri);

        # Stop  process  if no multihosting
        if ( ( $MHURI eq '1' ) || ( !($MHURI) ) ) {
            $log->warn(
            "$CONFIG{$ID_COLLECTED}->{HANDLERID} :multihoming failed for  $uri"
            );
            return DECLINED;
        }

        # load combo config   
        ### I switch the context#
        my $old_collected = $ID_COLLECTED;
        $ID_COLLECTED = $MHURI;

        $log->info("$CONFIG{$old_collected}->{HANDLERID} :SWITCH CONFIG $MHURI"
        );
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
 #   if ( $uri =~ /_lemonldap_internal/i ) {
        $r->handler("perl-script");
        $r->push_handlers( PerlHandler => \&_lemonldap_internal );
        return OK;
    }

    if ( ( $CONFIG{$ID_COLLECTED}->{FASTPATTERNS} )
      && ( $CONFIG{$ID_COLLECTED}->{ANONYMOUSFUNC}->($uri) eq 'OK' ) )
    {
        $log->info("$CONFIG{$ID_COLLECTED}->{HANDLERID} :uri FASTPATTERNS matched: $uri"
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
	$APACHE_CODE= OK ; 
    }

    ### before to enter in protected area 
    ###
    return $APACHE_CODE if ( $CONFIG{$ID_COLLECTED}->{DISABLEACCESSCONTROL} );

    ### raz cache level 1 
    # is this area protected
    # configuration check
    #
    #
    # first check cookie

    # AUTHENTICATION
    # cookie search
    #for apache 2 
    my $__cookie;
    my $entete2 = $r->headers_in();
    my $host    = $entete2->{Host};

    #<Recuperation de l'adresse IP cliente>
    		 my $connection  = $r->connection();
    		 my $client_addr = $connection->remote_ip();
    #</Recuperation de l'adresse IP cliente>

    #<Modification pour test time out> 
    		 #Recuperation du Cookie		 
   		  my $idx_tmp = $entete2->{'Cookie'};
    		 my $idx;
    		 my $timeout;

    		 if ( defined( $CONFIG{$ID_COLLECTED}->{INACTIVITYTIMEOUT} )
      		 		 && $CONFIG{$ID_COLLECTED}->{INACTIVITYTIMEOUT} != 0 )
    		 {

        ( $idx, $timeout ) =
          Lemonldap::Handlers::Utilities::get_my_timeout(
          $CONFIG{$ID_COLLECTED}, $idx_tmp );

    		 }
    		 else {
        		 $idx = $idx_tmp;
    		 }

    #</Modification pour test time out> 

    ( my $id, my $cook ) =
      Lemonldap::Handlers::Utilities::cleanupcookie( $CONFIG{$ID_COLLECTED},$idx );

    if ( $cook ne $idx ) {

        ### I must rewrite cookie header) 
        $r->headers_in->unset('Cookie');
        $r->headers_in->add( 'Cookie' => $cook ) if $cook;
    }

    $__cookie = $idx;

    # Load id value from cookie
    #NEW if the config is 'softcontrol'  no need cookie 
    if ( ( !( $CONFIG{$ID_COLLECTED}->{SOFTCONTROL} ) and !$id ) ) {

        # No cookie found: redirect to portal
        $messagelog =
          "$CONFIG{$ID_COLLECTED}->{HANDLERID} : No cookie found for "
          . $r->uri;
        $log->info($messagelog);
        return &Lemonldap::Handlers::Utilities::goPortal( $r,
          $CONFIG{$ID_COLLECTED}, 'c' );
    }
    my $label = $id || 'SOFTCONTROL';
    $log->info("$CONFIG{$ID_COLLECTED}->{HANDLERID}: id session : $label");

    #Verification du time out

    if (!( $CONFIG{$ID_COLLECTED}->{SOFTCONTROL} ) and defined( $CONFIG{$ID_COLLECTED}->{INACTIVITYTIMEOUT} )
      and $CONFIG{$ID_COLLECTED}->{INACTIVITYTIMEOUT} != 0 )
    {
        if ( time() > $timeout ) {
            $log->warn("SESSION EXPIRED FOR INACTIVITY");
            if ($CONFIG{$ID_COLLECTED}->{URLCDATIMEOUT}) {
	        return &Lemonldap::Handlers::Utilities::goPortal( $r,
              $CONFIG{$ID_COLLECTED}, 'x', $id );
	    
	    }  else 
	            {
	    return &Lemonldap::Handlers::Utilities::goPortal( $r,
              $CONFIG{$ID_COLLECTED}, 't', $id );
        }
	}
    }

    # SESSIONS CACHE
########################################################################################################################
    #<SEARCH IN CACHE LEVEL 1>
  
    my $ligne_h;
    my $sessExpTime;
   
    return $APACHE_CODE unless ($id);
    if ( $id ne $ID_SAVE ) {
        %CLIENT = '';
    }
    $ID_SAVE = $id;
    my $cache1key;
    #key of level one cache
if ( $CONFIG{$ID_COLLECTED}->{CLIENTIPCHECK} ) {
		 $cache1key = "$id#$ID_COLLECTED#$client_addr";
    }else{
		 $cache1key = "$id#$ID_COLLECTED";
}
    #value of level one cache
     $ligne_h = $CLIENT{$cache1key};

    if ($ligne_h) {
		   if ( defined( $CONFIG{$ID_COLLECTED}->{SESSCACHEREFRESHPERIOD} ) ) {
		 		 my @tab = split ( ":", $ligne_h );
		 		 $sessExpTime = $tab[2];
		   }
        $log->info("$CONFIG{$ID_COLLECTED}->{HANDLERID}: match in cache level 1 for $cache1key") if $ligne_h;
	
    #</SEARCH IN CACHE LEVEL 1>
########################################################################################################################
    #<SEARCH IN CACHE LEVEL 2>
    }
    else {
		 
        # Level 2 test by IPC
        $log->info("$CONFIG{$ID_COLLECTED}->{HANDLERID}: No match in cache level 1 for $cache1key");
        if ( $CONFIG{$ID_COLLECTED}->{CACHEDBPATH} ) {
            my $message;
            ( $ligne_h, $message ) =
              &Lemonldap::Handlers::Utilities::cache2( $CONFIG{$ID_COLLECTED}
              ->{CACHEDBPATH}, $$, $cache1key );
            $__STACK = 1;
            $log->info("$CONFIG{$ID_COLLECTED}->{HANDLERID}:$message");
        if ( $ligne_h && defined( $CONFIG{$ID_COLLECTED}->{SESSCACHEREFRESHPERIOD}  )) {
		         my @tab2 = split ( ":", $ligne_h );
		 		 $sessExpTime = $tab2[2];
        }
		 
		 }
		 
     #</SEARCH IN CACHE LEVEL 2>
###################################################################################################################################
     #<SEARCH IN CACHE LEVEL 3>
        unless ($ligne_h) {    # no match in cache level 1 and 2
            $log->info("$CONFIG{$ID_COLLECTED}->{HANDLERID} :  Search  in cache level 3 for $id");
            my $dn;
            my $etat = 0;    # 0 = denied ,NULL = not found other values is OK ;
        
		     #Search in the servers memcached
		     my $controle = &Lemonldap::Handlers::Core::locationRules(
              config => $CONFIG{$ID_COLLECTED},
              id     => $id,
              uri    => $uri,
              host   => $host,
            );
		 
		    
            if ( $controle == 0 ) {
		return &Lemonldap::Handlers::Utilities::goPortal( $r, $CONFIG{$ID_COLLECTED}, 't', $id );
            }
 
    		 		 
          		 
            if ( !defined( $controle->{string} ) ) {
                if ( $controle->{response} ) {
                    $log->notice("$CONFIG{$ID_COLLECTED}->{HANDLERID}: controle: $controle->{dn}  $uri :DENIED ($controle->{response}) ");
                    return $controle->{response};
                }
                $log->notice(
                  "$CONFIG{$ID_COLLECTED}->{HANDLERID}: $id ERROR TIMEOUT ");
                return &Lemonldap::Handlers::Utilities::goPortal( $r, $CONFIG{$ID_COLLECTED}, 't', $id );
            }
		
		     #Verification of the remote adress

	    if ( ($controle->{clientIPAdress} ne $client_addr) && $CONFIG{$ID_COLLECTED}->{CLIENTIPCHECK} ) {
                 $log->notice("$CONFIG{$ID_COLLECTED}->{HANDLERID}: $id ERROR WRONG IP : $client_addr");
                 return &Lemonldap::Handlers::Utilities::goPortal($r, $CONFIG{$ID_COLLECTED}, 'i', $id);
            }

		 
            my $header = &Lemonldap::Handlers::Core::getHeader(
              config => $CONFIG{$ID_COLLECTED},
              dn     => $controle->{dn},
              uid    => $controle->{uid},
              profil => $controle->{string},
            );
		 
            $ligne_h = $header->{decoded};

             if ( defined( $CONFIG{$ID_COLLECTED}->{SESSCACHEREFRESHPERIOD} ) ) {
		 		 		 $sessExpTime = $controle->{SessExpTime};		 
		 		 		 $ligne_h = $ligne_h.":".$sessExpTime;
            
		      }
		 
            		 $log->info("$CONFIG{$ID_COLLECTED}->{HANDLERID}: $cache1key saving in cache level 2");
		 
            $__STACK = 0;
            &Lemonldap::Handlers::Utilities::save_session( $cache1key,$ligne_h );
		 
            $log->info("$CONFIG{$ID_COLLECTED}->{HANDLERID}: SESSION FIND IN CACHE 3 FOR ID $id");

            $log->info("$CONFIG{$ID_COLLECTED}->{HANDLERID}: controle: $controle->{dn} $uri :ACCEPTED");

        }

        #</SEARCH IN CACHE LEVEL 3>

    #<UPDATING CACHE LEVEL 1>
        $CLIENT{$cache1key} = $ligne_h;
        $log->info("$CONFIG{$ID_COLLECTED}->{HANDLERID}: $cache1key saving in cache level 1");
    }

    #</UPDATING CACHE LEVEL 1>
my $titi;
    #<REFRESH LDAP>

if ( defined( $CONFIG{$ID_COLLECTED}->{SESSCACHEREFRESHPERIOD} ) ) {
		my $ttl;
		if ( defined( $CONFIG{$ID_COLLECTED}->{INACTIVITYTIMEOUT} ) ) { 
			$ttl = $CONFIG{$ID_COLLECTED}->{SESSCACHEREFRESHPERIOD} + $CONFIG{$ID_COLLECTED}->{INACTIVITYTIMEOUT};
		 }else{
			$ttl = $CONFIG{$ID_COLLECTED}->{SESSCACHEREFRESHPERIOD} * 2;
		}
		 (my $return_code,my $HashSession,my $profil,my $reponse) = &Lemonldap::Handlers::Core::Check_Refresh(     config => $CONFIG{$ID_COLLECTED},
		 		 		 		 		 		 		 		 		 		 		               id     => $id,
              		 		 		 		 		 		 		 		 		 		 		       uri    => $uri,
             		 		 		 		 		 		 		 		 		 		 		       host   => $host,
		 		 		 		 		 		 		 		 		 		 		 		       logs   => $log,
		 		 		 		 		 		 		 		 		 		 		 		       ExpTime => $sessExpTime);

		 if ($return_code == -1){

		 		 return &Lemonldap::Handlers::Utilities::goPortal( $r, $CONFIG{$ID_COLLECTED}, 't', $id );
		 }
		 
		 if ($return_code != 0){


		 		 $log->info("$CONFIG{$ID_COLLECTED}->{HANDLERID}: SessExpTime expired. Caches need to be refresh at all level");
		 		 if ($return_code == 1){
		 		 		 #Rafraichissement LDAP
		 		 		 #A modifier pour les versions ulte�riers
		 		 		 #
		 		 		 #

		 		 		$HashSession->{SessExpTime}= &Lemonldap::Handlers::Utilities::fake_refresh_ldap($HashSession,$CONFIG{$ID_COLLECTED},$ttl);
						 $titi = $HashSession->{SessExpTime};

		 		 		 $log->info("$CONFIG{$ID_COLLECTED}->{HANDLERID}: Reninitializing the SessExpTime on the central server memcached");



		 		 }

#Updating cache 3
               			&Lemonldap::Handlers::Utilities::save_memcached_local($HashSession,$CONFIG{$ID_COLLECTED}->{SERVERS},$ttl);
#Creation du Header

                                 my $new_header = &Lemonldap::Handlers::Core::getHeader(
                                                                         config => $CONFIG{$ID_COLLECTED},
                                                                         dn     => $HashSession->{dn},
                                                                         uid    => $HashSession->{uid},
                                                                         profil => $profil,
                                                                         );

               			$ligne_h = $new_header->{decoded};
               			$ligne_h = $ligne_h.":".$HashSession->{SessExpTime};

				

#Updating cache 1

                                $CLIENT{$cache1key} = $ligne_h;

#Updating cache 2

                                &Lemonldap::Handlers::Utilities::save_session( $cache1key,$ligne_h );



				if (!defined($profil)) {
                                        if ( defined($reponse) ) {	
                                           $log->notice("$CONFIG{$ID_COLLECTED}->{HANDLERID}: controle: $HashSession->{dn}  $uri :DENIED ($reponse) ");
				           return $reponse;
                                        }
                                        $log->notice("$CONFIG{$ID_COLLECTED}->{HANDLERID}: $id ERROR TIMEOUT ");
                                        return &Lemonldap::Handlers::Utilities::goPortal( $r, $CONFIG{$ID_COLLECTED}, 't', $id );
                                }

		 
	 				
		 		 		 $log->notice("$CONFIG{$ID_COLLECTED}->{HANDLERID}: Caches has been refresh");

		 }
    }
    #</REFRESH LDAP>


    #  all is done for this phase  we can cache the header .
    # now we must up date the cache level 1 and 2 (IPC)

    ##### I must to resume here (the three caches )
    ####
    ###
    #
    ###  add user in access log
    if ( defined( $CONFIG{$ID_COLLECTED}->{SESSCACHEREFRESHPERIOD} ) ) {
        my @tab = split ( ":", $ligne_h );
        $ligne_h = $tab[0] . ":" . $tab[1];
    }

    my $_header = &Lemonldap::Handlers::Core::forgeHeader(
      config => $CONFIG{$ID_COLLECTED},
      line   => $ligne_h,
    );
my $sep = "_";

    #<TEST TIMEOUT>
    if ( defined $CONFIG{$ID_COLLECTED}->{INACTIVITYTIMEOUT} ) {

        my $inact = $CONFIG{$ID_COLLECTED}->{INACTIVITYTIMEOUT};
        if ( $inact != 0 ) {	 		  		 
				
		     my $new_time = time() + $inact;
            if ( defined( $CONFIG{$ID_COLLECTED}->{ENCRYPTIONKEY} ) ) {
                my $cle   = $CONFIG{$ID_COLLECTED}->{ENCRYPTIONKEY};
                my $ciphe = new Crypt::CBC(
                  -key    => $cle,
                  -cipher => 'Blowfish',
                  -iv     => 'lemonlda',
                  -header => 'none'
                );
                $new_time = $ciphe->encrypt_hex($new_time);
            }

            my $val_test = $id . $sep . $new_time;
            my $name     = $CONFIG{$ID_COLLECTED}->{COOKIE};
            my $domain   = "." . $CONFIG{$ID_COLLECTED}->{DOMAIN};

            my $new_cookie = CGI::Cookie->new(
              -name   => $name,
              -value  => $val_test,
              -domain => $domain,
              -path   => "/",
            );

            $r->headers_out->add( 'Set-Cookie' => $new_cookie );
            $log->info("Timeout re-initialized");
        }
        else {
            $log->info(
              "The inactivity timeout  has been positionned at O!!!!");
        }
    }
    else {
        $log->info(
          "The inactivity timeout hasn't been set." );
    }

    #</TEST TIMEOUT>

    if ($_header) {
        $r->user( $_header->{user} ) if $_header->{user};
        my $hcode = $_header->{content};

        ###############  We can insert the header #####################

        $r->headers_in->add( $_header->{header} => $hcode );
        $log->debug(
		 "$CONFIG{$ID_COLLECTED}->{HANDLERID}: header genered :$_header->{header} => $hcode "
        );
        $log->info(
        "$CONFIG{$ID_COLLECTED}->{HANDLERID}: header before encoding: $_header->{decoded}"
        );
        $log->debug(
          "$CONFIG{$ID_COLLECTED}->{HANDLERID}: header after encoding: $hcode"
        );
    }
    else {
        $log->info("$CONFIG{$ID_COLLECTED}->{HANDLERID}:no header genered ");

    }

    ### supprimer en prod ####  
    # my $l = Dumper (%CONFIG );
    return $APACHE_CODE

}

################
#              #
# end handler  #
#              #
################

####################################
# proxy_handler :the lwp engine    #
#                                  #
####################################
#TODO : timeout
#       500 return code
#       motifout instead motifin   
sub proxy_handler {
    my $r = shift;

    # Transformation: GET /index.html becomes http://servername/index.html
    # $url contains the real value (hided server)
    # $url_init contains the asked value
    #add this in order to log
    my $log     = $r->log;
    my $url     = $r->uri;
    my $entete2 = $r->headers_in();
    my $HOST    = $entete2->{'Host'};
    my $flag    = 0;
    my $host_target;
    $url = "/" unless $url;

    # replace formatin by formatout 
    #
    $log->info("$CONFIG{$ID_COLLECTED}->{HANDLERID}: LWP ENGINE URL $url");
    $log->info("$CONFIG{$ID_COLLECTED}->{HANDLERID}: LWP ENGINE HOST $HOST");

    if ( $CONFIG{$ID_COLLECTED}->{MOTIFOUT} ) {
        if ( $CONFIG{$ID_COLLECTED}->{MOTIFOUT} =~ /ANYWHERE/ ) {
            $flag = 1;

            $r->headers_in->unset('Accept-Encoding');
            ( $host_target, my $suite ) = $url =~ /\/(.+?)\/(.+)/;
            ($host_target) = $url =~ /\/(.+)/ unless $host_target;
            $host_target =~ s/\/$//;

            #$host=~ s/_/\./g; 
            $suite = "/" unless $suite;
            $suite = "/" . $suite unless $suite =~ /^\//;
            $suite = "/" unless $suite;
            $url   = $suite;

            $log->info(
"$CONFIG{$ID_COLLECTED}->{HANDLERID}:LWP ANYWHERE DESTINATION actived $host_target --   $suite "
            );
            $CONFIG{$ID_COLLECTED}->{BASEPRIV} = "http://$host_target";
        }
        else {
	if  ($CONFIG{$ID_COLLECTED}->{MOTIFOUT} eq '/' )  {
    $url =~
s/$CONFIG{$ID_COLLECTED}->{MOTIFIN}//;
      }  else {
  $url =~
s/$CONFIG{$ID_COLLECTED}->{MOTIFIN}/$CONFIG{$ID_COLLECTED}->{MOTIFOUT}/;
              }
   }
   }
    $url .= "?" . $r->args if ( $r->args );
    my $url_init = $CONFIG{$ID_COLLECTED}->{BASEPUB} . $url;
    my $uuu      = $url;
    $url = $CONFIG{$ID_COLLECTED}->{BASEPRIV} . $uuu;
    $log->info( "$CONFIG{$ID_COLLECTED}->{HANDLERID}: URLPRIV ACTIVED: $url  
                     URLPUB REQUESTED : $url_init"
    );

    my $request = HTTP::Request->new( $r->method, $url );
    $r->headers_in->do( sub {
          $request->header(@_);
          1;
      } );

    # copy POST data, if any
    if ( $r->method eq 'POST' ) {
        my $len =0;
        $len = $r->headers_in->{'Content-length'};
        my $buf='';
	if ($len < 0 ) { $len=0;} 
        if ($len > 0) {
        $r->read( $buf, $len );
          }
        $request->content($buf);
        $request->content_type( $r->headers_in->{'Content-Type'} );
    }

    ###begin: some modification like mod_proxy does
    if ( $request->header('Host') ) {
        my $host = $request->header('Host');
        ( my $priv ) = $CONFIG{$ID_COLLECTED}->{BASEPRIV} =~ /:\/\/(.+)/;
        ( my $pub ) = $CONFIG{$ID_COLLECTED}->{BASEPUB} =~ /:\/\/(.+)/;
        $host =~ s/$pub/$priv/;
        $host =~ s/:\d+$// ;

        $request->header( 'Host' => $host );

#DEBUG 16/07/2007

#print STDERR "DEBUG ADONIS:  PRIV: $priv PUB:  $pub  HOST_TARGET : $host_target " ;
#
#END

    }

    ### here I modify keep alive by close
    #    if ($request->header('Connection')){
    #          $request->header('Connection' => 'close');
    #    }
    #    if ($request->header('Keep-Alive')){
    #          $request->header('Keep-Alive' => '');
    #    }

    my $messagelog =
      "$CONFIG{$ID_COLLECTED}->{HANDLERID}: request " . $request->as_string();
    $log->info($messagelog);
#> modif du 20/04/06  reverse  condition 
    if ( !$CONFIG{$ID_COLLECTED}->{CHASEREDIRECT} ) {
        $log->info(
          "$CONFIG{$ID_COLLECTED}->{HANDLERID}: LWP CHASEREDIRECT  DESACTIVED(DEFAULT)");
        my @tt = ('HEAD');
        $UA->requests_redirectable( \@tt );
        }  else 
       {
        my @tt = ('HEAD','GET');
        $UA->requests_redirectable( \@tt );
        $log->info(
          "$CONFIG{$ID_COLLECTED}->{HANDLERID}: LWP CHASEREDIRECT ACTIVED");
         
       }  

    ###  deal this lwptimeout :
    if ( $CONFIG{$ID_COLLECTED}->{LWPTIMEOUT} ) {
        $log->info(
"$CONFIG{$ID_COLLECTED}->{HANDLERID}:LWP TIMEOUT :$CONFIG{$ID_COLLECTED}->{LWPTIMEOUT} armed"
        );
        $UA->timeout( $CONFIG{$ID_COLLECTED}->{LWPTIMEOUT} );
    }

    # LWP proxy
    # I 'll forward  on an  external proxy
    if ( $CONFIG{$ID_COLLECTED}->{APPLPROXY} ) {
        $log->info(
"$CONFIG{$ID_COLLECTED}->{HANDLERID}:OUTPUT PROXY:$CONFIG{$ID_COLLECTED}->{APPLPROXY}"
        );

        $UA->proxy( http => $CONFIG{$ID_COLLECTED}->{APPLPROXY} );
    }
    if ( $url =~ /_lemonldap_debug/ ) {
        $r->content_type('text/html');
        $r->print(<<END);
		       <html>
		      <head><title>lemonldap websso</title></head>
		      <body>
		      <h1>Lemonldap websso headers</h1>
		      <p>
END
        my $l = $request->as_string();
        $l =~ s/\n/<br>/g;
        $r->print($l);
        $r->print( "</body>
             </html>" );

        return OK;
    }

    ####################################
    # here implementation              #
    # https gateway                    #
    #                                  #
    #                                  #
    #                                  #
    ####################################
    #
    if ( $CONFIG{$ID_COLLECTED}->{HTTPS} ) {

        # on veut faire du https avec le serveur a proteger
        eval "use Crypt::SSLeay;";

        $ENV{HTTPS_VERSION} = '3';
        if ( $CONFIG{$ID_COLLECTED}->{AUTH} ) {

            # lemonldap doit s'authentifier par certificat
            if ( $CONFIG{$ID_COLLECTED}->{PKCS12} ) {

                # la presence de pkcs12 est testee en premier
                $ENV{HTTPS_PKCS12_FILE}     = $CONFIG{$ID_COLLECTED}->{PKCS12};
                $ENV{HTTPS_PKCS12_PASSWORD} =
                  $CONFIG{$ID_COLLECTED}->{PKCS12_PWD};
            }
            else {
                $ENV{HTTPS_CERT_FILE} = $CONFIG{$ID_COLLECTED}->{CERT_FILE};
                $ENV{HTTPS_KEY_FILE}  = $CONFIG{$ID_COLLECTED}->{KEY_FILE};
            }
        }
    }

    #   
    ####################  
    # fin https gateway#
    ####################
    #
    #
    my $response = $UA->request($request);

    ### begin: somes bad requests have bad header .
    $messagelog =
      "$CONFIG{$ID_COLLECTED}->{HANDLERID}: response "
      . $response->as_string();

    $log->info($messagelog);

    my $content = $response->header('Content-type');
    $content = 'text/html' unless $content;
    $content =~ s/,/;/g;

    ### end: somes bad requests have bad header .
    $r->content_type($content);

    ### begin: I correct on the fly some incomming header like mod_proxy does
    if ( $response->header('Location') ) {
        my $h = $response->header('Location');
    ###  In case of multihoming context , sometimes location is  not a well know location ,so I must adjust this handly 
         if ($CONFIG{$ID_COLLECTED}->{SOURCEREDIRECTION}) {
         $h=~ s/$CONFIG{$ID_COLLECTED}->{SOURCEREDIRECTION}/$CONFIG{$ID_COLLECTED}->{TARGETREDIRECTION}/;
          }

#Patch 16/07/2007 pour traitement du port dans le Location des 302

my $trait_loc;
	
	if (( $h =~ /:\d+$/) && ($CONFIG{$ID_COLLECTED}->{BASEPRIV} =~ /:\d+$/ ) )  {
        $h =~
         s/$CONFIG{$ID_COLLECTED}->{BASEPRIV}/$CONFIG{$ID_COLLECTED}->{BASEPUB}/
          unless $flag;
	$trait_loc = "Port dans Location ET Basepriv \n" ;
	}elsif ( !( $h =~ /:\d+$/) && ! ($CONFIG{$ID_COLLECTED}->{BASEPRIV} =~ /:\d+$/ ) ) {

        $h =~ s/$CONFIG{$ID_COLLECTED}->{BASEPRIV}/$CONFIG{$ID_COLLECTED}->{BASEPUB}/
		           unless $flag;
       $trait_loc = "Aucun Port\n " ;	
	} else {
		
	(my $privreduct ) = $CONFIG{$ID_COLLECTED}->{BASEPRIV} =~ /^(.+):\d+$/ ;
	   $h =~ s/$privreduct/$CONFIG{$ID_COLLECTED}->{BASEPUB}/
			                     unless $flag;
        $trait_loc = "Port dans Basepriv uniquement \n" ;

	}

#print STDERR "Traitement Location : " . $trait_loc ;
#FIn de patch

        if ($flag) {
            $h =~ s/:\/\//:\/\/$HOST\//;
            $h =~ s/http:/https:/g;
        }
        $response->header( 'Location' => $h );
    
    
    }

    ############  a voir ######################## 
    if ( $response->header('Content-Base') ) {
        my $h = $response->header('Content-Base');
        $h =~
         s/$CONFIG{$ID_COLLECTED}->{BASEPRIV}/$CONFIG{$ID_COLLECTED}->{BASEPUB}/
          unless $flag;
        ;
        $h =~ s/:\/\//:\/\/$HOST\// if $flag;
        ;

        #       $h =~ s/http:\/\//http:\/\/$HOST\//;
        $response->header( 'Content-Base' => $h );
    }

    ### end: I correct on the fly some incomming header like mod_proxy does
    my $code = $response->code();
    if ( $code == 500 ) {
        $r->status(503);
        return 503;

    }
    else {
        $r->status( $response->code() );
    }
    $r->status_line( join " ", $response->code(), $response->message );
    $response->scan( sub {
          ( my $cle, my $val ) = @_;

          if ( $cle =~ /set-cookie/i ) {
              my $lcookie =
              Lemonldap::Handlers::Utilities::rewrite_cookie( $val,
              $CONFIG{$ID_COLLECTED} );
              $r->headers_out->add( $cle => $lcookie );

              #  $r->headers_out->add($cle => $lcookie[1] )  if $lcookie[1];
          }
          else { $r->headers_out->add( $cle => $val ) unless $cle =~ /Client/; }

      } );
    if ( $r->header_only ) {
        return OK;
    }

    $content = \$response->content;
    my $html = $$content;
    if ( $flag == 1 or $CONFIG{$ID_COLLECTED}->{REWRITEHTML} ) {     #### IF MODE ANYWHERE ####

        ######################################################################
        # here I 'm modifying the html source  for yahoo.fr and google.fr    #
        # I think that I must improve  modifications but It's just for demo  # 
        # the site target  must be KISS keep it Simple and Stupid            #  
        ######################################################################
        $html = &Lemonldap::Handlers::Core::ParseHtml(
          html   => $html,
          https  => $ENV{HTTPS},
          config => $CONFIG{$ID_COLLECTED},
          host   => $HOST,
	  uri    =>$url,
          target => $host_target
        );

    }

    $r->content_type('text/html') unless $$content;
    $r->print( $html || $response->error_as_HTML );
    $log->notice("$CONFIG{$ID_COLLECTED}->{HANDLERID}: $url response sent");
    return OK;

}

#####################
#                   #
# end proxy_handler #
# lwp engine        #
#                   #
#####################

###########################################################
# _lemonldap_internal  handler                            #
# add at your url /_lemonldap_internal                    #
# eg : http://appli1.demo.net/_lemonldap_internal         #
# in order to dump the internal config of apache children #
# add ?id=handler append another config handler on output #
#                                                         #
###########################################################

sub _lemonldap_internal {
    my $r     = shift;
    my $p     = $r->args;
    my @parax = split "&", $p;
    my @pr;

    foreach (@parax) {
        ( my $cle, my $val ) = split "=", $_;
        push @pr, $cle;
        push @pr, $val;
    }
    my %param = @pr;

    $r->content_type('text/html');
    $r->print(<<END);
<html>
<head><title>lemonldap websso</title></head>
<body>
<h1>Lemonldap websso internal table</h1>
<p>

END

    foreach ( keys %CONFIG ) {
        print "$_<br>\n";
    }
    print "<hr>\n";
    my $tmp = $CONFIG{$ID_COLLECTED};
    print "<h3>$ID_COLLECTED on $$</H3>\n";

    foreach ( keys %$tmp ) {
        if ( ref $tmp->{$_} ) {
            my $t = ref $tmp->{$_};
            print "$_ => $t  reference<br>\n";
        }
        else {
            print "$_ => $tmp->{$_}<br>\n";
        }

    }
    my $s = $param{'id'};
    if ($s) {
        print "<hr>\n";
        my $tmp = $CONFIG{$s};
        print "<h3>$s on $$ (features)</H3>\n";

        foreach ( keys %$tmp ) {
            if ( ref $tmp->{$_} ) {
                my $t = ref $tmp->{$_};
                print "$_ => $t  reference<br>\n";
            }
            else {
                print "$_ => $tmp->{$_}<br>\n";
            }

        }

    }

    print "</body>
</html>
  ";

    return OK;

}

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

=for html <center> <H1> Lemonldap::Handlers::Generic4a2 </H1></center> 


=head1 NAME

    Lemonldap::Handlers::Generic  - Perl extension for Lemonldap sso system

    Lemonldap::Handlers::Generic4a2 - Handler for Apache2 Lemonldap SSO
    system
    
    Lemonldap::Handlers::Generic4a2SSL - Handler full SSL  Apache2 Lemonldap SSO


=head1 SYNOPSIS
 
In httpd.conf 

  .....
  perltranshandler Lemonldap::Handlers::Generic4a2
  .....
 

=head1 DESCRIPTION

 Generic4a2 is the central piece of  websso framework .
 This module provides several methods but the principal goal of this is the handler function .
 It can be combined with mod_proxy or mod_rewrite and all other apache's  modules .
 It provides also an built-in  http proxy with LWP .
 see http://lemonldap.sf.net for more infos .
 

=head2 Parameters (see also doc folder)

 A minimal configuration  must provide  infos about :

=over 1

=item  config

  LemonldapConfig "/foo/bar/file_config.xml"
  The filename of the mean XML Config   :It's REQUIRED

=item domain

 LemonldapDomain foo.bar
 It fixes the value of domain for the  application protected by  this handler (see below) 

=item  xml section in config 
 
 LemonldapHandlerId  <xml section>

 It fixes the value of XML section in config 

=back 


=head2 Example (a KISS example, see also eg folder) 
 
In httpd.conf 

 <virtualHost 127.0.0.1:80>
 servername authen.demo.net
 PerlModule Apache2::compat
 PerlModule Bundle::Apache2
 PerlModule Lemonldap::Handlers::Generic4a2 
 perltranshandler Lemonldap::Handlers::Generic4a2
 PerlSetVar LemonldapDomain demo.net
 PerlSetVar LemonldapConfig /usr/local/apache/conf/application_new.xml
 PerlSetVar LemonldapHandlerID myintranet
 proxypass /intranet http://lemonldap.sourceforge.net
 proxypassreverse /intranet  http://lemonldap.sourceforge.net
 documentroot /usr/local/apache/htdocs
 </virtualhost>


 In /usr/local/apache/conf/application_new.xml
  <lemonconfig>
        <domain    id="demo.net"
                   Cookie="lemondemo"
		            >
		 <handler 
        		 id="myintranet" 
		 		 DisabledControl="1"
		        />  
        </domain>
  </lemonconfig>

   
 Now you can put http://authen.demo.net/intranet/ in your browser and you will see lemonldap's  site
 AND now you can control who and where goes on your site .
  
 You can pass parameters from httpd.conf with perlsetvar  facilities  or put them in xml file

=head2 Functions

=over 1

=item handler

 It's the mean  function which does all jobs . If the enebledproxy parameter is set to 1  ,this function
 will push proxy_handler function reference on  the handler's stack . If not it returns DECLINED (mod_proxy will be actived) 

=item proxy_handler 

 It's the built-in proxy (LWP)  web embedded  in lemonldap framework . It is  actived by  enabledproxy parameter .
 Some parameters are about this proxy and its behaviour     

=item _lemonldap_internal 

  append this keyword at the end of url and you will can see all config for a specific apache's child

=item _lemonldap_debug 

  append this keyword at the end of url and you will can see all headers send to host.
  Available  ONLY with built-in proxy


=back


=head2 Features

Generic4a2 is build arround perl's modules .

Those modules are :

=over 1

=item Utilities :

  collection of function

=item Core :
 
  It provides basics services like the cache service, forge header service or authorization service.
  
 Core.pm  can use YOUR own services for all this cycle . It's plugger . Lemonldap framework is available 
 with somes services but you can with Core.pm propose your schemas.
 News parameters  were added in XML DTD in order to describe the sequence.

=item  MatrixPolicy :
 
 manage authorization process , based on the hash of session (like preceding version)   

=item Memsession : 
 
 manage the backend of session (cache level 3) 

=item AuthorizationHeader :
 
 manage the construction of header 

=item RewriteHTML :

 Rewrite on fly html source in order to ajust somes tags like BASE , href or src
 Available  ONLY with built-in proxy
  

=back

=head4 More features

=over 1

=item Authentification
 
 Keep in mind  that the handler doesn't know HOW authenticate anybody but only knows WHERE authenticate . 
 The parameter 'portal' tells it where to send the authentification request. 

=item Caches 

 Thre are three levels of cache in lemonldap . 

 *First cache (level 1) is a very KISS  , it's a memory structure in the program .
 *Next  cache (level 2) is realised by using berkeleyDB hash
 *Last cache (level 3) is realised by using memcached (see Apache::Session::Memorycached on CPAN)

=back

=head1 SEE ALSO

Lemonldap(3), Lemonldap::Portal::Standard

http://lemonldap.sourceforge.net/

"Writing Apache Modules with Perl and C" by Lincoln Stein E<amp> Doug
MacEachern - O'REILLY

=over 1

=item Eric German, E<lt>germanlinux@yahoo.frE<gt>

=item Isabelle Serre, E<lt>isabelle.serre@justice.gouv.frE<gt>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Eric German E<amp> Isabelle Serre

Lemonldap originaly written by Eric german who decided to publish him in 2003
under the terms of the GNU General Public License version 2.

=over 1

=item This package is under the GNU General Public License, Version 2.

=item The primary copyright holder is Eric German.

=item Portions are copyrighted under the same license as Perl itself.

=item Portions are copyrighted by Doug MacEachern and Lincoln Stein.
This library is under the GNU General Public License, Version 2.

=item Portage under Apache2 is made with help of : Ali Pouya and 
Shervin Ahmadi (MINEFI/DGI) 

=back

  This program is free software; you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation; version 2 dated June, 1991.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  A copy of the GNU General Public License is available in the source tree;
  if not, write to the Free Software Foundation, Inc.,
  59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

=cut
