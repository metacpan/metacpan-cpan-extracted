# Ginger::Reference::Session::Default
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

Ginger::Reference::Session::Default - Ginger::Reference Component

=head1 VERSION

0.02

=cut

package Ginger::Reference::Session::Default;
use strict;
use Class::Core qw/:all/;
use vars qw/$VERSION/;
use XML::Bare;
use Data::Dumper;
$VERSION = "0.02";

sub construct {
    my ( $core, $self ) = @_;
    $self->{'dat'} = { test => 'blahblah' };
    #print "Constructing a session\n";
}

# called at the end of a session
sub cleanup {
}

sub register_cleanup {
    
}

sub show {
    my ( $core, $self, ) = @_;
    my $dat = $self->{'dat'};
    print "Session:\n  ".Dumper( $dat );
}

sub de_serialize {
    my ( $core, $self ) = @_;
    my $raw = $core->get('raw');
    my ( $ob, $xml ) = new XML::Bare( text => $raw );
    $self->{'dat'} = XML::Bare::simplify( $xml );
    return $self;
}

sub get_user {
    my ( $core, $self ) = @_;
    return $self->{'dat'}{'user'};
}

sub set_user {
    my ( $core, $self ) = @_;
    $self->{'dat'}{'user'} = $core->get('user');
}

sub save {
    my ( $core, $self ) = @_;
    $self->{'man'}->save_session( id => $self->{'id'}, data => $self );
}

sub serialize {
    my ( $core, $self ) = @_;
    return Class::Core::_hash2xml( $self->{'dat'} );
}

sub get_id {
    my ( $core, $self ) = @_;
    return $self->{'id'};
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