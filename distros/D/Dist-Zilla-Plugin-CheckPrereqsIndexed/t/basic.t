use strict;
use warnings;
use Test::More 0.88;
use Test::Fatal;
use Test::DZil;

use if !$ENV{AUTHOR_TESTING}, 'Test::RequiresInternet' => ('cpanmetadb.plackperl.org' => 80);

sub new_tzil {
  my ($corpus_dir, @skips) = @_;
  my $tzil = Builder->from_config(
    { dist_root => $corpus_dir },
    {
      add_files => {
        'source/dist.ini' => simple_ini(
          qw(GatherDir AutoPrereqs FakeRelease),
          [ CheckPrereqsIndexed => (@skips ? { skips => \@skips } : ()) ],
        ),
      },
    },
  );
}

# Write the log messages as diagnostics:
sub diag_log
{
  my $tzil = shift;

  # Output nothing if all tests passed:
  my $all_passed = shift;
  $all_passed &&= $_ for @_;

  return if $all_passed;

  diag(map { "$_\n" } @{ $tzil->log_messages });
}

subtest "unknown prereqs" => sub {
  my $tzil = new_tzil('corpus/DZT');

  my $err = exception { $tzil->release };

  diag_log( $tzil,
    like($err, qr/unindexed prereq/, "we aborted because we had weird prereqs"),
    ok(
      (grep { /Zorch/ } @{ $tzil->log_messages }),
      "and we specifically mentioned the one we expected",
    ),
  );
};

subtest "too-new version" => sub {
  my $tzil = Builder->from_config(
    { dist_root => 'corpus/DZZ' },
    {
      add_files => {
        'source/dist.ini' => simple_ini(
          qw(GatherDir AutoPrereqs CheckPrereqsIndexed FakeRelease),
          [ Prereqs => { 'Dist::Zilla' => 99 } ],
        ),
      },
    },
  );

  my $err = exception { $tzil->release };

  diag_log( $tzil,
    like($err, qr/unindexed prereq/, "we aborted because we had weird prereqs"),
    ok(
      (grep { /you required Dist::Zilla version 99/ } @{ $tzil->log_messages }),
      "it complained that we wanted a too-new version",
    ),
  );
};

subtest "stuff in our own dist" => sub {
  # This is to test that we don't have any problems with libraries that are in
  # our own dist.
  my $tzil = new_tzil('corpus/DZZ');

  my $err = exception { $tzil->release };

  diag_log($tzil, is($err, undef, "we released with no errors"));
};

subtest "explicit skip" => sub {
  my $tzil = new_tzil('corpus/DZT', '^Zorch::');

  my $err = exception { $tzil->release };

  diag_log($tzil, is($err, undef, "skipping Zorch:: allows release"));
};

done_testing;
