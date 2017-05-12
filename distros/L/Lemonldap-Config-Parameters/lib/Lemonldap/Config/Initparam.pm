package Lemonldap::Config::Initparam;
use APR::Table;
use Lemonldap::Config::Parameters;
use Data::Dumper;
our $VERSION = '3.1.2';

##########################
##########################
sub init_param_httpd {
##########################
# parameter input 
    my $log = shift;
    my ($__c) =@_;

#declaration
    my %__config;
    my $__param  = {
	'portal' => 'PORTAL',
        'basepub' => 'BASEPUB',
	'loginpage' => 'LOGINPAGE',
        'sslerrorpage' => 'SSLERRORPAGE',
	'basepriv' => 'BASEPRIV',
        'domain'  => 'DOMAIN',
 	'handlerid' => 'HANDLERID' ,
	'configfile' => 'CONFIGFILE',
	'configttl' => 'CONFIGTTL',
	'configdbpath' => 'CONFIGDBPATH',
	'enablelwp' => 'ENABLELWP',
	'cachedbpath' => 'CACHEDBPATH',
        'organization' => 'ORGANIZATION',
        'applcode' => 'APPLCODE',
        'disableaccesscontrol' => 'DISABLEACCESSCONTROL',
        'sessionstore' => 'SESSIONSTORE',
        'stopcookie' => 'STOPCOOKIE',
        'chaseredirect' => 'CHASEREDIRECT',
        'applproxy' => 'APPLPROXY',
        'fastpatterns' => 'FASTPATTERNS',
        'multihoming' => 'MULTIHOMING',
        'lwptimeout' => 'LWPTIMEOUT',
        'softcontrol' =>'SOFTCONTROL', 
        'sendheader' =>'SENDHEADER', 
        'allow' =>'ALLOW', 
	'pluginpolicy' =>'PLUGINPOLICY', 
	'regexpmatrixpolicy' =>'REGEXPMATRIXPOLICY', 
	'rewritehtmlplugin' =>'REWRITEHTMLPLUGIN', 
        'pluginheader' =>'PLUGINHEADER',
        'headerplugin' =>'HEADERPLUGIN',
        'sessionstoreplugin' =>'SESSIONSTOREPLUGIN',
	'ldapuserattributes' => 'LDAPUSERATTRIBUTES',
        'https' =>'HTTPS' ,
        'auth' => 'AUTH',
        'pkcs12' => 'PKCS12',
        'pkcs12_pwd' => 'PKCS12_PWD',
        'cert_file' => 'CERT_FILE' ,
        'key_file'  => 'KEY_FILE',    
	'cookie' => 'COOKIE' ,
	'accesspolicy' => 'ACCESSPOLICY',
	'inactivitytimeout' => 'INACTIVITYTIMEOUT',
	'encryptionkey' => 'ENCRYPTIONKEY',
	'clientipcheck' => 'CLIENTIPCHECK',
	'sesscacherefreshperiod' => 'SESSCACHEREFRESHPERIOD',
	'motifin' =>'MOTIFIN',
        'motifout' => 'MOTIFOUT',      
	'ldap_server' => 'LDAP_SERVER', 
	'ldap_port' => 'LDAP_PORT',
	'ldapfilterattribute' => 'LDAPFILTERATTRIBUTE',
	'dnmanager' => 'DNMANAGER',
	'passwordmanager' => 'PASSWORDMANAGER',
	'ldap_branch_people' => 'LDAP_BRANCH_PEOPLE',
	'sessionparams' => 'SESSIONPARAMS',	
	'commandopenssl' => 'COMMANDOPENSSL',
	'doverify' => 'DOVERIFY',
	'doocsp' => 'DOOCSP',
	'doldap' => 'DOLDAP',
	'verifycapath' => 'VERIFYCAPATH',
	'verifyoptions' => 'VERIFYOPTIONS',
	'ocspurl' => 'OCSPURL',
	'ocspoptions' => 'OCSPOPTIONS',
	'sslerrorcode' => 'SSLERRORCODE',
        'postlogouturl' => 'POSTLOGOUTURL',
        'directorytype' => 'DIRECTORYTYPE',
        'excluderegex' => 'EXCLUDEREGEX',
	'rewritehtml' => 'REWRITEHTML',
	'urlcdatimeout' => 'URLCDATIMEOUT',

};
# input
foreach (keys %$__c) 
{
 my $lkey =lc($_);
 my $val = $__c->get($_);
 #modif
	if($lkey eq 'basepriv'){
		if ($val=~/\/$/){
			chop($val);

		}
	}

 #modif 

 my $mkey = $__param->{$lkey};
 if ($mkey) 
 {
  $__config{$mkey} = $val;
 }else 
 {
  $log->error("lemonldap Initparam $_ : not valid parameter name"); 
 }
}

## work is done tel this 
## load session info
my $CONF= Lemonldap::Config::Parameters->new ( file => $__config{CONFIGFILE},cache => $__config{CONFIGDBPATH} );
if( defined ($__config{SESSIONPARAMS}) ){
	my $sessionparams= $__config{SESSIONPARAMS}; 
	$__config{STR_SERVERS}=  $sessionparams;
        $__config{SERVERS} = $CONF->formateLineHash ($sessionparams);	
}
elsif( defined ($__config{SESSIONSTORE}) ){
	my $xmlsession= $CONF->findParagraph('session',$__config{SESSIONSTORE});
	$__config{STR_SERVERS}=  $xmlsession->{SessionParams};
	$__config{SERVERS} = $CONF->formateLineHash ($xmlsession->{SessionParams});
}

$__config{'HTTPD'} =1;

return (\%__config );


}

