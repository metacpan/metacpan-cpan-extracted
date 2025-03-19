use strict;
use warnings;

use Test::More;

use FindBin;
use lib "$FindBin::Bin/lib";
use TestHelper;

use ExtUtils::Depends;

my $tmp_inc = temp_inc;

plan skip_all => "test only for 'MSWin32', 'cygwin', and 'android'"
  unless $^O eq 'MSWin32' || $^O eq 'cygwin' || $^O eq 'android';

my $dep_info = ExtUtils::Depends->new('DepTest');
$dep_info->save_config(catfile $tmp_inc, qw(DepTest Install Files.pm));

# --------------------------------------------------------------------------- #

push @INC, catdir(qw(t inc));
my $use_info = ExtUtils::Depends->new('UseTest', 'DepTest');
my %vars = $use_info->get_makefile_vars;

my $libname = 'DepTest';

require DynaLoader;
$libname = DynaLoader::mod2fname([$libname]) if defined &DynaLoader::mod2fname;

like $vars{LDFROM}, qr/$libname/ or diag explain \%vars;

# --------------------------------------------------------------------------- #

done_testing;
