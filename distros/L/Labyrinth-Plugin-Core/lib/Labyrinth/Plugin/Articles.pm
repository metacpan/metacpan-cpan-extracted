package Labyrinth::Plugin::Articles;

use warnings;
use strict;

our $VERSION = '5.19';

=head1 NAME

Labyrinth::Plugin::Articles - Plugin Articles handler for Labyrinth

=head1 DESCRIPTION

Contains all the default article handling functionality for the Labyrinth
framework.

=cut

# -------------------------------------
# Library Modules

use base qw(Labyrinth::Plugin::Base);

use Clone qw(clone);
use Data::Pageset;

use Labyrinth::Audit;
use Labyrinth::DBUtils;
use Labyrinth::DTUtils;
use Labyrinth::Media;
use Labyrinth::Metadata;
use Labyrinth::MLUtils;
use Labyrinth::Session;
use Labyrinth::Support;
use Labyrinth::Users;
use Labyrinth::Variables;

# -------------------------------------
# Constants

use constant    MaxArticleWidth     => 400;
use constant    MaxArticleHeight    => 400;

use constant    IMAGE           => 1;
use constant    PARA            => 2;
use constant    LINK            => 3;
use constant    MFILE           => 4;   # Media File
use constant    DFILE           => 5;   # Download File
use constant    VIDEO           => 6;

use constant    MAINPAGE        => 5;
use constant    LIMIT_LATEST    => 20;

# -------------------------------------
# Variables

# type: 0 = optional, 1 = mandatory
# html: 0 = none, 1 = text, 2 = textarea

my %fields = (
    articleid   => { type => 0, html => 0 },
    postdate    => { type => 0, html => 1 },
    quickname   => { type => 1, html => 1 },
    title       => { type => 1, html => 1 },
    publish     => { type => 1, html => 1 },
    folderid    => { type => 0, html => 0 },
    userid      => { type => 0, html => 0 },
    snippet     => { type => 0, html => 2 },
    front       => { type => 0, html => 1 },
    latest      => { type => 0, html => 1 },
    sectionid   => { type => 0, html => 0 },
    width       => { type => 0, html => 1 },
    height      => { type => 0, html => 1 },
    body        => { type => 0, html => 2 },
    metadata    => { type => 0, html => 1 },
);

my (@mandatory,@allfields);
for(keys %fields) {
    push @mandatory, $_     if($fields{$_}->{type});
    push @allfields, $_;
}

our $INDEXKEY   = 'articleid';
our $ALLSQL     = 'AllArticles';
our $SAVESQL    = 'SaveArticle';
our $ADDSQL     = 'AddArticle';
our $GETSQL     = 'GetArticleByID';
our $DELETESQL  = 'DeleteRecords';
our $PROMOTESQL = 'PromoteArticle';
our $LEVEL      = EDITOR;
our $LEVEL2     = PUBLISHER;

# sectionid is used to reference different types of articles,
# however, the default is also a standard article.
my $SECTIONID   = 1;

=head1 CONFIGURATION

The Articles package is meant to be used as a base package providing default
configuration and functionality for article based content. It is expected that
that a plugin will use this package as a base, and override configuration and
methods as required.

=head2 Section IDs

It is recommended that the following be used to differentiate the types of
sections, for which articles are used to provide the underlying structure.
If you wish to add your own plugins, it is recommended that you use a Section
ID that is greater than 99 to avoid clashing with any potential standard
plugins.

  1 = page article, traditional articles
  2 = section entries, for sites that require intro text for each section
      (see Articles::Section)
  3 = site content, such as 'About' or 'Home' fixed layout content
      (see Articles::Site)
  4 = products (see Articles::Products)
  5 = profiles (see Articles::Profiles)
  6 = diary (see Articles::Diary)
  7 = lyrics (see Articles::Lyrics)
  8 = liner notes (see Release)

Note that some plugins mentioned above may not be currently available, however
all are planned for release.

=head2 SQL Phrases

Several keys used to access SQL phrases can be overriden. These default keys
are used in the event that only basic configuration overrides are needed, such
as the Section ID.

Key variables available are:

  our $INDEXKEY   = 'articleid';
  our $ALLSQL     = 'AllArticles';
  our $SAVESQL    = 'SaveArticle';
  our $ADDSQL     = 'AddArticle';
  our $GETSQL     = 'GetArticleByID';
  our $DELETESQL  = 'DeleteRecords';
  our $PROMOTESQL = 'PromoteArticle';
  our $LEVEL      = EDITOR;             # for normal admin actions
  our $LEVEL2     = PUBLISHER;          # for delete actions

=cut

# -------------------------------------
# The Subs

=head1 PUBLIC INTERFACE METHODS

=over 4

=item LatestArticles

Retrieves a list of the latest article titles

=item Archive

Retrieves a list of the volumes available.

=item Page

Retrieves an set of articles, for a given page. Default to first page.

=item List

Retrieves an initial list of articles. Primarily used to prepare a front page.

=item Meta

Retrieves a list of articles based on given meta tags.

=item Search

Retrieves a list of articles based on a given search string.

=item Cloud

Provides the current tag cloud.

=item Tags

Retrieves the current list of meta tags

