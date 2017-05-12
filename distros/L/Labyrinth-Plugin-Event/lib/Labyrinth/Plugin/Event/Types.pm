package Labyrinth::Plugin::Event::Types;

use warnings;
use strict;

use vars qw($VERSION);
$VERSION = '1.10';

=head1 NAME

Labyrinth::Plugin::Event::Types - Event Type handler for the Labyrinth framework.

=head1 DESCRIPTION

Contains all the event type functionality for Labyrinth.

This package can be overridden to extended to the event types available.

=cut

# -------------------------------------
# Library Modules

use base qw(Labyrinth::Plugin::Base);

use Labyrinth::MLUtils;
use Labyrinth::Variables;

# -------------------------------------
# Variables

my %eventtypes;
our $AUTOLOAD;

# -------------------------------------
# The Subs

=head1 Pub INTERFACE METHODS

=over 4

=item SetType<n>

An AUTOLOADed method to set the event type. Note if the type does not exist
within the database, the value is set to 0.

=item EventType

Provides the name of a specified event type.

=item EventTypeSelect

Provides a dropdown list of event types available.

=back

=cut

sub AUTOLOAD {
    my $self = shift;
    ref($self) or die "$self is not an object";

    my $name = $AUTOLOAD;
    $name =~ s/.*://; # strip fully-qualified portion

    my ($type) = $name =~ /SetType(\d+)/;
    if($type) {
        my @rows = $dbi->GetQuery('hash','GetEventType',$type);
        if(@rows)   { $cgiparams{eventtypeid} = $type }
        else        { $cgiparams{eventtypeid} = 0     }
    }   else        { $cgiparams{eventtypeid} = 0     }
}

sub EventType {     
    my ($self,$type) = @_;

    unless(%eventtypes) {
        my @rows = $dbi->GetQuery('hash','AllEventTypes');
        $eventtypes{$_->{eventtypeid}} = $_->{eventtype}    for(@rows);
    }

    return $eventtypes{$type} || '';
}

sub EventTypeSelect {
    my ($self,$opt,$blank) = @_;
    $blank ||= 0;

    unless(%eventtypes) {
        my @rows = $dbi->GetQuery('hash','AllEventTypes');
        $eventtypes{$_->{eventtypeid}} = $_->{eventtype}    for(@rows);
    }

    my @list = map { { 'id' => $_, 'value' => $eventtypes{$_} } } sort keys %eventtypes;
    unshift @list, { id => 0, value => 'Select An Event Type' } if($blank == 1);
    return DropDownRows($opt,'eventtypeid','id','value',@list);
}

1;

__END__

=head1 SEE ALSO

L<Labyrinth>

=head1 AUTHOR

Barbie, <barbie@missbarbell.co.uk> for
Miss Barbell Productions, L<http://www.missbarbell.co.uk/>

=head1 COPYRIGHT & LICENSE

  Copyright (C) 2002-2015 Barbie for Miss Barbell Productions
  All Rights Reserved.

  This module is free software; you can redistribute it and/or
  modify it under the Artistic License 2.0.

=cut
