BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
  unless ($ENV{PERL5_DPPPC_PATCH_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are necessary to specify explicitly by environment variable PERL5_DPPPC_PATCH_TESTING');
  }
}

use Test::More;
use File::Temp;
use File::Path;
use IPC::Open3;
use App::perlbrew;

my $temp = File::Temp->newdir();
File::Path::mkpath($_) for map { $temp->dirname.'/'.$_ } qw(dists build);
my @stable = grep { /perl-5\.(\d+)/; $1 % 2 == 0 && $1 >= 8 && $_ !~ /TRIAL|RC/;  } App::perlbrew->new('--all')->available_perls();
plan tests => 2 * @stable;
$ENV{PERL5_PATCHPERL_PLUGIN} = 'Cygwin';
for my $stable (@stable) {
    my $pb = App::perlbrew->new('--root' => $temp->dirname);
    my $dist_version = $stable; $dist_version =~ s/perl-//;
    my ($dist_tarball, $dist_tarball_url) = $pb->perl_release($dist_version);
    my $dist_tarball_path = $App::perlbrew::PERLBREW_ROOT.'/dists/'.$dist_tarball;
    if(! -f $dist_tarball_path) {
        $pb->run_command_download($stable);
        $dist_tarball_path = $temp->dirname.'/dists/'.$dist_tarball;
    }
    my $dist_extracted_path = $pb->do_extract_tarball($dist_tarball_path);
    my $pid = open3(my $in, my $out, undef, 'patchperl', $dist_extracted_path);
    close $in;
    my $flag;
    while(<$out>) {
        $flag = 1 if /# Warnings from the plugin:/;
    }
    close $out;
    waitpid($pid, 0);
    ok(!($? >> 8), 'patch exit status for '.$stable);
    ok(!$flag, 'patch success for '.$stable);
}

