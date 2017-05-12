package Labyrinth::Plugin::News;

use warnings;
use strict;

our $VERSION = '5.19';

=head1 NAME

Labyrinth::Plugin::News - Plugin News handler for Labyrinth

=head1 DESCRIPTION

Contains all the news handling functionality for the Labyrinth
framework.

=cut

# -------------------------------------
# Library Modules

use base qw(Labyrinth::Plugin::Base);

use Clone qw(clone);

use Labyrinth::Globals;
use Labyrinth::DBUtils;
use Labyrinth::DTUtils;
use Labyrinth::Media;
use Labyrinth::MLUtils;
use Labyrinth::Session;
use Labyrinth::Support;
use Labyrinth::Users;
use Labyrinth::Variables;

# -------------------------------------
# Constants

use constant    FRONTPAGE   => 5;
use constant    MAINNEWS    => 5;
use constant    INBRIEF     => 10;

# -------------------------------------
# Variables

# type: 0 = optional, 1 = mandatory
# html: 0 = none, 1 = text, 2 = textarea

my %fields = (
    newsid      => { type => 0, html => 0 },
    folderid    => { type => 0, html => 0 },
    title       => { type => 1, html => 1 },
    userid      => { type => 0, html => 0 },
    body        => { type => 1, html => 2 },
    postdate    => { type => 1, html => 0 },
    imageid     => { type => 0, html => 0 },
    ALIGN0      => { type => 0, html => 0 },
    front       => { type => 0, html => 0 },
    alttag      => { type => 0, html => 1 },
    publish     => { type => 1, html => 0 },
    href        => { type => 0, html => 1 },
);

my (@mandatory,@allfields);
for(keys %fields) {
    push @mandatory, $_     if($fields{$_}->{type});
    push @allfields, $_;
}

my @savefields  = qw(folderid userid title body imageid ALIGN0 front publish createdate);
my @addfields   = qw(folderid userid title body imageid ALIGN0 front publish createdate);
my $INDEXKEY    = 'newsid';
my $ALLSQL      = 'AllNews';
my $SAVESQL     = 'SaveNews';
my $ADDSQL      = 'AddNews';
my $GETSQL      = 'GetNewsByID';
my $DELETESQL   = 'DeleteNews';
my $PROMOTESQL  = 'PromoteNews';
my $LEVEL       = EDITOR;
my $LEVEL2      = ADMIN;
my $NEXTCOMMAND = 'news-edit';

# -------------------------------------
# The Subs

=head1 PUBLIC INTERFACE METHODS

=over 4

=item Front

Front page news items only.

=item Main

Main news items in full, section in brief, the remainder just titles.

=item Archive

Archived news items only.

=item Item

Single specified news items in full.

=back

=cut

sub Front {
    my $front = $settings{'frontpage'} || FRONTPAGE;
    my (@mainnews);
    my @rows = $dbi->GetQuery('hash','FrontNews',{limit => "LIMIT $front"});
    for my $row (@rows) {
        $row->{name}      = UserName($row->{userid});
        $row->{postdate}  = formatDate(3,$row->{createdate});
        $row->{alignment} = AlignClass($row->{align});
    }
    $tvars{frontnews} = \@rows  if(@rows);
}

sub Main {
    my $main  = $settings{'mainnews'} || MAINNEWS;
    my $brief = $settings{'inbrief'}  || INBRIEF;
    my (@mainnews,@inbrief,@archive);
    my @rows = $dbi->GetQuery('hash','PubNews');
    foreach my $row (@rows) {
        last    unless($brief);
        # first n stories in full
        if($main) {
            $row->{name}      = UserName($row->{userid});
            $row->{postdate}  = formatDate(3,$row->{createdate});
            $row->{alignment} = AlignClass($row->{align});
            push @mainnews, $row;
            $main--;
            next;
        }
        # next n stories in brief
        if($brief) {
            push @inbrief, {newsid => $row->{newsid}, title => $row->{title}, snippet => substr(CleanHTML($row->{body}),0,(82-length($row->{title})))};
            $brief--;
            next;
        }
        # remaining stories, just titles
        push @archive, {newsid => $row->{newsid}, title => $row->{title}};
    }
    $tvars{news}{main}  = \@mainnews    if(@mainnews);
    $tvars{news}{brief} = \@inbrief     if(@inbrief);
    $tvars{news}{other} = \@archive     if(@archive);
}

sub Archive {
    my (@archive);
    my @rows = $dbi->GetQuery('hash','OldNews');
    foreach my $row (@rows) {
        push @archive, {newsid => $row->{newsid}, title => $row->{title}, snippet => substr(CleanHTML($row->{body}),0,(82-length($row->{title})))};
    }
    $tvars{archive} = \@archive     if(@archive);
}

