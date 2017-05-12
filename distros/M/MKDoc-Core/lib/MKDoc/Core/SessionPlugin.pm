# -------------------------------------------------------------------------------------
# MKDoc::Core::SessionPlugin
# -------------------------------------------------------------------------------------
# Author : Jean-Michel Hiver.
# Copyright : (c) MKDoc Holdings Ltd, 2003
#
# This object / and plug-in attempts to set a session on the target
# machine. It will use either a cookie or user login if the user is
# logged in.
# -------------------------------------------------------------------------------------
package MKDoc::Core::SessionPlugin;
use MKDoc::Core::FileCache;
use warnings;
use strict;

use base qw /MKDoc::Core::Plugin/;

use constant COOKIE_ID    => $ENV{MKD__SESSION_COOKIE_ID}    || 'MKDocCoreSessionID';
use constant EXPIRES      => $ENV{MKD__SESSION_EXPIRES}      || '+1y';
use constant CACHE_DOMAIN => $ENV{MKD__SESSION_CACHE_DOMAIN} || 'session';


sub main
{
    my $class = shift;
    $class->session_id_sent() && return;
   
    my $req   = $class->request();
    my $value = $class->_gen_id();
    $req->cookie (COOKIE_ID) || $req->cookie (
          -name    => COOKIE_ID,
	  -value   => $value,
	  -expires => EXPIRES
    );
    
    return $class->SUPER::main (@_);
}


sub run
{
    my $self = shift;
    $self->load();
    return $self->SUPER::run (@_);
}


sub HTTP_Set_Cookie
{
    my $self   = shift;
    my $req    = $self->request();
    my $cookie = $req->cookie (COOKIE_ID) || return;
    return "$cookie; path=/";
}


sub load
{
    my $self       = shift;
    my $session_id = shift || $self->session_id_sent() || return;
    my $store      = MKDoc::Core::FileCache->instance (CACHE_DOMAIN);
    $self->_set_session_hashref ( $store->get ($session_id) || {} );
}


sub save
{
    my $self       = shift;
    my $session_id = $self->session_id_sent() || return;
    my $store      = MKDoc::Core::FileCache->instance (CACHE_DOMAIN);
    $store->set ( $session_id => $self->_session_hashref() );
}


sub session_id_sent
{
    my $self = shift;
    my $req  = $self->request(); 

    my $req_cookie = $req->cookie (COOKIE_ID());
    return "cookie:$req_cookie" if ($req_cookie);
    
    my $env_user = $ENV{REMOTE_USER};
    return "user:$env_user" if ($env_user);
    
    return;
}


sub session_attribute
{
    my $self = shift;
    my $attr = shift;
    return $self->{".session_$attr"};
}


sub set_session_attribute
{
    my $self = shift;
    my $attr = shift;
    $self->{".session_$attr"} = shift;
}


sub _session_hashref
{
    my $self = shift;
    return {
        map { $_ => $self->{$_} }
        grep /^\.session_/, keys %{$self}
    };
}


sub _set_session_hashref
{
    my $self = shift;
    my $hash = shift;
    for (keys %{$hash}) { $self->{$_} = $hash->{$_} }
}


sub _gen_id
{
    my $class = shift;
    join '', map { chr (ord ('a') + int (rand 26)) } 1..20;
}


1;


__END__
