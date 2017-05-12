package GenericSHIB;
use strict;
#####  use ######
use Apache2::URI();
use Apache2::Const;
use Apache2::Connection;
use Apache2::ServerUtil ();
use MIME::Base64;
use LWP::UserAgent;
use Apache2::Const qw(DONE FORBIDDEN OK SERVER_ERROR REDIRECT);
use Apache2::Log();
use Apache2::ServerRec();
use CGI ':cgi-lib';
use CGI::Cookie;
use URI::Escape;
use XML::Simple;
###################################################

use Lemonldap::Federation::ShibbolethRequestMap ;

###################################################

#A retirer en prod
use Data::Dumper;
#### common declaration #######
our( @ISA, $VERSION, @EXPORTS );
$VERSION = '3.2.0';
our $VERSION_LEMONLDAP = "3.1.0";
our $VERSION_INTERNAL  = "3.1.0";
my $test;
####
####
#### my declaration #########

sub handler {
    my $r = shift;

    # URL des pages d'erreur a ne pas traiter
    if ( $r->uri =~ /^\/LemonErrorPages/ ) {
        return DECLINED;
    }
    my $uri = $r->uri;
    ########################
    ##  log initialization
    ########################
    my $log = $r->log;
    my $messagelog;
    my $cache2file;
    my $APACHE_CODE;
    my $h =  $r->get_server_name;
    my $p = $r->get_server_port;
    my $scheme = 'http' ;
    $scheme=  'https'  if   $ENV{HTTPS};
   undef $p  if $scheme eq 'http' &&  $p eq '80' ; 
   undef $p  if $scheme eq 'https' &&  $p eq '443' ; 
    my $hostport =  $h;
    $hostport .= ":$p" if $p ;
    my $url_totale = $scheme."://".$hostport.$uri;
    print STDERR "ERIC $url_totale\n";
my $full_uri = $scheme."://".$hostport.$uri;
print STDERR "ERIC $full_uri\n";

 my $shibfile=  $r->dir_config('shibbolethfile'); 
   print STDERR "ERIC SHIBE : $shibfile\n";
if  (!$test) {
eval {
$test = XMLin( $shibfile,
  #   'ForceArray' => '1'
			 );		     
} ;

}
my $extrait_de_xml = $test->{RequestMapProvider}->{RequestMap} ;
my $extrait_de_xml2 = $test->{Applications} ;

my $requestmap = Lemonldap::Federation::ShibbolethRequestMap->new( xml_host => $extrait_de_xml ,
                                  xml_application=> $extrait_de_xml2 ,
                                  uri => $full_uri , ) ;
my $re= $requestmap->application_id;
print STDERR "$re\n";
my  $redirection = $requestmap->redirection ;
print STDERR  "$redirection\n";
$r->err_headers_out->add('Location' => $redirection);
return REDIRECT;
    }

1;
