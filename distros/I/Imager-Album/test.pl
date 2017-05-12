# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..1\n"; }
END {print "not ok 1\n" unless $loaded;}
use Imager::Album;
use Imager::Album::GUI;

$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

my $imgdir = $ENV{'IPATH'};

#@images = qw( scale.gif foo.gif bar.gif );
@images = qw( scale.tga );

if (defined($imgdir)) {
    @extra = <$imgdir/*.jpg>;
    print "@extra\n";
    push(@images, @extra);
}

$mx = 6;
@images = @images[0..$mx-1] if @images>$mx;

use Data::Dumper;

$album = Imager::Album->new();

#print Dumper($album);

$album->add_image($_) for @images;


$album->update_previews();

$gui = Imager::Album::GUI->new($album);
#print Dumper($album);

Imager::Album::GUI::boot();


