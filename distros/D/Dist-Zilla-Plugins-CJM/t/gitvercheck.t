#! /usr/bin/perl
#---------------------------------------------------------------------

use strict;
use warnings;
use autodie ':io';

use Test::More 0.88;            # done_testing

BEGIN {
  eval "use Git::Wrapper; 1"
      or plan skip_all => "Git::Wrapper required for testing GitVersionCheckCJM";

  # RECOMMEND PREREQ: Test::Fatal
  eval "use Test::Fatal; 1"
      or plan skip_all => "Test::Fatal required for testing GitVersionCheckCJM";
}

use Test::DZil 'Builder';
use File::pushd 'pushd';
use File::Temp ();
use Path::Tiny ();
use Try::Tiny qw(try catch);

my $stoppedRE = qr/Stopped because of errors/;

#---------------------------------------------------------------------
# Initialise Git working copy:

my $fakeHome   = File::Temp->newdir;
$ENV{HOME}     = "$fakeHome"; # Don't want user's ~/.gitconfig to interfere

my $tempdir    = File::Temp->newdir;
my $gitRoot    = Path::Tiny::path("$tempdir")->absolute;
my $gitHistory = Path::Tiny::path("corpus/gitvercheck.git")->absolute;

my $git;

try {
  my $wd = pushd($gitRoot);
  system "git init --quiet" and die "Couldn't init repo\n";
  system "git fast-import --quiet <\"$gitHistory\""
      and die "Couldn't import repo\n";

  $git = Git::Wrapper->new("$gitRoot");

  $git->config('user.email', 'example@example.org');
  $git->config('user.name',  'E. Xavier Ample');
  $git->checkout(qw(--force --quiet master));
} catch {
  chomp;
  plan skip_all => $_;
};

plan tests => 18;

#---------------------------------------------------------------------
sub edit
{
  my ($file, $edit) = @_;

  my $fn = $gitRoot->child("lib/DZT")->child("$file.pm");

  local $_ = do {
    local $/;
    open my $fh, '<:raw', $fn;
    <$fh>;
  };

  $edit->();

  open my $fh, '>:raw', $fn;
  print $fh $_;
  close $fh;
} # end edit

#---------------------------------------------------------------------
sub set_version
{
  my $version = shift;

  foreach my $file (@_) {
    edit($file, sub { s/(\$VERSION\s*=)\s*'[^']*'/$1 '$version'/ or die });
  }
} # end set_version

#---------------------------------------------------------------------
sub new_tzil
{
  my $tzil = Builder->from_config(
    { dist_root => $gitRoot },
  );

  $tzil->plugin_named('GitVersionCheckCJM')->logger->set_debug(1);

  # Something about the copy dzil makes seems to confuse git into
  # thinking files are modified when they aren't.
  # Run "git reset --mixed" in the source directory to unconfuse it:
  Git::Wrapper->new( $tzil->tempdir->child("source")->stringify )
              ->reset('--mixed');

  $tzil;
} # end new_tzil

#------------------------------------------------------n---------------
# Extract the errors reported by GitVersionCheckCJM:

sub errors
{
  my ($tzil) = @_;

  my @messages = grep { s/^.*GitVersionCheckCJM.*ERROR:\s*// }
                      @{ $tzil->log_messages };
  my %error;

  for (@messages) {
    s!\s*lib/DZT/(\S+)\.pm\b:?\s*!! or die "Can't find filename in $_";
    $error{$1} = $_;
  }

  #use YAML::XS;  print Dump $tzil->log_events;

  return \%error;
} # end errors

#---------------------------------------------------------------------
# Write the log messages as diagnostics:

sub diag_log
{
  my $tzil = shift;

  # Output nothing if all tests passed:
  my $all_passed = shift;
  $all_passed &&= $_ for @_;

  return if $all_passed;

  diag(map { "$_\n" } @{ $tzil->log_messages });

  {
    my $wd = pushd($tzil->tempdir->child("source"));
    diag(
      `git --version`,
      "git diff-index:\n", `git diff-index HEAD --name-only`,
      "git ls-files:\n",   `git ls-files -o --exclude-standard`,
      "git status:\n",     `git status`,
    );
  }
} # end diag_log

#---------------------------------------------------------------------
{
  my $tzil = new_tzil;
  diag_log($tzil,
    is(exception { $tzil->build }, undef, "build 0.04"),
    is_deeply(errors($tzil), {}, "no errors in 0.04"),
  );
#  print "$_\n" for @{ $tzil->log_messages };
#  print $tzil->tempdir,"\n"; my $wait = <STDIN>;
}

{
  set_version('0.04', 'Sample/Second');

  my $tzil = new_tzil;
  diag_log($tzil,
    like(exception { $tzil->build }, $stoppedRE, "can't build modified 0.04"),

    is_deeply(errors($tzil),
              { 'Sample/Second' => 'dist version 0.04 needs to be updated' },
              "errors in modified 0.04"),
  );
}

{
  set_version('0.05', 'Sample');

  my $tzil = new_tzil;
  diag_log($tzil,
    like(exception { $tzil->build }, $stoppedRE, "can't build 0.05 yet"),

    is_deeply(errors($tzil),
              { 'Sample/Second' => '0.04 needs to be updated' },
              "errors in 0.05"),
  );
}

{
  set_version('0.05', 'Sample/Second');

  my $tzil = new_tzil;
  diag_log($tzil,
    is(exception { $tzil->build }, undef, "can build 0.05 now"),
    is_deeply(errors($tzil), {}, "no errors in 0.05 now"),
  );
}

#---------------------------------------------------------------------
$git->reset(qw(--hard --quiet)); # Restore to checked-in state

{
  set_version('0.045', 'First');

  my $tzil = new_tzil;
  diag_log($tzil,
    like(exception { $tzil->build }, $stoppedRE, "can't build with 0.045"),
    is_deeply(errors($tzil), { First => '0.045 exceeds dist version 0.04' },
              "errors with 0.045"),
  );
}

{
  set_version('0.05', 'Sample');

  my $tzil = new_tzil;
  diag_log($tzil,
    like(exception { $tzil->build }, $stoppedRE, "can't build 0.05 with 0.045"),
    is_deeply(errors($tzil), {
      First => '0.045 needs to be updated',
    }, "errors in 0.05 with 0.045"),
  );
}

{
  $git->add('lib/DZT/First.pm');
  $git->commit(-m => 'checking in DZT::First 0.045');

  my $tzil = new_tzil;
  diag_log($tzil,
    like(exception { $tzil->build }, $stoppedRE,
         "can't build 0.05 with 0.045 committed"),
    is_deeply(errors($tzil), {
      First => '0.045 does not seem to have been released, but is not current',
    }, "errors in 0.05 with 0.045 committed"),
  );
}

{
  set_version('0.05', 'First');

  my $tzil = new_tzil;
  diag_log($tzil,
    is(exception { $tzil->build }, undef, "can build with First 0.05"),
    is_deeply(errors($tzil), {}, "no errors with First 0.05"),
  );
}

{
  edit('First', sub { s/^.*VERSION.*\n//m or die });

  my $tzil = new_tzil;
  diag_log($tzil,
    like(exception { $tzil->build }, qr/ERROR: Can't find version/,
         "can't build with First unversioned"),
    is_deeply(errors($tzil), { First => "Can't find version in" },
              "errors with First unversioned"),
  );
}

undef $tempdir;                 # Clean up temporary directory

done_testing;
