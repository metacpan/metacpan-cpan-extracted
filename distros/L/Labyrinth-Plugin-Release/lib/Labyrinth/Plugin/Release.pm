package Labyrinth::Plugin::Release;

use warnings;
use strict;

use vars qw($VERSION);

$VERSION = '0.03';

=head1 NAME

Labyrinth::Plugin::Release - Release plugin handler for Labyrinth

=head1 DESCRIPTION

Contains all the release handling functionality for the Labyrinth Web
Framework.

=cut

# -------------------------------------
# Library Modules

use base qw(Labyrinth::Plugin::Articles);

use Clone qw(clone);

use Labyrinth::Audit;
use Labyrinth::DBUtils;
use Labyrinth::DTUtils;
use Labyrinth::Media;
use Labyrinth::MLUtils;
use Labyrinth::Support;
use Labyrinth::Users;
use Labyrinth::Variables;

# -------------------------------------
# Variables

# type: 0 = optional, 1 = mandatory
# html: 0 = none, 1 = text, 2 = textarea

my %fields = (
    articleid   => { type => 0, html => 0 },
    releaseid   => { type => 0, html => 0 },
    title       => { type => 1, html => 1 },
    quickname   => { type => 1, html => 0 },
    reldate     => { type => 1, html => 0 },
    publish     => { type => 1, html => 0 },
    reltypeid   => { type => 1, html => 0 },
);

my (@mandatory,@allfields);
for(keys %fields) {
    push @mandatory, $_     if($fields{$_}->{type});
    push @allfields, $_;
}

my $ALLSQL          = 'AllReleases';
my $SECTIONID       = 8;
my $SECTION_ALBUM   = 8;
my $SECTION_LYRIC   = 7;
my $SECTION_PROFILE = 5;
my $LEVEL       = ADMIN;

# -------------------------------------
# The Subs

=head1 PUBLIC INTERFACE METHODS

=over 4

=item * List

Provides basic information for each published release.

=item * Item

Retrieves the basic release data, liner notes and a list of the lyrics, 
profiles and mp3s associated with the release.

=item * Lyrics

Calls Item(), and provides the full content of each lyric of a release.

=item * Profiles

Calls Item(), and provides the full content of each profile of a release.

=back

=cut

sub List {
    my $self = shift;
    my @releases;

    my @rows = $dbi->GetQuery('hash','ListReleases');
    for my $row (@rows) {
        my @release = $dbi->GetQuery('hash','GetReleaseByID',$row->{releaseid});
        my @article = $dbi->GetQuery('hash','GetArticleByName',$row->{quickname});
        $release[0]->{$_} = $article[0]->{$_}   for(qw(link tag));
        my @formats = $dbi->GetQuery('hash','ListFormats',$row->{releaseid});
        $release[0]->{formats} = \@formats  if(@formats);

        my @lyrics = $dbi->GetQuery('hash','ListLyrics',$row->{releaseid});
        $release[0]->{lyrics} = \@lyrics    if(@lyrics);
        my @profiles = $dbi->GetQuery('hash','ListProfiles',$row->{releaseid});
        $release[0]->{profiles} = \@profiles    if(@profiles);
        my @mp3s = $dbi->GetQuery('hash','ListMp3s',$row->{releaseid});
        $release[0]->{mp3s} = \@mp3s    if(@mp3s);
        
        $release[0]->{postyear} = formatDate(1,$release[0]->{releasedate});

        $cgiparams{articleid} = $release[0]->{articleid};
        $cgiparams{sectionid} = $SECTION_ALBUM;
        $self->SUPER::Item;
        $release[0]->{data} = clone($tvars{articles}{$tvars{primary}});

        push @releases, $release[0];
    }

    my @types = $dbi->GetQuery('hash','ListAllTypes');

    $tvars{types}    = \@types      if(@types);
    $tvars{releases} = \@releases   if(@releases);
}

sub Item {
    my @release = $dbi->GetQuery('hash','GetReleaseByID',$cgiparams{releaseid});
    if(@release) {
        my @lyrics = $dbi->GetQuery('hash','ListLyrics',$cgiparams{releaseid});
        $release[0]->{lyrics} = \@lyrics    if(@lyrics);
        my @profiles = $dbi->GetQuery('hash','ListProfiles',$cgiparams{releaseid});
        $release[0]->{profiles} = \@profiles    if(@profiles);
        my @mp3s = $dbi->GetQuery('hash','ListMp3s',$cgiparams{releaseid});
        $release[0]->{mp3s} = \@mp3s    if(@mp3s);

        $release[0]->{postyear} = formatDate(1,$release[0]->{releasedate});
        $tvars{release} = $release[0];
    }

    $cgiparams{articleid} = $tvars{release}->{articleid};
    $cgiparams{sectionid} = $SECTION_ALBUM;
    shift->SUPER::Item;
    $tvars{release}{notes} = clone($tvars{articles}{$tvars{primary}});
}

