
###################################################################################
#
#   Embperl - Copyright (c) 1997-2008 Gerald Richter / ecos gmbh  www.ecos.de
#   Embperl - Copyright (c) 2008-2014 Gerald Richter
#
#   You may distribute under the terms of either the GNU General Public
#   License or the Artistic License, as specified in the Perl README file.
#
#   THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
#   IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
#   WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#
#   $Id: Embperl.pm 1578075 2014-03-16 14:01:14Z richter $
#
###################################################################################


package Embperl;

require Cwd ;

require Exporter;
require DynaLoader;

use Embperl::Syntax ;
use Embperl::Recipe ;
use Embperl::Constant ;
use Embperl::Util ;
use Embperl::Out ;
use Embperl::Log ;
use Embperl::App ;

use strict ;
use vars qw(
    @ISA
    $VERSION
    $cwd 
    $req_rec
    $srv_rec
    $importno 
    %initparam
    $modperl
    $modperl2
    $modperlapi
    $req
    $app
    ) ;


@ISA = qw(Exporter DynaLoader);

$VERSION = '2.5.0' ;


if ($modperl  = $ENV{MOD_PERL})
    {
    $modperl  =~ m#/(\d+)\.(\d+)# ;
    $modperl2 = 1 if ($1 == 2 || ($1 == 1 && $2 >= 99)) ;
    $modperlapi = $ENV{MOD_PERL_API_VERSION} || 1 ;
    }

if ($ENV{PERL_DL_NONLAZY}
	&& substr($ENV{GATEWAY_INTERFACE} || '', 0, 8) ne 'CGI-Perl'
	&& defined &DynaLoader::boot_DynaLoader)
    {
    $ENV{PERL_DL_NONLAZY} = '0';
    DynaLoader::boot_DynaLoader ('DynaLoader');
    }

if ($modperl2)
    {
    if ($modperlapi >= 2) 
        {
        require Apache2::ServerRec ;
        require Apache2::ServerUtil ;
        require Apache2::RequestRec ;
        require Apache2::RequestUtil ;
        require Apache2::SubRequest ;
        require APR::Table ;
        $srv_rec = Apache2::ServerUtil -> server ;
        }
    else
        {
        if (($modperl =~ /_(\d+)/) && $1 < 15)
	    {
            require Apache::Server ;
	    }
        else
	    {
            require Apache::ServerRec ;
	    }
        require Apache::ServerUtil ;
        require Apache::RequestRec ;
        require Apache::RequestUtil ;
        require Apache::SubRequest ;
        $srv_rec = Apache -> server ;
        }
    }
elsif ($modperl)
    {
    require Apache ;    
    $srv_rec = Apache -> server ;
    }

if (!defined(&Embperl::Init))
    {
    bootstrap Embperl $VERSION  ;
    Boot ($VERSION) ;
    Init ($srv_rec, \%initparam) ;
    }


$cwd       = Cwd::fastcwd();

tie *Embperl::LOG, 'Embperl::Log' ;


1 ;

#######################################################################################

sub Execute
    
    {
    my $_ep_param = shift ;

    local $SIG{__WARN__} = \&Warn ;

    # when called inside a Embperl Request, Execute the component only
    return Embperl::Req::ExecuteComponent ($_ep_param, @_) if ($req) ;

    $_ep_param = { inputfile => $_ep_param, param => [@_]} if (!ref $_ep_param) ;

    local $req_rec ;
    if ($modperl && !exists ($_ep_param -> {req_rec}))
        {
        eval
            {
            if ($modperlapi < 2)
                {
                $req_rec = Apache -> request  ;
                }
            else
                {
                $req_rec = Apache2::RequestUtil -> request  ;
                }
            } ;    
        }
    elsif (exists ($_ep_param -> {req_rec}) && defined ($_ep_param -> {req_rec}))
        {    
        $req_rec = $_ep_param -> {req_rec} ;
        }

    my $_ep_rc ;
        {
        $_ep_rc = Embperl::Req::ExecuteRequest (undef, $_ep_param)  ;
        }
    
    return $_ep_rc ;
    }

#######################################################################################

sub handler
    
    {
    local $SIG{__WARN__} = \&Warn ;
    $req_rec = $_[0] ;
    if ($modperlapi < 2)
        {
        Apache -> request ($req_rec) ;
        }
    else
        {
        Apache2::RequestUtil -> request ($req_rec) ;
        }
    
    my $rc = Embperl::Req::ExecuteRequest ($_[0]) ;
    return $rc ;
    }

#######################################################################################

