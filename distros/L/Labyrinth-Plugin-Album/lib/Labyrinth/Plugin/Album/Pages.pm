package Labyrinth::Plugin::Album::Pages;

use strict;
use warnings;

our $VERSION = '1.12';

=head1 NAME

Labyrinth::Plugin::Album::Pages - Photo album pages handler for Labyrinth

=head1 DESCRIPTION

Contains all the photo album handling functionality for the Labyrinth
framework.

=cut

#----------------------------------------------------------------------------
# Libraries

use base qw(Labyrinth::Plugin::Base);

use File::Path;

use Labyrinth::Audit;
use Labyrinth::DBUtils;
use Labyrinth::DTUtils;
use Labyrinth::Media;
use Labyrinth::Metadata;
use Labyrinth::MLUtils;
use Labyrinth::Support;
use Labyrinth::Variables;

use Labyrinth::Plugin::Hits;

# -------------------------------------
# Constants

use constant    MaxPhotoWidth   => 1024;
use constant    MaxPhotoHeight  => 1024;
use constant    MaxThumbWidth   => 200;
use constant    MaxThumbHeight  => 200;

#----------------------------------------------------------------------------
# Variables

# type: 0 = optional, 1 = mandatory
# html: 0 = none, 1 = text, 2 = textarea

my %fields = (
    title       => { type => 1, html => 1 },
    summary     => { type => 0, html => 2 },
    area        => { type => 0, html => 1 },
    year        => { type => 0, html => 1 },
    month       => { type => 0, html => 1 },
    pageid      => { type => 0, html => 1 },
    parent      => { type => 0, html => 1 },
    hide        => { type => 0, html => 1 },
);

my (@mandatory,@allfields);
for(keys %fields) {
    push @mandatory, $_     if($fields{$_}->{type});
    push @allfields, $_;
}

my @savefields  = qw(parent title summary year month hide pageid);
my @addfields   = qw(parent title summary year month hide area path);

my $INDEXKEY    = 'pageid';
my $LEVEL       = PUBLISHER;

my $hits   = Labyrinth::Plugin::Hits->new();

#----------------------------------------------------------------------------
# Public Interface Functions

=head1 PUBLIC INTERFACE METHODS

=head2 Public Methods

=over 4

=item List

Provides a list of all the public photo albums.

=item Children

Provides a list of photo albums for which the specified photo album is their 
parent.

=item Search

Search for photo albums matching a given set of metadata.

=back

=cut

sub List {
    my ($key,@args);

    my $now = time() - 2419200; # seconds in a 4 week month

    my ($where,@where);
    if($cgiparams{all}) {
        $key = 'SearchPages';
    } elsif($cgiparams{latest}) {
        $key = 'SearchPagesLatest';
    } elsif($cgiparams{month} || $cgiparams{year} || $cgiparams{metadata}) {
        push @where, "p.month=$cgiparams{month}"        if($cgiparams{month});
        push @where, "p.year=$cgiparams{year}"          if($cgiparams{year});
        push @where, "p.title='%$cgiparams{metadata}%'" if($cgiparams{metadata});
        $key = 'SearchPages';
    } else {
        $cgiparams{year} = formatDate(1);
        push @where, "p.year=$cgiparams{year}";
        $key = 'SearchPages';
    }

    $where = ' AND ' . join(' AND ',@where)    if(@where);

    my @rs = $dbi->GetQuery('hash',$key,{where=>$where});
    for my $rec (@rs) {
        $rec->{month} = isMonth($rec->{month});
        $rec->{new}   = ($rec->{now} > $now ? 1 : 0);
 #LogDebug( "$now < $rec->{now} = ".localtime($rec->{now})) if($rec->{new});
        for(keys %fields) {
               if($fields{$_}->{html} == 1) { $rec->{$_} = CleanHTML($rec->{$_}); }
            elsif($fields{$_}->{html} == 2) { $rec->{$_} = CleanTags($rec->{$_}); }
        }

        my $dw = $settings{gallerythumbwidth}  || MaxThumbWidth;
        my $dh = $settings{gallerythumbheight} || MaxThumbHeight;

        if($rec->{dimensions}) {
            my ($w,$h) = split('x',$rec->{dimensions});
            if($w/$dw > $h/$dh) {
                $rec->{width} = $dw;
            } else {
                $rec->{height} = $dh;
            }
        }
    }

    $tvars{records}  = \@rs    if(@rs);
    $tvars{month}    = $cgiparams{month} || '';
    $tvars{year}     = $cgiparams{year}  || '';
    $tvars{ddmonths} = MonthSelect($cgiparams{month},1);
    $tvars{ddyears}  = YearSelect($cgiparams{year},2,1);
    $tvars{pid} = 4;
    $tvars{iid} = 0;
}

