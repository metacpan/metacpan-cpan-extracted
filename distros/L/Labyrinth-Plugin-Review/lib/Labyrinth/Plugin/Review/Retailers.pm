package Labyrinth::Plugin::Review::Retailers;

use warnings;
use strict;

use vars qw($VERSION);
$VERSION = '1.01';

=head1 NAME

Labyrinth::Plugin::Review::Retailers - Retailers plugin for the Labyrinth framework

=head1 DESCRIPTION

Contains all the functionality for managing retailers used in reviews.

=cut

# -------------------------------------
# Library Modules

use base qw(Labyrinth::Plugin::Base);

use Labyrinth::Audit;
use Labyrinth::MLUtils;
use Labyrinth::Variables;

use Data::Dumper;

# -------------------------------------
# Variables

# type: 0 = optional, 1 = mandatory
# html: 0 = none, 1 = text, 2 = textarea

my %fields = (
    retailerid      => { type => 0, html => 0 },
    retailer        => { type => 1, html => 1 },
    retailerlink    => { type => 1, html => 1 },
);

my (@mandatory,@allfields);
for(keys %fields) {
    push @mandatory, $_     if($fields{$_}->{type});
    push @allfields, $_;
}

# -------------------------------------
# The Subs

=head1 ADMIN INTERFACE METHODS

=over 4

=item * Access

Check default access to the Admin methods

=item * Admin

List retailers for administration purposes.

=item * Add

Add a retailer.

=item * Edit

Edit a retailer.

=item * Save

Save a retailer.

=item * Delete

Delete one or more retailers.

=back

=cut

sub Access  { Authorised(PUBLISHER) }

sub Admin {
    return  unless AccessUser(PUBLISHER);

    if($cgiparams{doaction}) {
           if($cgiparams{doaction} eq 'Delete') { Delete(); }
    }

    my @rows = $dbi->GetQuery('hash','AllRetailers');
    $tvars{data} = \@rows   if(@rows);
}

sub Add {
    return  unless AccessUser(PUBLISHER);
}

sub Edit {
    return  unless AccessUser(PUBLISHER);
    return  unless AuthorCheck('GetRetailerByID','retailerid',PUBLISHER);
}

sub Save {
    return  unless AuthorCheck('GetRetailerByID','retailerid',PUBLISHER);
    return  if FieldCheck(\@allfields,\@mandatory);

    for(keys %fields) {
        if($fields{$_}->{html} == 1)    { $tvars{data}->{$_} = CleanHTML($tvars{data}->{$_}) }
        elsif($fields{$_}->{html} == 2) { $tvars{data}->{$_} = CleanTags($tvars{data}->{$_}) }
    }

    my @fields = (  
        $tvars{data}->{retailer},
        $tvars{data}->{retailerlink}
    );

    # store review details
    if($tvars{data}->{retailerid})
            { $dbi->DoQuery('SaveRetailer',@fields,$tvars{data}->{retailerid}); }
    else    { $cgiparams{retailerid} = $dbi->IDQuery('AddRetailer',@fields); }

    $tvars{thanks} = 1;
}

sub Delete {
    return  unless AccessUser(PUBLISHER);
    my @ids = CGIArray('LISTED');
    return  unless @ids;

    $dbi->DoQuery('DeleteRetailers',{ ids => join(',',@ids) });
}

1;

__END__

=head1 SEE ALSO

  Labyrinth

=head1 AUTHOR

Barbie, <barbie@missbarbell.co.uk> for
Miss Barbell Productions, L<http://www.missbarbell.co.uk/>

=head1 COPYRIGHT & LICENSE

  Copyright (C) 2002-2015 Barbie for Miss Barbell Productions
  All Rights Reserved.

  This module is free software; you can redistribute it and/or
  modify it under the Artistic License 2.0.

=cut
