package Labyrinth::Plugin::Event::Venues;

use warnings;
use strict;

use vars qw($VERSION);
$VERSION = '1.10';

=head1 NAME

Labyrinth::Plugin::Event::Venues - Venues administration for the Labyrinth framework.

=head1 DESCRIPTION

Contains all the venue administration functionality for Labyrinth.

=cut

# -------------------------------------
# Library Modules

use base qw(Labyrinth::Plugin::Base);

use Labyrinth::DBUtils;
#use Labyrinth::Media;
use Labyrinth::MLUtils;
use Labyrinth::Support;
use Labyrinth::Variables;

use Clone qw(clone);

# -------------------------------------
# Constants

# withdrawn, may be reintroduced later
#use constant    MaxVenueWidth    => 400;
#use constant    MaxVenueHeight   => 400;

# -------------------------------------
# Variables

my (@mandatory, @allfields);

# type: 0 = optional, 1 = mandatory
# html: 0 = none, 1 = text, 2 = textarea

my %fields = (
    eventid     => { type => 0, html => 0 },    # only applicable when adding via an event
    venueid     => { type => 0, html => 0 },
    venue       => { type => 1, html => 1 },
    venuelink   => { type => 0, html => 2 },
    address     => { type => 1, html => 1 },
    addresslink => { type => 0, html => 2 },
    info        => { type => 0, html => 2 },
);

for(keys %fields) {
    push @mandatory, $_     if($fields{$_}->{type});
    push @allfields, $_;
}

my @savefields  = qw(venue venuelink address addresslink info);
my $INDEXKEY    = 'venueid';
my $ALLSQL      = 'AllVenues';
my $SAVESQL     = 'SaveVenue';
my $ADDSQL      = 'AddVenue';
my $GETSQL      = 'GetVenueByID';
my $DELETESQL   = 'DeleteVenue';
my $LEVEL       = ADMIN;

# -------------------------------------
# The Subs

=head1 PUBLIC INTERFACE METHODS

=over 4

=item Current

Current list of venues for events.

=back

=cut

sub Current {
    my %venues;
    for my $event ($tvars{next},@{$tvars{future}}) {
        $venues{$event->{venueid}}->{$_} = $event->{$_} for(grep {$event->{$_}} qw(venueid venue venuelink address addresslink info));
    }
    my @venues = map {$venues{$_}} sort {$venues{$a}->{venue} cmp $venues{$b}->{venue}} keys %venues;
    $tvars{venues} = \@venues   if(@venues);
}

=head1 ADMIN INTERFACE METHODS

=over 4

=item Admin

Provides list of the venues currently available.

=item Add

Add a new venue.

=item Edit

Edit an existing venue.

=item Save

Save the current venue.

=item Delete

Delete a venue.

=back

=cut

sub Admin {
    return  unless AccessUser(EDITOR);
    if($cgiparams{doaction}) {
        if($cgiparams{doaction} eq 'Delete') { Delete(); }
    }
    my @rows = $dbi->GetQuery('hash',$ALLSQL);
    $tvars{data} = \@rows   if(@rows);
}

sub Edit {
    return  unless AccessUser(EDITOR);
    if($cgiparams{$INDEXKEY}) {
        my @rows = $dbi->GetQuery('hash',$GETSQL,$cgiparams{$INDEXKEY});
        $tvars{data}->{$_} = $rows[0]->{$_}   for(keys %{$rows[0]});
    }
    $tvars{preview} = clone($tvars{data});
    my $view = $tvars{preview};
    my $data = $tvars{data};
    for(keys %fields) {
           if($fields{$_}->{html} == 1) { $data->{$_} = CleanHTML($data->{$_}) }
        elsif($fields{$_}->{html} == 2) { $data->{$_} =  SafeHTML($data->{$_});
                                          $view->{$_} = CleanTags($view->{$_}) }
        elsif($fields{$_}->{html} == 3) { $data->{$_} = CleanLink($data->{$_});
                                          $view->{$_} = CleanLink($view->{$_}) }
    }
}

sub Save {
    return  unless AccessUser(EDITOR);
    for(keys %fields) {
           if($fields{$_}->{html} == 1) { $cgiparams{$_} = CleanHTML($cgiparams{$_}) }
        elsif($fields{$_}->{html} == 2) { $cgiparams{$_} = CleanTags($cgiparams{$_}) }
        elsif($fields{$_}->{html} == 3) { $cgiparams{$_} = CleanLink($cgiparams{$_}) }
    }
    return  if FieldCheck(\@allfields,\@mandatory);
    my @fields = map {$tvars{data}->{$_}} @savefields;
    if($cgiparams{$INDEXKEY})
            { $dbi->DoQuery($SAVESQL,@fields,$cgiparams{$INDEXKEY}); }
    else    { $cgiparams{venueid} = $dbi->IDQuery($ADDSQL,@fields); }

    # the following code has been withdrawn, but may be reintroduced in a later
    # version of this dtistribution.
    #
    # upload new photos
    #my $inx = 0;
    #my $width  = $settings{"venuewidth"}  || MaxVenueWidth;
    #my $height = $settings{"venueheight"} || MaxVenueHeight;
    #while($cgiparams{"file_$inx"}) {
    #    my ($imageid,$imagelink) =
    #        SaveImageFile(  param   => "file_$inx",
    #                        stock   => 'Special',
    #                        width   => $width,
    #                        height  => $height);
    #    $dbi->DoQuery('AddVenueImage',$cgiparams{venueid},$imageid);
    #    $inx++;
    #}
}

sub Delete {
    return  unless AccessUser(ADMIN);
    my @ids = CGIArray('LISTED');
    return  unless @ids;

    $dbi->DoQuery($DELETESQL,{ids => join(",",@ids)});
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
