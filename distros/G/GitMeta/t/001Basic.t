######################################################################
# Test suite for Git::Meta
# by Mike Schilli <cpan@perlmeister.com>
######################################################################

use warnings;
use strict;

use Cwd;
use Test::More;
use Sysadm::Install qw(:all);
use File::Temp qw(tempdir);
use FindBin qw($Bin);
use File::Basename;
use Log::Log4perl qw(:easy);
# Log::Log4perl->easy_init($DEBUG);

my $tests_to_go = 2;

plan tests => $tests_to_go;

use GitMeta;
use GitMeta::GMF;
use GitMeta::Github;
use GitMeta::SshDir;

my($stdout, $stderr, $rc) = tap "git", "version";

my $old_cwd = cwd();

SKIP:
{
    if( $rc ) {
        skip "'git' not found in \$PATH", $tests_to_go;
    }
    like $stdout, qr/\d\.\d/, "git version match";

    my $repodir   = tempdir( CLEANUP => 1 );
    my $reponame = basename $repodir;
    cd $repodir;
    tap { raise_error => 1 }, "git", "init";
    blurt "blah\n", "a.txt";
    tap { raise_error => 1 }, "git", "add", "a.txt";
    tap { raise_error => 1 }, "git", "commit", "-m", "test", "a.txt";
    cdback;

    my $metadir   = tempdir( CLEANUP => 1 );
    my $gmf_file = "$metadir/test.gmf";
    blurt(<<EOT, $gmf_file);
- file://$repodir
EOT

    my $localdir  = tempdir( CLEANUP => 1 );
    my( $stdout, $stderr, $rc ) = 
    tap $^X, "-I$Bin/../lib",
      "$Bin/../eg/gitmeta-update", $gmf_file, "$localdir";
    if( $rc ) {
        die "failed: $stderr";
    }

    cd "$localdir/$reponame";
    my $data = slurp "a.txt";
    cdback;

    is($data, "blah\n", "gitmeta-update with local gmf");
}

END {
    chdir $old_cwd;
};
