package Labyrinth::Plugin::Images;

use warnings;
use strict;

our $VERSION = '5.19';

=head1 NAME

Labyrinth::Plugin::Images - Plugin Images handler for Labyrinth

=head1 DESCRIPTION

Contains all the image handling functionality for the Labyrinth
framework.

=cut

# -------------------------------------
# Library Modules

use base qw(Labyrinth::Plugin::Base);

use Image::Size;
use File::Copy;
use File::Basename;

use Labyrinth::Audit;
use Labyrinth::Globals;
use Labyrinth::DBUtils;
use Labyrinth::DIUtils;
use Labyrinth::Media;
use Labyrinth::Metadata;
use Labyrinth::MLUtils;
use Labyrinth::Support;
use Labyrinth::Variables;

# -------------------------------------
# Constants

use constant    MaxDefaultWidth     => 120;
use constant    MaxDefaultHeight    => 120;
use constant    MaxDefaultThumb     => 120;

# -------------------------------------
# Variables

# type: 0 = optional, 1 = mandatory
# html: 0 = none, 1 = text, 2 = textarea

my %fields = (
    imageid     => { type => 1, html => 0 },
    image       => { type => 0, html => 0 },
    tag         => { type => 0, html => 1 },
    link        => { type => 0, html => 1 },
    type        => { type => 1, html => 0 },
    href        => { type => 0, html => 0 },
    metadata    => { type => 0, html => 1 },
);

my (@mandatory,@allfields);
for(keys %fields) {
    push @mandatory, $_     if($fields{$_}->{type});
    push @allfields, $_;
}

my $LEVEL = ADMIN;

# -------------------------------------
# The Subs

=head1 PUBLIC INTERFACE METHODS

The following are convience methods to provide the appropriate functionality 
to list the require number of random images for the page.

These are to be deprecated in the future, in favour of using configuration
settings and/or parameter values.

=over 4

=item Random()

Stores a random image in template variable 'irandX', where X is 1.

=item Random4()

Stores 4 random images in template variable 'irandX', where X is 1 to 4.

=item Random6()

Stores 6 random images in template variable 'irandX', where X is 1 to 6.

=item Random8()

Stores 8 random images in template variable 'irandX', where X is 1 to 8.

=back

=cut

sub Random  { RandomN(1);   }
sub Random4 { RandomN(4);   }
sub Random6 { RandomN(6);   }
sub Random8 { RandomN(8);   }

=head1 LOCAL INTERFACE METHODS

=over 4

=item RandomN()

Provide 'n' random images, prefixed in a template variable with 'irand'.

=back

=cut

sub RandomN {
    my $count = shift;
    my @rows = $dbi->GetQuery('hash','GetImagesByType',2);
    my $max = @rows;

    my %blank = (link=>$settings{blank},tag=>'');

    if($max <= $count) {
        foreach my $inx (1..$max) { $tvars{"irand$inx"} = $rows[($inx-1)]; }
        return;
    }

    my (%done,@random);
    srand;
    while(1) {
        my $index = int((rand) * $max);
        next    if($done{$index});
        push @random, $rows[$index];
        $done{$index} = 1;
        last    if(@random >= $count);
    }

    foreach my $inx (1..$count) { $tvars{"irand$inx"} = $random[($inx-1)]; }
}

=head1 ADMIN INTERFACE METHODS

Note that in all cases the images referred to do not include photos uploaded
via the Album plugin, for photo albums.

=over 4

=item List

List all uploaded images.

=item Add

Create a template variable hash for a new image.

=item Edit

Edit the attributes of a given image.

=item EditAmendments

Additional drop downs and fields for editing.

=item Save

Save a given image.

=item Delete

Delete a given image.

=item Gallery

Provide a set of images as a gallery for selection.

=back

=cut

sub List {
    return  unless AccessUser($LEVEL);

    my @delete = CGIArray('DELETE');
    if(@delete) {
        $cgiparams{'imageid'} = $_;
        Delete();
    }

    my $key = $cgiparams{'searchmeta'} ? 'MetaImages' : 'AllImages';
    $cgiparams{'searchmeta'} =~ s/[,\s]+/,/g;

    my @where = ();
    push @where, "i.type=$cgiparams{'stockid'}"             if($cgiparams{'stockid'});
    push @where, "m.tag IN ($cgiparams{'searchmeta'})"      if($cgiparams{'searchmeta'});
    my $where = @where ? 'WHERE '.join(' AND ',@where) : '';

    my @rows = $dbi->GetQuery('hash',$key,{where=>$where});
    foreach (@rows) { $_->{typename} = StockName($_->{type}); }
    $tvars{data} = \@rows   if(@rows);

    $tvars{ddstock} = StockSelect();
}

sub Add {
    return  unless AccessUser($LEVEL);

    my %data = (
        imageid     => 0,
        tag         => '',
        metadata    => '',
        link        => $settings{blank},
        ddstock     => StockSelect(),
    );

    $tvars{data} = \%data;
}

sub Edit {
    return  unless AccessUser($LEVEL);
    return  unless $cgiparams{'imageid'};

    my @rows = $dbi->GetQuery('hash','GetImageByID',$cgiparams{'imageid'});
    return  unless(@rows);

    $tvars{data} = $rows[0];
    EditAmendments();
}