##########################
##########################
sub init_param_xml {
##########################
my ($cn ) = @_;
my %__config;
my %CONFIG=%$cn;
my $GENERAL;
my $tmpconf;
	my $message;
    my $__param  = {
	'inactivitytimeout' => 'INACTIVITYTIMEOUT',
        'encryptionkey' => 'ENCRYPTIONKEY',
	'clientipcheck' => 'CLIENTIPCHECK',
        'cookie' => 'COOKIE' ,
        'portal' => 'PORTAL',
        'sessionstore' => 'SESSIONSTORE',  
        'softcontrol' =>'SOFTCONTROL', 
	'sesscacherefreshperiod' => 'SESSCACHEREFRESHPERIOD',
        'lwptimeout' =>'LWPTIMEOUT',
        'sendheader' => 'SENDHEADER' ,       
        'allow' =>'ALLOW',
        'pluginpolicy' =>'PLUGINPOLICY', 
        'rewritehtmlplugin' =>'REWRITEHTMLPLUGIN', 
        'sessionstoreplugin' =>'SESSIONSTOREPLUGIN',
        'pluginheader' =>'PLUGINHEADER',
        'headerplugin' =>'HEADERPLUGIN',
        'https' =>'HTTPS' ,
        'auth' => 'AUTH',
        'pkcs12' => 'PKCS12',
        'pkcs12_pwd' => 'PKCS12_PWD',
        'cert_file' => 'cert_file' ,
        'key_file'  => 'key_file',
	'ldap_server' => 'LDAP_SERVER',
        'ldap_port' => 'LDAP_PORT',
        'dnmanager' => 'DNMANAGER',
        'passwordmanager' => 'PASSWORDMANAGER',
        'ldap_branch_people' => 'LDAP_BRANCH_PEOPLE',
	'rewritehtml' => 'REWRITEHTML',
        'urlcdatimeout' => 'URLCDATIMEOUT',
	'sourceredirection'=>'SOURCEREDIRECTION',
	'targetredirection'=>'TARGETREDIRECTION',
	
};
  my $__param_loc  = {
	'enablelwp' => 'ENABLELWP' ,
        'organization' =>'ORGANIZATION',
        'applcode' => 'APPLCODE',
        'disableaccessControl' => 'DISABLEACCESSCONTROL' ,
        'basepub' => 'BASEPUB' ,
        'basepriv' => 'BASEPRIV',
        'stopcookie' => 'STOPCOOKIE' ,
        'chaseredirect' => 'CHASEREDIRECT' ,
        'portal' =>     'PORTAL',      
        'fastpatterns' => 'FASTPATTERNS',
        'multihoming' => 'MULTIHOMING',
        'motifin' =>'MOTIFIN',
        'motifout' => 'MOTIFOUT', 
        'lwptimeout' => 'LWPTIMEOUT',
        'softcontrol' =>'SOFTCONTROL', 
        'sendheader' => 'SENDHEADER',        
        'allow' =>'ALLOW',
        'pluginpolicy' =>'PLUGINPOLICY', 
        'rewritehtmlplugin' =>'REWRITEHTMLPLUGIN', 
        'sessionstoreplugin' =>'SESSIONSTOREPLUGIN',
        'pluginheader' =>'PLUGINHEADER',
        'headerplugin' =>'HEADERPLUGIN',
        'https' =>'HTTPS' ,
        'auth' => 'AUTH',
        'pkcs12' => 'PKCS12',
        'pkcs12_PWD' => 'PKCS12_PWD',
        'cert_file' => 'CERT_FILE' ,
        'key_file'  => 'KEY_FILE',
	'rewritehtml' => 'REWRITEHTML',
        'urlcdatimeout' => 'URLCDATIMEOUT',
	'sourceredirection'=>'SOURCEREDIRECTION',
	'targetredirection'=>'TARGETREDIRECTION',
	
};
 my $CONF= Lemonldap::Config::Parameters->new (
                        file => $CONFIG{CONFIGFILE} ,
		       	cache => $CONFIG{CONFIGDBPATH} );
    if ($CONF) {
	$message="$CONFIG{HANDLERID}: Phase : handler initialization LOAD XML conf :succeded"; } 
	 else {
	$message="$CONFIG{HANDLERID}: Phase : handler initialization LOAD XML conf : failed";
		}
    if ($CONFIG{DOMAIN}) {
       $GENERAL = $CONF->getDomain($CONFIG{DOMAIN}) ;
       $tmpconf = $GENERAL->{handler}->{$CONFIG{HANDLERID}};
 foreach (keys %$__param )  {
my $key = $__param->{$_};
 $__config{$key} = $GENERAL->{lc($_)} if defined ($GENERAL->{lc($_)}) ;
 } 
     
                }  else                 {
        $tmpconf= $CONF->{$CONFIG{HANDLERID}} ;
                        }
##  load session info 
my $xmlsession= $CONF->findParagraph('session',$__config{SESSIONSTORE});
$__config{STR_SERVERS}=  $xmlsession->{SessionParams}; 
$__config{SERVERS} = $CONF->formateLineHash ($xmlsession->{SessionParams});

			
### parse local conf #####

 foreach (keys %$__param_loc )  {
my $key = $__param_loc->{$_};
# $__config{$key} = lc($tmpconf->{$_}) if defined ($tmpconf->{$_}) ;
 $__config{$key} = $tmpconf->{lc($_)} if defined ($tmpconf->{lc($_)}) ;

 } 
$__config{'OK'} =1;
$__config{'message '} =$message;
## addon multihoming 
my $lig;
$lig= $CONFIG{MULTIHOMING} || $__config{MULTIHOMING}  ;
if ($lig ) { 
my @lmh= split "," ,$lig;
my @__TABLEMH=();
my %__HASHMH =();
foreach (@lmh) {
my $clmh = $GENERAL->{handler}->{$_};
my %__tmp;
 foreach (keys %$__param_loc )  {

my $key = $__param_loc->{$_};
# $__tmp{$key} = $clmh->{$_} if defined ($clmh->{$_}) ;
 $__tmp{$key} = $clmh->{lc($_)} if defined ($clmh->{lc($_)}) ;
 
} 
$__tmp{HANDLER} =$_;
$__HASHMH{$_} = \%__tmp;
## call function builer
my $sub = built_function(\%__HASHMH);
## add key in config 
$__config{SUB} =$sub;
$__config{MH} =\%__HASHMH;
}


}
 

$__config{XML}=1;
return (\%__config);
}

