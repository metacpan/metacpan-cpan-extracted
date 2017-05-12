# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Kwiki-Attachments.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 5;
BEGIN { use_ok('Kwiki::Attachments') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

SKIP: {
   eval { require Imager };
   skip "Imager not installed (for thumbnails) ", 2 if $@;
   my $image = Imager->new;
   isa_ok($image, "Imager" );
   my $ok = $image->read(file=>"t/test.png");
   isa_ok($image, "Imager" );
#   is($ok, 0, "No errors reading image with Imager");
}
SKIP: {
   eval { require Image::Magick };
   skip "Image::Magick not installed (for thumbnails)", 2 if $@;
   my $im = Image::Magick->new;
   isa_ok($im, "Image::Magick" );
   my $ok = $im->Read("t/test.png");
   is($ok, 0, "No errors reading image with Image::Magick");
}


