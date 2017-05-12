# Ginger::Reference::Log::Default
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

Ginger::Reference::Log::Default - Ginger::Reference Component

=head1 VERSION

0.02

=cut

package Ginger::Reference::Log::Default;
use Class::Core 0.03 qw/:all/;
use strict;
use Term::ANSIColor qw/:constants color/;
use vars qw/$VERSION/;
use threads::shared;
use Time::HiRes qw/time/;
use threads;
my @items :shared;

$VERSION = "0.02";

sub init {
    my ( $core, $self ) = @_;
    
    my $conf = $self->{'conf'} = $core->get('conf');
    my $console = $self->{'console'} = $conf->{'console'} ? 1 : 0; # flag to enable logging to console
    my $shared = $self->{'shared'} = $conf->{'shared'} ? 1 : 0; # flag to enable shared features
    
    if( $shared ) {
        my $app = $core->get_app();
        $app->register_class( name => 'hash', file => 'Ginger::Reference::Data::LockedHashSet', type => 'internal' ); 
        my $req_hash  = $self->{'hash_req'}  = $core->create('hash');
        my $inst_hash = $self->{'hash_inst'} = $core->create('hash');
        my $msg_hash  = $self->{'hash_msg'}  = $core->create('hash');
        my $func_hash = $self->{'hash_func'} = $core->create('hash');
        $self->{'id_req'}  = $req_hash->{'id'};
        $self->{'id_inst'} = $inst_hash->{'id'};
        $self->{'id_msg'}  = $msg_hash->{'id'};
        $self->{'id_func'} = $func_hash->{'id'};
    }
    
    if( $^O eq 'MSWin32' ) {
        eval('use Win32::Console::ANSI;');
    }
    
    print "Logging to console\n" if( $console );
}

sub init_thread {
    my ( $core, $self ) = @_;
    my $tid = $core->get('tid');
    
    my $inst_id = 0; #$self->{'inst_id'};
    # set dbh to a new connection to the db since the global one should not be used?? for now just try and reuse the same connection :(
    
    #if( $self->{'shared'} ) {
        my $hash_req  = $self->{'hash_req'}  = $core->create( 'hash', id => $self->{'id_req' } );
        my $hash_inst = $self->{'hash_inst'} = $core->create( 'hash', id => $self->{'id_inst'} );
        my $hash_msg  = $self->{'hash_msh'}  = $core->create( 'hash', id => $self->{'id_msg' } );
        my $hash_func = $self->{'hash_func'} = $core->create( 'hash', id => $self->{'id_func'} );
    #}
    
    my $hinst = $self->{'hash_inst'};
    return if( !$hinst );
    $self->{'trow'} = $hinst->push( {
            server_inst_id => $inst_id,
            tid => $tid
    } );
    
}

sub init_request {
    my ( $core, $self ) = @_;
    my $src = $self->{'src'};
    return if( !$src->{'shared'} );
}

# thread started
# thread ended

# request started
# request ended

sub server_start {}
sub server_stop {}

sub func_entry {
    my ( $core, $self, $arr ) = @_;
    my $src = $self->{'src'} || $self;
    my ( $cls, $func, $dbid ) = @$arr;
    #print "+++   $cls $func $dbid --\n";
    my $fhash = $src->{'hash_func'};
    return if( !$fhash );
    my $call_id = $fhash->push( {
        type => 1,
        start => time(),
        class => $cls,
        func => $func,
        rid => $dbid
    } );
    #print "+++   $cls $func $dbid $call_id\n";
    my $r = $self->{'r'};
    if( $r ) { push( @{$r->{'funcs'}}, $call_id ); }
    
    return $call_id;
}

sub func_exit {
    my ( $core, $self, $arr ) = @_;
    my $src = $self->{'src'} || $self;
    my ( $cls, $func, $dbid, $fid ) = @$arr;
    #print "---   $cls $func $dbid $fid\n";
    my $fhash = $src->{'hash_func'};
    return if( !$fhash );
    #my $finfo = $fhash->get( $fid );
    #$finfo->{'end'} = time;
    #$fhash->set( i => $fid, hash => $finfo );
    my $exit_id = $fhash->push( {
        type => 2,
        end => time(),
        fid => $fid,
        class => $cls,
        func => $func,
        rid => $dbid
    } );
    #print "---   $cls $func $dbid $fid\n";
    my $r = $self->{'r'};
    if( $r ) { push( @{$r->{'funcs'}}, $exit_id ); }
}

sub start_request {
    my ( $core, $self ) = @_;
    my $src = $self->{'src'} || $self;
    return if( !$src->{'shared'} );
    
    my $req_num = $core->get('req_num');
    my $url = $core->get('url');
    my $cookie_id = $core->get('cookie_id');
    
    my $r = $self->{'r'};
    
    my $inst_id = $src->{'inst_id'};
    my $trow = $src->{'trow'};
    
    my $rhash = $src->{'hash_req'};
    my $rid = $rhash->push( {
            req_num => $req_num,
            url => $url,
            cookie_id => $cookie_id,
            server_inst_id => $inst_id,
            thread_id => $trow,
            start => time
    } );
    
    my $glob = $src->{'obj'}{'_app'};
    my $stack = $glob->{'root'} = $glob->{'curfunc'} = { calls => [], _parent => 0 };
    
    return $rid;
}
use Data::Dumper;
sub stop_request {
    my ( $core, $self ) = @_;
    my $src = $self->{'src'} || $self;
    return if( !$self->{'src'}{'shared'} );
    my $dbid = $core->get('rid');
    my $msgs = $core->get('msgs');
    my $funcs = $core->get('funcs');
    my $msgcount = $core->get('msgcount');
     
    my $rhash = $self->{'src'}{'hash_req'};
    my $reqinfo = $rhash->get( $dbid );
    $reqinfo->{'end'} = time;
    $reqinfo->{'mcnt'} = $msgcount;
    $reqinfo->{'msgs'} = join( ',', @$msgs );
    $reqinfo->{'funcs'} = join( ',', @$funcs );
    $reqinfo->{'rid'} = $dbid;
    
    my $glob = $src->{'obj'}{'_app'};
    my $stack = $glob->{'root'};
    #print Dumper( $stack );
    $reqinfo->{'stack'} = $stack;
    
    $rhash->set( i => $dbid, hash => $reqinfo );
}

