package Labyrinth::Plugin::Hits;

use strict;
use warnings;

our $VERSION = '5.19';

=head1 NAME

Labyrinth::Plugin::Hits - Handles the hit and update stats for page impressions

=head1 DESCRIPTION

Contains all the page hit handling functionality for the Labyrinth
framework.

=cut

#----------------------------------------------------------------------------
# Libraries

use base qw(Labyrinth::Plugin::Base);

use Time::Local;

use Labyrinth::Audit;
use Labyrinth::DBUtils;
use Labyrinth::DTUtils;
use Labyrinth::MLUtils;
use Labyrinth::Support;
use Labyrinth::Variables;

use Labyrinth::Plugin::Content;

#----------------------------------------------------------------------------
# Variables

# type: 0 = optional, 1 = mandatory
# html: 0 = none, 1 = text, 2 = textarea

my %fields = (
    title       => { type => 1, html => 1 },
    tagline     => { type => 0, html => 1 },
    query       => { type => 0, html => 2 },
);

my $WEEKS1 = 60 * 60 * 24 * 7;
my $WEEKS4 = $WEEKS1 * 4;
my $WEEKS6 = $WEEKS1 * 6;

#----------------------------------------------------------------------------
# Public Interface Functions

=head1 PUBLIC INTERFACE METHODS

=over 4

=item GetUpdate

Provides the dates for the last update to the site and the requested page.

=item SetHits

Records the hit for the current page and photo (if applicable).

=item HitPages

List of hit stats for site pages.

=item HitAlbums

List of hit stats for galley albums.

=item HitPhotos

List of hit stats for galley photos.

=item HitSelects

Compile contents of the drop downs on hit pages.

=back

=cut

sub GetUpdate {
    my $section = $tvars{'section'} || 'unstated';
    my $pageid  = $cgiparams{pid} || $cgiparams{pageid}  || 0;

    my %updates = (
        siteupdate => ['site',0],
        pageupdate => [$section,$pageid],
    );

    foreach my $update (keys %updates) {
        my @rs = $dbi->GetQuery('array','PageTimeStamp',@{$updates{$update}});
        next unless(@rs);

        # get expanded timestamp [2004-05-07 13:24:56]
        $rs[0]->[0] =~ /(\d\d\d\d)[^\d]?(\d\d)[^\d]?(\d\d)/;
        $tvars{$update} = formatDate(5,timelocal(0,0,0,int($3),$2-1,$1));
    }
}

sub SetHits {
    my $counter = 0;
    my $section = $cgiparams{act} || 'unstated';
    my $pageid  = $cgiparams{pid} || $cgiparams{pageid}  || 0;
    my $photoid = $cgiparams{iid} || $cgiparams{photoid} || 0;
    my @keys    = sort grep {/(name|id|letter|data|volume|month|year)/} keys %cgiparams;
    my $query   = join( '&', map {defined $cgiparams{$_} ? "$_=$cgiparams{$_}" : ''} @keys)    if(@keys);
    my $dt      = formatDate(0);

    $dbi->DoQuery('AddAHit',1,$section,$pageid,$photoid,$query,$dt);
    my @rs = $dbi->GetQuery('array','GetAHit',$section,$query);
    $tvars{hits} = @rs ? $rs[0]->[0] : 0;
}

sub HitPages {
    my $dt = time() - $WEEKS4;

    my @pagesall = $dbi->GetQuery('hash','PageHitsAllTime');
    for my $row (@pagesall) {
        for(keys %fields) {
               if($fields{$_}->{html} == 1) { $row->{$_} = CleanHTML($row->{$_}); }
            elsif($fields{$_}->{html} == 2) { $row->{$_} = CleanTags($row->{$_});  }
        }
    }
    $tvars{pagesall}  = \@pagesall  if(@pagesall);

    my @pagesmon = $dbi->GetQuery('hash','PageHitsLastMonth',$dt);
    for my $row (@pagesmon) {
        for(keys %fields) {
               if($fields{$_}->{html} == 1) { $row->{$_} = CleanHTML($row->{$_}); }
            elsif($fields{$_}->{html} == 2) { $row->{$_} = CleanTags($row->{$_});  }
        }
    }

    $tvars{ddmonths} = MonthSelect($tvars{data}->{month},1);
    $tvars{ddyears}  = YearSelect($tvars{data}->{year},2,1);
    $tvars{today}    = formatDate(7);
    $tvars{pagesmon} = \@pagesmon  if(@pagesmon);
}