=item Item

Provides a single article.

=back

=cut

sub LatestArticles {
    # latest Articles list
    my $limit = $settings{article_latest} || LIMIT_LATEST;
    my @rows = $dbi->GetQuery('hash','GetArticlesLatest',{limit => $limit});
    LogDebug("Latest:rows=".scalar(@rows));
    for my $row (@rows) {
        $row->{postdate} = formatDate(19,$row->{createdate});
        $row->{name}     = UserName($row->{userid});
    }
    $tvars{latest}->{articles} = \@rows if(@rows);
}

sub Archive {
    $cgiparams{sectionid} ||= $SECTIONID;
    $cgiparams{section}   ||= 'articles';

    my @rows = $dbi->GetQuery('hash','GetVolumes',$cgiparams{sectionid});
    $tvars{archive}{$cgiparams{section}} = \@rows   if(@rows);
}

sub Page {
    my @mainarts;
    $cgiparams{name} = undef;
    my $page = $cgiparams{page} || 1;
    
    my $limit = $settings{data}{article_pageset} || $settings{article_pageset} || MAINPAGE;
    my $sectionid = $cgiparams{sectionid} || $SECTIONID;
    my @where = ("sectionid=$sectionid","publish=3");
    my $where = 'WHERE ' . join(' AND ',@where);
    my $order = 'ORDER BY ' . ($settings{data}{order} || 'createdate DESC');
    my @rows = $dbi->GetQuery('hash',$ALLSQL,{where=>$where,order=>$order});

    my $page_info = Data::Pageset->new({
        'total_entries'       => scalar(@rows), 
        'entries_per_page'    => $limit, 
        # Optional, will use defaults otherwise.
        'current_page'        => $page,
        #'pages_per_set'       => $pages_per_set,
        #'mode'                => 'fixed', # default, or 'slide'
    });

    $tvars{pages}{first}    = $page_info->first_page;
    $tvars{pages}{last}     = $page_info->last_page;
    $tvars{pages}{next}     = $page_info->next_page;
    $tvars{pages}{previous} = $page_info->previous_page;

    my @arts = splice(@rows, ($page - 1) * $limit, $limit);
    for my $row (@arts) {
        $cgiparams{articleid} = $row->{articleid};
        Item();
        push @mainarts, $tvars{articles}->{$tvars{primary}};
    }
    $tvars{mainarts} = \@mainarts   if(@mainarts);
    $cgiparams{sectionid} = undef;
}

sub List {
    my (@mainarts,@inbrief,@archive);
    $cgiparams{name} = undef;

    my $limit = $settings{data}{article_limit} || $settings{article_limit};
    my $step  = "LIMIT $limit"  if($limit);
    my $stop  = $settings{data}{article_stop} || MAINPAGE;

    my $sectionid = $cgiparams{sectionid} || $SECTIONID;

    my @where = ("sectionid=$sectionid","publish=3");
    push @where, $settings{where}  if($settings{where});
    my $where = 'WHERE ' . join(' AND ',@where);
    my $order = 'ORDER BY ' . ($settings{data}{order} || 'createdate DESC');

    my @rows = $dbi->GetQuery('hash',$ALLSQL,{where=>$where,limit=>$step,order=>$order});
    for my $row (@rows) {
        if($stop) {
            $cgiparams{articleid} = $row->{articleid};
            Item();
            push @mainarts, $tvars{articles}->{$tvars{primary}};
            $stop--;
            next;
        }
        push @inbrief, {name => $row->{quickname}, title => $row->{title}, snippet => _snippet($row,82)};
    }
    # archived articles
    @where = ("sectionid=$sectionid","publish=4");
    $where = 'WHERE ' . join(' AND ',@where);
    @rows = $dbi->GetQuery('hash',$ALLSQL,{where=>$where,limit=>$limit,order=>$order});
    for my $row (@rows) {
        push @archive, {name => $row->{quickname}, title => $row->{title}, snippet => _snippet($row,82)};
    }
    $tvars{mainarts} = \@mainarts   if(@mainarts);
    $tvars{inbrief}  = \@inbrief    if(@inbrief);
    $tvars{archive}  = \@archive    if(@archive);
    $cgiparams{sectionid} = undef;
}

sub Meta {
    my $page        = $cgiparams{page} || 1;
    my $limit       = $settings{data}{article_pageset} || $settings{article_pageset} || MAINPAGE;
    my $sectionid   = $cgiparams{sectionid} || $SECTIONID;

    my @data = split(qr/[ ,]+/,$cgiparams{data});
    my @rows = MetaSearch(  'keys'  => ['Art'],
                            'meta'  => \@data,
                            'where' => "sectionid=$sectionid AND publish=3",
                            'limit' => '',
                            'order' => 'createdate',
                            'sort'  => 'desc');

    my $page_info = Data::Pageset->new({
        'total_entries'       => scalar(@rows), 
        'entries_per_page'    => $limit, 
        'current_page'        => $page,
    });

    my @arts = splice(@rows, ($page - 1) * $limit, $limit);
    for my $row (@arts) {
        $cgiparams{articleid} = $row->{articleid};
        Item();
        push @{$tvars{mainarts}}, $tvars{articles}{$tvars{primary}};
    }

    $tvars{pages}{first}    = $page_info->first_page;
    $tvars{pages}{last}     = $page_info->last_page;
    $tvars{pages}{next}     = $page_info->next_page;
    $tvars{pages}{previous} = $page_info->previous_page;
    $tvars{pages}{data}     = $cgiparams{data};
}

