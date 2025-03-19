use strict;
use warnings;

use Test::More;

use FindBin;
use lib "$FindBin::Bin/lib";
use TestHelper;

use ExtUtils::Depends;

my $tmp_inc = temp_inc;

my $dep_info = ExtUtils::Depends->new ('DepTest');
$dep_info->save_config (catfile $tmp_inc, qw(DepTest Install Files.pm));

# --------------------------------------------------------------------------- #

my $info = ExtUtils::Depends->new ('UseTest', 'DepTest');

my %deps = $info->get_deps;
ok (exists $deps{DepTest});

# --------------------------------------------------------------------------- #

$info = ExtUtils::Depends->new ('UseTest');
$info->add_deps ('DepTest');
$info->load_deps;

%deps = $info->get_deps;
ok (exists $deps{DepTest});

# --------------------------------------------------------------------------- #

done_testing;
