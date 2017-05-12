package Lemonldap::Portal::LogoutDAC;
use strict;
use warnings;
use Apache2::Const;
use Data::Dumper;
use CGI ':cgi-lib';
use Apache2::ServerRec();
use MIME::Base64;
our $VERSION = '3.1.0';

sub handler {	

	my $r = shift;
	my $domain = $r->dir_config('Domain');
	my $cookie = $r->dir_config('Cookie'); 
	my $Portal = $r->dir_config('Portal');
	my $PostLogoutURL = $r->dir_config('PostLogoutURL');


	my $entete = $r->headers_in();
	my $Cookies = $entete->{'Cookie'};		
			
	my $LogoutCookie = CGI::cookie(
            	    -name   => $cookie,
	            -value  => '0',
                    -domain => ".".$domain,
               	    -path   => '/',
		    -expires => 'now'
               	);  		
	
	my $test = $r->construct_url();

        #ATTENTION : ne valide que les http et https
        my $prot;

        if ($test =~ /^https/){
                $prot = "https://";
        }else{
                $prot = "http://"
        }
	my $url_portail;
	if (defined($PostLogoutURL)){
		$url_portail = $PostLogoutURL;
        }else{
		$url_portail = $prot.$r->headers_in->{Host};

	}


	
        my  $url_portail_encode = encode_base64($url_portail,"");
        $r->err_headers_out->add(Pragma => 'no-cache');
        $r->headers_out->add(Location =>$Portal."?op=c&url=$url_portail_encode");
        $r->err_headers_out->add(Connection => 'close');
	$r->err_headers_out->add( 'Set-Cookie' => $LogoutCookie );
 	
	
	return REDIRECT ;		
}
1;
