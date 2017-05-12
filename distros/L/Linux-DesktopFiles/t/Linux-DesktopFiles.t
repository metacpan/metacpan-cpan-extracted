# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Linux-DesktopFiles.t'

#########################

use 5.010;
use strict;
use warnings;

use Test::More tests => 10;
BEGIN { use_ok('Linux::DesktopFiles') }

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $obj = Linux::DesktopFiles->new(
                                   keys_to_keep              => [qw(Name GenericName Comment Comment[ro] Terminal Icon Exec)],
                                   categories                => [qw(Game Archiving)],
                                  );

my $t_file = 't/file.desktop';
my $hash_ref = $obj->parse_desktop_file(-f $t_file ? $t_file : -f $0 ? 'file.desktop' : ());

ok($hash_ref->{Name}          eq "The right name",          "Name");
ok($hash_ref->{GenericName}   eq "Also this name is right", "GenericName");
ok($hash_ref->{Exec}          eq "some_command -z -9",      "Exec");
ok($hash_ref->{Comment}       eq "This is a test!",         "Comment");
ok($hash_ref->{'Comment[ro]'} eq "Acesta este un test!",    "Comment[ro]");
ok($hash_ref->{Terminal}      eq "true",                    "Terminal");
ok($hash_ref->{Icon}          eq "icon_name",               "Icon");

# Not defined
ok(!defined($hash_ref->{Categories}), "Categories");
ok(!defined($hash_ref->{Encoding}),   "Encoding");
