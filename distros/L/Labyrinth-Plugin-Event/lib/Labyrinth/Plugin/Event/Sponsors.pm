package Labyrinth::Plugin::Event::Sponsors;

use warnings;
use strict;

use vars qw($VERSION);
$VERSION = '1.10';

=head1 NAME

Labyrinth::Plugin::Event::Sponsors - Event Sponsor handler for the Labyrinth framework.

=head1 DESCRIPTION

Contains all the event sponsor functionality for Labyrinth.

=cut

# -------------------------------------
# Library Modules

use base qw(Labyrinth::Plugin::Base);

use Clone qw(clone);

use Labyrinth::DBUtils;
use Labyrinth::MLUtils;
use Labyrinth::Support;
use Labyrinth::Variables;

# -------------------------------------
# Variables

# type: 0 = optional, 1 = mandatory
# html: 0 = none, 1 = text, 2 = textarea


my %fields = (
    sponsorid   => { type => 0, html => 0 },
    sponsor     => { type => 1, html => 1 },
    sponsorlink => { type => 0, html => 1 },
);

my (@mandatory,@allfields);
for(keys %fields) {
    push @mandatory, $_     if($fields{$_}->{type});
    push @allfields, $_;
}

our $INDEXKEY   = 'sponsorid';
our $LEVEL      = ADMIN;

# -------------------------------------
# The Subs

=head1 PUBLIC INTERFACE METHODS

=over 4

=item SponsorSelect

Provides a dropdown list of sponsors available.

=back

=cut

sub SponsorSelect {
    my ($self,$opt,$blank) = @_;
    $blank ||= 0;

    my @rows = $dbi->GetQuery('hash','AllSponsors');
    my @list;
    for(@rows) { push @list, { id => $_->{sponsorid}, value => $_->{sponsor} }; }
    unshift @list, { id => 0, value => 'Select Sponsor' }   if($blank == 1);
    DropDownRows($opt,$INDEXKEY,'id','value',@list);
}

=head1 ADMIN INTERFACE METHODS

=over 4

=item Admin

Provides list of the sponsors currently available.

=item Add

Add a new sponsor.

=item Edit

Edit an existing sponsor.

=item Save

Save the current sponsor.

=item Delete

Delete a sponsor.

=back

=cut

sub Admin {
    return  unless AccessUser(EDITOR);

    if($cgiparams{doaction}) {
        if($cgiparams{doaction} eq 'Delete') { Delete(); }
    }

    my @rows = $dbi->GetQuery('hash','AllSponsors');
    $tvars{data} = \@rows   if(@rows);
}

sub Add {
    return  unless AccessUser(EDITOR);
    $tvars{data} = {
        sponsor     => 'Sponsor',
        sponsorlink => ''
    };
}

sub Edit {
    return  unless AccessUser(EDITOR);
    return  unless AuthorCheck('GetSponsorByID',$INDEXKEY,EDITOR);
}

sub Save {
    return  unless AccessUser(EDITOR);
    return  unless AuthorCheck('GetSponsorByID',$INDEXKEY,EDITOR);

    return  if FieldCheck(\@allfields,\@mandatory);

    for(keys %fields) {
        next    unless($fields{$_});
           if($fields{$_}->{html} == 1) { $tvars{data}->{$_} = CleanHTML($tvars{data}->{$_}) }
        elsif($fields{$_}->{html} == 2) { $tvars{data}->{$_} = CleanTags($tvars{data}->{$_}) }
    }

    my @fields = (  
        $tvars{data}->{sponsor},
        $tvars{data}->{sponsorlink}
    );

    if($cgiparams{$INDEXKEY})
            { $dbi->DoQuery('SaveSponsor',@fields,$cgiparams{$INDEXKEY}); }
    else    { $cgiparams{$INDEXKEY} = $dbi->IDQuery('AddSponsor',@fields); }
}

sub Delete {
    return  unless AccessUser(ADMIN);
    my @ids = CGIArray('LISTED');

    return  unless @ids;

    $dbi->DoQuery('DeleteSponsors',{ids => join(',',@ids)});
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