sub HitAlbums {
    my $dt = time() - $WEEKS4;

    my @albumsall = $dbi->GetQuery('hash','AlbumHitsAllTime');
    for my $row (@albumsall) {
        $row->{month} = isMonth($_->{month});
        $row->{title} =~ s/&#39;/\'/g   if $row->{title};
        for(keys %fields) {
               if($fields{$_}->{html} == 1) { $row->{$_} = CleanHTML($row->{$_}); }
            elsif($fields{$_}->{html} == 2) { $row->{$_} = CleanTags($row->{$_});  }
        }
    }
    $tvars{albumsall}  = \@albumsall    if(@albumsall);

    my @albumsmon = $dbi->GetQuery('hash','AlbumHitsLastMonth',$dt);
    for my $row (@albumsmon) {
        $row->{month} = isMonth($_->{month});
        $row->{title} =~ s/&#39;/\'/g   if $row->{title};
        for(keys %fields) {
               if($fields{$_}->{html} == 1) { $row->{$_} = CleanHTML($row->{$_}); }
            elsif($fields{$_}->{html} == 2) { $row->{$_} = CleanTags($row->{$_});  }
        }
    }

    $tvars{ddmonths} = MonthSelect($tvars{data}->{month},1);
    $tvars{ddyears}  = YearSelect($tvars{data}->{year},2,1);
    $tvars{today}    = formatDate(7);
    $tvars{albumsmon}  = \@albumsmon    if(@albumsmon);
}

sub HitPhotos {
    my $dt = time() - $WEEKS4;

    my @photosall = $dbi->GetQuery('hash','PhotoHitsAllTime');
    for my $row (@photosall) {
        $row->{month} = isMonth($row->{month});
        $row->{tagline} =~ s/&#39;/\'/g if $row->{tagline};
        $row->{title} =~ s/&#39;/\'/g   if $row->{title};
        for(keys %fields) {
               if($fields{$_}->{html} == 1) { $row->{$_} = CleanHTML($row->{$_}); }
            elsif($fields{$_}->{html} == 2) { $row->{$_} = CleanTags($row->{$_});  }
        }
    }
    $tvars{photosall}  = \@photosall    if(@photosall);

    my @photosmon = $dbi->GetQuery('hash','PhotoHitsLastMonth',$dt);
    for my $row (@photosmon) {
        $row->{month} = isMonth($row->{month});
        $row->{tagline} =~ s/&#39;/\'/g if $row->{tagline};
        $row->{title} =~ s/&#39;/\'/g   if $row->{title};
        for(keys %fields) {
               if($fields{$_}->{html} == 1) { $row->{$_} = CleanHTML($row->{$_}); }
            elsif($fields{$_}->{html} == 2) { $row->{$_} = CleanTags($row->{$_});  }
        }
    }
    $tvars{photosmon}  = \@photosmon    if(@photosmon);
}

sub HitSelects {
    $tvars{ddmonths} = MonthSelect($tvars{data}->{month},1);
    $tvars{ddyears}  = YearSelect($tvars{data}->{year},2,1);
    $tvars{today}    = formatDate(7);
}

#----------------------------------------------------------------------------
# Administration Interface Functions

=head1 PUBLIC INTERFACE METHODS

=over 4

=item AdminUpdates

List the last site page updates, via the 'AdminUpdates' phrasebook query.

=item SetUpdates

Store page and site update from current timestamp. Only called internally.

=item AdminHits

Shorthand method to list all the hit counters for admin use.

=item Reset

Original method to reset hit counters, such that individual counters older than
a given date, are summed and stored in one counter entry.

This is being deprecated in favour of a new script, which will be incorporated
here in the future.

=back

=cut

sub AdminUpdates {
    return  unless AccessUser(EDITOR);
    my @rs = $dbi->GetQuery('hash','AdminUpdates');

    foreach my $rec (@rs) {
        $rec->{pagets} =~ /^(\d\d\d\d)(\d\d)(\d\d)/;
        LogDebug("pagets=".$rec->{pagets});
        $rec->{updated} = formatDate(5,timelocal(0,0,0,int($3),$2-1,$1));
    }

    $tvars{records} = \@rs  if(@rs);
}

sub SetUpdates {
    my $self = shift;
    my $area = shift;
    my $now = formatDate(0);

    while(@_) {
        my $pageid = shift @_;
#        LogDebug("SetUpdates: area=$area, pageid=$pageid");

        # check whether old or new
        my @rs = $dbi->GetQuery('hash','GetUpdate',$area,$pageid);

        # store page update
        my $key = (@rs ? 'SetUpdate' : 'AddUpdate');
        $dbi->DoQuery($key,$now,$area,$pageid);
    }

    # store index updates
    $dbi->DoQuery('SetUpdate',$now,'site',0)    if($area ne 'site');
}

sub AdminHits {
    return  unless AccessUser(EDITOR);
    HitPages();
    HitAlbums();
    HitPhotos();
    HitSelects();
}

sub Reset {
    return  unless AccessUser(ADMIN);
    my $dt = formatDate(0) - ($WEEKS6);
    my @rows = $dbi->GetQuery('hash','SumHits',$dt);
    for my $row (@rows) {
        $dbi->DoQuery('DelHits',$row->{area},$row->{query},$dt);
        $dbi->DoQuery('AddAHit',$row->{counter},$row->{area},$row->{pageid},$row->{photoid},$row->{query},0);
    }
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
