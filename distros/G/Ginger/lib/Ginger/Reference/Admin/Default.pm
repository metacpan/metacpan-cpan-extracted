# Ginger::Reference::Admin::Default
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

Ginger::Reference::Admin::Default - Ginger::Reference Component

=head1 VERSION

0.02

=cut

package Ginger::Reference::Admin::Default;
use Class::Core 0.03 qw/:all/;
use strict;
use Data::Dumper;
use XML::Bare qw/xval/;
use Date::Format;

use vars qw/$VERSION $spec/;
$VERSION = "0.02";

$spec = "
    <group>core</group>
    <func name='admin' perms='fsd'>
        <api v='1' name='admin'/>
    </func>
    <func name='login'>
        <api v=1 name='login'/>
    </func>
";

sub init {
    my ( $core, $self ) = @_; # this self is src
    my $conf = $self->{'conf'} = $core->get('conf');
    my $router = $core->get_mod( 'web_router' );
    $router->route_path( path => "core/login", obj => 'core_admin', func => 'login', session => 'CORE' );
    $router->route_path( path => "core/admin", obj => 'core_admin', func => 'admin', session => 'CORE', bounce => 'core/login' );
    $router->route_path( path => "core/log", obj => 'core_admin', func => 'log', session => 'CORE', bounce => 'core/login' );
    $router->route_path( path => "log", obj => 'core_admin', func => 'log', session => 'CORE' );
    $router->route_path( path => "req", obj => 'core_admin', func => 'req', session => 'CORE' );
    $router->route_path( path => "func", obj => 'core_admin', func => 'func', session => 'CORE' );
    $self->{'base'} = xval( $core->get_conf()->{'base'} );
    
    #my $api = $core->get_mod( 'core_api' );
    #$api->register_via_spec( mod => $self, session => 'CORE' );
    #print "****" . ref( $core ) . "*****\n";
    #core->blah();
}