sub Cloud {
    my $sectionid = $cgiparams{sectionid} || $SECTIONID;
    my $actcode   = $cgiparams{actcode}   || 'arts-meta';
    $tvars{cloud} = MetaCloud(key => 'Art', sectionid => $sectionid, actcode => $actcode);
}

sub Tags {
    my $sectionid = $cgiparams{sectionid} || $SECTIONID;
    my @tags = MetaTags(key => 'Art', sectionid => $sectionid);
    $tvars{metatags} = \@tags   if(@tags);
}

sub Search {
    my $page        = $cgiparams{page} || 1;
    my $limit       = $settings{data}{article_pageset} || $settings{article_pageset} || MAINPAGE;
    my $sectionid   = $cgiparams{sectionid} || $SECTIONID;

    my @data = split(qr/[ ,]+/,$cgiparams{data});
    my @rows = MetaSearch(  'keys'  => ['Art'],
                            'meta'  => \@data,
                            'full'  => 1,
                            'where' => "sectionid=$sectionid AND publish=3",
                            'limit' => '',
                            'order' => 'createdate',
                            'sort'  => 'desc');

    my $page_info = Data::Pageset->new({
        'total_entries'       => scalar(@rows), 
        'entries_per_page'    => $limit, 
        'current_page'        => $page,
    });

    my @arts = splice(@rows, ($page - 1) * $limit, $limit);
    for my $row (@arts) {
        $cgiparams{articleid} = $row->{articleid};
        Item();
        push @{$tvars{mainarts}}, $tvars{articles}{$tvars{primary}};
    }

    $tvars{pages}{first}    = $page_info->first_page;
    $tvars{pages}{last}     = $page_info->last_page;
    $tvars{pages}{next}     = $page_info->next_page;
    $tvars{pages}{previous} = $page_info->previous_page;
    $tvars{pages}{data}     = $cgiparams{data};
}

sub Item {
    my $name = $cgiparams{'name'}    || undef;
    my $naid = $cgiparams{articleid} || $cgiparams{id} || undef;

    my $maximagewidth  = $settings{maximagewidth}  || MaxArticleWidth;
    my $maximageheight = $settings{maximageheight} || MaxArticleHeight;

    unless($name || $naid) {
        $tvars{errcode} = 'ERROR';
        return;
    }

    # main article data
    my ($key,$search) = $name ? ('GetArticleByName',$name) :
                                ('GetArticleByID',$naid);
    my @data = $dbi->GetQuery('hash',$key,$search);
    return  unless(@data);

    $data[0]->{postdate} = formatDate(19,$data[0]->{createdate});
    $data[0]->{name} = UserName($data[0]->{userid});
    $tvars{article}  = $data[0];
    if($data[0]->{imageid}) {
        my ($tag,$link,undef,$x) = GetImage($data[0]->{imageid});
        $data[0]->{tag}    = $tag;
        $data[0]->{link}   = $link;
        $data[0]->{resize} = 1 if($x && $x > 100)
    }

    # article content
    my @body = $dbi->GetQuery('hash','GetContent',$data[0]->{$INDEXKEY});
    foreach my $body (@body) {
        if($body->{type} == IMAGE) {
            my @rows = $dbi->GetQuery('hash','GetImageByID',$body->{imageid});
            $body->{link}       = $rows[0]->{link};
            $body->{alignclass} = AlignClass($body->{align});
            ($body->{tag},$body->{width},$body->{height}) = split(qr/\|/,$body->{body})
                if($body->{body});

            ($body->{width},$body->{height}) = GetImageSize($body->{link},$rows[0]->{dimensions},$body->{width},$body->{height},$maximagewidth,$maximageheight);

            #LogDebug(sprintf "%d/%s [%d x %d]", ($body->{imageid}||0),($body->{link}||'-'),($body->{width}||0),($body->{height}||0));
        } elsif($body->{type} == PARA) {
            $body->{body} = LinkTitles($body->{body});
        }
    }

    $tvars{primary} = $data[0]->{quickname} || 'draft' . $data[0]->{articleid};
    $tvars{articles}->{$tvars{primary}} = {
        data    => $data[0],
        body    => \@body,
    };

    $tvars{article} = $tvars{articles}->{$tvars{primary}};
    $cgiparams{sectionid} = undef;
    my @meta = MetaGet($data[0]->{articleid},'Art');
    $tvars{articles}->{$tvars{primary}}->{meta} = \@meta    if(scalar(@meta));
    $tvars{article} = $tvars{articles}->{$tvars{primary}};
}

=head1 ADMIN INTERFACE METHODS

=over 4

=item Admin

Lists the current set of articles for the given section.

Also provides the delete, copy and promote functionality from the main
administration page for the given section.

=item Add

Add an article to the current section.

=item Edit

Edit an article within the current section.

=item AddParagraph

