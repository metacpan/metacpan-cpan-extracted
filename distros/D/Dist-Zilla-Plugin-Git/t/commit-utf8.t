use strict;
use warnings;
use utf8;

use Dist::Zilla  1.093250;
use Dist::Zilla::Tester;
use Encode qw( decode );
use File::pushd qw(pushd);
use Path::Tiny 0.012 qw(path); # cwd
use Test::More;

plan skip_all => "Dist::Zilla 5 required" if Dist::Zilla->VERSION < 5;
plan tests => 1;

use lib 't';
use Util qw(clean_environment init_repo);

# Mock HOME to avoid ~/.gitexcludes from causing problems
# and clear GIT_ environment variables
my $homedir = clean_environment;

# UTF-8 encoded strings:
my $changes1 = 'Ævar Arnfjörð Bjarmason';
my $changes2 = 'ブログの情報';
my $changes3 = 'plain ASCII';

# build fake repository
my $zilla = Dist::Zilla::Tester->from_config({
  dist_root => path('corpus/commit')->absolute,
},{
  add_files => {
    'source/Changes' => <<"END CHANGES",
Changes

1.23 2012-11-10 19:15:45 CET
 - $changes1
 - $changes2
 - $changes3
END CHANGES
  },
});

{
  my $dir = pushd(path($zilla->tempdir)->child('source'));

  my $git = init_repo( qw{ .  dist.ini Changes } );

  # do a release, with changes and dist.ini updated
  append_to_file('Changes',  "\n");
  append_to_file('dist.ini', "\n");
  $zilla->release;

  # check if dist.ini and changelog have been committed
  my ($log) = $git->log( 'HEAD' );
  like( decode('UTF-8', $log->message), qr/v1.23\n[^a-z]*\Q$changes1\E[^a-z]*\Q$changes2\E[^a-z]*\Q$changes3\E/, 'commit message taken from changelog' );
}

sub append_to_file {
    my ($file, @lines) = @_;
    my $fh = path($file)->opena;
    print $fh @lines;
    close $fh;
}
