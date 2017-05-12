use strict;
use warnings;

use Dist::Zilla  1.093250;
use Dist::Zilla::Tester;
use Path::Tiny 0.012 qw(path); # cwd
use File::Copy 'move';
use Test::More   tests => 1;

use lib 't';
use Util qw(chdir_original_cwd clean_environment init_repo);

# Mock HOME to avoid ~/.gitexcludes from causing problems
# and clear GIT_ environment variables
my $homedir = clean_environment;

# build fake repository
my $zilla = Dist::Zilla::Tester->from_config({
  dist_root => path('corpus/repo-dir')->absolute,
});

chdir path($zilla->tempdir)->child( 'source' );

my $git = init_repo('.');

mkdir 'dist';

# move corpus files to subdir of git repo
move 'dist.ini', 'dist/dist.ini';
move 'Changes', 'dist/Changes';

# do a release in a subdir; the git repo is one level up
chdir 'dist';

$git->add( qw{ dist.ini Changes } );
$git->commit( { message => 'initial commit' } );


append_to_file('Changes',  "\n");
append_to_file('dist.ini', "\n");


# create a new zilla with dist root in the right place
my $zilla2 = Dist::Zilla::Dist::Builder->from_config( { chrome => Dist::Zilla::Chrome::Test->new } );
$zilla2->release;

# check if dist.ini and changelog have been committed
my ($log) = $git->log( 'HEAD' );
like( $log->message, qr/v1.23\n[^a-z]*foo[^a-z]*bar[^a-z]*baz/, 'commit message taken from changelog' );

chdir_original_cwd;

sub append_to_file {
    my ($file, @lines) = @_;
    my $fh = path($file)->opena;
    print $fh @lines;
    close $fh;
}