##########################
##########################
sub built_function    {
##########################

    my $tablemh= shift;

    my @key = keys %$tablemh ;
    my $def;
my $code = "sub {local \$_ = shift;\n"; 

foreach (@key) {
    my $tmp = $tablemh->{$_};
      if ($tmp->{HANDLER} =~ /DEFAULT/i)  {
     $def= 'DEFAULT';
    next ;
 }

$code .= "return \"$tmp->{HANDLER}\"  if /^\\$tmp->{MOTIFIN}/i;\n";  
}
    $code.= "return \"DEFAULT\";\n" if $def;

$code.= "1;}\n";
return $code;
}

##########################
##########################
sub built_functionics {
##########################
    my $tablemh= shift;
my @lmh= split "," ,$tablemh;

    my $code = "sub {local \$_ = shift;\n"; 
foreach (@lmh) {
$code .= "return \"OK\"  if /\\.$_\$/i;\n";  
}
$code.= "1;}\n";
return $code;
}

##########################
##########################
sub merge {
##########################

my ($ht , $xm) =@_;
my %__config;
foreach (keys %$xm ){
$__config{$_} = $xm->{$_} ;
} 
foreach (keys %$ht ){
$__config{$_} = $ht->{$_} if defined ($ht->{$_})  ;
} 
delete $__config{message};
return (\%__config);

}
##########################
##########################
sub mergeMH {
##########################

my ($ht , $mh) =@_;
my %__config;
%__config=%$ht;
my $_tmp = $__config{MH}->{$mh} ;
my %tmp= %$_tmp;
foreach (keys %tmp ){
$__config{$_} = $tmp{$_} ;
} 
my $id =$__config{HANDLERID}."/".$mh ;
$__config{HANDLERID} = $id;
$__config{XML}=1;
return (\%__config);

}

	
1;

