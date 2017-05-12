package Labyrinth::Plugin::Review::Types;

use warnings;
use strict;

use vars qw($VERSION);
$VERSION = '1.01';

=head1 NAME

Labyrinth::Plugin::Review::Types - Review Types plugin for the Labyrinth framework

=head1 DESCRIPTION

Contains all the functionality for managing review types for reviews.

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
    reviewtypeid    => { type => 0, html => 0 },
    typename        => { type => 1, html => 1 },
    typeabbr        => { type => 1, html => 1 },
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

List entries for administration purposes.

=item * Add

Add a review type.

=item * Edit

Edit a review type.

=item * Save

Save a review type.

=item * Delete

Delete one or more review types.

=back

=cut

sub Access  { Authorised(PUBLISHER) }

sub Admin {
    return  unless AccessUser(PUBLISHER);

    if($cgiparams{doaction}) {
           if($cgiparams{doaction} eq 'Delete') { Delete(); }
    }

    my @rows = $dbi->GetQuery('hash','AllReviewTypes');
    $tvars{data} = \@rows   if(@rows);
}

sub Add {
    return  unless AccessUser(PUBLISHER);
}

sub Edit {
    return  unless AccessUser(PUBLISHER);
    return  unless AuthorCheck('GetReviewTypeByID','reviewtypeid',PUBLISHER);
}

sub Save {
    return  unless AuthorCheck('GetReviewTypeByID','reviewtypeid',PUBLISHER);
    return  if FieldCheck(\@allfields,\@mandatory);

    for(keys %fields) {
        if($fields{$_}->{html} == 1)    { $tvars{data}->{$_} = CleanHTML($tvars{data}->{$_}) }
        elsif($fields{$_}->{html} == 2) { $tvars{data}->{$_} = CleanTags($tvars{data}->{$_}) }
    }

    my @fields = (  
        $tvars{data}->{typename},
        $tvars{data}->{typeabbr}
    );

    # store review details
    if($tvars{data}->{reviewtypeid})
            { $dbi->DoQuery('SaveReviewType',@fields,$tvars{data}->{reviewtypeid}); }
    else    { $cgiparams{reviewtypeid} = $dbi->IDQuery('AddReviewType',@fields); }

    $tvars{thanks} = 1;
}

sub Delete {
    return  unless AccessUser(PUBLISHER);
    my @ids = CGIArray('LISTED');
    return  unless @ids;

    $dbi->DoQuery('DeleteReviewTypes',{ ids => join(',',@ids) });
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