Add a text block to the current article.

=item AddImage

Add an image block to the current article.

=item AddLink

Add a link block to the current article.

=item AddVideo

Add a embedded video block to the current article.

=item DeleteItem

Delete an article.

=item Relocate

Relocate an article in a list, where an order is in use.

=item LoadContent

Load complete article from form fields, save all image and media files.

=item EditAmendments

Additional drop downs and fields prepared for edit form.

=item Save

Save an article within the current section.

=item Promote

Promote the given article within the current section.

=item Copy

Copy an article, to create a new article, within the current section.

=item Delete

Delete a given article within the current section.

=back

=cut

sub Admin {
    return  unless AccessUser($LEVEL);

    if($cgiparams{doaction}) {
           if($cgiparams{doaction} eq 'Delete')  { Delete()  }
        elsif($cgiparams{doaction} eq 'Copy')    { Copy()    }
        elsif($cgiparams{doaction} eq 'Promote') { Promote() }
    }

    my @front = CGIArray('FRONT');
    if(@front) {
        my @check = $dbi->GetQuery('hash','CheckFrontPageArticles');
        my %check = map {$_->{articleid} => 1} @check;
        for my $id (@front) {
            if($check{$id}) {
                $check{$id} = 0;
            } else {
                $dbi->DoQuery('SetFrontPageArticle',$id);
            }
        }
        for my $id (keys %check) {
            next    unless($check{$id});
            $dbi->DoQuery('ClearFrontPageArticle',$id);
        }
    }

    my $sectionid = $cgiparams{sectionid} || $SECTIONID;
    my @where = ("sectionid=$sectionid");
    push @where, "publish<4"                                    unless($cgiparams{publish});
    push @where, "publish=$cgiparams{publish}"                  if($cgiparams{publish});
    push @where, "userid=$tvars{'loginid'}"                     unless(Authorised(EDITOR));
    push @where, "quickname LIKE '%$cgiparams{'searchname'}%'"  if($cgiparams{'searchname'});
    my $where = @where ? 'WHERE '.join(' AND ',@where) : '';

    my @rows = sort {int($b->{createdate}||0) <=> int($a->{createdate}||0)}
                $dbi->GetQuery('hash',$ALLSQL,{where=>$where});
#   LogDebug("Admin: rows=".scalar(@rows));
    foreach my $row (@rows) {
        $row->{publishstate} = PublishState($row->{publish});
        $row->{name} = UserName($row->{userid});
        $row->{postdate} = formatDate(3,$row->{createdate});
    }
    $tvars{data} = \@rows   if(@rows);
    $tvars{ddpublish} = PublishSelect($cgiparams{publish},1);
    $tvars{sectionid} = $sectionid;
}

sub Add {
    return  unless AccessUser($LEVEL);

    my %data = (
        articleid   => 0,
        folderid    => $tvars{user}->{folder},
        userid      => $tvars{loginid},
        name        => $tvars{user}->{name},
        postdate    => formatDate(3),
        ddpublish   => PublishSelect(1),
        sectionid   => $cgiparams{sectionid} || $SECTIONID, # default 1=article
    );

    $tvars{primary} = 'draft' . $data{articleid};
    my @fields = (  $data{folderid},
                    'DRAFT',
                    $data{userid},
                    $data{sectionid},
                    $tvars{primary},
                    1,
                    formatDate(0));
    $data{articleid} = $dbi->IDQuery('AddArticle',@fields);
    $data{quickname} = 'ID'.$data{articleid};

    @fields = ( $data{articleid},
                1,                  # orderno
                2,                  # type - paragraph
                0,                  # imageid
                '',                 # link
                '',                 # body
                ''                  # align
    );
    my $paraid = $dbi->IDQuery('AddContent',@fields);

    my @body = (
        {   paraid=>$paraid,orderno=>1,type=>PARA},
    );

    $tvars{articles}->{$tvars{primary}} = {
        blocks      => '1', # '1,2'
        data        => \%data,
        body        => \@body,
        htmltags    => LegalTags(),
    };

    $tvars{authors} = UserSelect($tvars{loginid},1);
    $tvars{article} = $tvars{articles}{$tvars{primary}};
    $tvars{preview} = $tvars{articles}{$tvars{primary}};
}

