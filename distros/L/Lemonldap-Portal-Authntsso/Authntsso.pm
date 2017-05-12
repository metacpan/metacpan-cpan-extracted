package Lemonldap::Portal::Authntsso;
use strict;
use warnings;
use Net::LDAP;
use Authen::Smb;
use Data::Dumper;
use MIME::Base64;
our $VERSION = '0.05';

sub new {
    my $class = shift;
    my %args  = @_;
    my $self  = bless {}, ref($class) || $class;
    $self->{controlUrlOrigin} = \&__controlUrlOrigin;
    $self->{controlTimeOut}   = \&__controlTimeOut;
    $self->{controlSyntax}    = \&__controlSyntax;
    $self->{bind}             = \&__bind;
    $self->{formateUser}      = \&__none;
    $self->{formateFilter}    = \&__Filter;
    $self->{formateBaseLDAP}  = \&__none;
    $self->{contactServer}    = \&__contactServer;
    $self->{bind}             = \&__bind;
    $self->{search}           = \&__ldapsearch;
    $self->{setSessionInfo}   = \&__session;
    $self->{unbind}           = \&__unbind;
    $self->{credentials}      = \&__credentials;
    my $mess = {
        1 =>
          'Your connection has expired; You must to be authentified once again',
        2 => 'User and password fields must be filled',
        3 => 'Wrong directory manager account or password',
        4 => 'not found in directory',
        5 => 'wrong credentials',
    };
    $self->{msg} = $mess;

    foreach ( keys %args ) {
        $self->{$_} = $args{$_};
    }

    return $self;
}
##------------------------------------------------------------------
## method none
## This method  does nothing ..
##------------------------------------------------------------------
sub __none {    #does ...nothing;

}
##------------------------------------------------------------------
## method controlUrlOrigin
## This method looks at param cgi 'urlc'  in order to determine if
## the request comes with  a vip url (redirection)  or for the menu
##------------------------------------------------------------------
sub __controlUrlOrigin {
    my $urldc;
    my $self = shift;
    my $urlc = $self->{param}->{'url'};

    if ( defined($urlc) ) {
        $urldc = decode_base64($urlc);

        #  $urldc =~ s#:\d+/#/#;   # Suppress  port number in  URL
        $urlc = encode_base64( $urldc, '' );
        $self->{'urlc'}  = $urlc;
        $self->{'urldc'} = $urldc;
    }
}
##------------------------------------------------------------------
## method controlTimeOut
## This method looks at param cgi 'op'
## if op eq 't' (like timeout) the handler couldn't retrieve the
## storage session from id session
##------------------------------------------------------------------
sub __controlTimeOut {
    my $self      = shift;
    my $operation = $self->{param}->{'op'};
    $self->{operation} = $operation;
    if ( defined($operation)
        and $operation eq 't' )
    {
        $self->{'message'} = $self->{msg}{1};
        $self->{'error'}   = 1;
    }
}
##------------------------------------------------------------------
## method controlSyntax
## This method looks at param cgi 'identifant' and 'secret'
##
##------------------------------------------------------------------
sub __controlSyntax {
    my $self = shift;
    my $user = $self->{param}->{'identifiant'};
    $self->{'user'} = $user;
    my $password = $self->{param}->{'secret'};
    $self->{'password'} = $password;
    if (   defined($user)
        or defined($password) )
    {
        if (   !defined($user)
            or $user eq ''
            or !defined($password)
            or $password eq '' )
        {
            $self->{'message'} = $self->{msg}{2};
            $self->{'error'}   = 2;
        }

    }
    if (    !defined($user)
        and !defined($password) )
    {    # empty form
        $self->{'message'} = '';
        $self->{'error'}   = 9;
    }

}
##---------------------------------------------------------------------------
## Connection  ldap on server and port ldap
##---------------------------------------------------------------------------

sub __contactServer {
    my $self = shift;
    unless ( $self->{ldap} ) {
        my $ldap = Net::LDAP->new(
            $self->{server},
            port    => $self->{port},
            onerror => undef,
          )
          or die( 'Net::LDAP->new: ' . $@ );
        $self->{ldap} = $ldap;
    }
}

sub func_bind {
    my $ldap     = shift;
    my $dn       = shift;
    my $password = shift;
    my $mesg;
    if ( $dn and $password ) {    #named bind
        $mesg = $ldap->bind( $dn, password => $password );
    }
    else {                        # anonymous bind
        $mesg = $ldap->bind();
    }

    my $me = $mesg->code();
    if ( $mesg->code() != 0 ) {
        $ldap = undef;
        return ("wrong password");
    }
    return;
}

##---------------------------------------------------------------------------
## formate filter
##---------------------------------------------------------------------------
sub __Filter {
    my $self   = shift;
    my $user   = $self->{user};
    my $filtre = "uid=$user";
    $self->{filter} = $filtre;
}
##---------------------------------------------------------------------------
## Connection  on  server LDAP with manager credential
## in order to extract user infos
##---------------------------------------------------------------------------

