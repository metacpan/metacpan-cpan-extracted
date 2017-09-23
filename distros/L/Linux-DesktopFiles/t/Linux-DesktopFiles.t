#!perl -T

#########################

use strict;
use warnings;

use Test::More tests => 10;
BEGIN { use_ok('Linux::DesktopFiles') }

#########################

my $obj = Linux::DesktopFiles->new(
                                   keys_to_keep              => [qw(Name GenericName Comment Comment[ro] Terminal Icon Exec)],
                                   categories                => [qw(Game Archiving)],
                                  );

my $t_file = 't/file.desktop';
$obj->parse(\my %hash, (-f $t_file) ? $t_file : (-f $0) ? 'file.desktop' : ());

my $info = $hash{Archiving}[0];

ok($info->{Name}          eq "The right name",          "Name");
ok($info->{GenericName}   eq "Also this name is right", "GenericName");
ok($info->{Exec}          eq "some_command -z -9",      "Exec");
ok($info->{Comment}       eq "This is a test!",         "Comment");
ok($info->{'Comment[ro]'} eq "Acesta este un test!",    "Comment[ro]");
ok($info->{Terminal}      eq "true",                    "Terminal");
ok($info->{Icon}          eq "icon_name",               "Icon");

# Not defined
ok(!defined($info->{Categories}), "Categories");
ok(!defined($info->{Encoding}),   "Encoding");
