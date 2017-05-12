# Ginger::Reference::Request::Default
# Version 0.01
# Copyright (C) 2013 David Helkowski

# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 2 of the
# License, or (at your option) any later version.  You may also can
# redistribute it and/or modify it under the terms of the Perl
# Artistic License.
  
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

=head1 NAME

Ginger::Reference::Request::Default - Ginger::Reference Component

=head1 VERSION

0.02

=cut

package Ginger::Reference::Request::Default;
use Class::Core 0.03 qw/:all/;
use Carp;
use strict;
use vars qw/$VERSION/;
use Data::Dumper;
use threads::shared;
use Time::HiRes qw/time/;
use Date::Format;

my $urid :shared;

$VERSION = "0.02";

our $spec;
$spec = <<DONE;
DONE

sub init {
    my ( $core, $r ) = @_;
    {
        lock $urid;
        $urid++;
    }
    my $app = $r->{'app'};
    my $modhash = $app->{'obj'}{'modhash'};
    my %rmods;
    $r->{'mods'} = \%rmods;
    $r->{'body'} = '';
    $r->{'otype'} = '';
    $r->{'urid'} = $urid;
    $r->{'start'} = time;
    $r->{'msgs'} = [];
    $r->{'funcs'} = [];
    
    for my $modname ( keys %$modhash ) {
        my $mod = $modhash->{ $modname };
        my $ref = $mod->{'obj'}{'_class'};
        
        my $dup = $mod->_duplicate( r => $r, _extend => $mod->{'_extend'} );
        
        $rmods{$modname} = $dup;
    }
    
    for my $modname ( keys %$modhash ) {
        my $dup = $rmods{$modname};
        if( $dup->_hasfunc('init_request') ) {
            $dup->init_request();
        }
    }
    
    #print "Request was init'ed\n";
}

sub log_start {
    my ( $core, $r ) = @_;
    my $url = $core->get('url');
    my $session_id = $core->get('sid'); # randomized session key fetched when a valid request comes in
    my $log = $r->{'log'} = $core->get_mod('log');
    my $dbid = $log->start_request( req_num => $r->{'urid'}, url => $url, cookie_id => $session_id );
    $r->{'dbid'} = $dbid;
}

sub log_end {
    my ( $core, $r ) = @_;
    my $dbid = $r->{'dbid'};
    my $log = $r->{'log'};
    my $msgs = $r->{'msgs'};
    my $funcs = $r->{'funcs'};
    my $msgcount = $#$msgs + 1;
    $log->stop_request( rid => $dbid, msgs => $r->{'msgs'}, funcs => $r->{'funcs'}, msgcount => $msgcount );
}

sub out {
    my ( $core, $r ) = @_;
    $r->{'body'} .= $core->get('text');
}

sub end {
    my ( $core, $r ) = @_;
    my $mods = $r->{'mods'};
    for my $modname ( keys %$mods ) {
        my $mod = $mods->{ $modname };
        if( $mod->_hasfunc('end_request') ) {
            $mod->end_request();
        }
    }
    undef $r->{'mods'};
    my $end = $r->{'end'} = time;
    
    #print "Request was ended\n";
}

sub get_mod {
    my ( $core, $r ) = @_;
    #my $glob = $app->{'_glob'};
    
    my $modname = $core->get('mod');
    
    #return $core->get_mod( $modname );
    #print "Attempting to get mod $modname\n";
    my $mod = $r->{'mods'}{ $modname };
    if( !defined $mod ) {
        #$core->dumper( 'modname', $modname );
        #$core->dumper( 'mod', $mod, 3 );
        #$core->dumper( 'mods', $r->{'mods'}, 1 );
        confess( "Cannot find mod $modname\n" );
    }
    return $mod;
}

sub content_type_as_header {
    my ( $core, $r ) = @_;
    my $type = $r->{'content_type'} || 'text/html';
    my $charset = $r->{'charset'} || 'ISO-8859-1';
    return "Content-Type: $type; charset=$charset\r\n" if( $type =~ m/text/ );
    return "Content-Type: $type\r\n";
}

sub get_headers {
    my ( $core, $r ) = @_;
    my $headers = '';
    if( $r->{'otype'} eq 'redirect' ) {
        $headers .= "Location: /".$r->{'url'}."\r\n";
    }
    elsif( $r->{'otype'} eq 'notfound' ) {
        return "";
    }
    else {
        $headers .= $r->content_type_as_header();
    }
    if( $r->{'expires'} ) {
        $headers .= $r->expires_as_header();
    }
    return $headers;
    
}

sub expires {
    my ( $core, $r, $expires ) = @_;
    $r->{'expires'} = $expires;
}

sub expires_as_header {
    my ( $core, $r ) = @_;
    my $expires = $r->{'expires'};
    my $seconds = 0;
    if( $expires =~ m/([0-9]+)h/ ) { $seconds += $1 * 3600; }
    if( $expires =~ m/([0-9]+)m/ ) { $seconds += $1 * 60; }
    if( $expires =~ m/([0-9]+)s/ ) { $seconds += $1; }
    my $header = '';
    $header .= "Cache-Control: max-age=$seconds, must-revalidate\r\n";
    my $now = time;
    $now += $seconds;
    
    my $date = time2str('%a, %e %b %Y %X GMT', $now, 'GMT');
    $date =~ s/  / /; # remove the double space caused by a day of month that is 1 character
    $header .= "Expires: $date\r\n";
    return $header;
}

sub get_body {
    my ( $core, $r ) = @_;
    if( $r->{'otype'} eq 'redirect' ) {
        return "";
    }
    elsif( $r->{'otype'} eq 'notfound' ) {
        return $r->{'body'};
    }
    else {
        return $r->{'body'};
    }
    
}

sub redirect {
    my ( $core, $r ) = @_;
    my $url = $core->get('url');
    $r->{'url'} = $r->{'app'}->get_base()."/$url";
    $r->{'otype'} = 'redirect';
}

sub not_found {
    my ( $core, $r ) = @_;
    $r->{'otype'} = 'notfound';
}

# get the type of the output
sub get_type {
    my ( $core, $r ) = @_;
    # redirect or 
    $core->set('type',$r->{'otype'});
    if( $r->{'otype'} eq 'redirect' ) {
        $core->set('url', $r->{'url'} );
    }
}

# http://www.w3.org/Protocols/rfc2616/rfc2616.html
sub get_code {
    my ( $core, $r ) = @_;
    if( $r->{'otype'} eq '' ) {
        return "200 OK";
    }
    elsif( $r->{'otype'} eq 'notfound' ) {
        return "404 Not Found";
    }
    elsif( $r->{'otype'} eq 'redirect' ) {
        return "302 Found";
    }
}

sub set_permissions {
    my ( $core, $r ) = @_;
    my $perms = $core->get('perms');
    $r->{'perms'} = $perms;
}

1;