sub __bind {
    my $self = shift;
##---------------------------------------------------------------------------
## Authentification
##---------------------------------------------------------------------------

    my $d = $self->{ldap};
    my $p = $self->{DnManager};
    my $r = $self->{passwdManager};

    my $mesg =
      &func_bind( $self->{ldap}, $self->{DnManager}, $self->{passwordManager} );

    if ($mesg) {
        $self->{'message'} = $self->{sg}{3};
        $self->{'error'}   = 3;

    }
}

sub __ldapsearch {
    my $self   = shift;
    my $ldap   = $self->{ldap};
    my $filter = $self->{filter};
    my $base   = $self->{branch};

    my $mesg = $ldap->search(
        base   => $base,
        scope  => 'sub',
        filter => $filter,
    );
    die $mesg->error() if ( $mesg->code() != 0 );
    my $retour          = $mesg->entry(0);
    my $identifiantCopy = $self->{user};
    if ( !defined($retour) ) {
        $self->{'message'} = "$identifiantCopy :" . $self->{msg}{4};
        $self->{'error'}   = 4;
        return;
    }
    $self->{entry} = $retour;
    return;
}
##==============================================================================
## function _session
##
##==============================================================================

sub __session {
    my $self = shift;
    my %session;
    my $entry = $self->{entry};
    $session{dn}            = $entry->dn();
    $self->{dn}             = $entry->dn();
    $session{uid}           = $entry->get_value('uid');
    $session{cn}            = $entry->get_value('cn');
    $session{personaltitle} = $entry->get_value('personaltitle');
    $session{mail}          = $entry->get_value('mail');
    $session{title}         = $entry->get_value('title');
    $self->{infosession}    = \%session;

}
##==============================================================================
## Function unbind
##  do unbind;
##==============================================================================
sub __unbind {
    my $self = shift;
    $self->{ldap}->unbind if $self->{ldap};
}
##---------------------------------------------------------------------------
## Credential against   nt domain
##---------------------------------------------------------------------------
sub __credentials {
    my $self        = shift;
    my $login       = $self->{user};
    my $passwd      = $self->{password};
    my $BDC         = $self->{BDC};
    my $BDC_secours = $self->{BDC_secours};
    my $ntdomain    = $self->{ntDomain};

    unless (
        Authen::Smb::authen( $login, $passwd, $BDC, $BDC_secours || $BDC,
            $ntdomain ) == 0
      )
    {

        $self->{'message'} = $self->{msg}{5};
        $self->{'error'}   = 5;
    }
}

sub message {
    my $self = shift;
    return ( $self->{message} );
}

sub infoSession {
    my $self = shift;
    return ( $self->{infosession} );
}

sub getAllRedirection {
    my $self = shift;
    return ( $self->{urlc}, $self->{urldc} );
}

sub getRedirection {
    my $self = shift;
    return ( $self->{urldc} );
}

sub user {
    my $self = shift;
    return ( $self->{user} );
}

sub error {
    my $self = shift;
    return ( $self->{error} );
}

sub process {
    my $self = shift;
    my %args = @_;
    foreach ( keys %args ) {
        $self->{$_} = $args{$_};
    }
##------------------------------------------------------------------
## method process
## This method step after step calls methods for dealing the
## connection
##  step 0  : setting configuration
##  step 1  : manage the source of request
##  step 2  : manage timeout
##  step 3  : control the input form of user and password
##  step 4  : formate the user id if needing
##  step 5  : build the filter for  the  search
##  step 6  : build subtree for the search ldap
##  step 7  : make socket upon ldap server
##  step 8  : bind operation
##  step 9  : make search
##  step 10 : confection of %session from ldap infos
##  step 11 : unbind
##  step 12 : validing user's  credentials  upon ntdomain
##------------------------------------------------------------------
    &{ $self->{controlUrlOrigin} }($self);    # no error avaiable in this step
    &{ $self->{controlTimeOut} }($self);
    return ($self) if $self->{'error'};       ## it's not necessary to go next.
    &{ $self->{controlSyntax} }($self);
    return ($self) if $self->{'error'};       ## it's not necessary to go next.
    &{ $self->{formateUser} }($self);         # no error avaiable in this step
    &{ $self->{formateFilter} }($self);       # no error avaiable in this step
    &{ $self->{formateBaseLDAP} }($self);     # no error avaiable in this step
    &{ $self->{contactServer} }($self)
      ;    # can die if the server if unreachable: critical error
    &{ $self->{bind} }($self);
    return ($self) if $self->{'error'};    ## it's not necessary to go next.
    &{ $self->{search} }($self);

    if ( $self->{'error'} ) {
        ## it's not necessary to go next.
        &{ $self->{unbind} }($self);
        return ($self);
    }
    &{ $self->{setSessionInfo} }($self);    # no error avaiable in this step
    &{ $self->{credentials} }($self);
    &{ $self->{unbind} }($self);            # no error avaiable in this step
    return ($self);
}

