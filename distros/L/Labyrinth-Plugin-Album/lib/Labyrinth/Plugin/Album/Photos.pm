package Labyrinth::Plugin::Album::Photos;

use strict;
use warnings;

our $VERSION = '1.12';

=head1 NAME

Labyrinth::Plugin::Album::Photos - Photo album photos handler for Labyrinth

=head1 DESCRIPTION

Contains all the photo album handling functionality for the Labyrinth
framework.

=cut

#----------------------------------------------------------------------------
# Libraries

use base qw(Labyrinth::Plugin::Base);

use Image::Size;

use Labyrinth::Audit;
use Labyrinth::DBUtils;
use Labyrinth::DTUtils;
use Labyrinth::Media;
use Labyrinth::MLUtils;
use Labyrinth::Support;
use Labyrinth::Variables;

use Labyrinth::Plugin::Hits;

#----------------------------------------------------------------------------
# Variables

# type: 0 = optional, 1 = mandatory
# html: 0 = none, 1 = text, 2 = textarea

my %fields = (
    photoid     => { type => 1, html => 0 },
    pageid      => { type => 0, html => 0 },
    thumb       => { type => 0, html => 0 },
    image       => { type => 0, html => 0 },
    tagline     => { type => 0, html => 1 },
    summary     => { type => 0, html => 2 },
    hide        => { type => 0, html => 0 },
);

my (@mandatory,@allfields);
for(keys %fields) {
    push @mandatory, $_     if($fields{$_}->{type});
    push @allfields, $_;
}

my $LEVEL       = EDITOR;
my $INDEXKEY    = 'photoid';

my $hits = Labyrinth::Plugin::Hits->new();

#----------------------------------------------------------------------------
# Public Interface Functions

=head1 PUBLIC INTERFACE METHODS

=head2 Public Methods

=over 4

=item List

Provides a list of all the public photos within a given photo album.

=item View

Returns details of a specific photo.

=item Random

Stores random images in the $tvars{"irand$inx"} template variable array.
Number of images stored is determined for configuration settings variable,
'random'. If not set, will default to 1 image.

=item Gallery

Provides a set of images to be used within a gallery pop-up window. Assumes 
a 3x3 grid of nine images. Includes links for prev & next to further gallery
images.

Images returned are determined by the given metadata.

=item Albums

Retrieve a collection of albums and their photos. This is particularly useful
when multiple galleries are being displayed. The results are stored in the 
template variable $tvars{albums}{<album id>}{records}, as an array of the
photos, as per the List method.

=back

=cut

sub List {
    my ($pageid,@rs);
    if($cgiparams{'pid'} || $cgiparams{'pageid'}) {
        $pageid = $cgiparams{'pid'} || $cgiparams{'pageid'};
        @rs = $dbi->GetQuery('hash','GetPage',$pageid);
    } elsif($cgiparams{'path'}) {
        @rs = $dbi->GetQuery('hash','GetPageByPath',"photos/$cgiparams{'path'}");
        $pageid = $rs[0]->{pageid}  if(@rs);
    }

    if(@rs) {
        # get page details
        $rs[0]->{month} = isMonth($rs[0]->{month});
        for(keys %fields) {
               if($fields{$_}->{html} == 1) { $rs[0]->{$_} = CleanHTML($rs[0]->{$_}); }
            elsif($fields{$_}->{html} == 2) { $rs[0]->{$_} = CleanTags($rs[0]->{$_});  }
        }

        $tvars{album}->{page} = $rs[0];

        # get photo listing
        my @recs = $dbi->GetQuery('hash','ListPhotos',$pageid);
        my $orderno = 1;
        for my $rec (@recs) {
            $rec->{tagline} =~ s/&#39;/\'/g if $rec->{tagline};
            $rec->{orderno} = $orderno++;
        }

        $tvars{album}->{records} = \@recs   if(@recs);
    }

    $tvars{album}->{iid} = 0;
}

# image page required