sub Children {
    $cgiparams{'pageid'} ||= $cgiparams{'pid'};
    my @rs = $dbi->GetQuery('hash','GetChildPages',$cgiparams{pageid});
    $tvars{album}{children} = \@rs if(@rs);
}

sub Search {
    my $limit = $settings{limit};

    my $now = time() - 2419200; # seconds in a 4 week month
    my @rs;

    if($cgiparams{metadata}) {
        my @data = split(qr/[ ,]+/,$cgiparams{metadata});
        @rs = MetaSearch(   'keys'  => ['PagePhoto','Photo'],
                            'meta'  => \@data,
                            'where' => "hide=0",
                            'limit' => ($limit || ''));
        for my $rec (@rs) {
            $rec->{month} = isMonth($rec->{month});
            $rec->{new}   = ($rec->{now} > $now ? 1 : 0);
#LogDebug( "$now < $rec->{now} = ".localtime($rec->{now})) if($rec->{new});
            for(keys %fields) {
                   if($fields{$_}->{html} == 1) { $rec->{$_} = CleanHTML($rec->{$_}); }
                elsif($fields{$_}->{html} == 2) { $rec->{$_} = SafeHTML($rec->{$_});  }
            }
        }
    }

    $tvars{records}  = \@rs if(@rs);
    $tvars{month}    = $cgiparams{month} || '';
    $tvars{year}     = $cgiparams{year}  || '';
    $tvars{ddmonths} = MonthSelect($cgiparams{month},1);
    $tvars{ddyears}  = YearSelect($cgiparams{year},2,1);
    $tvars{pid} = 4;
    $tvars{iid} = 0;
}

#----------------------------------------------------------------------------
# Administration Interface Functions

=head1 ADMIN INTERFACE METHODS

=head2 Administration Methods

=over 4

=item Admin

Provides a list of all the current photo albums, with additional administrator
functions.

=item Add

Prep for adding a photo album.

=item ArchiveEdit

Delete archived photos or Move photos to public albums.

=item Edit

Edit details of a photo album.

=item Save

Save the details of a photo album.

=item Delete

Delete a public album, moving all photos to the archive album.

=item PageSelect

Provides a HTML drop-down list of available pages.

=item Selection

Shortcut to PageSelect, automatically selecting the current album.

=back

=cut