sub Edit {
    return  unless AccessUser($LEVEL);
    return  unless AuthorCheck($GETSQL,$INDEXKEY,$LEVEL);
    $tvars{primary} = $tvars{data}->{quickname} || 'draft' . ($tvars{data}->{articleid}||0);

    my $maximagewidth  = $settings{maximagewidth}  || MaxArticleWidth;
    my $maximageheight = $settings{maximageheight} || MaxArticleHeight;

    # article content
    my @blocks;
    my $orderno = 1;
    my @body = $dbi->GetQuery('hash','GetContent',$cgiparams{$INDEXKEY});
    foreach my $body (@body) {
        push @blocks, $orderno;
        if($body->{type} == IMAGE
        || $body->{type} == MFILE
        || $body->{type} == DFILE) {
            my @rows = $dbi->GetQuery('hash','GetImageByID',$body->{imageid});
            $rows[0]->{body} ||= '';
            ($body->{tag},$body->{width},$body->{height}) = split(qr/\|/,$body->{body});
            $body->{link}       = $rows[0]->{link};
            $body->{ddalign}    = AlignSelect($body->{align},$orderno);
            $body->{alignclass} = AlignClass($body->{align});

            ($body->{width},$body->{height}) = GetImageSize($body->{link},$rows[0]->{dimensions},$body->{width},$body->{height},$maximagewidth,$maximageheight);

            LogDebug("$body->{imageid}/$body->{link} [$body->{width} x $body->{height}]");
        }

        $body->{orderno} = $orderno++;
    }
    $tvars{articles}->{$tvars{primary}} = {
        data    => $tvars{data},
        blocks  => join(",",@blocks),
        body    => \@body,
    };
    EditAmendments();

    $tvars{dimensions}->{width}  = $settings{maximagewidth}  || MaxArticleWidth;
    $tvars{dimensions}->{height} = $settings{maximageheight} || MaxArticleHeight;
}

sub AddParagraph {
    my ($blocks,$data) = LoadContent();
    my $item = @$blocks ? (@$blocks)[-1] + 1 : 1;
    $dbi->DoQuery('AddContent',$data->{articleid},$item,PARA,0,'','',0);
}

sub AddImage {
    my ($blocks,$data) = LoadContent();
    my $item = @$blocks ? (@$blocks)[-1] + 1 : 1;
    $dbi->IDQuery('AddContent',$data->{articleid},$item,IMAGE,0,'','',1);
}

sub AddLink {
    my ($blocks,$data,$body) = LoadContent();
    my $item = @$blocks ? (@$blocks)[-1] + 1 : 1;
    $dbi->IDQuery('AddContent',$data->{articleid},$item,LINK,0,'','',0);
}

sub AddVideo {
    my ($blocks,$data,$body) = LoadContent();
    my $item = @$blocks ? (@$blocks)[-1] + 1 : 1;
    $dbi->IDQuery('AddContent',$data->{articleid},$item,VIDEO,0,'','',0);
}

sub DeleteItem {
    return  unless AccessUser($LEVEL2);
    return  unless $cgiparams{'recordid'};
    $dbi->DoQuery('DeleteContent',$cgiparams{'recordid'});
}

sub Relocate {
    return  unless AccessUser($LEVEL);
    return  unless $cgiparams{'recordid'};
    my $move = shift;

    my ($blocks,$data,$body) = LoadContent();
    my $para = $cgiparams{'recordid'};

    my ($this,$that);
    for my $block (@$blocks) {
        if($body->[$block]->{paraid} == $para) {
            $this = $block;
        } else {
            $that = $block  if( $move && !$this);           # before
            $that = $block  if(!$move &&  $this && !$that); # after
        }
    }

    if($this && $that) {
        $dbi->DoQuery('Relocate',$that,$body->[$this]->{paraid});
        $dbi->DoQuery('Relocate',$this,$body->[$that]->{paraid});
    }
}

# list=1,2,3,4
# BLOCK2="1,2"      - IMAGE,orderno
# IMAGETAG2=""
# IMAGEHREF2=""
# IMAGEUPLOAD2=""
# BLOCK1="2,1"      - PARAGRAPH,orderno
# TEXT1=""          - paragraphs are textblocks
# BLOCK1="3,3"      - LINK,orderno
# LINK3=""          - links are textblocks

