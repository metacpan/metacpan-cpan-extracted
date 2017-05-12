# Ginger::Reference::Request::Manager::Default
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

Ginger::Reference::Request::Manager::Default - Ginger::Reference Component

=head1 VERSION

0.02

=cut

package Ginger::Reference::Request::Manager::Default;
use Class::Core 0.03 qw/:all/;
use strict;
use vars qw/$VERSION/;
use Ginger::Reference::Request::Default 0.01;
use Date::Format;
$VERSION = "0.02";

sub init {
    my ( $core, $self ) = @_;
    my $app = $core->get_app();
    $app->register_class( name => 'req', file => 'Ginger::Reference::Request::Default' ); 
}

my $rid = 0;

sub new_request {
    my ( $core, $manager ) = @_;
        
    my $v = $core->get_all(); # path,query,post,cookies,up,postvars,type, more?
    $v->{'app'} = $core->get_app();
    
    $rid++;
    my $now = time2str('%X', time);
    $v->{'id'} = $v->{'id'}. '.' . $rid . '.' . $now;
    my $req = $core->create( 'req', %$v );
    $req->{'r'} = $req;
    
    $req->init();
    
    return $req;
    #app
    #  conf
    #  obj
    #  r
    #  session
    #  modhash ( modules by name )
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