sub Admin {
    return  unless AccessUser($LEVEL);

    my (%current,$where,@rs);
    if($cgiparams{doaction} || $cgiparams{order}) {
        $where = '';
        if($cgiparams{was}) {
            my @was;
            my ($this,$that) = split("/",$cgiparams{was});
            push @was, "month=$cgiparams{month}"      if($this);
            push @was, "year=$cgiparams{year}"        if($that);
            $where = 'WHERE ' . join(' AND ',@was)    if(@was);
        }

        @rs = $dbi->GetQuery('hash','AdminPages',{where=>$where});
        $current{$_->{pageid}} = $_  for(@rs);
    }

    if($cgiparams{doaction}) {
        if($cgiparams{doaction} eq 'Update') {

            # check whether we need to hide/show any pages
            my @ids = CGIArray('HIDE');
            my %hide = map {$_ => 1} @ids;
            my @show;
            my $where = '';

            for(keys %hide) {
                if($current{$_}->{hide})    { delete $current{$_}; delete $hide{$_}; }
            }
            for(keys %current) {
                if($current{$_}->{hide})   { push @show, $_; }
            }

            $dbi->DoQuery('HidePages',{list=>join(",",keys %hide)}) if(keys %hide);
            $dbi->DoQuery('ShowPages',{list=>join(",",@show)})      if(@show);
            $hits->SetUpdates('album',0,@show)                      if(@show);
        }
    }

    # reorder a specific page
    if($cgiparams{'order'} && $cgiparams{'pageid'}) {
        my $order   = $cgiparams{'order'};
        my $pageid  = $cgiparams{'pageid'};
        my (@was,%order,%pages) = ();

        push @was, "month=$current{$pageid}->{month}";
        push @was, "year=$current{$pageid}->{year}";
        $where = 'WHERE ' . join(' AND ',@was);
        @rs = $dbi->GetQuery('hash','AdminPages',{where=>$where});
        if(@rs > 1) {
            my $max = my $inx = @rs;
            for(@rs) {
                $order{$inx} = $_->{pageid};
                $pages{$_->{pageid}} = $inx--;
            }

            my $changed = 0;
            if($order =~ /up/i) {
#               LogDebug("max=$inx, this=$pages{$pageid}");
                if($pages{$pageid} < $max) {
                    $inx = $pages{$pageid};
                    $order{$inx} = $order{$inx + 1};
                    $order{$inx + 1} = $pageid;
                    $changed = 1;
                }
            } else {
                if($pages{$pageid} > 1) {
                    $inx = $pages{$pageid};
                    $order{$inx} = $order{$inx - 1};
                    $order{$inx - 1} = $pageid;
                    $changed = 1;
                }
            }

            if($changed) {
                $dbi->DoQuery('ReorderPage',$_,$order{$_})  for(keys %order);
            }
        }
    }

    # now show the latest settings :)
    $where = '';
    my @where;
    push @where, "month=$cgiparams{month}"      if($cgiparams{month});
    push @where, "year=$cgiparams{year}"        if($cgiparams{year});
    $where = 'WHERE ' . join(' AND ',@where)    if(@where);

    @rs = $dbi->GetQuery('hash','AdminPages',{where=>$where});
    foreach my $rec (@rs) {
        $rec->{year}  = '-' unless($rec->{year});
        $rec->{month} = isMonth($rec->{month});
        for(keys %fields) {
               if($fields{$_}->{html} == 1) { $rec->{$_} = CleanHTML($rec->{$_}); }
            elsif($fields{$_}->{html} == 2) { $rec->{$_} = CleanTags($rec->{$_});  }
        }
    }

    $tvars{month} = $cgiparams{month} || '';
    $tvars{year}  = $cgiparams{year}  || '';

    $tvars{ddmonths} = MonthSelect($cgiparams{month},1);
    $tvars{ddyears}  = YearSelect($cgiparams{year},2,1);
    $tvars{records}  = \@rs if(@rs);
}

sub Add {
    return  unless AccessUser($LEVEL);

    $tvars{data}->{senarios} = [
        { id=>2, title=>'Photos Section' },
    ];

    $tvars{data}->{ddmonths} = MonthSelect($tvars{data}->{month});
    $tvars{data}->{ddyears}  = YearSelect($tvars{data}->{year},2);
}

sub ArchiveEdit {
    return  unless AccessUser($LEVEL);

    if($cgiparams{doaction}) {
        my @ids = CGIArray('LISTED');

        if($cgiparams{doaction} eq 'Delete') {
            for my $id (@ids) {
                my @rows = $dbi->GetQuery('hash','GetPhotoByID',$id);
                unlink "$settings{webdir}/photos/".$rows[0]->{image};
                unlink "$settings{webdir}/photos/".$rows[0]->{thumb};
            }

            $dbi->DoQuery('DeletePhotos',1,{ids=>join(',',@ids)});

        } elsif($cgiparams{doaction} eq 'Move') {
            $cgiparams{'pageid'} ||= 1;
            $dbi->DoQuery('MovePhotos',{ids=>join(',',@ids)},$cgiparams{'pageid'})  if(@ids);
        }
    }

    $cgiparams{'pageid'} = 1;
}

