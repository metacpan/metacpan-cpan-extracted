#!/usr/bin/env perl

use Test::More tests => 9;

use File::Spec;
use FindBin;
use lib "$FindBin::Bin/lib";

require_ok('Medical::Growth::Base');

require Medical::Growth::Testme;

is_deeply(
    Medical::Growth::Testme->check_data,
    [ [ 1, 2 ], [ 3, 4 ], [ 5, 6 ] ],
    'inherited read_data (DATA)'
);

is_deeply(
    Medical::Growth::Testme->new->read_data,
    [ [ 1, 2 ], [ 3, 4 ], [ 5, 6 ] ],
    'inherited read_data via object (DATA)'
);

my $config = File::Spec->catfile( $FindBin::Bin, 'lib', 'testdata.txt' );
is_deeply(
    Medical::Growth::Testme->read_data($config),
    [ [ 10, 20 ], [ 30, 40 ], [ 50, 60 ] ],
    'inherited read_data (config file name)'
);

open my $fh, '<', $config;
is_deeply(
    Medical::Growth::Testme->read_data($fh),
    [ [ 10, 20 ], [ 30, 40 ], [ 50, 60 ] ],
    'inherited read_data (config file name)'
);
close $fh;

my $sts = eval { Medical::Growth::Testme->read_data('/non/existent') };
my $err = $@;
ok( !defined($sts), 'read_data fails with non-existent config file' );
like(
    $err,
    qr[Can't read file "/non/existent": .*],
    'non-existent file error message'
);

require Medical::Growth::TestFail;
my $sts =
  eval { Medical::Growth::TestFail->measure_class_for( test => 'missing' ) };
my $err = $@;
ok( !defined($sts), 'base class measure_class_for not overridden' );
like(
    $err,
qr[No measure_class_for\(\) method found \(called via "Medical::Growth::TestFail"\)],
    'base class error message'
);

