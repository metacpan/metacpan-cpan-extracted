package Labyrinth::Plugin::Articles::Profiles;

use warnings;
use strict;

use vars qw($VERSION);
$VERSION = '1.03';

=head1 NAME

Labyrinth::Plugin::Articles::Profiles - Profiles plugin for Labyrinth framework

=head1 DESCRIPTION

Contains all the profile handling functionality for Labyrinth.

This module forms part 1 of the Music Suite of modules for the Labyrinth 
framework.

The Profiles module only contains the basic handling of profiles currently. The
intention is to expand the stored data to include years active, in order to
create a Rock Family Tree style output, and example of which is included within
the distribution.

=head1 THE MUSIC SUITE

The Music Suite are a collection of modules, which can be used separately or
collectively, to help implement music related websites. These include modules 
for managing band member profiles, MP3s, lyrics and discographies.

=cut

# -------------------------------------
# Library Modules

use base qw(Labyrinth::Plugin::Articles);

use Labyrinth::Audit;
use Labyrinth::Variables;

# -------------------------------------
# Variables

use vars qw($ALLSQL $SECTIONID);

$ALLSQL     = 'AllArticles';
$SECTIONID  = 5;

# -------------------------------------
# Public Methods

sub List {
    $cgiparams{sectionid} = $SECTIONID;
    shift->SUPER::List;
    $tvars{profiles} = $tvars{mainarts};
}

sub Item {
    shift->SUPER::Item;
    $tvars{who} = $tvars{articles}->{$tvars{primary}};
}

# -------------------------------------
# Admin Methods

sub Admin {
    $cgiparams{sectionid} = $SECTIONID;
    shift->SUPER::Admin;
}

sub Edit {
    shift->SUPER::Edit;
    $tvars{who} = $tvars{articles}->{$tvars{primary}};
}

1;

__END__

# -------------------------------------
# Documentation

=head1 PUBLIC INTERFACE METHODS

=over 4

=item List

Retrieves an initial list of profile entries. Primarily used to prepare a front
page.

=item Item

Provides a single profile entry.

=back

=head1 ADMIN INTERFACE METHODS

=over 4

=item Access

Check whether user has the appropriate admin access.

=item Admin

Lists the current set of profile entries.

Also provides the delete, copy and promote functionality from the main
administration page for the given section.

=item Add

Add a profile entry.

=item Edit

Edit a profile entry.

=item Save

Save a profile entry.

=item Delete

Delete a profile entry.

=item AddParagraph

Add a text block to the current article.

=item AddImage

Add an image block to the current article.

=item AddLink

Add a link block to the current article.

=item DeleteItem

Delete an article block.

=item Relocate

Relocate an article in a list, where an order is in use.

=back

=head1 SEE ALSO

  Labyrinth

=head1 AUTHOR

Barbie, <barbie@missbarbell.co.uk> for
Miss Barbell Productions, L<http://www.missbarbell.co.uk/>

=head1 COPYRIGHT & LICENSE

  Copyright (C) 2002-2015 Barbie for Miss Barbell Productions
  All Rights Reserved.

  This distribution is free software; you can redistribute it and/or
  modify it under the Artistic Licence v2.

=cut