sub Edit {
    return  unless AccessUser($LEVEL);

    my $order   = $cgiparams{'order'};
    my $pageid  = $cgiparams{'pageid'};
    my $photoid = $cgiparams{'photoid'};
    my ($sql,@rs);

    if($order && $photoid) {
        @rs = $dbi->GetQuery('hash','GetPhotosInOrder',$pageid);
        my ($old,$cnt) = (-1,-1);
        foreach (@rs) {
            $cnt++;
            if($_->{photoid} == $photoid) {
                $old = $cnt;
                last;
            }
        }

        my $max = @rs;
        if($old >= 0) {
            my $new = $old;
            if($order eq 'up' && $old > 0)          { $new--; }
            elsif($order eq 'down' && $old < $max)  { $new++; }

            if($old != $new) {
                $dbi->DoQuery('ReorderPhoto',$rs[$old]->{orderno},$rs[$new]->{photoid});
                $dbi->DoQuery('ReorderPhoto',$rs[$new]->{orderno},$rs[$old]->{photoid});
            }
        }
    }

    @rs = $dbi->GetQuery('hash','GetPage',$pageid);
    if(@rs) {
        for(keys %fields) {
               if($fields{$_}->{html} == 1) { $rs[0]->{$_} = CleanHTML($rs[0]->{$_}) }
            elsif($fields{$_}->{html} == 2) { $rs[0]->{$_} = SafeHTML($rs[0]->{$_}) }
            elsif($fields{$_}->{html} == 3) { $rs[0]->{$_} = SafeHTML($rs[0]->{$_}) }
        }

#       $rs[0]->{title} =~ s/&#39;/\'/g if $rs[0]->{title};
#       $rs[0]->{summary} =~ s/&#39;/\'/g   if $rs[0]->{summary};
        $tvars{data} = $rs[0];

        @rs = $dbi->GetQuery('hash','GetPhotosInOrder',$pageid);
        foreach my $rec (@rs) {
            $rec->{tagline} =~ s/&#39;/\'/g if $rec->{tagline};
            $rec->{metadata} = MetaGet($rec->{photoid},'Photo');
        }

        $tvars{photos} = \@rs   if(@rs);
    }

    $tvars{data}->{ddmonths} = MonthSelect($tvars{data}->{month});
    $tvars{data}->{ddyears}  = YearSelect($tvars{data}->{year},2);
    $tvars{data}->{ddpages}  = PageSelect(undef,1,'parent',$tvars{data}->{pageid});

    # check we have an accessible directory to store photos
    if($tvars{data}->{path}) {
        $settings{webdir} ||= '';
        my $dir = "$settings{webdir}/$tvars{data}->{path}";
        $tvars{data}->{exists}     = -e "$settings{webdir}/$tvars{data}->{path}" ? 1 : 0;
        $tvars{data}->{directory}  = -d "$settings{webdir}/$tvars{data}->{path}" ? 1 : 0;
        $tvars{data}->{readable}   = -r "$settings{webdir}/$tvars{data}->{path}" ? 1 : 0;
        $tvars{data}->{writeable}  = -w "$settings{webdir}/$tvars{data}->{path}" ? 1 : 0;
        $tvars{data}->{executable} = -x "$settings{webdir}/$tvars{data}->{path}" ? 1 : 0;
    } else {
        $tvars{data}->{$_} = 0  for(qw(exists directory readable writeable executable));    
    }

    # default image sizes
    $tvars{dimensions}->{photowidth}  = $settings{maxphotowidth}  || MaxPhotoWidth;
    $tvars{dimensions}->{photoheight} = $settings{maxphotoheight} || MaxPhotoHeight;
    $tvars{dimensions}->{thumbwidth}  = $settings{maxthumbwidth}  || MaxThumbWidth;
    $tvars{dimensions}->{thumbheight} = $settings{maxthumbheight} || MaxThumbHeight;

    $tvars{timestamp} = formatDate(0);
}

