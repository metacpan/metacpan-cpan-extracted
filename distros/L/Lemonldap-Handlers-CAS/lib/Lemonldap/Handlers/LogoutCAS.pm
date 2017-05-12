package Lemonldap::Handlers::LogoutCAS;

use strict;
use warnings;

use Lemonldap::Config::Parameters;
use Apache2::Const qw(DONE FORBIDDEN OK SERVER_ERROR REDIRECT);
use Apache2::ServerUtil ();
use Apache2::Log();
use Apache2::ServerRec();
use CGI ':cgi-lib';
use CGI::Cookie;
my $html;

sub handler {
    my $r                    = shift;
    my $log                  = $r->log;
    my $MyApplicationXmlFile = $r->dir_config('ConfigFile');
    my $MyDomain             = lc( $r->dir_config('Domain') );

    my $Parameters =
      Lemonldap::Config::Parameters->new( file => $MyApplicationXmlFile, );
    my $Conf_Domain = $Parameters->getDomain($MyDomain);

    my $Cookie_Name = $Conf_Domain->{Cookie};
    my $page_html   = $Conf_Domain->{LogoutCASPage};

##########################################################################
    my $pathlemon  = "/";
    my $pathCookie = "/cas";
    my $dotdomain  = "." . $MyDomain;

    $log->info( "Set-Cookie: -name   => $Cookie_Name  -value  =>  -domain => "
          . ".$dotdomain -path   => $pathCookie" );
    my $CASCookie = CGI::cookie(
        -name   => "CASTGC",
        -value  => 0,
        -domain => $dotdomain,
        -path   => $pathCookie,
    );

    my $LemonCookie = CGI::cookie(
        -name   => $Cookie_Name,
        -value  => 0,
        -domain => $dotdomain,
        -path   => $pathlemon,
    );
##############################################
    if ( !$html ) {
        my $file;
        open( $file, "<$page_html" );
        local $/;
        $/    = '';
        $html = <$file>;
        close $file;
    }
    $r->content_type('text/html');

    #  my $linecookie= "CASTGC=0;domain=$dotdomain;path=/cas/ ; $cookiename=0;
    #  $r->headers_out->{'Set-Cookie'}= [$LemonCookie,$CASCookie] ;
    $r->headers_out->add( 'Set-Cookie' => $CASCookie );
    $r->headers_out->add( 'Set-Cookie' => $LemonCookie );
     $html =~ s/%user%//g;
     $html =~ s/%secret%//g;
     $html =~ s/%message%//g;
     $html =~ s/%urldc%//g;
     $html =~ s/%urlc%//g;
     $html =~ s/%it%//g;

    $r->print;
    $r->print($html);
    return OK;

}
1;