sub Item {
    return  unless($cgiparams{'newsid'});
    my @rows = $dbi->GetQuery('hash','GetNewsByID',$cgiparams{'newsid'});
    if(@rows) {
        $rows[0]->{name}        = UserName($rows[0]->{userid});
        $rows[0]->{postdate}    = formatDate(3,$rows[0]->{createdate});
        $rows[0]->{alignment}   = AlignClass($rows[0]->{align});
        $tvars{news}{item} = $rows[0];
    }
}

=head1 ADMIN INTERFACE METHODS

=over 4

=item Access

Check whether user has access to admin functions. Must be Editor or greater.

=item ImageCheck

Checks whether images are being referenced in a news item. Used to allow the 
images plugin to delete unused images.

=item Admin

List new items.

=item Add

Create a template variable hash to create a news item.

=item Edit

Edit the given news item.

=item Copy

Copy a specified news item to create a new one. Called via Admin().

=item EditAmendments

Provide additional drop downs and fields for editing.

=item Promote

Promote the given news item.

=item Save

Save the given news item.

=item Delete

Delete the listed news items. Called via Admin().

=back

=cut

sub Access  { Authorised(EDITOR) }

sub ImageCheck  {
    my @rows = $dbi->GetQuery('array','NewsImageCheck',$_[0]);
    @rows ? 1 : 0;
}

sub Admin {
    return  unless AccessUser(EDITOR);
    if($cgiparams{doaction}) {
           if($cgiparams{doaction} eq 'Delete') { Delete(); }
        elsif($cgiparams{doaction} eq 'Copy')   { Copy(); }
    }
    # (un)check front paged items
    my @front = CGIArray('FRONT');
    if(@front) {
        my @check = $dbi->GetQuery('hash','CheckFrontPageNews');
        my %check = map {$_->{newsid} => 1} @check;
        for my $id (@front) {
            if($check{$id}) {
                $check{$id} = 0;
            } else {
                $dbi->DoQuery('SetFrontPageNews',$id);
            }
        }
        for my $id (keys %check) {
            next    unless($check{$id});
            $dbi->DoQuery('ClearFrontPageNews',$id);
        }
    }
    # selected or default (Draft/Submitted/Published)
    my $publish = $cgiparams{'publish'} || '1,2,3';
    my @where;
    push @where, "userid=$tvars{'loginid'}" unless(Authorised(PUBLISHER));
    push @where, "publish IN ($publish)"    if($publish);
    my $where = @where ? 'WHERE '.join(' AND ',@where) : '';
    my @rows = $dbi->GetQuery('hash','AllNews',{where=>$where});
    foreach my $row (@rows) {
        $row->{publishstate}    = PublishState($row->{publish});
        $row->{name}            = UserName($row->{userid});
        $row->{postdate}        = formatDate(3,$row->{createdate});
    }
    $tvars{data} = \@rows;
    $publish = $cgiparams{'publish'};
    $tvars{ddpublish} = PublishSelect($publish,1);
}

sub Add {
    return  unless AccessUser($LEVEL);
    my $ddpublish;
    if(Authorised($LEVEL2)) {
        $ddpublish = PublishSelect($tvars{data}->{publish});
    } else {
        $ddpublish = PublishAction(1,1);
    }
    my %data = (
        folderid    => 1,
        title       => '',
        userid      => $tvars{loginid},
        name        => $tvars{user}->{name},
        postdate    => formatDate(3),
        body        => '',
        link        => 'images/blank.png',
        alttag      => '',
        ddpublish   => $ddpublish,
        ddalign     => AlignSelect(1),
        imageid     => 1,
        align       => 1,
        href        => '',
        front       => 0,
    );
    $tvars{data} = \%data;
}

sub Edit {
    return  unless $cgiparams{$INDEXKEY};
    return  unless AuthorCheck($GETSQL,$INDEXKEY,$LEVEL);
    EditAmendments();
}

sub Copy {
    $cgiparams{'newsid'} = $cgiparams{'LISTED'};
    return  unless AuthorCheck('GetNewsByID','newsid',EDITOR);

    my @fields = (  $tvars{data}->{folderid},
                    $tvars{data}->{title},
                    $tvars{data}->{body},
                    $tvars{data}->{imageid},
                    $tvars{data}->{align},
                    $tvars{data}->{href},
                    $tvars{data}->{alttag},
                    1,
                    formatDate(0),
                    $tvars{loginid});

    $cgiparams{newsid} = $dbi->IDQuery('AddNews',@fields);
#LogDebug("Copy: newsid=[$cgiparams{newsid}]");
    SetCommand('news-edit');
}