sub Save {
    return  unless AccessUser($LEVEL);
    return  unless AuthorCheck('GetPage','pageid',$LEVEL);

    for(keys %fields) {
           if($fields{$_}->{html} == 1) { $cgiparams{$_} = CleanHTML($cgiparams{$_}) }
        elsif($fields{$_}->{html} == 2) { $cgiparams{$_} = CleanTags($cgiparams{$_}) }
        elsif($fields{$_}->{html} == 3) { $cgiparams{$_} = CleanLink($cgiparams{$_}) }
    }

    return  if FieldCheck(\@allfields,\@mandatory);

    my (undef,$month,$year) = split("/",formatDate(3));
    $tvars{data}->{year}  ||= $year;
    $tvars{data}->{month} ||= $month;

    # only create the path when a new page is created
    unless($tvars{data}->{pageid}) {
        $tvars{data}->{path} = 'photos/' . formatDate(11);
        my $path = $settings{webdir} . '/' . $tvars{data}->{path};
        mkpath($path);
    }

    $tvars{data}->{parent} ||= 0; # no parent by default
    $tvars{data}->{area}   ||= 2; # photo album
    $tvars{data}->{hide}   = $tvars{data}->{hide} ? 1 : 0; # visible by default
    my @columns = $tvars{data}->{pageid} ? @savefields : @addfields;
    my @fields = map {(defined $tvars{data}->{$_} ? $tvars{data}->{$_} : undef)} @columns;
#LogDebug("columns=[@columns], fields=[@fields]");
    if($tvars{data}->{pageid})
            {                         $dbi->DoQuery('UpdatePage',@fields)  }
    else    {$tvars{data}->{pageid} = $dbi->IDQuery('InsertPage',@fields)  }

    $cgiparams{pageid} = $tvars{data}->{pageid};
    $hits->SetUpdates('album',0,$tvars{data}->{pageid});
    $tvars{thanks_message} = 'Page saved successfully.';
    return  unless($tvars{data}->{pageid});

    # archive unwanted photos
    my @ids = grep { /^\d+$/ } CGIArray('DELETE');
#   LogDebug("Delete IDs: @ids");
    if(@ids) {
        if($cgiparams{pageid} == 1) {
            # only delete photos in the archive
            my @rows = $dbi->GetQuery('hash','CheckPhotos',{ids => join(',',@ids)},1);
            for(@rows) {
                my @photo = $dbi->GetQuery('hash','CheckPhoto',1,$_->{photoid});
                if(@photo && $photo[0]->{count} == 1) {   # only delete if no others match
                    DeleteFile( file => "$settings{webdir}/photos/$_->{image}" );
                    DeleteFile( file => "$settings{webdir}/photos/$_->{thumb}" );
                }
                $dbi->DoQuery('DeletePhoto',$_->{photoid});
            }
        } else {
            $dbi->DoQuery('MovePhotos',{ids => join(',',@ids)},1)   if(@ids);
        }
    }

    # get fresh list
    my @rs = $dbi->GetQuery('hash','GetPhotosInOrder',$tvars{data}->{pageid});

    # store hidden photos
    @ids = CGIArray('HIDE');
    my %hidden = map {$_ => 1} @ids;

    # update tags, order and metadata
    my $order = 1;
    foreach my $rec (@rs) {
        my $id = $rec->{photoid};
        my $tag = defined $cgiparams{"TAG$id"} ? $cgiparams{"TAG$id"} : '';
        my $hide = $hidden{$id} ? 1 : 0;
        my $cover = defined $cgiparams{"COVER"} && $cgiparams{"COVER"} == $id ? 1 : 0;

        $dbi->DoQuery('UpdatePhoto',$order,$hide,$tag,$cover,$id);
        $order++;

        my $data = defined $cgiparams{"META$id"} ? $cgiparams{"META$id"} : '';
        MetaSave($id,['Photo'],split(/[ ,]+/,$data))    if($data);
    }

    # upload new photos
    my $inx = 0;
    while($cgiparams{"file_$inx"}) {
        SavePhotoFile(
            param   => "file_$inx",
            path    => $tvars{data}->{path},
            page    => $tvars{data}->{pageid},
            iwidth  => $settings{maxphotowidth}  || MaxPhotoWidth,
            iheight => $settings{maxphotoheight} || MaxPhotoHeight,
            twidth  => $settings{maxthumbwidth}  || MaxThumbWidth,
            theight => $settings{maxthumbheight} || MaxThumbHeight,
            order   => $order++,
            tag     => ''
        );
        $inx++;
    }

    $tvars{thanks_message} = 'Page saved successfully.';
}

sub Delete {
    return  unless AccessUser(ADMIN);
    return  unless $cgiparams{$INDEXKEY};
    return  unless $cgiparams{$INDEXKEY} > 2;   # Cannot delete the Archive or Homepage folders

    my @rows = $dbi->GetQuery('array','GetPhotos',$cgiparams{$INDEXKEY});
    $dbi->DoQuery('MovePhoto',1,$_->[0])    for(@rows);
    $dbi->DoQuery('DeletePage',$cgiparams{$INDEXKEY});

    $tvars{thanks_message} = 'Page deleted successfully.';
}

sub Selection {
    my $pageid = $tvars{data}->{pageid} || 1;
    $tvars{ddpages} = PageSelect($pageid,1);
}

sub PageSelect {
    my ($opt,$blank,$name,@ignore) = @_;
    my (@list,%ignore);

    $name ||= 'pageid';
    %ignore = map {$_=>1} grep {$_} @ignore;

    my @rs = $dbi->GetQuery('hash','AdminPages');
    for my $rec (@rs) {
        next    if($ignore{$rec->{pageid}});
        push @list, {id=>$rec->{pageid},value=>"$rec->{title}"};
    }

    unshift @list, {id=>0,value=>'Select Gallery Page'} if(defined $blank && $blank == 1);
    return DropDownRows($opt,$name,'id','value',@list);
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
