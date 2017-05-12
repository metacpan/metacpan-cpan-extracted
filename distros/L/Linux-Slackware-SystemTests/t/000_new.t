#!/usr/bin/perl

use strict;
use warnings;
use Test::Most;

use lib "./lib";
use Linux::Slackware::SystemTests;

my $st = Linux::Slackware::SystemTests->new(
    "ichi-ni" => "san-shi",
     self_id  => {
        'name'    => 'foo',
        'version' => '97.7',
        'arch'    => 'Z80',
        'kernel'  => '0.98pl6',
        'bits'    => 128,
        'tm'      => 2345679900,
        'distro'  => 'yggdrasil',
        'release' => 'yggdrasil 97.7',
        'lt'      => 'Sat Apr 30 18:45:00 2044',
        'os'      => 'CP/M'
    }
);

ok defined($st), "new works";
is ref($st), "Linux::Slackware::SystemTests",    "new returns Linux::Slackware::SystemTests object";
ok defined($st->{opt_hr}->{ichi_ni}),            "new transforms option names correctly";
is $st->{opt_hr}->{ichi_ni} // '', "san-shi",    "new does not transform option values";
is ref($st->{sys_hr}), "HASH",                   "new populated sys_hr";
is $st->{sys_hr}->{name}    // '', 'foo',        "new populated sys_hr->name";
is $st->{sys_hr}->{version} // '', '97.7',       "new populated sys_hr->version";
is $st->{sys_hr}->{tm}      // '', '2345679900', "new populated sys_hr->tm";

# that's good enough for me

done_testing();
exit 0;
