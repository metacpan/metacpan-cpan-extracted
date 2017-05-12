# Ginger::Reference::Request::IO::HTTP_Server_Simple
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

Ginger::Reference::Request::IO::HTTP_Server_Simple - Ginger::Reference Component

=head1 VERSION

0.02

=cut

package Ginger::Reference::Request::IO::HTTP_Server_Simple;
use strict;
use Class::Core 0.03 qw/:all/;
use Ginger::Reference::Shared::HTTP_Server_Simple_Wrapper;
use Data::Dumper;

use vars qw/$VERSION/;
$VERSION = "0.02";

sub init {
    my ( $core, $self ) = @_;
    my $app = $self->{'obj'}{'_app'};
    my $sman = $self->{'session_man'} = $app->get_mod( mod => 'session_man' );
}

sub run {
    my ( $core, $self ) = @_;
    my $app = $self->{'obj'}{'_app'};
    $self->{'router'     } = $app->get_mod( mod => 'web_router' );
    $self->{'log'        } = $app->get_mod( mod => 'log' );
    $self->{'request_man'} = $app->get_mod( mod => 'request_man' );
    $self->{'rid'} = 1;
    
    #print Dumper( $self->{'router'}{'route'} );
    #print Dumper( $self->{'router'} );
    my $server = Ginger::Reference::Shared::HTTP_Server_Simple_Wrapper->new( 8083 );
    $server->set_handler( \&go, $core, $self );
    $server->run();
}

sub go {
    my ( $cgi, $core, $self ) = @_;
    my $app = $self->{'obj'}{'_app'};
    my $path = $cgi->path_info();
    #$core->dumper( '', $cgi );
    my $log = $self->{'log'};
    $log->note( text => "Recieved request to $path" );
    #my $router = $self->{'router'};
    
    my $type = lc( $cgi->request_method() );
    
    my $rman = $self->{'request_man'};
    my $sman = $self->{'session_man'};
    
    my $postvars = $cgi->Vars;
    my $queryhash = url2hash( $cgi->env_query_string() );
    
    my $r = $rman->new_request(
        path => $path,
        query => $queryhash,
        postvars => $postvars,
        id => $self->{'rid'}++,
        ip => $cgi->remote_addr(),
        type => $type # either 'post', 'get', or 'disconnect_notice'
        );
    $log->{'r'} = $r;
    
    my $router = $r->get_mod( mod => 'web_router' );
    
    my $res = $router->route( session_man => $sman );
    if( $type =~ m/notice/ ) {
        next;
    }
    
    print "HTTP/1.0 200 OK\r\n";
    my $htype = $r->{'type'} || 'text/html';
    print $cgi->header( -type => $htype );
    
    my $body = $r->get_body();
    print $body;
    
    #print "$path test\n";
    $r->end();
    
    my $rlen = $r->{'end'} - $r->{'start'};
    $rlen *= 100000;
    $rlen = int( $rlen );
    $rlen /= 100;
    
    $log->note( text => "Request finished; len=${rlen}ms" );
}

sub url2hash {
    my $url = shift;
    my $hash;
    
    my @parts = split('&', $url );
    for my $part ( @parts ) {
        next if( ! defined $part );
        if( $part =~ m/(.+)=(.+)/ ) {
            my $key = $1;
            my $val = $2;
            $key =~ s/%([a-zA-Z0-9]{2})/pack('H2',$1)/ge;$key =~ s/\+/ /g;
            $val =~ s/%([a-zA-Z0-9]{2})/pack('H2',$1)/ge;$val =~ s/\+/ /g;
            if( $key =~ m/^(.+)\[([0-9]+)\]$/ ) {
                my $arr = $hash->{ $1 } ||= [];
                $arr->[$2] = $val;
            }
            else {
                $hash->{ $key } = $val;
            }
        }
    }
    return $hash;
}


1;

__END__

=head1 SYNOPSIS

Component of L<Ginger::Reference>

=head1 DESCRIPTION

Component of L<Ginger::Reference>

=head1 LICENSE

  Copyright (C) 2013 David Helkowski
  
  This program is free software; you can redistribute it and/or
  modify it under the terms of the GNU General Public License as
  published by the Free Software Foundation; either version 2 of the
  License, or (at your option) any later version.  You may also can
  redistribute it and/or modify it under the terms of the Perl
  Artistic License.
  
  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

=cut


