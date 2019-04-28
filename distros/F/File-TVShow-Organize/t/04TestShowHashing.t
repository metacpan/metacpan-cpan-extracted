# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl BAS-TVShow-Organize.t'

#########################

use strict;
use warnings;
use Data::Dumper;

use Test::More;
use Test::Carp;
use Cwd;
BEGIN {use_ok( 'File::TVShow::Organize' ) };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $obj = File::TVShow::Organize->new();

my $ShowDirectory = getcwd . '/t/TV Shows';

subtest "Set show_folder path" => sub {
$obj->show_folder($ShowDirectory);

can_ok($obj, 'create_show_hash');

};

$obj->create_show_hash();

subtest "Long test to check that we can get the correct folder to store Shows in based on the filename" => sub {
can_ok($obj, 'show_path');

is ($obj->show_path("Agent X"), "Agent X US", "Agent X returns Agent X US");
is ($obj->show_path("Agent X US"), "Agent X US", "Agent X US returns Agent X US");
is ($obj->show_path("Agent X (US)"), "Agent X US", "Agent X (US) returns Agent X US");

is ($obj->show_path("Travelers"), "Travelers (2016)", "Travelers returns Travelers (2016)");
is ($obj->show_path("Travelers 2016"), "Travelers (2016)", "Travelers 2016 returns Travelers (2016)");
is ($obj->show_path("Travelers (2016)"), "Travelers (2016)", "Travelers (2016) returns Travelers (2016)");

is ($obj->show_path("Bull"), "Bull (2016)", "Bull returns Bull (2016)");
is ($obj->show_path("Bull 2016"), "Bull (2016)", "Bull 2016 returns Bull (2016)");
is ($obj->show_path("Bull (2016)"), "Bull (2016)", "Bull (2016) returns Bull (2016)");

is ($obj->show_path("Doctor Who"), "Doctor Who (2005)", "Doctor Who returns Doctor Who (2005)");
is ($obj->show_path("Doctor Who 2005"), "Doctor Who (2005)", "Doctor Who 2005 returns Doctor Who (2005)");
is ($obj->show_path("Doctor Who (2005)"), "Doctor Who (2005)", "Doctor Who (2005) returns Doctor Who (2005)" );

is ($obj->show_path("S.W.A.T"), "S.W.A.T 2017", "S.W.A.T returns S.W.A.T 2017");
is ($obj->show_path("S.W.A.T 2017"), "S.W.A.T 2017", "S.W.A.T 2017 returns S.W.A.T 2017");
is ($obj->show_path("S.W.A.T (2017)"), "S.W.A.T 2017", "S.W.A.T (2017)returns S.W.A.T 2017");

is ($obj->show_path("S.W.A.T 2018"), "S.W.A.T 2018", "S.W.A.T 2018 returns S.W.A.T 2018");


is ($obj->show_path("The Librarian"), "The Librarian", "The Librarian returns The Librarian");

is ($obj->show_path("The Librarians"), "The Librarians US", "The Librarian returns The Librarian US");
is ($obj->show_path("The Librarians US"), "The Librarians US", "The Librarians US returns The Librarian US");
is ($obj->show_path("The Librarians (US)"), "The Librarians US", "The Librarians (US) returns The Librarian US");

is ($obj->show_path("The Tomorrow People (1992) - The New Generation"), "The Tomorrow People (1992) - The New Generation", "The Tomorrow People (1992) - The New Generation");

is ($obj->show_path("The Tomorrow People"), "The Tomorrow People", "The Tomorrow Pople returns The Tomorrow People");

is ($obj->show_path("The Tomorrow People US"), "The Tomorrow People US", "The Tomorrow People US");
is ($obj->show_path("The Tomorrow People (US)"), "The Tomorrow People US", "The Tomorrow People (US)");
isnt ($obj->show_path("The Tomorrow People"), "The Tomorrow People US", "The Tomorrow Poeple doesnt return The Tomorrow People US");

is ($obj->show_path("bogus"), undef, "If a show Folder does not exist return undef");

};

subtest "Test that we can empty the showHash" => sub {

can_ok($obj, 'clear_show_hash');
$obj->clear_show_hash();
is($obj->{shows},undef, "Show Hash is empty.");
};

subtest "We can reload the showHash" => sub {
$obj->create_show_hash();
ok(keys %{$obj->{shows}} > 0, "showHash contains objects");
};

done_testing();
