use strict;
use warnings;
use Dist::Surveyor::MakeCpan;
use File::Spec;
use FindBin;
use File::Path; # core
use Test::More;
use Test::RequiresInternet 'fastapi.metacpan.org' => 443, 'cpan.metacpan.org' => 80, 'backpan.perl.org' => 80;

my $cpan_dir = File::Spec->catdir($FindBin::Bin, "testcpan");
rmtree($cpan_dir);
ok(!-e $cpan_dir, "MiniCPAN directory deleted");

my $progname = "dist-surveyor";
my $irregularities = {};
my $verbose = 0;

my $cpan = Dist::Surveyor::MakeCpan->new(
        $cpan_dir, $progname, $irregularities, $verbose);
isnt($cpan, undef, "Created object");
ok(-e $cpan_dir, "MiniCPAN directory created");

my $rel = {
    download_url => 'http://cpan.metacpan.org/authors/id/S/SE/SEMUELF/Dist-Surveyor-0.009.tar.gz',
    url => 'authors/id/S/SE/SEMUELF/Dist-Surveyor-0.009.tar.gz',
    author => 'SEMUELF',
    name => 'Dist-Surveyor-0.009',
    distribution => 'Dist-Surveyor',
};

$cpan->add_release($rel);
$cpan->close();

is($cpan->errors(), 0, "no errors");

ok(-e File::Spec->catdir($cpan_dir, '/authors/id/S/SE/SEMUELF/Dist-Surveyor-0.009.tar.gz'), "Release file downloaded");

rmtree($cpan_dir);
ok(!-e $cpan_dir, "MiniCPAN directory deleted");

done_testing();