sub View {
    my $photoid = $cgiparams{'iid'} || $cgiparams{'photoid'};
    unless($photoid) {
        $tvars{errcode} = 'ERROR';
        return;
    }

    # get photo details
    my @rs = $dbi->GetQuery('hash','GetPhotoDetail',$photoid);
    unless(@rs) {
        $tvars{errcode} = 'ERROR';
        return;
    }

    $rs[0]->{tagline} =~ s/&#39;/\'/g   if $rs[0]->{tagline};
    $tvars{photo} = $rs[0];

    # get page details
    my $pageid = $rs[0]->{pageid};
    @rs = $dbi->GetQuery('hash','GetPage',$pageid);
    unless(@rs) {
        $tvars{errcode} = 'ERROR';
        return;
    }

    $rs[0]->{month} = isMonth($rs[0]->{month});
    for(keys %fields) {
           if($fields{$_}->{html} == 1) { $rs[0]->{$_} = CleanHTML($rs[0]->{$_}); }
        elsif($fields{$_}->{html} == 2) { $rs[0]->{$_} = CleanTags($rs[0]->{$_});  }
    }

    $tvars{page} = $rs[0];

    my ($orderno,$this,@order) = (0,0);
    @rs = $dbi->GetQuery('hash','ListPhotos',$pageid);
    for my $row (@rs) {
        $this = $orderno    if($row->{photoid} eq $photoid);
        push @order, $row->{photoid};
        $orderno++;
    }

    $tvars{photo}->{prev} = $order[$this-1] unless($this == 0);
    $tvars{photo}->{next} = $order[$this+1] unless($this == $#order);
    $tvars{ddmonths} = MonthSelect($tvars{month});
    $tvars{ddyears}  = YearSelect($tvars{years});
    $tvars{today}    = formatDate(7);

    # Get the size of image
    if($tvars{photo}->{dimensions}) {
        my ($size_x) = split("x",$tvars{photo}->{dimensions});
        $tvars{photo}->{toobig} = 1 if($size_x > $tvars{maxpicwidth});
    } else {
        my $file = "$settings{webdir}/photos/$tvars{photo}->{image}";
        if(-f $file) {
            my ($size_x) = imgsize($file);
            $tvars{photo}->{toobig} = 1 if($size_x > $tvars{maxpicwidth});
        }
    }
}

sub Random {
    my $count = $settings{random} || 1;
    my @max = $dbi->GetQuery('array','MaxPhotoID');
    return  unless(@max);

    my $max = $max[0]->[0];
    if($max <= $count) {
        foreach my $index (1..$max) {
            my @rows = $dbi->GetQuery('hash','GetRandomPhoto',$index);
            next    unless(@rows);
            $tvars{"irand$index"} = $rows[0];
        }
        return;
    }

    my (%done,@random);
    srand;
    while(1) {
        my $index = int((rand) * $max);
        next    if($done{$index});
        my @rows = $dbi->GetQuery('hash','GetRandomPhoto',$index);
        next    unless(@rows);

        # Get the size of image
        if($rows[0]->{dimensions}) {
            my ($size_x) = split("x",$rows[0]->{dimensions});
            $rows[0]->{toobig} = 1 if($size_x > $tvars{randpicwidth});
        } elsif($rows[0]->{image}) {
            my $file = "$settings{webdir}/photos/$rows[0]->{image}";
            if(-f $file) {
                my ($size_x) = imgsize($file);
                $rows[0]->{toobig} = 1 if($size_x > $tvars{randpicwidth});
            }
        } else {
            next;
        }

        push @random, $rows[0];
        $done{$index} = 1;
        last    if(@random >= $count);
    }

    foreach my $inx (1..$count) {
        $tvars{"irand$inx"} = $random[($inx-1)];
        $tvars{"random"} = \@random;
    }
}

my @blanks = (
{ thumb=>'images/blank.png',tagline=>'' },
{ thumb=>'images/blank.png',tagline=>'' },
{ thumb=>'images/blank.png',tagline=>'' },
{ thumb=>'images/blank.png',tagline=>'' },
{ thumb=>'images/blank.png',tagline=>'' },
{ thumb=>'images/blank.png',tagline=>'' },
{ thumb=>'images/blank.png',tagline=>'' },
{ thumb=>'images/blank.png',tagline=>'' },
{ thumb=>'images/blank.png',tagline=>'' },
);

sub Gallery {
    return  unless AccessUser(EDITOR);
    my $start   = $cgiparams{'start'} || 1;
    my $key     = $cgiparams{'searchmeta'} ? 'Meta' : '';
    my $where;

    if($cgiparams{'searchmeta'}) {
        $cgiparams{'searchmeta'} =~ s/[,\s]+/,/g;
        $cgiparams{'searchmeta'} = join(",", map {"'$_'"} split(",",$cgiparams{'searchmeta'}));
        $where .= " AND m.tag IN ($cgiparams{'searchmeta'})"        if($cgiparams{'searchmeta'});
    }

    my @rows = $dbi->GetQuery('hash',$key.'Gallery',{where=>$where},$start);
    $tvars{next} = $rows[9]->{photoid}  unless(@rows < 10);
    for my $row (@rows) { $row->{thumb} = 'photos/' . $row->{thumb} unless($row->{thumb} =~ m!^images/!) }

    push @rows, @blanks;
    $tvars{data} = \@rows   if(@rows);
    my @prev = $dbi->GetQuery('hash',$key.'GalleryMin',{where=>$where},$start);
    $tvars{prev} = $prev[8]->{photoid}  unless(@prev < 9);
}

sub Albums {
    return  unless($cgiparams{'pages'});
    my @pages = split(',',$cgiparams{'pages'});
    for my $page (@pages) {
        $cgiparams{pageid} = $page;
        List();
        $tvars{albums}{$page}{records} = $tvars{album}->{records};
    }
}

#----------------------------------------------------------------------------
# Administration Interface Functions

=head1 ADMIN INTERFACE METHODS

=head2 Administration Methods

=over 4

=item Admin

Provides a list of all photos.

=item Add

Prep for adding a photo.

=item Edit

Edit details of an existing photo.

=item Move

Move a photo between albums.

=item Save

Saves details of a given photo.

=item Archive

Delete a photo reference if held in the archive photo album, or move to the
archive photo album, if held in another album. 

=back

=cut

sub Admin {
    return  unless AccessUser($LEVEL);
    my @rs = $dbi->GetQuery('hash','AdminPhotos');
#   foreach my $rec (@rs) {
#       $rec->{title} =~ s/&#39;/\'/g       if $rec->{title};
#       $rec->{tagline} =~ s/&#39;/\'/g if $rec->{tagline};
#   }

    $tvars{records} = \@rs  if(@rs);
}

sub Add {
    return  unless AccessUser($LEVEL);
    my @rs = $dbi->GetQuery('hash','ListPages');
    $tvars{pages} = $rs[0]    if(@rs);
}

sub Edit {
    return  unless AccessUser($LEVEL);
    my $photoid = $cgiparams{'iid'};

    # get page details
    my @pg = $dbi->GetQuery('hash','ListPages');
    $tvars{pages} = \@pg    if(@pg);
    # get photo details
    my @rs = $dbi->GetQuery('hash','GetPhotoDetail',$photoid);
    if(@rs) {
        $rs[0]->{tagline} =~ s/&#39;/\'/g   if $rs[0]->{tagline};
        $tvars{record} = $rs[0];
    }

}

sub Move {
    return  unless AccessUser($LEVEL);
    my $photoid = $cgiparams{'iid'};
    my $pageid  = $cgiparams{'pid'};
    my $oldid   = $cgiparams{'oid'};

    return  unless($photoid && $pageid && $oldid);

    # get page details
    $dbi->DoQuery('MovePhoto',$pageid,$oldid,$photoid);
}

sub Save {
    return  unless AccessUser($LEVEL);
    my @fields;

    for(keys %fields) {
           if($fields{$_}->{html} == 1) { $cgiparams{$_} = CleanHTML($cgiparams{$_}) }
        elsif($fields{$_}->{html} == 2) { $cgiparams{$_} = CleanTags($cgiparams{$_}) }
        elsif($fields{$_}->{html} == 3) { $cgiparams{$_} = CleanLink($cgiparams{$_}) }
    }

    return  if FieldCheck(\@allfields,\@mandatory);

    $tvars{data}->{hide} = $tvars{data}->{hide} ? 1 : 0;
    push @fields, $tvars{data}->{$_} for(qw(pageid thumb image tagline hide photoid));
    $dbi->DoQuery('UpdatePhoto2',@fields);

    $hits->SetUpdates('album',0,$tvars{data}->{pageid});
    $tvars{thanks_message} = 'Photo saved successfully.';
}

sub Archive {
    return  unless AccessUser($LEVEL);
    return  unless $cgiparams{$INDEXKEY};

    my @rows = $dbi->GetQuery('hash','GetPhotoDetail',$cgiparams{$INDEXKEY});
    if($rows[0]->{pageid} == 1) {
        return  unless AccessUser(ADMIN);
        my @photo = $dbi->GetQuery('hash','CheckPhoto',1,$cgiparams{$INDEXKEY});
        if(@photo && $photo[0]->{count} == 1) {   # only delete if no others match
            DeleteFile( file => "$settings{webdir}/photos/$rows[0]->{image}" );
            DeleteFile( file => "$settings{webdir}/photos/$rows[0]->{thumb}" );
        }
        $dbi->DoQuery('DeletePhoto',$cgiparams{$INDEXKEY});
        $tvars{thanks_message} = 'Photo deleted successfully.';
    } else {
        $dbi->DoQuery('MovePhoto',1,$cgiparams{$INDEXKEY});
        $tvars{thanks_message} = 'Photo archived successfully.';
    }
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