sub get_request {
    my ( $core, $self, $rid ) = @_;
    return $self->{'src'}{'hash_req'}->get( $rid );
}

sub get_requests {
    my ( $core, $self ) = @_;
    return $self->{'src'}{'hash_req'}->getall();
}

sub get_request_msgs {
    my ( $core, $self, $rid ) = @_;
    my $rhash = $self->{'src'}{'hash_req'};
    my $mhash = $self->{'src'}{'hash_msg'};
    
    my $req = $rhash->get( $rid );
    my $msgtext = $req->{'msgs'} || '';
    my @msgs = split( /,/,$msgtext );
    my $msgs = $mhash->get_these( \@msgs );    
    # my $req = $rhash
}

sub get_request_funcs {
    my ( $core, $self, $rid ) = @_;
    my $rhash = $self->{'src'}{'hash_req'};
    my $fhash = $self->{'src'}{'hash_func'};
    
    my $req = $rhash->get( $rid );
    my $msgtext = $req->{'funcs'} || '';
    my @msgs = split( /,/,$msgtext );
    my $msgs = $fhash->get_these( \@msgs );    
    # my $req = $rhash
}

sub note {
    my ( $core, $self ) = @_;
    my $src = $self->{'src'} || $self;
    my $text = $core->get('text');
    my $msg = "note: $text\n";
    my $r = $self->{'r'};
    my $rid = $r ? $r->{'urid'} : '';
    
    my @cl = ( 1,2,3 );#, 2, 3, 4, 5, 6, 7 );
    my $trace = '';
    for my $up ( @cl ) {
        my ( $x, $file, $line ) = caller($up);
        $file ||= ''; $line ||= '';
        $file =~ s|^[./]+||g; $file =~ s|\.pm$||g;
        next if( $file =~ m|^Class| );
        next if( $file eq 'Ginger/Reference/Core' );
        $trace .= "$file:$line,";
    }
    
    my $now = time; #$now *= 10000; $now = int( $now ); $now /= 10000;
    my $mhash = $src->{'hash_msg'};
    my $mid = $mhash->push( {
        type => 'note', 
        text => $text, 
        time => $now, 
        rid => $rid, 
        trace => $trace, 
        tid => threads->tid()
    } );
    if( $r ) { push( @{$r->{'msgs'}}, $mid ); }
    
    print STDERR $msg if( $src->{'console'} );
}

sub noter {
    my ( $core, $self ) = @_;
    my $src = $self->{'src'} || $self;
    my $text = $core->get('text');
    my $msg = "note: $text\n";
    my $r = $self->{'r'};
    my $rid = $r ? $r->{'urid'} : '';
    
    my @cl = ( 1,2,3 );#, 2, 3, 4, 5, 6, 7 );
    my $trace = '';
    for my $up ( @cl ) {
        my ( $x, $file, $line ) = caller($up);
        $file ||= ''; $line ||= '';
        $file =~ s|^[./]+||g; $file =~ s|\.pm$||g;
        next if( $file =~ m|^Class| );
        next if( $file eq 'App/Core' );
        $trace .= "$file:$line,";
    }
    
    my $now = time; $now *= 10000; $now = int( $now ); $now /= 10000;
    my $mhash = $src->{'hash_msg'};
    my $mid = $mhash->push( {
        type => 'note',
        text => $text,
        time => $now,
        rid => $rid,
        trace => $trace,
        tid => threads->tid()
    } );
    if( $r ) { push( @{$r->{'msgs'}}, $mid ); }
    
    print STDERR $msg if( $src->{'console'} );
}

sub error {
    my ( $core, $self ) = @_;
    my $src = $self->{'src'} || $self;
    my $text = $core->get('text');
    my $msg = "error: $text\n";
    my $rid = '';
    if( $self->{'r'} ) {
        $rid = $self->{'r'}{'urid'};
    }
    my @cl = ( 1 );
    my $trace = '';
    for my $up ( @cl ) {
        my ( $x,$file, $line ) = caller($up);
        $file =~ s|^[./]+||g; $file =~ s|\.pm$||g;
        $trace .= "$file:$line,";
    }
    my $now = time; $now *= 10000; $now = int( $now ); $now /= 10000;
    my $mhash = $src->{'hash_msg'};
    $mhash->push( {
        type => 'note', 
        text => $text, 
        time => $now, 
        rid => $rid, 
        trace => $trace
    } );
    
    if( $src->{'console'} ) {
        print STDERR color 'bold red';
        print STDERR $msg;
        print STDERR RESET;
    }
}

sub get_items {
    my ( $core, $self ) = @_;
    my $mhash = $self->{'src'}{'hash_msg'};
    return $mhash->getall();
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