sub EditAmendments {
    $tvars{data}->{align}       = $cgiparams{ALIGN0}    if $cgiparams{ALIGN0};
    $tvars{data}->{alignment}   = AlignClass($tvars{data}->{align});
    $tvars{data}->{ddalign}     = AlignSelect($tvars{data}->{align});
    $tvars{data}->{ddpublish}   = PublishSelect($tvars{data}->{publish});
    $tvars{data}->{name}        = UserName($tvars{data}->{userid});
    $tvars{data}->{postdate}    = formatDate(3,$tvars{data}->{createdate});
    $tvars{data}->{body}        =~ s/^\s+//;

    if(Authorised($LEVEL2)) {
        $tvars{data}->{ddpublish} = PublishSelect($tvars{data}->{publish});
    } else {
        my $promote = 0;
        $promote = 1    if($tvars{data}->{publish} == 1);
        $promote = 1    if($tvars{data}->{publish} == 2 && AccessUser(PUBLISHER));
        $promote = 1    if($tvars{data}->{publish} == 3 && AccessUser(PUBLISHER));
        $tvars{data}->{ddpublish} = PublishAction($tvars{data}->{publish},$promote);
    }

    $tvars{preview} = clone($tvars{data});  # data fields need to be editable

    for(keys %fields) {
           if($fields{$_}->{html} == 1) { $tvars{preview}->{$_} = CleanHTML($tvars{preview}->{$_});
                                          $tvars{data}->{$_} = CleanHTML($tvars{data}->{$_}); }
        elsif($fields{$_}->{html} == 2) { $tvars{data}->{$_} = SafeHTML($tvars{data}->{$_}); }
    }
}

sub Promote {
    return  unless AccessUser($LEVEL);
    my @ids = CGIArray('LISTED');
    return  unless @ids;

    for my $id (@ids) {
        $cgiparams{$INDEXKEY} = $id;
        next    unless AuthorCheck($GETSQL,$INDEXKEY,$LEVEL);
        my $publish = $tvars{data}->{publish} + 1;
        next    unless($publish < 5);
        $dbi->DoQuery($PROMOTESQL,$publish,$cgiparams{$INDEXKEY});
    }
}

sub Save {
    return  unless AuthorCheck('GetNewsByID','newsid',EDITOR);
    my $publish = $tvars{data}->{publish} || 0;

    EditAmendments();
    for(keys %fields) {
           if($fields{$_}->{html} == 1) { $cgiparams{$_} = CleanHTML($cgiparams{$_}) }
        elsif($fields{$_}->{html} == 2) { $cgiparams{$_} = CleanTags($cgiparams{$_}) }
        elsif($fields{$_}->{html} == 3) { $cgiparams{$_} = CleanTags($cgiparams{$_}) }
    }
    return  if FieldCheck(\@allfields,\@mandatory);

    if($cgiparams{image}) {
        ($tvars{data}->{'imageid'}) =
            SaveImageFile(
                param   => 'image',
                stock   => 'Special',
                href    => $tvars{data}->{href},
                alttag  => $tvars{data}->{alttag}
            );
    }

    $tvars{data}->{createdate}  = formatDate(0)      if($tvars{data}->{publish} == 3 && $publish < 3);
    $tvars{data}->{createdate}  = unformatDate(3,$tvars{data}->{postdate});
    $tvars{data}->{front}       = $tvars{data}->{front}  ? 1 : 0;
    $tvars{data}->{latest}      = $tvars{data}->{latest} ? 1 : 0;
    $tvars{data}->{folderid}    ||= 1;
    $tvars{data}->{imageid}     ||= 1;

    my @fields = (  $tvars{data}->{folderid},
                    $tvars{data}->{title},
                    $tvars{data}->{snippet},
                    $tvars{data}->{body},
                    $tvars{data}->{imageid},
                    $tvars{data}->{align},
                    $tvars{data}->{front},
                    $tvars{data}->{latest},
                    $tvars{data}->{publish},
                    $tvars{data}->{createdate},
        );

    if($tvars{data}->{newsid})
            {   $dbi->DoQuery('SaveNews',@fields,$tvars{data}->{newsid}); }
    else    {   $cgiparams{newsid} = $dbi->IDQuery('AddNews',@fields,$tvars{loginid}); }
    $tvars{thanks} = 1;
}

sub Delete {
    return  unless AccessUser($LEVEL2);
    my @ids = CGIArray('LISTED');
    return  unless @ids;
    for my $id (@ids) {
        $cgiparams{'newsid'} = $id;
        next    unless AuthorCheck('GetNewsByID','newsid',EDITOR);
        $dbi->DoQuery('DeleteNews',$cgiparams{'newsid'});
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