sub LoadContent {
    my (@body,@ordernos);
    my @blocks = $cgiparams{'list'} ? split(",", $cgiparams{'list'}) : ();

    my $maximagewidth  = $settings{maximagewidth}  || MaxArticleWidth;
    my $maximageheight = $settings{maximageheight} || MaxArticleHeight;

    for my $block (@blocks) {
        my ($type,$paraid) =  split(",", $cgiparams{"BLOCK$block"});
        push @ordernos, $block;

        $body[$block]->{type} = $type;
        $body[$block]->{orderno} = $block;

        # images
        if($type == IMAGE) {
            $body[$block]->{paraid}     = $paraid;
            $body[$block]->{imagelink}  = $cgiparams{"IMAGELINK$block"};
            $body[$block]->{href}       = $cgiparams{"IMAGEHREF$block"};
            $body[$block]->{align}      = $cgiparams{"ALIGN$block"};
            my $tag    = CleanTags($cgiparams{"IMAGETAG$block"});
            my $width  = $cgiparams{"width$block"}  || $maximagewidth;
            my $height = $cgiparams{"height$block"} || $maximageheight;

            # uploaded own image
            if(defined $cgiparams{"IMAGEUPLOAD$block"} && $cgiparams{"IMAGEUPLOAD$block"}) {
                my ($imageid,$imagelink) = SaveImageFile(
                                    param   => "IMAGEUPLOAD$block",
                                    stock   => 'Special',
                                    width   => $width,
                                    height  => $height);
                $body[$block]->{imageid}   = $imageid;
                $body[$block]->{imagelink} = $imagelink;

            # using an existing image
            } elsif(defined $cgiparams{"display$block"}) {
                $body[$block]->{imageid} = $cgiparams{"display$block"};
                (undef,$body[$block]->{imagelink}) = GetImage($body[$block]->{imageid});

            # already uploaded photo
            } elsif(defined $cgiparams{"gallery$block"}) {
                $body[$block]->{imageid} = $cgiparams{"gallery$block"};
                (undef,$body[$block]->{imagelink}) = GetImage($body[$block]->{imageid});
            }

            $body[$block]->{href} ||= $body[$block]->{imagelink};

            $tag  ||= '';
            $width  = $cgiparams{"width$block"}  ? ($cgiparams{"width$block"}  > $maximagewidth  ? $maximagewidth  : $cgiparams{"width$block"})  : '';
            $height = $cgiparams{"height$block"} ? ($cgiparams{"height$block"} > $maximageheight ? $maximageheight : $cgiparams{"height$block"}) : '';
            $body[$block]->{body}   = "$tag|$width|$height";
            $body[$block]->{tag}    = $tag;
            $body[$block]->{width}  = $width;
            $body[$block]->{height} = $height;

        # paragraphs
        } elsif($type == PARA) {
            $body[$block]->{paraid} = $paraid;
            $body[$block]->{body} = CleanTags($cgiparams{"TEXT$block"});
            $body[$block]->{link} = '';
            $body[$block]->{imageid} = 0;

        # links
        } elsif($type == LINK) {
            $body[$block]->{paraid}  = $paraid;
            $body[$block]->{body}    = $cgiparams{"LINK$block"};
            $body[$block]->{href}    = CleanTags($cgiparams{"LINK$block"});
            $body[$block]->{imageid} = 0;

        # video
        } elsif($type == VIDEO) {
            $body[$block]->{paraid}  = $paraid;

            my $body = $cgiparams{"VIDEO$block"};
            $body =~ s!.*?<iframe.*?src="([^"]+)".*!$1! if($body =~ /<iframe/);
            
            my $videoid = 0;
            my ($type,$code) = $body =~ m!(.*)/(\w+)$!;
            if($type =~ /youtu\.?be/)  { $videoid = 1 }
            elsif($type =~ /vimeo/) { $videoid = 2 }

            $body[$block]->{body}    = $body;
            $body[$block]->{href}    = $code;
            $body[$block]->{imageid} = $videoid;

        # media files
        } elsif($type == MFILE) {
            $body[$block]->{paraid}    = $paraid;

            # uploaded own image
            if(defined $cgiparams{"MEDIA$block"} && $cgiparams{"MEDIA$block"}) {
                my ($fileid) = SaveMediaFile(
                                    param   => "MEDIA$block",
                                    stock   => 'Media');
                $body[$block]->{imageid}   = $fileid;

            # already uploaded
            } elsif(defined $cgiparams{"media$block"}) {
                $body[$block]->{imageid} = $cgiparams{"media$block"};
            }

        # download files
        } elsif($type == DFILE) {
            $body[$block]->{paraid}    = $paraid;

            LogDebug("LoadContent:DFILE");
            LogDebug(qq!LoadContent:param=[MEDIA$block][$cgiparams{"MEDIA$block"}]!);

            # uploaded own image
            if(defined $cgiparams{"MEDIA$block"} && $cgiparams{"MEDIA$block"}) {
                my ($fileid) = SaveMediaFile(
                                    param   => "MEDIA$block",
                                    stock   => 'Talks');
                $body[$block]->{imageid}   = $fileid;

            # already uploaded
            } elsif(defined $cgiparams{"media$block"}) {
                $body[$block]->{imageid} = $cgiparams{"media$block"};
            }
        }
    }

    $cgiparams{quickname} ||= $cgiparams{title};
    $cgiparams{quickname} =~ tr/ /_/;
    $cgiparams{quickname} = lc $cgiparams{quickname};

    my %data = map {$_ => ($cgiparams{$_} || $tvars{data}->{$_})}
                    qw(articleid createdate folderid userid title quickname publish snippet front latest sectionid);
    $data{front}    = ($data{'front'} ? 1 : 0);
    $data{latest}   = ($data{'latest'} ? 1 : 0);
    $data{imageid}  = $cgiparams{'display0'};
    $data{postdate} = formatDate(6,$data{createdate});

    return(\@blocks,\%data,\@body);
}

