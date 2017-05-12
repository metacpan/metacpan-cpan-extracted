package Labyrinth::Plugin::Articles::Lyrics;

use warnings;
use strict;

use vars qw($VERSION);
$VERSION = '1.03';

=head1 NAME

Labyrinth::Plugin::Articles::Lyrics - Lyrics plugin for the Labyrinth framework

=head1 DESCRIPTION

Contains all the lyrics handling functionality, as part of the Music Suite of
modules for the Labyrinth web framework.

=head1 DESCRIPTION

Contains all the lyrics handling functionality for Labyrinth.

This module forms part 2 of the Music Suite of modules for the Labyrinth web
framework.

The Lyrics module only contains the basic handling of lyrics. With a future 
distribution, the lyrics and/or poems can be grouped into collections, which 
can then be attributed as a release, such as an album or book.

=head1 THE MUSIC SUITE

The Music Suite are a collection of modules, which can be used separately or
collectively, to help implement music related websites. These include modules 
for managing band member lyrics, MP3s, lyrics and discographies.

=cut

# -------------------------------------
# Library Modules

use base qw(Labyrinth::Plugin::Articles);

use Labyrinth::Audit;
use Labyrinth::DBUtils;
use Labyrinth::MLUtils;
use Labyrinth::Variables;

# -------------------------------------
# Variables

my $ALLSQL      = 'AllArticles';
my $SECTIONID   = 7;

# -------------------------------------
# Public Methods

sub List {
    $cgiparams{sectionid}          = $SECTIONID;
    $settings{data}{article_limit} = $settings{lyrics_limit};
    $settings{data}{article_stop}  = $settings{lyrics_stop};
    $settings{data}{order}         = 'title';
    shift->SUPER::List;
}

# -------------------------------------
# Admin Methods

sub Admin {
    $cgiparams{sectionid} = $SECTIONID;
    shift->SUPER::Admin;
}

sub LyricSelect {
    my ($opt,$blank) = @_;
    my @list = $dbi->GetQuery('hash',$ALLSQL,{where => "WHERE sectionid=$SECTIONID"});
    unshift @list, {articleid=>0,title=>'Select Lyric'} if(defined $blank && $blank == 1);
    DropDownRows($opt,'lyricid','articleid','title',@list);
}

1;

__END__

# -------------------------------------
# Documentation

=head1 PUBLIC INTERFACE METHODS

=over 4

=item List

Retrieves an initial list of lyric entries. Primarily used to prepare a front
page.

=item Item

Provides a single lyric entry.

=back

=head1 ADMIN INTERFACE METHODS

=over 4

=item Access

Check whether user has the appropriate admin access.

=item Admin

Lists the current set of lyric entries.

Also provides the delete, copy and promote functionality from the main
administration page for the given section.

=item LyricSelect

Provides a drop-down select box of lyrics within the system. The method is
intended to be called via other plugins.

=item Add

Add a lyric entry.

=item Edit

Edit a lyric entry.

=item Save

Save a lyric entry.

=item Delete

Delete a lyric entry.

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