sub admin {
    my ( $core, $self ) = @_;
    #$core->set('html', 'test' );
    my $base = $core->get_base();
    my $dump = Dumper( $self->{'r'}{'perms'} );
    $self->{'r'}->out( text => "
        <h2>Ginger::Reference Admin</h2>
        <ul>
        <li><a href='/$base/core/log'>log</a>
        </ul>
        $dump
        " );
}

sub req {
    my ( $core, $self ) = @_;
    my $log = $core->get_mod( 'log' );
    my $root = $core->get_base();
    my $reqs = $log->get_requests();
    my $out = '';
    $out .= "<table border='1' cellspacing='0' cellpadding='3'>
    <tr><td>Req</td><td>Thread</td><td>Inst</td><td>URL</td><td>cookie</td><td>log count</td><td>start</td><td>len</td></tr>
    ";
    my @keys = ( 'thread_id', 'server_inst_id', 'url', 'cookie_id', 'mcnt' );
    #my $i = 0;
    for my $req ( @$reqs ) {
        $out .= "<tr>";#<td>$i</td>";
        #$i++;
        my $rnum = $req->{'req_num'};
        my $rid = $req->{'rid'};
        $out .= "<td><a href='/$root/log/?r=$rid'>$rnum</a></td>";
        for my $key ( @keys ) {
            my $val = $req->{ $key } || '';
            $out .= "<td>$val</td>";
        }
        my $start = $req->{'start'};
        my $end = $req->{'end'};
        my $len = '';
        if( $end ) {
            $len = $end - $start;
            $len *= 1000000;
            $len = int( $len );
            $len /= 1000;
            $len .= "ms";
        }
        $start = int( $start );
        $start = time2str( '%C', $start );
        $out .= "<td>$start</td><td>$len</td><td><a href='/$root/func/?r=$rid'>func</a></tr>";
    }
    $out .= "</table>";
    $self->{'r'}->out( text => $out );
}

sub func {
    my ( $core, $self ) = @_;
    my $log = $core->get_mod( 'log' );
    
    my $r = $self->{'r'};
    my $q = $r->{'query'};
    if( !$q->{'r'} ) {
        $self->{'r'}->out( text => "No r set in query params" );
        return;
    }
    my $out;
    my $funcs = $log->get_request_funcs( $q->{'r'} );  
    
    my $cur;
    my @stack;
    my $root = $cur = { subs => [], id => -2, i => -2 };
    
    #for my $func ( @$funcs ) {
    #    my $type = $func->{'type'};
    #    my $i = $func->{'i'};
    #    if( $type == 1 ) {
    #        printf('1 %02i %02i %s %s'." $i\n", $func->{'rid'}, -1, $func->{'func'}, $func->{'class'} );
    #    }
    #    if( $type == 2 ) {
    #        printf('2 %02i %02i %s %s'." $i\n", $func->{'rid'}, $func->{'fid'}, $func->{'func'}, $func->{'class'} );
    #    }
    #}
    
    my $app = $core->get_app();
    my $map = $app->get_namespace_map();
    #print Dumper( $map );
    
    for( my $i=0;$i<=$#$funcs;$i++ ) {
        my $func = $funcs->[ $i ];
        my $type = $func->{'type'};
        if( $type == 1 ) { # entry
            my $shortname = $map->{ $func->{'class'} };
            #if( !$shortname ) {
            #    print "Cannot find ". $func->{'class'} . "\n";
            #}
            my $new = { subs => [], i => $func->{'i'}, class => $shortname, func => $func->{'func'}, start => $func->{'start'} };
            push( @{$cur->{'subs'}}, $new );
            push( @stack, $cur );
            $cur = $new;
        }
        elsif( $type == 2 ) { # exit
            my $fid = $func->{'fid'};
            if( ! defined $fid ) { $fid = -1; }
            my $cur_id = $cur->{'i'};
            my $end = $cur->{'end'} = $func->{'end'};
            my $start = $cur->{'start'} || 0;
            my $len = $end - $start;
            $len *= 1000;
            $len *= 100;
            $len = int( $len );
            $len /= 100;
            #$len .= "ms";
            $cur->{'len'} = $len;
            
            if( $cur_id == $fid ) {
                $cur = pop( @stack );
            }
            else {
                #print "$cur_id != $fid\n";
            }
        }
    }
    #my $sdump = Dumper( $root );
    #$out .= "<pre>$sdump</pre><br>";
    
    $out .="<table cellpadding=3 border=1 cellspacing=0>";
    
    $out .= do_lev( $root, 0 );
    
    $out .= "</table>";
    $self->{'r'}->out( text => $out );
}

sub do_lev {
    my ( $node, $dep ) = @_;
    my $out = '';
    if( $node->{'i'} >= 0 ) {
        my $class = $node->{'class'};
        my $func = $node->{'func'};
        my $len = $node->{'len'} || '';
        
        $out .= "<tr>";
        for( my $i=0;$i<$dep;$i++ ) {
            $out .= "<td></td><td></td><td></td><td></td>";
        }
        my $t = substr( $class, 0, 1 );
        $class = substr( $class, 2 );
        $out .= "<td>$t</td><td>$class</td><td>$func</td><td>$len</td>";
        $out .= "</tr>";
    }
    my $subs = $node->{'subs'};
    for my $sub ( @$subs ) {
        $out .= do_lev( $sub, $dep + 1 );
    }
    return $out;
}

sub log {
    my ( $core, $self ) = @_;
    my $log = $core->get_mod( 'log' );
    
    #my $dump = Dumper( $items );
    my @obs;
    my $out;
    
    my $r = $self->{'r'};
    my $q = $r->{'query'};
    my $nocore = 0;
    if( $q && $q->{'nocore'} ) {
        $nocore = 1;
    }
    
    my $items;
    
    my $single = 0;
    my $start_time;
    if( $q && $q->{'r'} ) {
        $items = $log->get_request_msgs( $q->{'r'}  );  
        $single = 1;
        my $rinfo = $log->get_request( $q->{'r'} );
        my $sdump = Dumper( $rinfo );
        $out .= "<pre>$sdump</pre><br>";
    }
    else {
        $items = $log->get_items();
    }
    my $first = $items->[ 0 ];
    $start_time = $first->{'time'} || 0;
    
    if( !$nocore ) {
        $out .= "<a href='?nocore=1'>hide core logs</a><br>";
    }
    else {
        $out .= "<a href='?'>show core logs</a><br>";
    }
    $out .= "
    <table cellpadding=3 border=1 cellspacing=0>";
    my $len = $#$items;
    
    for( my $i=$len;$i>=0;$i-- ) {
        #my $item = $items->[ $i ];
        #my ( $ob, $xml ) = XML::Bare->new( text => $item );
        #$xml = XML::Bare::simplify( $xml );
        my $xml = $items->[ $i ];
        my $type = $xml->{'type'} || '';
        my $text = $xml->{'text'} || '';
        my $time = $xml->{'time'} || 0;
        
        my $dif = 0;
        if( $i ) {
            my $prevt = $items->[ $i - 1 ]{'time'};
            $dif = $time - $prevt;
        }
        if( $single ) {
            $time -= $start_time;
            $time *= 1000 * 100;
            $time = int( $time );
            $time /= 100;
            
            $dif *= 1000 * 100;
            $dif = int( $dif );
            $dif /= 100;
        }
        my $rid = $xml->{'rid'} || '';
        my $tid = $xml->{'tid'} || '';
        my $trace = $xml->{'trace'} || '';
        $trace =~ s/,/<br>/g;
        if( $nocore && $trace =~ m|^Ginger/Reference| ) { next; }
        $out .= "<tr><td>$type</td><td>$text</td><td>$time</td><td>$dif</td><td>$rid</td><td>$trace</td><td>$tid</td></tr>";
    }
    $out .= "</table>";
    $self->{'r'}->out( text => $out );
}

sub login {
    my ( $core, $self ) = @_;
    my $base = $self->{'src'}{'base'};
    my $r = $self->{'r'};
    my $cookieman = $r->get_mod( mod => 'cookie_man' );
    
    if( $r->{'notice'} ) {
        #my $tmp = $r->{'tmp_notice'};
        #$core->set( 'html', $tmp );
        #print "Temp notice: $tmp\n";
        return;
    }
    #print Dumper( $r->{'postvars'} );
    
    $r->out( text => '<h2>Ginger::Reference Admin Login</h2>' );
    if( $r->{'type'} eq 'post' ) {
        my $postvars = $r->{'postvars'};
        my $user = $postvars->{'user'};
        my $pw = $postvars->{'pw'};
        $r->out( text => "Login attempt by $user<br>" );
        my $perm_man = $r->get_mod( mod => 'core_perm_man' );
        
        my $res = $perm_man->user_check_pw( user => $user, pw => $pw );
        if( $res->get_res('ok') ) {
            $r->out( text => "Admin login success<br>" );
            
            my $sessionman = $r->get_mod( mod => 'session_man' );
            $sessionman = $sessionman->{'src'}; # we want the global one, not the request specific one
            my $session = $sessionman->create_session();
            $session->set_user( user => $user );
            $session->save();
            $r->set_permissions( perms => $perm_man->user_get_permissions( user => $user ) );
            my $sid = $session->get_id();
            
            my $cookie = $cookieman->create( name => 'CORE', content => { session_id => $sid }, expires => [1,0,0,0] );
            #$cookieman->clear();
            #print Dumper( $cookie );
            $cookieman->add( cookie => $cookie );
            
            $r->redirect( url => "core/admin" );
        }
    }
    
    $r->out( text => "
    <form method='post' enctype='multipart/form-data' action='/$base/core/login/?postid=10'>
    <table>
        <tr>
            <td>User</td>
            <td><input type='text' name='user'></td>
        </tr>
        <tr>
            <td>Password</td>
            <td><input type='password' name='pw'></td>
        </tr>
        <!--<tr>
            <td>File</td>
            <td><input type='file' name='myfile'></td>
        </tr>-->
    </table>
    <input type='submit' value='Login'>
    </form>" );
    #$core->set( 'html', $html );
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