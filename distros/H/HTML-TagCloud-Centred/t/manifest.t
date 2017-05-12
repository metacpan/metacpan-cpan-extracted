use strict;
use warnings;
my $VERSION = 1;

use lib qw(../lib . t/);
use ExtUtils::testlib;
use ExtUtils::Manifest;
use Cwd;
use Data::Dumper;
use Test::More tests => 3;

chdir ".." if getcwd =~ /\Wt$/;
#ExtUtils::Manifest::mkmanifest();

my ($missing, $extra) = ExtUtils::Manifest::fullcheck();

@_ = grep {/t\W.*\.t$/} @$missing;
is( 0, scalar(@_), 'No tests missing from manifest') or diag join", ",@_;

@_ = grep {/\.pm$/} @$missing;
is( 0, scalar(@_), 'No PMs missing from manifest') or diag join", ",@_;

is( 0, scalar(@$extra), 'No un-MANIFESTed files found') or diag join", ",@$extra;