sub EditAmendments {
    $tvars{data}->{metadata}    = MetaGet($cgiparams{'imageid'},['Image'])  if($cgiparams{'imageid'});
    $tvars{data}->{typename}    = StockName($tvars{data}->{type});
    $tvars{data}->{ddstock}     = StockSelect($tvars{data}->{type});

    for(keys %fields) {
        if($fields{$_}->{html} == 1)    { $tvars{data}->{$_} = CleanHTML($tvars{data}->{$_}) }
        elsif($fields{$_}->{html} == 2) { $tvars{data}->{$_} = SafeHTML($tvars{data}->{$_}) }
    }

    return  unless($tvars{data}->{link});

    # Get the size of image
    ($tvars{data}->{x_resize},$tvars{data}->{y_resize})
        = ResizeDimensions($tvars{data}->{dimensions},"$settings{webdir}/$tvars{data}->{link}",$tvars{maxpicwidth},$tvars{maxpicheight});
}

sub Save {
    return  unless AccessUser($LEVEL);
    return  unless AuthorCheck('GetImageByID','imageid',$LEVEL);
    EditAmendments();

    for(keys %fields) {
           if($fields{$_}->{html} == 1) { $cgiparams{$_} = CleanHTML($cgiparams{$_}) }
        elsif($fields{$_}->{html} == 2) { $cgiparams{$_} = CleanTags($cgiparams{$_}) }
        elsif($fields{$_}->{html} == 3) { $cgiparams{$_} = CleanLink($cgiparams{$_}) }
    }

    my $link = $tvars{data}->{link};
    return  if FieldCheck(\@allfields,\@mandatory);

    if($cgiparams{image}) {
        my ($name,$filename) = CGIFile('image',$tvars{data}->{type});
        unless($name) { # blank if anything goes wrong
            $tvars{errcode} = 'ERROR';
            return;
        }

        my $i = Labyrinth::DIUtils->new("$settings{webdir}/$filename");
        $i->reduce(MaxDefaultWidth,MaxDefaultHeight);

        $tvars{data}->{link} = $filename;
    } else {
        $tvars{data}->{link} = $link;
    }

    $cgiparams{imageid} = SaveImage(    $cgiparams{imageid},
                                        $tvars{data}->{tag},
                                        $tvars{data}->{link},
                                        $tvars{data}->{type},
                                        $tvars{data}->{href});

    my @metadata = $tvars{data}->{metadata} ? split(qr/[, ]+/,$tvars{data}->{metadata}) : ();
    MetaSave($cgiparams{imageid},['Image'],@metadata);
}

sub Delete {
    return  unless AccessUser($LEVEL);
    return  unless($cgiparams{'imageid'});

    # check whether image still referenced
    if(ImageCheck($cgiparams{'imageid'})) {
        $tvars{errcode} = 'MESSAGE';
        $tvars{errmess} = 'Sorry cannot delete that image, it is used within other areas of the site.';
        return;
    }

    my @rows = $dbi->GetQuery('hash','GetImageByID',$cgiparams{'imageid'});

    # do the delete
    if($dbi->DoQuery('DeleteImage',$cgiparams{'imageid'})) {
        unlink "$settings{webdir}/" . $rows[0]->{link};
    }
}

my @blanks = (
{ imageid=>1,link=>$settings{blank},tag=>'',height=>100,width=>100 },
{ imageid=>1,link=>$settings{blank},tag=>'',height=>100,width=>100 },
{ imageid=>1,link=>$settings{blank},tag=>'',height=>100,width=>100 },
{ imageid=>1,link=>$settings{blank},tag=>'',height=>100,width=>100 },
{ imageid=>1,link=>$settings{blank},tag=>'',height=>100,width=>100 },
{ imageid=>1,link=>$settings{blank},tag=>'',height=>100,width=>100 },
{ imageid=>1,link=>$settings{blank},tag=>'',height=>100,width=>100 },
{ imageid=>1,link=>$settings{blank},tag=>'',height=>100,width=>100 },
{ imageid=>1,link=>$settings{blank},tag=>'',height=>100,width=>100 },
);

sub Gallery {
    return  unless AccessUser(EDITOR);
    my $start     = $cgiparams{'start'}     || 2;
    my $key = '';

    if($cgiparams{'searchmeta'}) {
        $key = 'Meta';
        $cgiparams{'searchmeta'} =~ s/[,\s]+/,/g;
        $cgiparams{'searchmeta'} = join(",", map {"'$_'"} split(",",$cgiparams{'searchmeta'}));
    }

    my $where;
    $where .= " AND i.type IN ($cgiparams{'imagetype'})"        if($cgiparams{'imagetype'});
    $where .= " AND m.tag IN ($cgiparams{'searchmeta'})"        if($cgiparams{'searchmeta'});

    my @rows = $dbi->GetQuery('hash',$key.'Gallery',{where=>$where},$start);
    for(@rows) {
        ($_->{width},$_->{heigth})
            = ResizeDimensions($_->{dimensions},"$settings{webdir}/$_->{link}",100,100);
    }

    $tvars{next} = $rows[9]->{imageid}  unless(@rows < 10);
    push @rows, @blanks;
    $tvars{data} = \@rows   if(@rows);
    my @prev = $dbi->GetQuery('hash',$key.'GalleryMin',{where=>$where},$start);

    $tvars{prev}      = $prev[8]->{imageid} unless(@prev < 9);
    $tvars{imagetype} = $cgiparams{'imagetype'};
    $tvars{ddstock}   = StockSelect();
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
