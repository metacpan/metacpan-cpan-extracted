use strict;
use Test::Simple tests => 6;
use Image::Grab qw(grab);
use File::Compare;
use Cwd;

use constant IMAGE => cwd . "/t/data/perl.gif";
use constant IMAGE_URL => "file://" . IMAGE;
use constant PAGE  => cwd . "/t/data/bkgrd.html";
use constant PAGE_URL  => "file://" . PAGE;
use constant BKGRD => cwd . "/t/data/background.jpg";
use constant BKGRD_URL => "file://" . BKGRD;
use constant OUTFILE => cwd . "/test.gif";

my $pic = new Image::Grab;

ok(UNIVERSAL::isa($pic, "Image::Grab"));

my $image = grab(URL=>IMAGE_URL);
open(F, ">" . OUTFILE) || die"image.jpg: $!";
binmode F;  # for MSDOS derivations.
print F $image;
close F;
ok(compare(OUTFILE, IMAGE) == 0);
unlink OUTFILE;
undef $pic;

# You can also pass new arguments:
my $pic2 = Image::Grab->new(SEARCH_URL=>PAGE_URL,
                            REGEXP    =>'.*\.jpg');
ok([$pic2->getAllURLs]->[0] eq BKGRD_URL);
undef $pic2;

# The simplest OO case of a grab
my $pic3 = Image::Grab->new;
$pic3->url(IMAGE_URL);
$pic3->grab;
ok(defined $pic3->image && $pic3->image ne ''); # Not great...

# Now to save the image to disk
open(F, ">" . OUTFILE) || die"image.jpg: $!";
binmode F;  # for MSDOS derivations.
print F $pic3->image;
close F;
ok(compare(OUTFILE, IMAGE) == 0);
unlink OUTFILE;
undef $pic3;

my $pic4 = Image::Grab->new;
$pic4->regexp('.*\.gif');
$pic4->search_url(PAGE_URL);
$pic4->grab;
open(F, ">" . OUTFILE) || die"image.jpg: $!";
binmode F;  # for MSDOS derivations.
print F $pic4->image;
close F;
ok(compare(OUTFILE, IMAGE) == 0);
unlink OUTFILE;
undef $pic4;