sub EditAmendments {
    $tvars{articles}->{$tvars{primary}}{data}{metadata}   = MetaGet(     $tvars{articles}->{$tvars{primary}}{data}{'articleid'},'Art');
    $tvars{articles}->{$tvars{primary}}{data}{name}       = UserName(    $tvars{articles}->{$tvars{primary}}{data}{userid});
    $tvars{articles}->{$tvars{primary}}{data}{postdate}   = formatDate(3,$tvars{articles}->{$tvars{primary}}{data}{createdate});
    $tvars{articles}->{$tvars{primary}}{data}{publish}  ||= 1;

    my $resize = 0;
    if($tvars{articles}->{$tvars{primary}}{data}{imageid}) {
        my ($tag,$link,undef,$x) = GetImage($tvars{articles}->{$tvars{primary}}{data}{imageid});
        $tvars{articles}->{$tvars{primary}}{data}{tag}  = $tag;
        $tvars{articles}->{$tvars{primary}}{data}{link} = $link;
        $resize = 1 if($x && $x > 100)
    }

    if(Authorised(ADMIN)) {
        LogDebug("EditAmendments: publish=[$tvars{articles}->{$tvars{primary}}{data}{publish}]");
        $tvars{articles}->{$tvars{primary}}{data}{ddpublish} = PublishSelect($tvars{articles}->{$tvars{primary}}{data}{publish});
    } else {
        my $promote = 0;
        $promote = 1    if($tvars{articles}->{$tvars{primary}}{data}{publish} == 1);
        $promote = 1    if($tvars{articles}->{$tvars{primary}}{data}{publish} == 2 && AccessUser(PUBLISHER));
        $promote = 1    if($tvars{articles}->{$tvars{primary}}{data}{publish} == 3 && AccessUser(PUBLISHER));
        LogDebug("EditAmendments: publish=[$tvars{$tvars{primary}}{data}{publish}], promote=[$promote]");
        $tvars{articles}->{$tvars{primary}}{data}{ddpublish} = PublishAction($tvars{articles}->{$tvars{primary}}{data}{publish},$promote);
    }

    $tvars{htmltags} = LegalTags();
    $tvars{preview}->{body} = clone($tvars{articles}->{$tvars{primary}}->{body});
    $tvars{preview}->{data} = clone($tvars{articles}->{$tvars{primary}}->{data});
    $tvars{preview}{data}{resize}   = $resize;
    $tvars{preview}{data}{postdate} = formatDate(6,$tvars{articles}->{$tvars{primary}}{data}{createdate});

    my @meta = MetaGet($tvars{articles}->{$tvars{primary}}{data}{'articleid'},'Art');
    $tvars{preview}->{meta} = \@meta    if(@meta);

    for(keys %fields) {
           if($fields{$_}->{html} == 1) { $tvars{preview}{data}{$_} = CleanHTML($tvars{preview}{data}{$_});
                                          $tvars{articles}->{$tvars{primary}}{data}{$_} = CleanHTML($tvars{articles}->{$tvars{primary}}{data}{$_}); }
        elsif($fields{$_}->{html} == 2) { $tvars{articles}->{$tvars{primary}}{data}{$_} = SafeHTML($tvars{articles}->{$tvars{primary}}{data}{$_}); }
        elsif($fields{$_}->{html} == 3) { $tvars{articles}->{$tvars{primary}}{data}{$_} = SafeHTML($tvars{articles}->{$tvars{primary}}{data}{$_}); }
    }

    for my $item (@{$tvars{articles}->{$tvars{primary}}->{body}}) {
        $item->{body} = SafeHTML($item->{body}) if($item->{type} == PARA);
    }

    $tvars{article} = $tvars{articles}->{$tvars{primary}};
    $tvars{authors} = UserSelect($tvars{article}{data}{userid},1);
}

