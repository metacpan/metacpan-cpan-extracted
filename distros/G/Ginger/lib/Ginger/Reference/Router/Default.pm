# Ginger::Reference::Router::Default
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

Ginger::Reference::Router::Default - Ginger::Reference Component

=head1 VERSION

0.02

=cut

package Ginger::Reference::Router::Default;
use strict;
use Class::Core 0.03 qw/:all/;
use Data::Dumper;
use XML::Bare qw/xval forcearray/;
use vars qw/$VERSION/;
$VERSION = "0.02";

sub init {
    my ( $core, $self_src ) = @_;
    $self_src->{'path_routes'} = {};
    my $base = $self_src->{'base'} = xval( $core->get_conf()->{'base'} );
    my $app = $core->get_app();
    my $xml = $self_src->{'_xml'};
    # <session name='CORE' perms='core_perm_man' />
    #$Data::Dumper::Maxdepth = 2;
    #$core->dumperx( "self_src", $self_src->{'_xml'} );
    
    my $log = $self_src->{'log'} = $app->get_mod( mod => 'log' );
    #$self_src->{'perm'} = $app->get_mod( mod => 'perm_man' );
    $log->note( text => "Routing with web base of: $base" );
}

sub read_routes {
    my ( $core, $self_src ) = @_;
    my $xml = $self_src->{'_xml'};
    my $log = $core->get_mod('log');
    
    my $sessions = forcearray( $xml->{'session'} );
    my $sesshash = $self_src->{'sesshash'} = {};
    for my $session ( @$sessions ) {
        my $name = xval $session->{'name'};
        my $perm_mod_name =  xval $session->{'perms'};
        my $perm_mod = $core->get_mod( $perm_mod_name );
        $sesshash->{ $name } = $perm_mod;
    }
    
    if( $xml->{'routes'} ) {
        #$core->dumperx('routes', $xml->{'routes'} );
        my $route_sets = forcearray( $xml->{'routes'} );
        for my $routes ( @$route_sets ) {
            my $ob;
            my $rs;
            if( $routes->{'file'} ) {
                my $fname = xval( $routes->{'file'} );
                ( $ob, $rs ) = XML::Bare->new( file => $fname );
                #$core->dumperx('rs', $rs );
                $rs = $rs->{'xml'};
            }
            else {
                $rs = $routes;
            }
            $self_src->proc_xml( xml => $rs );
        }
    }
}

