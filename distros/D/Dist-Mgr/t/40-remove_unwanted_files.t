use warnings;
use strict;

use Capture::Tiny qw(:all);
use Cwd qw(getcwd);
use Test::More;
use Data::Dumper;
use Module::Starter;
use Dist::Mgr qw(:all);
use Dist::Mgr::FileData qw(:all);

use lib 't/lib';
use Helper qw(:all);

my $work = 't/data/work';
my $orig = 't/data/orig';

my @unwanted_entries = _unwanted_filesystem_entries();

my %module_args = (
    author  => 'Steve Bertrand',
    email   => 'steveb@cpan.org',
    modules => [ qw(Acme::STEVEB) ],
    license => 'artistic2',
    builder => 'ExtUtils::MakeMaker',
);

remove_unwanted();

my $cwd = getcwd();

like $cwd, qr/dist-mgr/i, "in proper directory ok";

chdir $work or die $!;
like getcwd(), qr/$work$/, "in $work directory ok";

mkdir 'unwanted' or die $!;
is -d 'unwanted', 1, "'unwanted' dir created ok";

chdir 'unwanted' or die $!;
like getcwd(), qr/$work\/unwanted$/, "in $work/unwanted directory ok";

capture_merged {
    Module::Starter->create_distro(%module_args);
};
is -d 'Acme-STEVEB', 1, "Acme-STEVEB directory created ok";

chdir 'Acme-STEVEB' or die $!;
like getcwd(), qr/Acme-STEVEB/, "in Acme-STEVEB dir ok";

# do stuff
{
    for (@unwanted_entries) {
        is -e $_, 1, "'$_' exists ok";
    }

    remove_unwanted_files();

    for (@unwanted_entries) {
        next if $_ eq 'MANIFEST'; # We remove, then re-add this file
        is -e $_, undef, "'$_' removed ok";
    }
}

chdir $cwd or die $!;
like getcwd(), qr/dist-mgr/i, "back in root directory ok";

remove_unwanted();

done_testing;