1;
__END__

=head1 NAME

Lemonldap::Portal::Authntsso - Perl extension for the Lemonldap SSO system

=head1 SYNOPSIS

  use Lemonldap::Portal::Authntsso;
  sub my_method {
     my $self = shift;
     my $user = $self->{'user'};
     $user.="-cp" if  $user !~ /-cp$/;
     $self->{'user'} = $user;
      return ;
             }

 my $message = '';
 my %params =Vars;
 my $stack_user=Lemonldap::Portal::Authntsso->new('formateUser' => \&my_method);
 my $urlc;
 my $urldc; 
 $retour=$stack_user->process(param =>  \%params,           
                server          => $ReverseProxyConfig::ldap_serveur,
                port            => $ReverseProxyConfig::ldap_port,
                DnManager       => $ReverseProxyConfig::ldap_admin_dn,
                passwordManager => $ReverseProxyConfig::ldap_admin_pd,
                branch => $ReverseProxyConfig::ldap_branch_people,
		BDC     => $ReverseProxyConfig::BDC,
		BDC_secours     => $ReverseProxyConfig::BDC_secours,
	        ntdomain     => $ReverseProxyConfig::ntdomain,
			  
                             );
    if ($retour)   { 
      	$message=$retour->message;
	$erreur=$retour->error;
                         }

  

=head1 DESCRIPTION

Lemonldap is a SSO system under GPL. 
The authentification phase need to display a form with user / password .
Authntsso.pm  manage all the cycle of authentification against ntdomain :

 step 0  : setting configuration
 step 1  : manage the source of request
 step 2  : manage timeout 
 step 3  : control the input form of user and password
 step 4  : formate the userid if needing
 step 5  : build the filter for  the  search
 step 6  : build subtree for the search ldap 
 step 7  : make socket upon ldap server
 step 8  : bind operation
 step 9  : make search
 step 10 : confection of %session from ldap infos   
 step 11 : unbind 
 step 12 : validing user's  credentials  against ntdomain 

Any step can bee overload for include your custom method.

 standards errors messages :

 1 => 'Your connection has expired; You must to be authentified once again',
 2 => 'User and password fields must be filled',
 3 => 'Wrong directory manager account or password' ,
 4  => 'not found in directory',
 5  => 'wrong credentials' ,
	      
 warning the value 9 for error message is returned then the form is empty is't not an real error , perhaps it's the initial request.

=head1 METHODS
 
=head2  Standard->new();
 
my $stack_user= Lemonldap::Portal::Authntsso->new('standard_method' => \&my_method);
 
=head2 process();

 $retour=$stack_user->process(param =>  \%params,           
                server          => 'ldap_serveur',
                port            => 'ldap_port',
                DnManager       => 'ldap_admin_dn',
                passwordManager => 'ldap_admin_pd',
                branch => 'ldap_branch_people'  
		BDC     => $ReverseProxyConfig::BDC,
		BDC_secours     => $ReverseProxyConfig::BDC_secours,
	        ntdomain     => $ReverseProxyConfig::ntdomain,
                             );
  You can keep DnManager and passwordManager in undef state in order to  provide anonymous bind.
   Don't pass them like parameter for this. 
 %params is  the hash initialized whith  CGI params 
  Lemonldap provide several  parameters like :
  identifiant , secret  (user and password) 
  urlc : url of  the original request .
 
=head2 message() ;
 
  return the text of error 

=head2 error() ;
 
  return the  number of error 

=head2 sub infoSession ()

  return a reference of hash of session 
 
=head2 getRedirection ()

  return a plaintext url of redirection
 
=head2 (urlc,urldc) :getAllRedirection ()

  return a  list of encoded url and decoded  url of redirection
 

=head1 SEE ALSO

Lemonldap(3), Lemonldap::Handler::Intrusion(3), Lemonldap::Standard.

http://lemonldap.sourceforge.net/

"Writing Apache Modules with Perl and C" by Lincoln Stein E<amp> Doug
MacEachern - O'REILLY

 See the examples directory

=head1 AUTHORS

=over 1

=item Eric German, E<lt>germanlinux@yahoo.frE<gt>

=item Xavier Guimard, E<lt>x.guimard@free.frE<gt>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Eric German E<amp> Xavier Guimard

Lemonldap originaly written by Eric german who decided to publish him in 2003
under the terms of the GNU General Public License version 2.

=over 1

=item This package is under the GNU General Public License, Version 2.

=item The primary copyright holder is Eric German.

=item Portions are copyrighted under the same license as Perl itself.

=item Portions are copyrighted by Doug MacEachern and Lincoln Stein.
This library is under the GNU General Public License, Version 2.


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


