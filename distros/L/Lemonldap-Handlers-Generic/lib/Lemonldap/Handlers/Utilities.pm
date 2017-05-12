package Lemonldap::Handlers::Utilities;
use Apache2::Const;
use Apache::Session::Memorycached;
use BerkeleyDB;
use MIME::Base64;
use Crypt::CBC;
use URI::Escape;
use Data::Dumper;
use Template;
use CGI ':cgi-lib';
use Sys::Hostname;
use strict;
our ( @ISA, $VERSION, @EXPORTS );
$VERSION = '3.5.3';
our $VERSION_LEMONLDAP = "3.5.3";
our $VERSION_INTERNAL  = "3.5.3";
my %STACK;
###########################################################
# cleanupcookie function  (config,cookie line)            #
# return $id storing in lemonldap cookie                  #
# and remove lemonldap cookie of header cookie            #
# if STOPCCOKIE is actived                                #
# Should return undef,undef wihtout $id and cookie        #
#                                                         #
###########################################################
sub cleanupcookie {
    ( my $config, my $cookie_line ) = @_;
    return ( undef, undef ) unless $cookie_line;
    my $local_cookie = $config->{'COOKIE'};
    my @tab = split /;/, $cookie_line;
    my @tmp;
    my $id;
    foreach (@tab) {
        if (/$local_cookie=([^; ]+)/) {
            push @tmp, $_ unless ( $config->{STOPCOOKIE} );
            $id = $1;
            $id =~ s/\s//g;    # remove  space
        }
        else { push @tmp, $_; }
    }
    my $ret;

    if (@tmp) {
        $ret = join ";", @tmp;
    }
    return ( $id, $ret );
}

sub get_my_timeout {
    ( my $config, my $cookie_line ) = @_;
    return ( undef, undef ) unless $cookie_line;
    my $local_cookie = $config->{'COOKIE'};
    my @tab = split /;/, $cookie_line;
    my @tmp;
    my $cookie;
    my $id;
    my $sep;

    foreach (@tab) {
        if (/$local_cookie=([^; ]+)/) {
            $cookie = $_;
        }
        else {
            push @tmp, $_;
        }

    }
    $sep = "_";

    #On separe le time_end et l'id de session
    my @tab_tmp = split( $sep, $cookie );
    my $id      = $tab_tmp[0];
    my $timeout = $tab_tmp[1];
    if ( defined( $config->{ENCRYPTIONKEY} ) ) {
        my $clef   = $config->{ENCRYPTIONKEY};
        my $cipher = new Crypt::CBC(
            -key    => $clef,
            -cipher => 'Blowfish',
            -iv     => 'lemonlda',
            -header => 'none'
        );
        $timeout = $cipher->decrypt_hex($timeout);
    }
    push @tmp, $id;

    my $ret;

    if (@tmp) {
        $ret = join ";", @tmp;

    }

    return ( $ret, $timeout );
}

sub rewrite_cookie {
    ( my $cookie_line, my $config ) = @_;
    my $local_domain = $config->{'DOMAIN'};
    my @tab = split /;/, $cookie_line;
    my @tmp;
    my $flag;
    foreach (@tab) {
        next if /path/;

        #    $date = $_ if /expire/i;

        ( push @tmp, $_ ) and (next) unless /domain/;
        ( my $domain ) = /domain\s?=\s?([^; ]+)/;
        if ( $domain =~ /$local_domain/i ) {
            push @tmp, $_;
        }
        else {
            $flag = 1;
            my $l = 'domain = .' . $local_domain;
            push @tmp, $l;
        }

    }
    my $ret = join ";", @tmp;
    if ($flag) {
        return $ret;
    }
    else { return $cookie_line; }

}

sub cache2 {
    my ( $path, $pid, $id ) = @_;
    my $message;
    my $ligne_h;
    tie %STACK, 'BerkeleyDB::Btree',
      -Filename => "$path/$pid.db",
      -Flags    => DB_CREATE;
    $ligne_h = $STACK{$id};
    if ($ligne_h) {    ## match in ipc
        $message = "match in cache level 2 for $id";
        untie %STACK;
    }
    else {
        $message = "No match in cache level 2 for $id";
    }

    return ( $ligne_h, $message );

}

sub goPortal {
    my ( $r, $conf, $op, $id ) = @_;
    my $log    = $r->log;
    my %CONFIG = %$conf;
    my $test   = $r->construct_url();

    #ATTENTION : ne valide que les http et https
    my $prot;

    if ( $test =~ /^https/ ) {
        $prot = "https://";
    }
    else {
        $prot = "http://";
    }

    my $urlc_init = $prot . $r->headers_in->{Host} . $r->uri;
    $urlc_init .= "?" . $r->args if $r->args;
    my $urlc_initenc = encode_base64( $urlc_init, "" );
    $r->err_headers_out->add( Pragma => 'no-cache' );
    if ($CONFIG{URLCDATIMEOUT}  && $op eq 'x' ) {
    $r->headers_out->add(
        Location => $CONFIG{URLCDATIMEOUT} . "?op=$op&url=$urlc_initenc" );
    } else {
    $r->headers_out->add(
        Location => $CONFIG{PORTAL} . "?op=$op&url=$urlc_initenc" );
    }
    $r->err_headers_out->add( Connection => 'close' );
    $log->error(
"SERVER MEMCACHED UNREACHABLE. PLEASE CHECK IF YOUR SERVER IS ON OR IF YOUR CONFIGURATION FILE IS CORRECT"
      )
      if ( $op eq 'm' );
    my $messagelog =
      "$CONFIG{HANDLERID} : Redirect to portal (url was " . $urlc_init . ")";
    $log->info($messagelog);
    return REDIRECT;

}

sub save_session {
    my $id    = shift;
    my $trace = shift;
    $STACK{$id} = $trace;
    untie %STACK;
}

sub fake_refresh_ldap {

    my $HashSession = shift;
    my $config      = shift;
    my $ttl         = shift;
    my $new_SessExp;
    my $central = $config->{SERVERS};
    my $refresh = $config->{SESSCACHEREFRESHPERIOD};
    $central->{timeout} = $ttl;

    #No insertion in Memcached before untie
    $central->{updateOnly} = 1;

    my %Session;
    tie %Session, 'Apache::Session::Memorycached', undef, $central;
    foreach ( keys %{$HashSession} ) {
        if ( "SessExpTime" eq $_ ) {
            $new_SessExp = time() + $refresh;
            $HashSession->{$_} = $new_SessExp;
        }
        $Session{$_} = $HashSession->{$_} if $HashSession->{$_};
    }
    untie %Session;
    return $new_SessExp;

}

sub save_memcached_local {

    my $HashSession = shift;
    my $local       = shift;
    my $ttl         = shift;
    my $safe        = $local->{'servers'};

    if ( $local->{'servers'} ) {
        delete $local->{'servers'};
    }
    $local->{timeout} = $ttl;

    #No insertion in Memcached before untie
    $local->{updateOnly} = 1;

    my %Session;
    tie %Session, 'Apache::Session::Memorycached', undef, $local;
    foreach ( keys %{$HashSession} ) {

        $Session{$_} = $HashSession->{$_} if $HashSession->{$_};
    }

    untie %Session;
    if ($safe) {
        $local->{'servers'} = $safe;
    }

}

1;