sub Warn 
    {
    local $^W = 0 ;
    my $msg = $_[0] ;
    chop ($msg) ;
    
    my $lineno = getlineno () ;
    my $Inputfile = Sourcefile () ;
    if ($msg =~ /Embperl\.pm/)
        {
        $msg =~ s/at (.*?) line (\d*)/at $Inputfile in block starting at line $lineno/ ;
        }
    logerror (Embperl::Constant::rcPerlWarn, $msg);
    }

#######################################################################################


sub PreLoadFiles 

    {
    my $files = $initparam{preloadfiles} ;
    delete $initparam{preloadfiles} ;
    
    if ($files && ref $files eq 'ARRAY')
        {
        foreach my $file (@$files)
            {
            if (ref $file)
                {
                Execute ({%$file, import => 0}) ;
                }
            else
                {
                Execute ({inputfile => $file, import => 0}) ;
                }
            }
        }
    }

#######################################################################################

package Embperl::Req ; 

#######################################################################################

use strict ;

if ($Embperl::modperl)
    { 
    if (!$Embperl::modperl2)
        { 
        eval 'use Apache::Constants qw(&OPT_EXECCGI &DECLINED &OK &FORBIDDEN)' ;
        die "use Apache::Constants failed: $@" if ($@); 
        }
    elsif ($Embperl::modperlapi >= 2)
        { 
        eval 'use Apache2::Const qw(&OPT_EXECCGI &DECLINED &OK &FORBIDDEN)' ;
        die "use Apache2::Const failed: $@" if ($@); 
        }
    else
        { 
        eval 'use Apache::Const qw(&OPT_EXECCGI &DECLINED &OK &FORBIDDEN)' ;
        die "use Apache::Const failed: $@" if ($@); 
        }
    }

#######################################################################################

sub ExecuteComponent
    
    {
    my $_ep_param = shift ;
    my $rc ;

    if (!ref $_ep_param)
        {
        $rc = $Embperl::req -> execute_component ({ inputfile => $_ep_param, param => [@_]}) ;
        }
    elsif ($_ep_param -> {object})
        {
        my $c = $Embperl::req -> setup_component ($_ep_param) ;
        my $rc = $c -> run ;
        my $package = $c -> curr_package ;
        $c -> cleanup ;
        if (!$rc)
            {
            my $object = {} ;
            bless $object, $package ;
            return $object ;
            }
        return undef ;
        }
    else
        {
        $rc = $Embperl::req -> execute_component ($_ep_param) ;
        }
    Embperl::exit() if ($Embperl::req -> had_exit) ;

    return $rc ;
    }

#######################################################################################

