#!/usr/bin/perl -w
use strict;

my $BASE;

# create images in pages
BEGIN {
    $BASE = '..';
}

#############################################################################
#Global Variables                                                           #
#############################################################################

my ($LMAX,$SMAX) = (800,150);

#############################################################################
#Modules/External Subroutines                                               #
#############################################################################

use Carp;
use Image::Magick;

use lib qw|../cgi-bin/lib ../cgi-bin/plugins|;
use Labyrinth::Globals;
use Labyrinth::Variables;

#############################################################################
#Subroutines
#############################################################################

Labyrinth::Globals::LoadSettings("$BASE/cgi-bin/config/settings.ini");
Labyrinth::Globals::DBConnect();

my @rs = $dbi->GetQuery('hash','GetAllPhotos');
for my $row (@rs) {
    my $image  = lc $row->{image};
    $image =~ s!(\d{8})t(\d{6})!$1T$2!;
    $image =~ s!^.*$BASE/html/photos/!!;

    my $source = "$BASE/html/photos/$row->{image}";
    my $target = "$BASE/html/photos/$image";

    if($image ne $row->{image}) {
        system("mv $source $target");
        $source = $target;
        $dbi->DoQuery('SetImage',$image,$row->{photoid});
    }

    $target =~ s/\./-thumb./;
    $target =~ s/\s+//g;

    unless(-f $source) {
        $image = $source;
        $image =~ s!\.jpg$!.JPG!;
        if(-f $image) {
            system("mv $image $source");
        } else {
            print STDERR "IMAGE MISSING: $source\n";
            next;
        }
    }

    next unless(-f $source);
    unlink $target  if(-f $target);

    # read in current image
    my $i = Image::Magick->new();
    croak "object image error: [$source]"   if !$i;
    my $c = $i->Read($source);
    croak "read image error: [$source] $c"  if $c;
    $c = $i->AutoOrient();
    croak "orient image error: [$source] $c"  if $c;

    # resize main image if necessary
    my ($width,$height) = $i->Get('columns', 'rows');
    if($width > $LMAX || $height > $LMAX) {
        $i->Scale(geometry => "${LMAX}x${LMAX}");
    }

    $c = $i->Write($source);
    if($c) {
        print STDERR "write image error: [$source] $c\n";
        next;
    }

    # generate thumbnail
    $i->Scale(geometry => "${SMAX}x${SMAX}");
    $c = $i->Write($target);
    if($c) {
        print STDERR "write image error: [$target] $c\n";
        next;
    }

    # update DB
    $target =~ s!^$BASE/html/photos/!!;
    $dbi->DoQuery('SetThumb',$target,$row->{photoid});
}

__END__