sub Save {
    return  unless AccessUser($LEVEL);
    return  unless AuthorCheck($GETSQL,$INDEXKEY,$LEVEL);
    $tvars{primary} = $tvars{data}->{quickname} || 'draft' . ($tvars{data}->{articleid}||0);
    my $publish = $tvars{data}->{publish} || 0;
    my $sectionid = $cgiparams{sectionid} || $SECTIONID;

    for(keys %fields) {
           if($fields{$_}->{html} == 1) { $cgiparams{$_} = CleanHTML($cgiparams{$_}) }
        elsif($fields{$_}->{html} == 2) { $cgiparams{$_} = CleanTags($cgiparams{$_}) }
        elsif($fields{$_}->{html} == 3) { $cgiparams{$_} = CleanLink($cgiparams{$_}) }
    }

    # read the encoded form
    my ($blocks,$data,$body) = LoadContent();
    $tvars{$tvars{primary}}->{blocks} = join(",",@$blocks);
    $tvars{$tvars{primary}}->{data}   = $data;
    $tvars{$tvars{primary}}->{body}   = $body;

    my @manfields = @mandatory;
    push @manfields, qw(snippet)    if($cgiparams{front});
    FieldCheck(\@allfields,\@manfields);

    for my $key (keys %{$tvars{data}}) {
        next    unless($key =~ /^(?:TEXT|LINK|IMAGELINK|IMAGEHREF|IMAGETAG)(\d+)_err/);
        $tvars{body}->[$1]->{error} = ErrorSymbol;
        $tvars{errcode} = 'ERROR';
    }

    # check title is unique
    my @data = $dbi->GetQuery('hash','FindTitle',$cgiparams{title});
    for(@data) {
        next    if($_->{articleid} == $tvars{data}->{articleid});
        $tvars{article}{data}{title_err} = ErrorSymbol;
        $tvars{errmess} = 2;
        last;
    }

    return  if($tvars{errcode});

    $data->{front}       = $data->{front}  ? 1 : 0;
    $data->{latest}      = $data->{latest} ? 1 : 0;
    $data->{createdate}  =   formatDate(0)                      if($data->{publish} == 3 && $publish < 3);
    $data->{createdate}  = unformatDate(3,$cgiparams{postdate}) if($cgiparams{postdate});
    $data->{userid}    ||= $tvars{loginid};
    $data->{sectionid} ||= 1;           # default 1 = article

    if($sectionid == 6) {
        if($data->{publish} == 3 && $publish < 3) {
            my $archdate =        formatDate(2, $data->{createdate});
            my $volumeid = substr(formatDate(13,$data->{createdate}),0,6);
            my @vols = $dbi->GetQuery('hash','GetVolume',$volumeid,$sectionid);
            if(@vols) {
                $dbi->DoQuery('UpdateVolume',$vols[0]->{counter}+1,$volumeid,$sectionid);
            } else {
                $dbi->DoQuery('InsertVolume',$volumeid,$sectionid,$archdate,1);
            }
        }
    }

    # save master image, if one supplied
    $data->{imageid} ||= 0;
    if(defined $cgiparams{"IMAGEUPLOAD0"}) {
        my $maximagewidth  = $settings{maximagewidth}  || MaxArticleWidth;
        my $maximageheight = $settings{maximageheight} || MaxArticleHeight;
        ($data->{imageid}) = 
            SaveImageFile(
                param   => "IMAGEUPLOAD0",
                stock   => 'Special',
                width   => $maximagewidth,
                height  => $maximageheight
            );
    }

    # save article metadata
    $dbi->DoQuery($SAVESQL,
                    $data->{folderid},
                    $data->{title},
                    $data->{userid},
                    $data->{sectionid},
                    $data->{quickname},
                    $data->{snippet},
                    $data->{imageid},
                    $data->{front},
                    $data->{latest},
                    $data->{publish},
                    $data->{createdate},
                    $data->{articleid}
    );

    # save each content item as appropriate
    foreach my $block (@$blocks) {
        # MUST have a paraid
        next    unless($body->[$block]->{paraid});

        # save article paragraph
        $dbi->DoQuery('SaveContent',
                        $data->{articleid},
                        $block,
                        $body->[$block]->{type},
                        $body->[$block]->{imageid},
                        $body->[$block]->{href},
                        $body->[$block]->{body},
                        $body->[$block]->{align},
                        $body->[$block]->{paraid});
    }

    if($cgiparams{doaction}) {
           if($cgiparams{doaction} eq 'AddImage')  { AddImage();        }
        elsif($cgiparams{doaction} eq 'AddPara')   { AddParagraph();    }
        elsif($cgiparams{doaction} eq 'AddLink')   { AddLink();         }
        elsif($cgiparams{doaction} eq 'AddMedia')  { AddMedia();        }
        elsif($cgiparams{doaction} eq 'AddFile')   { AddFile();         }
        elsif($cgiparams{doaction} eq 'AddVideo')  { AddVideo();        }
        elsif($cgiparams{doaction} eq 'Delete')    { DeleteItem();      }
        elsif($cgiparams{doaction} eq 'MoveUp')    { Relocate(1);       }
        elsif($cgiparams{doaction} eq 'MoveDn')    { Relocate(0);       }
    }

    # save metadata
    my @metadata = $cgiparams{metadata} ? split(qr/[, ]+/,$cgiparams{metadata}) : ();
    MetaSave($cgiparams{articleid},['Art'],@metadata);

    $tvars{thanks} = 1;
}

sub Promote {
    return  unless AccessUser(PUBLISHER);
    my @ids = CGIArray('LISTED');
    return  unless @ids;
    for my $id (@ids) {
        $cgiparams{'articleid'} = $id;
        next    unless AuthorCheck('GetArticleByID','articleid');
        my $publish = $tvars{data}->{publish} + 1;
        next    unless($publish < 5);
        $dbi->DoQuery('PromoteArticle',$publish,$cgiparams{'articleid'});
    }
}

sub Copy {
    return  unless AccessUser($LEVEL);
    $cgiparams{$INDEXKEY} = $cgiparams{'LISTED'};
    return  unless AuthorCheck($GETSQL,$INDEXKEY,$LEVEL);

    my @fields = (  $tvars{data}->{folderid},
                    $tvars{data}->{title} . ' - COPY',
                    $tvars{loginid},
                    formatDate(0),
                    $tvars{data}->{sectionid},
                    $tvars{data}->{name} . '-copy',
                    1);
    my $articleid = $dbi->IDQuery($ADDSQL,@fields);

    my $order = 1;
    my @body = $dbi->GetQuery('hash','GetContent',$cgiparams{$INDEXKEY});
    for my $item (@body) {
        $dbi->DoQuery('AddContent',$articleid,$order,$item->{type},$item->{imageid},$item->{link},$item->{body});
        $order++;
    }

    $cgiparams{$INDEXKEY} = $articleid;
    SetCommand('arts-edit');
}

sub Delete {
    return  unless AccessUser($LEVEL2);
#   return  unless AuthorCheck('GetArticleByID','articleid',$LEVEL);

    my @delete = CGIArray('LISTED');
    if(@delete) {
        $dbi->DoQuery('DeleteArticleContent',{ids=>join(",",@delete)});
        $dbi->DoQuery('DeleteArticle',       {ids=>join(",",@delete)});
    }
}

sub _snippet {
    my ($row,$chars) = @_;
    my $text = $row->{snippet} || $row->{body};
    return substr(CleanHTML($text),0,($chars-length($row->{title})));
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