sub get_multipart_formdata
    {
    my ($self) = @_ ;

    my $dbgForm = $self -> config -> debug & Embperl::Constant::dbgForm ;

    # just let CGI.pm read the multipart form data, see cgi docu
    if ($Embperl::modperl2)
        {
        if ($Embperl::modperlapi < 2)
            {
            require Apache::compat  # Apache::compat is needed for CGI.pm
            }
        else
            {
            require Apache2::compat  # Apache::compat is needed for CGI.pm
            }
        }
    require CGI ;

    my $cgi = new CGI ;
    my $fdat = $self -> thread -> form_hash ;
    $self -> param -> cgi ($cgi) ;       # keep it until then end of the request
					 # otherwsie templ files be
					 # destroyed in CGI.pm 3.01+
    my $ffld = $self -> thread -> form_array ;
    @$ffld = $cgi->param;

    $self -> log ("[$$]FORM: Read multipart formdata, length=$ENV{CONTENT_LENGTH}\n") if ($dbgForm) ; 
    my $params ;
    foreach ( @$ffld )
	{
    	# the param_fetch needs CGI.pm 2.43
	$params = $cgi->param_fetch( -name => $_ ) ;
    	#$params = $cgi->{$_} ;
	if ($#$params > 0)
	    {
	    $fdat->{ $_ } = join ("\t", @$params) ;
	    }
	else
	    {
	    $fdat->{ $_ } = $params -> [0] ;
	    }
	
	$self -> log ("[$$]FORM: $_=$fdat->{$_}\n") if ($dbgForm) ; 

	if (ref($fdat->{$_}) eq 'Fh') 
	    {
	    $fdat->{"-$_"} = $cgi -> uploadInfo($fdat->{$_}) ;
	    }
        }
    }



#######################################################################################

sub SetupSession

    {
    my ($req_rec, $uid, $sid, $appparam) = @_ ;
    
    my ($rc, $thread, $app) = Embperl::InitAppForRequest ($req_rec, $appparam) ;

    my $cookie_name = $app -> config -> cookie_name ;
    my $debug = $appparam?$appparam -> {debug} & Embperl::Constant::dbgSession:0 ;
    if (!$uid)
        {
        my $cookie_val  = $ENV{HTTP_COOKIE} || ($req_rec?$req_rec->headers_in -> {'Cookie'}:undef) ;

	if ((defined ($cookie_val) && ($cookie_val =~ /$cookie_name=(.*?)(\;|\s|$)/)) || ($ENV{QUERY_STRING} =~ /$cookie_name=.*?:(.*?)(\;|\s|&|$)/) || $ENV{EMBPERL_UID} )
	    {
	    $uid = $1 ;
	    print Embperl::LOG "[$$]SES:  Received user session id $1\n" if ($debug) ;
            }

        }
    
    if (!$sid)
        {
	if (($ENV{QUERY_STRING} =~ /${cookie_name}=(.*?)(\;|\s|&|:|$)/))
	    {
	    $sid = $1 ;
	    print Embperl::LOG "[$$]SES:  Received state session id $1\n" if ($debug) ;
            }
        }

    $app -> user_session -> setid ($uid) if ($uid) ;    
    $app -> state_session -> setid ($sid) if ($sid) ;    

    return wantarray?($app -> udat, $app -> mdat, $app -> sdat):$app -> udat ;
    }


#######################################################################################

sub GetSession

    {
    my $r = shift || Embperl::CurrReq () ;

    if ($r -> session_mgnt)
	{
        return wantarray?($r -> app -> udat, $r -> app -> mdat, $r -> app -> sdat):$r -> app -> udat ;
	}
    else
        {
        return undef ; # No session Management
        }
    }

#######################################################################################

sub DeleteSession

    {
    my $r = shift || Embperl::CurrReq () ;
    my $disabledelete = shift ;

    my $udat = $r -> app -> user_session ;
    if (!$disabledelete)  # Delete session data
        {
        $udat -> delete  ;
        }
    else
        {
        $udat-> {data} = {} ; # for make test only
        $udat->{initial_session_id} = "!DELETE" ;
        }
    $udat->{status} = 0;
    }


#######################################################################################

sub RefreshSession

    {
    my $r = shift || Embperl::CurrReq () ;

    $r -> session_mgnt ($r -> session_mgnt | 4) if ($r -> session_mgnt) ; # resend cookie 
    }

#######################################################################################

sub CleanupSession

    {
    my ($req_rec, $appparam) = @_ ;

    my ($rc, $thread, $app) = Embperl::InitAppForRequest ($req_rec, $appparam) ;

    foreach my $obj ($app -> user_session, $app -> state_session, $app -> app_session)
        {
        $obj -> cleanup if ($obj) ;
        }

    }


#######################################################################################

sub SetSessionCookie

    {
    my ($req_rec, $appparam) = @_ ;

    my ($rc, $thread, $app) = Embperl::InitAppForRequest ($req_rec, $appparam) ;
    my $udat    = $app -> user_session ;
    $req_rec ||= Apache -> request ;

    if ($udat && $req_rec)
        {
        my ($initialid, $id, $modified)  = $udat -> getids ;
        
        my $name     = $app -> config -> cookie_name ;
        my $domain   = $app -> config -> cookie_domain ;
        my $path     = $app -> config -> cookie_path ;
        my $expires  = $app -> config -> cookie_expires ;
        my $secure   = $app -> config -> cookie_secure ;
        my $domainstr  = $domain?"; domain=$domain":'';
        my $pathstr    = $path  ?"; path=$path":'';
        my $expiresstr = $expires?"; expires=$expires":'' ;
        my $securestr  = $secure?"; secure":'' ;
                        
        if ($id || $initialid)
            {    
            $req_rec -> header_out ("Set-Cookie" => "$name=$id$domainstr$pathstr$expiresstr$securestr") ;
            }
        }
    }



#######################################################################################

sub export

    {
    my ($r, $caller) = @_ ;
    
    my $package = $r -> component -> curr_package ;
    no strict ;
    my $exports = \%{"$package\:\:_ep_exports"} ;

    print Embperl::LOG  "[$$]IMP:  Create Imports for $caller from $package\n" ;

    foreach $k (keys %$exports)
	{
        *{"$caller\:\:$k"}    = $exports -> {$k} ; #\&{"$package\:\:$k"} ;
        print Embperl::LOG  "[$$]IMP:  Created Import for $package\:\:$k -> $caller\n" ;
        }

    use strict ;
    }


#######################################################################################

package Apache::Embperl; 

*handler2 = \&Embperl::handler ;

package HTML::Embperl; 

*handler2 = \&Embperl::handler ;

package XML::Embperl; 

*handler2 = \&Embperl::handler ;

1 ;