sub route {
    my ( $core, $self ) = @_;
    my $sman  = $core->get('session_man');
    my $r     = $self->{'r'};
    my $path  = $r->{'path'};
    my $query = $r->{'query'};
    my $post  = $r->{'post'};
    my $app   = $self->{'obj'}{'_app'}; # perhaps $core->get_app() would be better here
    my $rs    = $self->{'src'}{'path_routes'};
    my $log   = $core->get_mod('log');
    
    #my $perm  = $self->{'src'}{'perm'};
    
    my $base = $self->{'src'}{'base'};
    if( $base ne '' && $path =~ m|^/$base/(.+)| ) {
        $path = $1;
    }
    else {
        $r->out( text => 'error' );
        $r->not_found(); 
        return;
    }
    
    my $opath = $path;
    $path =~ s|^/||g;
    $path =~ s|/$||g;
    
    my $resolved = 0;
    my $full = 1;
    my @parts = split('/',$path );
    my $tpl = 0;
    my $tple = 0;
    while( @parts ) {
        my $joined = join('/', @parts );
        my $route;
        if( $route = $rs->{ $joined } ) {
            my $leftover = $opath;
            $leftover =~ s|^/?$joined||g;
            $r->{'leftover'} = $leftover;
            $log->note( text => "joined: $joined, leftover: $leftover" );
            
            my $set = $route->{'set'};
            my $info;
            for my $ainfo ( @$set ) {
                if( $ainfo->{'regex'} ) {
                    if( $leftover =~ $ainfo->{'regex'} ) {
                        $info = $ainfo;
                    }
                    else {
                        $log->note( text => "$leftover does not match ".$ainfo->{'regex'} );
                    }
                }
                else {
                    $info = $ainfo;
                }
            }
            if( $info ) {
                my $objname      = $info->{'obj'};
                my $obj          = $r->get_mod( mod => $objname );
                my $func         = $info->{'func'};
                my $session_name = $info->{'session'} || 'DEFAULT';
                my $perm = $self->{'src'}{'sesshash'}{ $session_name };
                if( !$perm ) {
                    eval('use Data::Dumper');
                    $Data::Dumper::Maxdepth = 2;
                    print Dumper( $self->{'src'} );
                    die "No map from session $session_name to perm module";
                }
                
                my $bounce       = $info->{'bounce'};
                my $extra        = $info->{'extra'} || {};
                
                my $session      = $sman->get_session( r => $r, cookie => $session_name );
                
                if( $session ) {
                    $r->log_start( sid => $session->{'session_id'}, url => $opath );
                    my $cookieman = $r->get_mod( mod => 'cookie_man' );
                    my $cookie = $cookieman->extend( cookie => $session_name, len => [ 1, 0, 0, 0 ] );
                    my $date = $cookie->{'expires'};
                    $log->note( text => "Loaded a session - extended cookie till $date" );
                    $session->show();
                    $r->set_permissions( perms => $perm->user_get_permissions( user => $session->get_user() ) );
                }
                else {
                    if( $bounce ) {
                        $log->note( text =>  "Bounce to $bounce" );
                        $r->redirect( url => $bounce );
                        return;
                    }
                    $r->log_start( sid => 'none', url => $opath );
                }
                
                if( $full && $info->{'folder'} && $opath !~ m|/$| ) {
                    $r->redirect( url => "$path/" );
                    return;
                }
                
                #$core->dumper( 'extra', $extra );
                if( %$extra && $extra->{'tpls'} ) {
                    $tpl = $extra->{'tpl'} = $core->requestify( $extra->{'tpls'}, $r );
                    my $conf = $extra->{'conf'};
                    my $atpl = $conf->{'tpl'};
                    
                    $tpl->{'mod_to_use'} = $atpl->{'mod'} ? $core->get_mod( $atpl->{'mod'} ) : $obj;
                    
                    my $map = $conf->{'map'};
                    if( $map ) {
                        $tple = $core->get_mod('tpl_engine');
                        $tple->run_map( map => $map );
                    }
                }
                my $res = $obj->$func( %$extra );
                if( $tpl ) {
                    my $text = $tpl->run();
                    if( $text ) {
                        $r->out( text => $text );
                    }
                }
                $resolved = 1;
                $r->log_end();
                last;
            }
            else {
                $log->error( text => "Match but regex fail" );
            }
        }
        $full = 0;
        pop @parts;
    }
    
    if( !$resolved ) {
        $r->not_found();
        my $out = '';
        $out .= "<h2>Unhandled URL</h2>";
        $out .= "Path: $path<br>";
        $out .= "Query: ".Dumper($query)."<br>";
        $post ||= '';
        $out .= "Post: $post<br>";
        $r->out( text => $out );
    }
}

# process xml
sub proc_xml {
    my ( $core, $self_src ) = @_;
    
    my $log = $core->get_mod('log');
    my $tpl_engine = $core->get_mod( 'tpl_engine', 0 ); # 0 is to say this module is not required
    if( $tpl_engine ) {
        $self_src->{'tpl_engine'} = $tpl_engine;
        $log->note( text => "Router will read in templates");
    }
    else {
        $log->note( text => "Router will not read in templates");
    }
    
    my $xml = $core->get('xml');
    #$core->dumperx( 'xml', $xml );
    my $routes = forcearray( $xml->{'route'} ); delete $xml->{'route'};
    my $groups = forcearray( $xml->{'group'} ); delete $xml->{'group'};
    my $folders = forcearray( $xml->{'folder'} ); delete $xml->{'folder'};
    my $conf = $xml;
    #$core->dumper( 'routes', $routes );
    #$core->dumperx( 'conf', $conf );
    if( @$groups ) {
        for my $group ( @$groups ) {
            handle_group( $core, $self_src, $conf, $group );
        }
    }
    if( @$routes ) {
        for my $route ( @$routes ) {
            #$core->dumper( 'route', $route );
            handle_route( $core, $self_src, $conf, $route );
        }
    }
    if( @$folders ) {
        my $fs = $core->get_mod( 'file_server' );
        $fs->register_folders( folders => $folders, conf => $conf );
    }
}

