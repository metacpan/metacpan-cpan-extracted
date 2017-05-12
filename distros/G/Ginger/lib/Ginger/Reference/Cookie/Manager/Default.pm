# Ginger::Reference::Cookie::Manager::Default
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

Ginger::Reference::Cookie::Manager::Default - Ginger::Reference Component

=head1 VERSION

0.02

=cut

# my $c1 = $cookieman->create( name => 'MY_COOKIE', content => 'a=test1', path => '/', expires => 'Tue, 16-Feb-2013 19:51:45 GMT' );
            # my $c2 = $cookieman->create( name => 'B'        , content => 'b=test2', path => '/', expires => 'Tue, 16-Feb-2013 19:51:45 GMT' );
            # $cookieman->add( cookie => $c1 );
            # $cookieman->add( cookie => $c2 );

package Ginger::Reference::Cookie::Manager::Default;
use strict;
use Class::Core 0.03 qw/:all/;
use Data::Dumper;
#use URI::Encode;
use URI::Escape qw/uri_escape uri_unescape/;
use Carp;
use Date::Format;

use vars qw/$VERSION/;
$VERSION = "0.02";

sub init {
    my ( $core, $self ) = @_;
    $self->{'byname'} = {};
}

sub parse {
    my ( $core, $self ) = @_;
    #print "Parsing cookies\n";
    my $raw = $core->get('raw');
    my $log = $core->get_mod('log');
    #'MY_COOKIE=BEST_COOKIE%3Dchocolatechip; B=BEST_COOKIE%3Dchocolatechip',
    my @rawcookies = split( '; ', $raw );
    $self->{'byname'} ||= {};
    my $byname = $self->{'byname'};
    for my $rawcookie ( @rawcookies ) {
        if( $rawcookie =~ m/^([A-Z_]+)=(.+)/ ) {
            my $name = $1;
            my $cookie = { name => $name, content => decode( uri_unescape( $2 ) ) };
            #$log->note( text =>  "Found cookie named $name" );
            $byname->{ $name } = $cookie;
        }
        elsif( $rawcookie =~ m/^([A-Z_]+)=/ ) {
            my $name = $1;
            my $cookie = { name => $name, content => {} };
        }
        else {
            die "cookie is not of form: ([A-Z_]+)=(.+)\nIs: $rawcookie";
        }
    }
}

sub showall {
    my ( $core, $self ) = @_;
    print Dumper( $self->{'byname'} );
}

sub get {
    my ( $core, $self ) = @_;
    my $name = $core->get('name');
    #print Dumper( $self->{'byname'} );
    return $self->{'byname'}{$name};
}

sub add {
    my ( $core, $self ) = @_;
    my $cookie = $core->get('cookie');
    my $name = $cookie->{'name'};
    $self->{'byname'}{$name} = $cookie;
}

sub decode {
    my $raw = shift;
    if( !$raw ) { confess( 'raw not set' ); }
    my $hash = {};
    while( $raw =~ m'([a-z_]+)=(.+[^\\])(\&|$)'g ) {
        my $key = $1;
        my $val = $2;
        $val =~ s/\\(.)/$1/g;
        print "$key = $val\n";
        $hash->{ $key } = $val;                  
    }
    return $hash;
}

sub extend {
    my ( $core, $self ) = @_;
    my $cname = $core->get('cookie');
    my $len = $core->get('len');
    my $cookie = $self->{'byname'}{ $cname };
    
    my $future = unix_plus_some( 0, @$len ); # some time in the future from now
    my $expires = time2str('%a, %e-%b-%Y %X GMT', $future, 'GMT');
    $expires =~ s/  / /; # remove the double space caused by a day of month that is 1 character
    
    $cookie->{'expires'} = $expires;
    $cookie->{'path'} = '/';
    return $cookie;
}

sub create {
    my ( $core, $self ) = @_;
    my $name    = $core->get('name');
    my $content = $core->get('content'); # ( can be text or a hash ref )
    my $path    = $core->get('path') || '/';
    my $expires = $core->get('expires');
    
    if( ref( $expires ) eq 'ARRAY' ) {
        my $future = unix_plus_some( 0, @$expires ); # some time in the future from now
        $expires = time2str('%a, %e-%b-%Y %X GMT', $future, 'GMT');
        $expires =~ s/  / /; # remove the double space caused by a day of month that is 1 character
    }
    
    return { name => $name, content => $content, path => $path, expires => $expires };
}

sub unix_plus_some {
    my ( $unix, $days, $hours, $mins, $secs ) = @_;
    my $now_unix = $unix ? $unix : time;
    my $now_jul = unix_to_julian( $now_unix );
    my $new_jul = $now_jul + $days + ( $hours * 3600 + $mins * 60 + $secs ) / 86400;
    my $new_unix = julian_to_unix( $new_jul );
    return $new_unix;
}
sub unix_to_julian { return ( $_[0] / 86400.0 ) + 2440588; }
sub julian_to_unix { return ( $_[0] - 2440588 ) * 86400.0; }

sub flatten {
    my $cookie = shift;
    my $content = $cookie->{'content'};
    if( ref( $content ) eq 'HASH' ) {
        my @set;
        for my $key ( keys %$content ) {
            my $str = "$key=";
            my $val = $content->{ $key };
            $val =~ s|([=&\\])|\\$1|g;
            $str .= $val;
            push( @set, $str );
        }
        $content = join( '&', @set );
    }
    return $content;
}

sub to_raw {
    my $info = shift;
    
    my $rawcontent = uri_escape( flatten( $info ) );
    my $path = $info->{'path'};
    my $expires = $info->{'expires'};
    if( !$expires ) {
        return 0;
    }
    return $info->{'name'}."=$rawcontent; path=$path; expires=$expires";
}

sub set_header {
    my ( $core, $self ) = @_;
   
    my $headers = '';
    my $byname = $self->{'byname'};
    for my $cname ( keys %$byname ) {
        my $cookie = $byname->{ $cname };
        my $raw = to_raw( $cookie );
        $headers .= "Set-Cookie: $raw\r\n" if( $raw );
    }
    
    return $headers;
}

# this returns -just- the cookie data
sub raw_cookies {
    my ( $core, $self ) = @_;
    my @set;
    
    my $byname = $self->{'byname'};
    for my $cname ( keys %$byname ) {
        my $cookie = $byname->{ $cname };
        my $raw = $cookie->{'name'}."=".uri_escape( flatten( $cookie ) );
        push( @set, $raw ) if( $raw );
    }
    return \@set;
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


