use strict; use warnings;
my $xt; use lib ($xt = -e 'xt' ? 'xt' : 'test/devel');

use Test::More 'no_plan';
use File::Share ':all';

use Cwd qw[abs_path cwd];
use lib "$xt/freebsd/usr/local/lib/perl5/site_perl/5.16";
use Foo::Bar;

my $xt = -e 'xt' ? 'xt' : 'test/devel';
my $share_dir = abs_path "$xt/freebsd/usr/local/lib/perl5/site_perl/5.16/auto/share/dist/Foo-Bar";
my $share_file = abs_path "$xt/freebsd/usr/local/lib/perl5/site_perl/5.16/auto/share/dist/Foo-Bar/sample.txt";

is abs_path(dist_dir('Foo-Bar')), $share_dir, 'Dir is correct';
is abs_path(dist_file('Foo-Bar','sample.txt')), $share_file, 'File is correct';
