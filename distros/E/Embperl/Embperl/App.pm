
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
#   $Id: App.pm 1578075 2014-03-16 14:01:14Z richter $
#
###################################################################################
 


package Embperl::App ;

use strict ;
use vars qw{%Recipes} ;

# ---------------------------------------------------------------------------------
#
#   Get/create named recipe
#
# ---------------------------------------------------------------------------------


sub get_recipe

    {
    my ($self, $r, $name) = @_ ;

    $name ||= 'Embperl' ;
    my @names = split (/\s/, $name) ;

    foreach my $recipe (@names)
        {
        my $mod ;
        $recipe =~ /([a-zA-Z0-9_:]*)/ ;
        $recipe = $1 ;
        if (!($mod = $Recipes{$recipe})) 
            {
            $mod = ($name =~ /::/)?$recipe:'Embperl::Recipe::'. $recipe ;
            if (!defined (&{$mod . '::get_recipe'}))
                {
                eval "require $mod" ;
                if ($@) 
                    {
                    warn $@ ;
                    return undef ;
                    }
                }
            $Recipes{$recipe} = $mod ;
            }
        print Embperl::LOG "[$$] Use Recipe $recipe\n" if ($r -> component -> config -> debug) ;
        my $obj = $mod -> get_recipe ($r, $recipe) ;
        return $obj if ($obj) ;
        }
        
    return undef ;                
    }


# ---------------------------------------------------------------------------------
#
#   send error page
#
# ---------------------------------------------------------------------------------


sub send_error_page

    {
    my ($self, $r) = @_ ;

    local $SIG{__WARN__} = 'Default' ;
    my $virtlog     = '' ; # $r -> VirtLogURI || '' ;
    my $logfilepos  = $r -> log_file_start_pos ;
    my $url         = '' ; # $Embperl::dbgLogLink?"<A HREF=\"$virtlog\?$logfilepos\&$$\">Logfile</A>":'' ;    
    my $req_rec     = $r -> apache_req ;
    my $status      = $req_rec?$req_rec -> status:0 ;
    my $err ;
    my $cnt = 0 ;
    local $Embperl::escmode = 0 ;
    my $time = localtime ;
    my $mail = $req_rec -> server -> server_admin if (defined ($req_rec)) ;
    $mail ||= '' ;
    $req_rec -> content_type('text/html') if (defined ($req_rec)) ;

    # don't use method call to avoid trouble with overloading
    Embperl::Req::output ($r,"<HTML><HEAD><TITLE>Embperl Error</TITLE></HEAD><BODY bgcolor=\"#FFFFFF\">\r\n$url") ;
    if ($status == 403)
        {
        Embperl::Req::output ($r,"<H1>Forbidden</H1>\r\n") ;
        }
    elsif ($status == 404)
        {
        Embperl::Req::output ($r,"<H1>Not Found</H1>\r\n") ;
        }
    else
        {
        Embperl::Req::output ($r,"<H1>Internal Server Error</H1>\r\n") ;
        }
    Embperl::Req::output ($r,"The server encountered an internal error or misconfiguration and was unable to complete your request.<P>\r\n") ;
    Embperl::Req::output ($r,"Please contact the server administrator, $mail and inform them of the time the error occurred, and anything you might have done that may have caused the error.<P><P>\r\n") ;

    my $errors = $r -> errors ;
    if ($virtlog ne '' && $Embperl::dbgLogLink)
        {
        foreach $err (@$errors)
            {
            Embperl::Req::output ($r,"<A HREF=\"$virtlog?$logfilepos&$$#E$cnt\">") ; #<tt>") ;
            $Embperl::escmode = 3 ;
            $err =~ s|\\|\\\\|g;
            $err =~ s|\n|\n\\<br\\>\\&nbsp;\\&nbsp;\\&nbsp;\\&nbsp;|g;
            $err =~ s|(Line [0-9]*:)|$1\\</a\\>|;
            Embperl::Req::output ($r,$err) ;
            $Embperl::escmode = 0 ;
            Embperl::Req::output ($r,"<p>\r\n") ;
            #Embperl::Req::output ($r,"</tt><p>\r\n") ;
            $cnt++ ;
            }
        }
    else
        {
        $Embperl::escmode = 3 ;
        Embperl::Req::output ($r,"\\<table cellspacing='2' cellpadding='5'\\>\r\n") ;
        foreach $err (@$errors)
            {
            $err =~ s|\\|\\\\|g;
            $err =~ s|\n|\n\\<br\\>\\&nbsp;\\&nbsp;\\&nbsp;\\&nbsp;|g;
            Embperl::Req::output ($r,"\\<tr bgcolor='#eeeeee'\\>\\<td\\>\r\n\\<!-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - --\\>\r\n") ;
            Embperl::Req::output ($r,"$err\r\n") ;
            Embperl::Req::output ($r,"\\<!-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - --\\>\r\n\\</td\\>\\</tr\\>\r\n") ;
            #Embperl::Req::output ($r,"\\<tt\\>$err\\</tt\\>\\<p\\>\r\n") ;
            $cnt++ ;
            }
        Embperl::Req::output ($r,"\\</table\\>\r\n\\<br\\>\n\r") ;
        $Embperl::escmode = 0 ;
        }
    my $server = $ENV{SERVER_SOFTWARE} || 'Offline' ;

    Embperl::Req::output ($r,$server . ($server =~ /Embperl/?'':" Embperl $Embperl::VERSION") . " [$time]<P>\r\n") ;
    Embperl::Req::output ($r,"</BODY></HTML>\r\n\r\n") ;
    }