sub Lyrics {
    my $self = shift;
    return  unless($cgiparams{articleid});

    $self->Item;

    for my $lyric (sort {$a->{orderno} <=> $b->{orderno}} @{$tvars{release}{lyrics}}) {
        $cgiparams{articleid} = $lyric->{articleid};
        $cgiparams{sectionid} = $SECTION_LYRIC;
        shift->SUPER::Item;
        $lyric->{data} = clone($tvars{articles}{$tvars{primary}});
    }
}

sub Profiles {
    my $self = shift;
    return  unless($cgiparams{articleid});

    $self->Item;

    for my $profile (sort {$a->{orderno} <=> $b->{orderno}} @{$tvars{release}{profiles}}) {
        $cgiparams{articleid} = $profile->{articleid};
        $cgiparams{sectionid} = $SECTION_PROFILE;
        shift->SUPER::Item;
        $profile->{data} = clone($tvars{articles}{$tvars{primary}});
    }
}

=head1 ADMIN INTERFACE METHODS

=over 4

=item * Admin

Manage current list of releases.

=item * Add

Add a release.

=item * Edit

Edit existing release.

=item * Save

Save a release.

=item * SaveFormat

Save release format.

=item * SaveLyric

Attach a lyric associated with this release.

=item * SaveProfile

Attach a profile associated with this release.

=item * Promote

Promote the publish status of a release.

=item * Delete

Delete one or more releases.

=item * TypeSelect

Provide a drop down list of release types.

=back

=cut

sub Admin {
    return  unless(AccessUser($LEVEL));
    if($cgiparams{doaction}) {
           if($cgiparams{doaction} eq 'Promote' ) { Promote(); }
           if($cgiparams{doaction} eq 'Delete'  ) { Delete();  }
    }

    my @rows = $dbi->GetQuery('hash','ListAllReleases');
    for my $row (@rows) {
        $row->{publishstate} = PublishState($row->{publish});
    }
    $tvars{data} = \@rows;
    $tvars{sectionid} = $SECTION_ALBUM;
}

sub Add {
    return  unless(AccessUser($LEVEL));
    $cgiparams{sectionid} = $SECTION_ALBUM;
    shift->SUPER::Add;

    my %data = (
        releaseid   => 0,
        title       => 'DRAFT',
        reldate     => formatDate(3),
        ddpublish   => PublishSelect(1),
        ddtypes     => TypeSelect(),
        quickname   => $tvars{article}{data}{quickname}
    );

    my @allformats = $dbi->GetQuery('hash','ListAllFormats');
    $tvars{allformats} = \@allformats if(@allformats);
    my @alltracks = $dbi->GetQuery('hash','ListAllLyrics');
    $tvars{alltracks} = \@alltracks   if(@alltracks);

    $tvars{release} = \%data;
}

sub Edit {
    return  unless(AccessUser($LEVEL));
    my @release = $dbi->GetQuery('hash','GetReleaseByID',$cgiparams{releaseid});
    return  unless(@release);
    $tvars{release} = $release[0];
    $tvars{release}{reldate} = formatDate(3,$tvars{release}{releasedate});
    $tvars{release}{ddtypes} = TypeSelect($cgiparams{releaseid});

    my @formats = $dbi->GetQuery('hash','ListFormats',$cgiparams{releaseid});
    $tvars{formats} = \@formats if(@formats);
    my @lyrics = $dbi->GetQuery('hash','ListLyrics',$cgiparams{releaseid});
    $tvars{lyrics} = \@lyrics   if(@lyrics);

    my @allformats = $dbi->GetQuery('hash','ListAllFormats');
    $tvars{allformats} = \@allformats if(@allformats);
    my @alltracks = $dbi->GetQuery('hash','ListAllLyrics');
    $tvars{alltracks} = \@alltracks   if(@alltracks);

    $cgiparams{articleid} ||= $tvars{release}{articleid};
    $cgiparams{sectionid} = $SECTION_ALBUM;
    shift->SUPER::Edit;
}

