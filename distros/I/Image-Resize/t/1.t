# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';


use Test::More tests => 5;
BEGIN { use_ok('Image::Resize') };
use File::Spec;
#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $image = Image::Resize->new(File::Spec->catfile('t', 'large'));
ok($image);

printf "Original image size: %s x %s\n", $image->gd->width, $image->gd->height;

my @array = (
#        desired           expected    #
    [   [10, 15],          [10, 6]     ],
    [   [15, 10],          [14, 10]    ],
    [   [120, 120],        [120, 80]   ],
);

sub DESIRED()   {   0   }
sub RESULT()    {   1   }
sub WIDTH()     {   0   }
sub HEIGHT()    {   1   }

my $gd = undef;
foreach my $dimensions ( @array ) {
    my ($desired, $result) = ($dimensions->[DESIRED], $dimensions->[RESULT]);
    $gd = $image->resize($desired->[WIDTH], $desired->[HEIGHT]);
    printf("Desired: %s x %s, Resulted: %s x %s\n", 
                $desired->[WIDTH], $desired->[HEIGHT], $gd->width, $gd->height);
    ok(($gd->width == $result->[WIDTH]) && ($gd->height == $result->[HEIGHT]));
}