sub handle_group {
    my ( $core, $self_src, $conf, $xml ) = @_;
    my $routes = forcearray( $xml->{'route'} ); delete $xml->{'route'};
    my $groups = forcearray( $xml->{'group'} ); delete $xml->{'group'};
    my $folders = forcearray( $xml->{'folder'} ); delete $xml->{'folder'};
    my $new_conf = $xml;
    my $mux = Ginger::Reference::Core::mux_dup( $conf, $new_conf );
    if( @$groups ) {
        for my $group ( @$groups ) {
            handle_group( $core, $self_src, $mux, $group );
        } 
    }
    if( @$routes ) {
        for my $route ( @$routes ) {
            handle_route( $core, $self_src, $mux, $route );
        }
    }
    if( @$folders ) {
        my $fs = $core->get_mod( 'file_server' );
        $fs->register_folders( folders => $folders, conf => $conf );
    }
}

sub handle_route {
    my ( $core, $self_src, $conf, $route ) = @_;
    #$core->dumperx( 'conf', $conf );
    my $mux = Ginger::Reference::Core::mux_dup( $conf, $route );
    #$core->dumperx( 'conf muxed with route', $conf );
    # in theory the conf here should be a mux of all the parent confs
    #my $obj     = xval $conf->{'obj'};
    #my $func    = xval $conf->{'func'};
    #my $session = xval $conf->{'session'};
    #my $bounce  = xval $conf->{'bounce'};
    #my $folder  = xval $conf->{'folder'};
    #my $extra   = xval $conf->{'extra'};
    #if( $extra ) { $extra = XML::Bare::simplify( $extra ); }
       
    my $info = XML::Bare::simplify( $mux );
    
    my $tple = $self_src->{'tpl_engine'};
    if( $tple && $mux->{'tpl'} ) {
        my $tplxml = $mux->{'tpl'};
        my $tpl;
        
        #$core->dumper( 'tplxml', $tplxml );
        if( $tplxml->{'file'} ) {
            $tpl = $tple->load_xml( xml => $tplxml );
        }
        else {
            my $tplname = xval $tplxml->{'name'};
            $tpl = $tple->get( name => $tplname );
        }
        $info->{'extra'} = { tpls => $tpl, conf => $info };
    }
    
    #$core->dumper( 'info', $info );
    $self_src->route_path( %$info );
}

# Note that this should only be called from init functions
sub route_path {
    my ( $core, $self_src ) = @_;
    # path    - the path to handle
    # obj     - name of the module containing the handling function
    # func    - the name of the function that handles the page
    # session - the cookie name that contains a valid session key
    # bounce  - whether or not to bounce if there is no key, and where to bounce to
    # extra   - other information to pass along
    #my ( $path, $obj, $func, $session, $bounce, $extra, $file ) = $core->get_arr( qw/path obj func session bounce extra file/ );
    my $in = $core->get_all();
    my %parms = ( %$in );
    $parms{'folder'} = $parms{'file'} ? 0 : 1;
    
    #print "Adding path to $path\n";
    my $log = $core->get_mod('log');
    my $routes = $self_src->{'path_routes'};
    my $path = $parms{'path'};
    $log->note( text => "Routing $path to ".$parms{'obj'}."-".$parms{'func'} );
    if( $routes->{ $path } ) {
        my $set = $routes->{ $path }{'set'};
        push( @$set, \%parms );
    }
    else {
        $self_src->{'path_routes'}{ $path } = {
            set => [ \%parms ]
        };
    }
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