sub Save {
    return  unless(AccessUser($LEVEL));
    # save content
    $cgiparams{sectionid} = $SECTION_ALBUM;
    shift->SUPER::Save;

    # check details
    return  unless AuthorCheck('GetReleaseByID','releaseid',EDITOR);
    my $publish = $tvars{data}->{publish} || 0;
    $tvars{release} = $tvars{data};

    for(keys %fields) {
           if($fields{$_}->{html} == 1) { $cgiparams{$_} = CleanHTML($cgiparams{$_}) }
        elsif($fields{$_}->{html} == 2) { $cgiparams{$_} = CleanTags($cgiparams{$_}) }
        elsif($fields{$_}->{html} == 3) { $cgiparams{$_} = CleanTags($cgiparams{$_}) }
    }
    return  if FieldCheck(\@allfields,\@mandatory);

    # save release data
    $tvars{data}->{releasedate} = unformatDate(3,$tvars{data}->{reldate});

    my @fields = (  $tvars{data}->{title},
                    $tvars{data}->{quickname},
                    $tvars{data}->{publish},
                    $tvars{data}->{releasedate},
                    $tvars{data}->{reltypeid},
        );

    if($tvars{data}->{releaseid})
            {   $dbi->DoQuery('UpdateRelease',@fields,$tvars{data}->{releaseid}); }
    else    {   $cgiparams{releaseid} = $dbi->IDQuery('InsertRelease',@fields); }

    # save formats
    for my $key ( keys %cgiparams ) {
        if($key =~ /^frm_(\d+)/) {
            $cgiparams{ixformatid}  = $1;
            $cgiparams{'relformid'} = $cgiparams{'frm_'.$1};
            $cgiparams{'catalogue'} = $cgiparams{'cat_'.$1};
            $cgiparams{'label'}     = $cgiparams{'lab_'.$1};
            SaveFormat();
        } elsif($key =~ /^frm_(x\d+)/) {
            $cgiparams{ixformatid}  = 0;
            $cgiparams{'relformid'} = $cgiparams{'frm_'.$1};
            $cgiparams{'catalogue'} = $cgiparams{'cat_'.$1};
            $cgiparams{'label'}     = $cgiparams{'lab_'.$1};
            SaveFormat();
        }
    }

    if($cgiparams{FORMATS}) {
        my @ids = CGIArray('FORMATS');
        $dbi->DoQuery('DeleteFormats',{ids=>join(',',@ids)},$cgiparams{releaseid});
    }

    # save track list
    my %ids;
    if($cgiparams{LISTED}) {
        my @ids = CGIArray('LISTED');
        %ids = map {$_ => 1} @ids;
    }
    $dbi->DoQuery('DeleteLyricLinks',{ids => $cgiparams{releaseid}});
    for my $ord ( keys %cgiparams ) {
        if($ord =~ /^ord_(\d+)/) {
            $cgiparams{lyricid} = $1;
            $cgiparams{orderno} = $cgiparams{$ord};
            $dbi->DoQuery('InsertLyricLink',$cgiparams{orderno},$cgiparams{releaseid},$cgiparams{lyricid})  unless($ids{$cgiparams{lyricid}});
        } elsif($ord =~ /^ord_(x\d+)/) {
            $cgiparams{lyricid} = $cgiparams{'trk_'.$1};
            $cgiparams{orderno} = $cgiparams{$ord};
            $dbi->DoQuery('InsertLyricLink',$cgiparams{orderno},$cgiparams{releaseid},$cgiparams{lyricid});
        }
    }

    if($cgiparams{lyric_title} && $cgiparams{lyric_name}) {
        SaveLyric();
    }
}

sub SaveFormat {
    return  unless(AccessUser($LEVEL));
    if($cgiparams{ixformatid}) {
        $dbi->DoQuery('UpdateFormat',$cgiparams{releaseid},$cgiparams{relformid},$cgiparams{catalogue},$cgiparams{label},$cgiparams{ixformatid});
    } else {
        $dbi->DoQuery('InsertFormat',$cgiparams{releaseid},$cgiparams{relformid},$cgiparams{catalogue},$cgiparams{label});
    }
}

sub SaveLyric {
    return  unless(AccessUser($LEVEL));
    my $id = $dbi->IDQuery('InsertLyric',$cgiparams{lyric_title},$cgiparams{lyric_name},$SECTION_LYRIC);
    $dbi->DoQuery('InsertLyricLink',$cgiparams{lyric_order},$cgiparams{releaseid},$id);
}

sub SaveProfile {
    return  unless(AccessUser($LEVEL));
    my $id = $dbi->IDQuery('InsertProfile',$cgiparams{profile_title},$cgiparams{profile_name},$SECTION_PROFILE);
    $dbi->DoQuery('InsertProfileLink',$cgiparams{profile_order},$cgiparams{releaseid},$id);
}

sub Promote {
    return  unless(AccessUser($LEVEL));
    my @ids = CGIArray('LISTED');
    next    unless(@ids);

    my @rows = $dbi->GetQuery('hash',$ALLSQL);
    my %ids = map {$_->{mp3id} => $_->{publish}} @rows;

    for my $id (@ids) {
        next    unless(defined $ids{$id} && $ids{$id} < 4);
        $dbi->DoQuery('PromoteReleases',($ids{$id} + 1),$id);
    }
}

