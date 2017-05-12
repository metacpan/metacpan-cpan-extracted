package Lemonldap::Federation::ShibbolethRequestMap;
use Lemonldap::Federation::SplitURI ;
use URI::Escape ;
our $VERSION= '1.0.0';
sub new {
my $class =shift;
my %args = @_;
my $self;
$self=\%args;
my $uri = $self->{uri};
my $obj= Lemonldap::Federation::SplitURI->new (uri=> $uri );
$self->{host}=$obj->get_host;
$self->{scheme} =  $obj->get_scheme;
$self->{port} =  $obj->get_port;
$self->{ref_of_array_of_path} = $obj->get_ref_array_of_path;
bless $self,$class;
return $self;
}
sub application_id {
my $self = shift;
my $h_host = $self->{xml_host}->{Host} ;

###  id par defaut = default 
$self->{application_id} = 'default' ;
my$authtype ;
my $require ;
my $export ;
my $tmp_id ;
my $f_match;
my $host = $self->{host};
my $scheme = $self->{scheme};
my $port = $self->{port};
my $ref_of_array_of_path= $self->{ref_of_array_of_path};
 if (exists $h_host->{$host} ) {
# il faut veriffier  le schemas et  port
	my %_host =%{$h_host->{$host}};
	$f_match = 1;
	$f_match =0  if ((exists $_host{scheme}) && ($_host{scheme} ne $scheme));
	$f_match =0  if ((exists $_host{port}) && ($_host{port} ne $port));
	if ($f_match)  { 
      	$tmp_id = $_host{applicationId}   if   exists $_host{applicationId};
        $tmp_authtype = $_host{authType}  if   exists $_host{authType};
        $tmp_require = $_host{requireSession}  if   exists $_host{requireSession};
        $tmp_export = $_host{exportAssertion} if   exists $_host{exportAssertion};
         }   
	 
        my @w_path ;
        @w_path    = @$ref_of_array_of_path  if $ref_of_array_of_path;
        while (@w_path) {
            my $_p = shift @w_path ;
            if ( $_host{Path}->{name} eq $_p) {
            $tmp_id = $_host{Path}->{applicationId}  if   exists $_host{Path}->{applicationId}; 
	    	$tmp_authtype = $_host{Path}->{authType}  if   exists $_host{Path}->{authType};
         	$tmp_require = $_host{Path}->{requireSession}  if   exists $_host{Path}->{requireSession};
                $tmp_export = $_host{Path}->{exportAssertion} if   exists $_host{Path}->{exportAssertion};
                    my $tmp =$_host{Path};
                    %_host =%$tmp ;
                
                     #  descendre  
                      } 
                   else 
                     { 
		last ; 
           	 }
         
           }                    
             
 }    
$self->{application_id} =$tmp_id if $tmp_id;
$self->{authtype} = $tmp_authtype  if   $tmp_authtype;
$self->{require}= $tmp_require  if   $tmp_require;
$self->{export}= $tmp_export if $tmp_export;
return $self->{application_id};
}
sub redirection {
my $self = shift;
if (!$self->{application_id})  
  { $self->application_id($self); 
   } 
## 
my $application_id =$self->{application_id};
my $providerid;
my $shire ;
my $idp ;
$shire = $self->{xml_application}->{shire} ;
$shire = $self->{xml_application}->{Application}{$application_id}{shire} if 
  (exists  ($self->{xml_application}->{Application}{$application_id}{shire})) ;
$idp = $self->{xml_application}->{IdpURL} ;
$idp = $self->{xml_application}->{Application}{$application_id}{IdpURL} if 
  (exists  ($self->{xml_application}->{Application}{$application_id}{IdpURL})) ;


$providerid= $self->{xml_application}->{Application}{$application_id}{providerId} ;
$self->{providerID} = $providerid;
$self->{shire} = $shire ;
my $target= $self->{uri};
$target = uri_escape($target);
$shire = uri_escape($shire);
$providerid = uri_escape($providerid);

my $redirection=$idp."?target=".$target."&shire=".$shire."&providerId=".$providerid ;
 $self->{redirection}= $redirection;
return $redirection ;
}

1;
