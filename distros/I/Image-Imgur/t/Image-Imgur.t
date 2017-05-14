# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Image-Imgur.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 3;
BEGIN { use_ok('Image::Imgur') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
# API Key provided by Alan@imgur.com
my $apikey = "b3625162d3418ac51a9ee805b1840452";
my $imgur = new Image::Imgur(key=>$apikey);
ok( $imgur );
my $result = $imgur->upload('http://st.pimg.net/tucs/img/cpan_banner.png');
ok( $result );