use strict;
use warnings;
use utf8;
use Test::More;
use File::Temp 'tempdir';
use Cwd 'abs_path';
sub cpanm { !system "cpanm", "-nq", "--reinstall", @_ or die "cpanm fail"; }

use Distribution::Metadata::Factory;

my $tempdir1 = tempdir CLEANUP => 1;
my $tempdir2 = tempdir CLEANUP => 1;
$tempdir1 = abs_path $tempdir1;
$tempdir2 = abs_path $tempdir2;
cpanm "-l$tempdir1/local", 'File::pushd';
cpanm "-l$tempdir2/local", 'Capture::Tiny';
my $factory = Distribution::Metadata::Factory->new(
    inc => ["$tempdir1/local/lib/perl5", "$tempdir2/local/lib/perl5", @INC], fill_archlib => 1,
);

my $info1 = $factory->create_from_module("File::pushd");
my $info2 = $factory->create_from_module("Capture::Tiny");
my $info3 = $factory->create_from_module("ExtUtils::MakeMaker");


like $info1->install_json, qr{^$tempdir1/local/lib/perl5};
like $info2->install_json, qr{^$tempdir2/local/lib/perl5};
ok $info3->packlist;

done_testing;