sub Delete {
    return  unless(AccessUser($LEVEL));
    my @arts;
    my @ids = CGIArray('LISTED');
    return  unless @ids;
    my $ids = join(",",@ids);
    my @rows = $dbi->GetQuery('hash','GetReleases',{ids => $ids});
    for my $row (@rows) {
        push @arts, $row->{articleid};
    }
    if(@arts) {
        my $arts = join(",",@arts);
        $dbi->DoQuery('DeleteArticleContent',{ids => $arts});
        $dbi->DoQuery('DeleteArticle',       {ids => $arts});
    }
    $dbi->DoQuery('DeleteReleases',      {ids => $ids});
    $dbi->DoQuery('DeleteReleaseLinks',  {ids => $ids});
    $dbi->DoQuery('DeleteReleaseFormats',{ids => $ids});
}

sub TypeSelect {
    my $opt = shift;
    my @rows = $dbi->GetQuery('hash','ListAllTypes');
    DropDownRows($opt,'reltypeid','reltypeid','type',@rows);
}

1;

__END__

=head1 BACKGROUND

The suite of Music plugins for Labyrinth were originally developed for the Ark
and Slim Pickins band websites. With enhancements along the way as they were
used in part or wholly for other sites.

There are four key modules within the suite, which enables a "release" to be 
linked to each element within it. 

  * Labyrinth::Plugin::Articles::Lyrics
  * Labyrinth::Plugin::Articles::Profiles
  * Labyrinth::Plugin::MP3s
  * Labyrinth::Plugin::Release

The first three can be use completely independently, and do not require the
last. However, the last, this module, does require the other three, even if
they aren't used.

In the music world, the term 'discography' is used to represent a collection
of records (albums, singles, demos, etc), while in the literary world, the
term 'bibliography' is used to represent a collection of works by an author
(novels, novellas, articles, short stories, etc). This suite of modules can
hopefully be used for both, and any other collection type that may be used in
other fields of work.

=head1 CREATING A RELEASE

When creating a release, there are many components that can make up the whole
picture. 

Thinking of albums, there is the basic release information, the liner
notes, the lyrics, the people involved (mostly the performers, but may be also
a producer, engineer and road crew), and possible MP3s, either samples or
complete tracks.

For a book, you may only require the release information, cover notes, the 
people involved (author(s), editor(s), publisher, etc), and maybe extracts
or complete short stories. You may wish to even include audio snippets or 
interviews via MP3s (or even video files).

All these elements are collected together under this module, so that they can
be neatly associated with multiple releases, songs can appear on more than one
album, and a short story may feature in more than one collected stories.

To help identify where elements are stored in the system, the following 
provides a helpful guide.

=over

=item * Release Information

  mangement module = Labyrinth::Plugin::Release
  database tables = releases, release_ixformats
  templates = ./releases

=item * Liner Notes

  mangement module = Labyrinth::Plugin::Release
  database tables = releases, articles, paragraphs, images
  templates = ./releases

Where sectionid=8 in articles table.

=item * Lyrics

  mangement module = Labyrinth::Plugin::Articles::Lyrics
  database tables = ixreleases, articles, paragraphs
  templates = ./lyrics

Where sectionid=7 in articles table, and type=1 in ixreleases.

=item * Profiles

  mangement module = Labyrinth::Plugin::Articles::Profiles
  database tables = ixreleases, articles, paragraphs, ixprofile, profiles
  templates = ./who

Where sectionid=5 in articles table, and type=2 in ixreleases.

=item * MP3s

  mangement module = Labyrinth::Plugin::MP3s
  database tables = ixmp3s, ixreleases, mp3s
  templates = ./mp3s

Where type=3 in ixreleases.

Note that ixmp3s is used to link an mp3 to a specific lyric. This can then be
used to add appropriate links associated with the displayed lyrics.

=item * Support Information

These are the data types, that are provided to describe the release
information. The default set up is for music, but these should be updated to
reference other forms, to be more appropriate for the collection type.

  mangement module = Labyrinth::Plugin::Release
  database tables = release_forms, release_types
  templates = ./releases

=back

=head1 SEE ALSO

  Labyrinth

=head1 AUTHOR

Barbie, <barbie@missbarbell.co.uk> for
Miss Barbell Productions, L<http://www.missbarbell.co.uk/>

=head1 COPYRIGHT & LICENSE

  Copyright (C) 2002-2014 Barbie for Miss Barbell Productions
  All Rights Reserved.

  This distribution is free software; you can redistribute it and/or
  modify it under the Artistic Licence v2.

=cut
