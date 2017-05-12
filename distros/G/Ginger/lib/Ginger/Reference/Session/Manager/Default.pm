# Ginger::Reference::Session::Manager::Default
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

Ginger::Reference::Session::Manager::Default - Ginger::Reference Component

=head1 VERSION

0.02

=cut

package Ginger::Reference::Session::Manager::Default;
use strict;
use Ginger::Reference::Session::Default;
use Class::Core 0.03 qw/:all/;
use Data::Dumper;
use vars qw/$VERSION/;
use threads;
use threads::shared;

$VERSION = "0.02";

sub init {
    my ( $core, $self ) = @_;
    $self->{'session_count'} = 0;
    $self->{'sessions'} = {};
    
    my $os = $^O;
    
    share( $self->{'sessions'} );
}

sub get_session {
    my ( $core, $self ) = @_;
    #print "Call to get_session\n";
    $self = $self->{'src'} || $self;
    
    my $r = $core->get('r');
    my $cookie = $core->get('cookie');# name of cookie session id is in
    my $ip = $r->{'ip'};
    my $id = '';
    my $log = $core->get_mod( 'log' );
    
    my $cookieman = $r->get_mod( mod => 'cookie_man' );
    
    #print Dumper( $cookieman->{'cookies'} );
    #print Dumper( $cookieman->{'byname'} );
    #$cookieman->showall();
    
    my $active_cookie = $cookieman->get( name => $cookie );
    if( $active_cookie ) {
        my $content = $active_cookie->{'content'};
        #print Dumper( $active_cookie );
        print "Found cookie with name $cookie:\n  ";
        #my $chash = $cookieman->decode( raw => $content );
        #print Dumper( $content );
        my $sid;
        if( $sid = $content->{'session_id'} ) {
            $id = $self->{'session_id'} = $sid;
        }
    }
    else {
        $log->error( text => "No cookie with name $cookie found" );
    }
    
    if( $ip eq '172.22.27.133' ) {
        #$id = 'dhelkowski';
    }
    my $session;
    
    #print "sessions =\n  ".Dumper( $self->{'sessions'} )."\n";
    lock $self->{'sessions'};
    my $raw;
    if( $raw = $self->{'sessions'}{ $id } ) {
        $log->note( text => "Fetched session for $id" );
        my $session = Ginger::Reference::Session::Default->new( id => $id, man => $self );
        $session->de_serialize( raw => $raw );
        return $session;
    }
    else {
        $log->note( text => "No session found under id '$id'" );
        #print Dumper( $self->{'sessions'} );
    }
    
    # print "No existing session\n";
    return 0;
    #print "ip: $ip\n";
}

sub create_session {
    my ( $core, $self ) = @_;
    my $dat = $self->{'src'} || $self;
    if( $self->{'src'} ) {
        print "There is a source\n";
    }
    my $session;
    
    {
        lock $dat->{'sessions'};
        my $id = random_str( $dat->{'sessions'} );
        $session = Ginger::Reference::Session::Default->new( id => $id, man => $self );
        print "##############       Added session with id $id\n";
        
        my $raw = $session->serialize();
        $dat->{'sessions'}{ $id } = $raw;
    }
    
    return $session;
}

sub random_str {
    my $hash = shift;
    my $str = '';
    while( !$str ) {
        for( my $i=0;$i<10;$i++ ) {
            $str .= chr( 50 + rand( 77 ) ); # ascii 50 to 126 ( all printable )
        }
        $str = '' if( $hash && $hash->{$str} );
    }
    return $str."=";
}

sub save_session {
    my ( $core, $self ) = @_;
    my $id = $core->get('id');
    my $session = $core->get('data');
    {
        lock $self->{'sessions'};
        $self->{'sessions'}{ $id } = $session->serialize();        
    }
}

sub expire_sessions {
    # go through sessions and end them if they are expired
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
