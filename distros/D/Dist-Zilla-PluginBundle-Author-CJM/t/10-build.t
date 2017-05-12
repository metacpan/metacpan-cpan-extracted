#---------------------------------------------------------------------
# 10-build.t
# Copyright 2015 Christopher J. Madsen
#
# Test building a distribution with @Author::CJM
#---------------------------------------------------------------------

use strict;
use warnings;
use 5.008;

use Test::More 0.88 tests => 4; # done_testing

use Dist::Zilla 4.200001 ();
use Dist::Zilla::Tester;
use File::pushd qw(pushd);
use Path::Tiny qw(path);

my $original_cwd;

BEGIN {
  # Change back to the original directory when shutting down,
  # to avoid problems with cleaning up tmpdirs.
  $original_cwd = path('.')->absolute;
  # we chdir around so make @INC absolute
  @INC = map {; ref($_) ? $_ : path($_)->absolute->stringify } @INC;
}

END { chdir $original_cwd if $original_cwd }

my $homedir = Path::Tiny->tempdir( CLEANUP => 1 );

delete $ENV{V}; # In case we're being released with a manual version
delete $ENV{$_} for grep /^G(?:IT|PG)_/i, keys %ENV;

$ENV{HOME} = $ENV{GNUPGHOME} = $homedir;
$ENV{GIT_CONFIG_NOSYSTEM} = 1; # Don't read /etc/gitconfig

# The POD tests moved from xt/release to xt/author in Dist::Zilla 5.040
my $pod_test_dir = (Dist::Zilla->VERSION < 5.040) ? 'release' : 'author';

my $zilla = Dist::Zilla::Tester->from_config({
  dist_root => path('corpus/DZT')->absolute,
  }, {
  add_files => {
    'source/.gitignore' => <<'END GITIGNORE',
/.build/
/_build/
/blib/
/Build
/Build.bat
Makefile
/META.*
/MYMETA.*
/pm_to_blib
DZT-Sample-*.tar.gz
DZT-Sample-*/
/test-results/
*.c
*.obj
*.pdb
END GITIGNORE
    'source/MANIFEST' => <<"END MANIFEST",
Changes
LICENSE
MANIFEST
META.json
META.yml
Makefile.PL
README
lib/DZT/Sample.pm
t/00-all_prereqs.t
t/00-load.t
xt/$pod_test_dir/pod-coverage.t
xt/$pod_test_dir/pod-syntax.t
END MANIFEST
  },
});

sub slurp_text_file
{
  my ($filename) = @_;

  return scalar do {
    local $/;
    # Don't use Path::Tiny's slurp_utf8 because it doesn't do
    # CRLF translation on Windows.
    if (open my $fh, '<:utf8', path( $zilla->tempdir )->child( $filename )) {
      <$fh>;
    } else {
      diag("Unable to open $filename: $!");
      undef;
    }
  };
} # end slurp_text_file

{
  my $dir = pushd(path($zilla->tempdir)->child('source'));

  system qw(git init --quiet) and die "Can't initialize repo in $dir";

  my $git = Git::Wrapper->new("$dir");

  $git->config( 'push.default' => 'matching' ); # compatibility with Git 1.8
  $git->config( 'user.name'  => 'dzp-git test' );
  $git->config( 'user.email' => 'dzp-git@test' );

  # If core.autocrlf is true, then git add may hang on Windows.
  # This is probably a bug in Git::Wrapper, but a workaround is to set
  # autocrlf to false.  It seems to be caused by these warning messages
  # (from git version 1.8.5.2.msysgit.0):
  #   warning: LF will be replaced by CRLF in .gitignore.
  #   The file will have its original line endings in your working directory.
  $git->config( 'core.autocrlf' => 'false' );

  $git->add('.');
  $git->commit( { message => 'initial commit' } );

  $zilla->build;
  ok(1, 'built distribution');

  my $README = slurp_text_file('build/README');
  $README =~ s/\n.*//s;
  is($README, 'DZT-Sample version 0.007, released NOT', 'README ok');

  my $module = slurp_text_file('build/lib/DZT/Sample.pm');

  like($module, qr/^\Q# This file is part of DZT-Sample 0.007 (NOT)\E/m,
       'module incorporates dist version');

  like($module,
       qr/^=head1 NAME\s+DZT::Sample - Sample plugin for testing \@Author::CJM/m,
       'module has NAME section');

  #print STDERR "$dir"; my $x = <STDIN>;
}

chdir $original_cwd;

done_testing;