# ---------------------------------------------------------------------------------
#
#   mail errors
#
# ---------------------------------------------------------------------------------


sub mail_errors

    {
    my ($self, $r) = @_ ;

    local $SIG{__WARN__} = 'Default' ;
    
    my $to = $self -> config -> mail_errors_to  ;
    return undef if (!$to) ;

    $r -> log ("[$$]ERR:  Mail errors to $to\n") ;

    my $time = localtime ;

    require Net::SMTP ;

    my $mailhost = $self -> config -> mailhost || 'localhost' ;
    my $smtp = Net::SMTP->new($mailhost, Debug => $self -> config -> maildebug) or die "Cannot connect to mailhost $mailhost" ;
    $smtp->mail("Embperl\@$ENV{SERVER_NAME}");
    $smtp->to($to);
    my $ok = $smtp->data();
    $ok and $ok = $smtp->datasend("To: $to\r\n");
    $ok and $ok = $smtp->datasend("Subject: ERROR in Embperl page " . $r -> param -> uri . " on $ENV{HTTP_HOST}\r\n");
    $ok and $ok = $smtp->datasend("\r\n");

    $ok and $ok = $smtp->datasend("ERROR in Embperl page $ENV{HTTP_HOST}$ENV{SCRIPT_NAME}\r\n");
    $ok and $ok = $smtp->datasend("\r\n");

    $ok and $ok = $smtp->datasend("-------\r\n");
    $ok and $ok = $smtp->datasend("Errors:\r\n");
    $ok and $ok = $smtp->datasend("-------\r\n");
    my $errors = $r -> errors ;
    my $err ;
        
    foreach $err (@$errors)
        {
	$ok and $ok = $smtp->datasend("$err\r\n");
        }
    
    $ok and $ok = $smtp->datasend("-----------\r\n");
    $ok and $ok = $smtp->datasend("Formfields:\r\n");
    $ok and $ok = $smtp->datasend("-----------\r\n");
    
    my $ffld = $r -> thread -> form_array ;
    my $fdat = $r -> thread -> form_hash ;
    my $k ;
    my $v ;
    
    foreach $k (@$ffld)
        { 
        $v = $fdat->{$k} ;
        $ok and $ok = $smtp->datasend("$k\t= \"$v\" \n" );
        }
    $ok and $ok = $smtp->datasend("-------------\r\n");
    $ok and $ok = $smtp->datasend("Environment:\r\n");
    $ok and $ok = $smtp->datasend("-------------\r\n");

    my $env = $r -> thread -> env_hash ;

    foreach $k (sort keys %$env)
        { 
        $v = $env -> {$k} ;
        $ok and $ok = $smtp->datasend("$k\t= \"$v\" \n" );
        }

    my $server = $ENV{SERVER_SOFTWARE} || 'Offline' ;

    $ok and $ok = $smtp->datasend("-------------\r\n");
    $ok and $ok = $smtp->datasend("$server Embperl $Embperl::VERSION [$time]\r\n") ;

    $ok and $ok = $smtp->dataend() ;
    $smtp->quit; 

    return $ok ;
    }    

# ---------------------------------------------------------------------------------
#
#   MailFormTo
#
# ---------------------------------------------------------------------------------


sub mail_form_to

    {
    my ($self, $to, $subject, $returnfield) = @_ ;
    my $v ;
    my $k ;
    my $ok ;
    my $smtp ;
    my $ret ;
    my $r = $self -> curr_req ;
    my $fdat = $r -> thread -> form_hash ;

    $ret = $fdat -> {$returnfield} ;

    require Net::SMTP ;

    $smtp = Net::SMTP->new($self -> config -> mailhost || 'localhost', 
                           Debug => $self -> config -> maildebug || 0,
                           $self -> config -> mailhelo?(Hello => $self -> config -> mailhelo):()) 
             or die "Cannot connect to mailhost" ;
    
    $smtp->mail($self -> config -> mailfrom || ("WWW-Server\@" . ($ENV{SERVER_NAME} || 'localhost')));
    $smtp->to($to);
    $ok = $smtp->data();
    $ok = $smtp->datasend("Reply-To: $ret\n") if ($ok && $ret) ;
    $ok and $ok = $smtp->datasend("To: $to\n");
    $ok and $ok = $smtp->datasend("Subject: $subject\n");
    $ok and $ok = $smtp->datasend("\n");
    foreach $k (@{$r -> thread -> form_array})
        { 
        $v = $fdat->{$k} ;
        if (defined ($v) && $v ne '')
            {
            $ok and $ok = $smtp->datasend("$k\t= $v \n" );
            }
        }
    $ok and $ok = $smtp->datasend("\nClient\t= $ENV{REMOTE_HOST} ($ENV{REMOTE_ADDR})\n\n" );
    $ok and $ok = $smtp->dataend() ;
    $smtp->quit; 

    $? = $ok?0:1 ;

    return $ok ;
    }    




1;


__END__        


=pod

=head1 NAME

Embperl::App - Embperl base class for application objects

=head1 SYNOPSIS


=head1 DESCRIPTION

You may override the following methods in your application object

=over

=item $app -> get_recipe ($r, $name)

=item $app -> send_error_page ($r) 

=item $app -> mail_errors ($r) 

=item $app -> mail_form_to ($to, $subject, $returnfield)

=back


