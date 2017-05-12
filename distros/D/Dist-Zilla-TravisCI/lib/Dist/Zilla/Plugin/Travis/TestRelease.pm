package Dist::Zilla::Plugin::Travis::TestRelease;

our $AUTHORITY = 'cpan:BBYRD'; # AUTHORITY
our $VERSION = '1.15'; # VERSION
# ABSTRACT: makes sure repo passes Travis tests before release

#############################################################################
# Modules

use v5.10;
use Moose;

use Net::Travis::API::UA;
use Date::Parse 'str2time';
use Date::Format 'time2str';
use Storable 'dclone';

use Dist::Zilla::Util::Git::Bundle;

with 'Dist::Zilla::Role::BeforeRelease';

#############################################################################
# Private Attributes

has _git_bundle => (
   is       => 'ro',
   isa      => 'Dist::Zilla::Util::Git::Bundle',
   lazy     => 1,
   init_arg => undef,
   handles  => { _git => 'git' },
   default  => sub {
      my $self = shift;
      Dist::Zilla::Util::Git::Bundle->new(
         ### XXX: deep recursion on the branches
         zilla         => $self->zilla,
         logger        => $self->logger,
         #branch        => $self->branch,
         remote_name   => $self->remote,
         #remote_branch => $self->remote_branch,
      );
   },
);
has _travis_ua => (
   is       => 'ro',
   isa      => 'Net::Travis::API::UA',
   lazy     => 1,
   init_arg => undef,
   default  => sub {
      my $ua = Net::Travis::API::UA->new;
      no strict 'vars';
      no warnings 'uninitialized';  # $VERSION is undef when bootstrapping

      $ua->agent(__PACKAGE__."/$VERSION ");  # prepend our own UA string
      return $ua;
   }
);

#############################################################################
# Public Attributes

has branch => (
   is      => 'ro',
   lazy    => 1,
   default => sub { join('/', 'release_testing', shift->_git_bundle->current_branch) },
);
has remote_branch => (
   is      => 'ro',
   lazy    => 1,
   default => sub { shift->branch },
);
has remote => (
   is      => 'ro',
   default => 'origin',
);
has slug => (
   is      => 'ro',
   lazy    => 1,
   default => sub {
      my $self = shift;
      my @github = $self->_git_bundle->acquire_github_repo_info;
      $self->log_fatal(["Remote '%s' is not a Github repo!", $self->remote]) unless @github;

      return join('/', @github);
   },
);
has create_builddir => (
   is      => 'ro',
   isa     => 'Bool',
   default => 0,
);
has open_status_url => (
   is      => 'ro',
   isa     => 'Bool',
   default => 0,
);

#############################################################################
# Methods

my %RESULT_MAP = (
   '' => 'Error',
   0  => 'Pass',
   1  => 'Fail',
);

sub before_release {
   my ($self, $tgz) = @_;

   my $gb   = $self->_git_bundle;

   $gb->branch($self->branch);
   $gb->_remote_branch($self->remote_branch);

   # Stash, checkout, apply, untar, update, push, reset
   my $prev_repo_info;
   $gb->dirty_branch_push(
      create_builddir => $self->create_builddir,
      commit_reason   => 'Travis release testing',
      tgz             => $tgz,
      pre_remote_code => sub {
         # Check TravisCI prior to the push to make sure the distro works and exists
         $self->log('Checking Travis CI...');
         $prev_repo_info = $self->travisci_api_get_repo;
      },
   );

   # Start a clock
   my $start_time = time;
   $self->_set_time_prefix($start_time);
   $self->log('Checking Travis CI for test details...');

   # Run through the API polling loop
   my $build_summary_info;
   while (1) {
      my $builds_info = $self->travisci_api_get_build;
      $self->_set_time_prefix($start_time);

      my @potential_builds = grep {
         $_->{branch} eq $self->remote_branch &&
         $_->{number} >  $prev_repo_info->{last_build_number} &&
         $_->{id}     != $prev_repo_info->{last_build_id}
      } @$builds_info;

      if (@potential_builds) {
         $build_summary_info = $potential_builds[0];

         if ($build_summary_info->{started_at}) {
            my $build_time = str2time($build_summary_info->{started_at}, 'GMT');
            $self->log([ 'Build %u started at %s', $build_summary_info->{number}, time2str('%l:%M%p', $build_time) ]);
         }
         else {
            $self->log([ 'Build %u detected, but not started yet', $build_summary_info->{number} ]);
         }

         my $url = sprintf 'https://travis-ci.org/%s/builds/%u', $self->slug, $build_summary_info->{id};
         $self->log("Status URL: $url");

         # Open it up in a browser
         if ($self->open_status_url) {
            require Browser::Open;
            Browser::Open::open_browser($url);
         }

         last;
      }

      $self->log_fatal("Waited over 5 minutes and TravisCI still hasn't even seen the new commit yet!") if (time - $start_time > 5*60);
      sleep 10;
   };

   $self->_set_time_prefix($start_time);

   # Get a relative idea of test duration for polling time
   my $last_test_duration =
      str2time($prev_repo_info->{last_build_finished_at}, 'GMT') -
      str2time($prev_repo_info->{last_build_started_at},  'GMT')
   ;
   $last_test_duration = 5*60 if $last_test_duration <= 0;

   my $poll_freq = int($last_test_duration / 4);
   $poll_freq = 10  if $poll_freq < 10;
   $poll_freq = 120 if $poll_freq > 120;

   my $build_id = $build_summary_info->{id};

   # Another polling loop with the build status
   my $prev_build_info;
   $start_time = time;
   while (1) {
      my $build_info = $self->travisci_api_get_build($build_id);
      $self->_set_time_prefix($start_time);

      # make sure the job actually started
      unless ($build_info->{started_at}) {
         $self->log('   Waiting to start...');
         sleep $poll_freq * 2;
         $self->log_fatal("Waited over an hour and the build still hasn't started yet!") if (time - $start_time > 60*60);
         next;
      }
      elsif (!$build_summary_info->{started_at}) {
         $self->_set_time_prefix($start_time = time);
         my $build_time = str2time($build_info->{started_at}, 'GMT');
         $self->log([ 'Build %u started at %s', $build_summary_info->{number}, time2str('%l:%M%p', $build_time) ]);
      }

      # transplant the build info into the summary
      $build_summary_info = {
         %$build_summary_info,
         map { $_ => $build_info->{$_} if exists $build_info->{$_} } keys %$build_summary_info
      };

      # aggregiate job details
      my @matrix   = @{ $build_info->{matrix} };
      my @started  = grep { defined $_->{started_at}  } @matrix;
      my @finished = grep { defined $_->{finished_at} } @matrix;

      my $pending    = int @matrix  - @started;
      my $running    = int @started - @finished;
      my $finished   = int @finished;
      my $passed     = int scalar grep { $RESULT_MAP{ $_->{result} // '' } eq 'Pass' } @finished;
      my $allow_fail = int scalar grep { $RESULT_MAP{ $_->{result} // '' } ne 'Pass' &&  $_->{allow_failure} } @finished;
      my $failed     = int scalar grep { $RESULT_MAP{ $_->{result} // '' } ne 'Pass' && !$_->{allow_failure} } @finished;

      $running = 0 if $running < 0;

      my @job_status;
      push @job_status, sprintf('%u jobs pending', $pending) if $pending;
      push @job_status, sprintf('%u jobs running', $running) if $running;

      if ($finished) {
         push @job_status, sprintf('%u jobs finished', $finished);
         push @job_status,
            $allow_fail ?
               sprintf('%u/%u/%u jobs passed/failed/allowed to fail', $passed, $failed, $allow_fail) :
               sprintf('%u/%u jobs passed/failed', $passed, $failed)
         ;
      }

      # fake a $prev_build_info if it doesn't exist
      unless ($prev_build_info) {
         $prev_build_info = dclone $build_info;
         foreach my $job (@{ $prev_build_info->{matrix} }) {
            $job->{started_at}  = undef;
            $job->{finished_at} = undef;
            $job->{result}      = undef;
         }
      }

      # individual job updates
      my %prev_matrix = map { $_->{number} => $_ } @{ $prev_build_info->{matrix} };

      foreach my $job (@matrix) {
         my $prev = $prev_matrix{ $job->{number} };

         # jobs that have started
         if (!defined $prev->{started_at} && defined $job->{started_at}) {
            my $config = $job->{config};
            my @config_label;
            push @config_label, 'Perl '.$config->{perl} if $config->{perl};
            push @config_label, $config->{env} if $config->{env};

            $self->log(['   Job %s%s started at %s',
               $job->{number},
               (@config_label ? ' ('.join(', ', @config_label).')' : ''),
               time2str('%l:%M%p', str2time($job->{started_at}, 'GMT') ),
            ]);
         }

         # jobs that have finished
         if    (!defined $prev->{finished_at} && defined $job->{finished_at}) {
            my $result = $RESULT_MAP{ $job->{result} // '' };
            $result .= ' (allowed)' if ($result eq 'Fail' && $job->{allow_failure});

            my $finish_time = str2time($job->{finished_at}, 'GMT');

            $self->log(['   Job %s finished at %s with a status of %s', $job->{number}, time2str('%l:%M%p', $finish_time), $result ]);
         }
      }
      $prev_build_info = $build_info;

      $self->log('   === '.join(', ', @job_status));

      ### NOTE: Travis' Fast Finish feature will already speed up the build status, so just honor that feature and don't use
      ### $failed to determine if the build is finished.

      # figure out if we need to exit or not
      if ($build_info->{state} eq 'finished') {
         my $result = $RESULT_MAP{ $build_info->{result} };

         my $finish_time = str2time($build_info->{finished_at}, 'GMT');

         $self->log([ 'Build %u finished at %s with a status of %s', $build_info->{number}, time2str('%l:%M%p', $finish_time), $result ]);
         $self->logger->set_prefix('');

         $self->log_fatal("Travis CI build didn't pass!") unless $result eq 'Pass';
         last;
      }

      $self->log_fatal("Waited over an hour and the build still hasn't finished yet!") if (time - $start_time > 60*60);

      $poll_freq = int($poll_freq / 2) if ($finished && !$pending || time - $start_time >= $last_test_duration * 0.75);
      $poll_freq = 10 if $poll_freq < 10;
      sleep $poll_freq;
   };

   return 1;
}

sub travisci_api_get_repo {
   my ($self) = @_;

   my $result = $self->_travis_ua->get('/repos/'.$self->slug);
   $self->log_fatal("Travis CI API reported back with: $result") unless $result->content_type eq 'application/json';

   my $repo_info = $result->content_json;
   $self->log_fatal("Travis CI cannot find your repository; did you forget to configure it?")
      if ($repo_info->{file} && $repo_info->{file} eq 'not found');

   # {
   #   description => "Distro description",
   #   id => 999999,
   #   last_build_duration => 3387,
   #   last_build_finished_at => "2055-05-05T55:55:55Z",
   #   last_build_id => 55555555,
   #   last_build_language => undef,
   #   last_build_number => 55,
   #   last_build_result => 0,
   #   last_build_started_at => "2055-05-05T55:55:55Z",
   #   last_build_status => 0,
   #   public_key => "-----BEGIN RSA PUBLIC KEY-----\nXXXXXXX\n-----END RSA PUBLIC KEY-----\n",
   #   slug => "Name/Distro"
   # }

   return $repo_info;
}

sub travisci_api_get_build {
   my ($self, $build_id) = @_;

   # This is also used to get a build list (without a $build_id)
   my $result = $self->_travis_ua->get('/repos/'.$self->slug."/builds".($build_id ? "/$build_id" : ''));
   $self->log_fatal("Travis CI API reported back with: $result") unless $result->content_type eq 'application/json';

   my $build_info = $result->content_json;
   $self->log_fatal("Travis CI cannot find your build?!?")
      if (ref $build_info eq 'HASH' && $build_info->{file} && $build_info->{file} eq 'not found');

   # Without $build_id (a list of these):
   # {
   #   branch => "release_testing/master",
   #   commit => "ffffffffffffffffffffffffffffffffffffffff",
   #   duration => undef,
   #   event_type => "push",
   #   finished_at => undef,
   #   id => 99999999,
   #   message => "Travis release testing for local branch master",
   #   number => 99,
   #   repository_id => 999999,
   #   result => undef,
   #   started_at => undef,
   #   state => "created"
   # },

   # With $build_id:
   # {
   #   author_email => "asd\@asd.com",
   #   author_name => "First Last",
   #   branch => "release_testing/master",
   #   commit => "ffffffffffffffffffffffffffffffffffffffff",
   #   committed_at => "2055-05-05T55:05:05Z",
   #   committer_email => "asd\@asd.com",
   #   committer_name => "First Last",
   #   compare_url => "https://github.com/Name/Distro/compare/ffffffffffff...ffffffffffff",
   #   config => {},
   #   duration => undef,
   #   event_type => "push",
   #   finished_at => undef,
   #   id => 99999999,
   #   matrix => [],
   #   message => "Travis release testing for local branch master",
   #   number => 99,
   #   repository_id => 999999,
   #   result => undef,
   #   started_at => undef,
   #   state => "created",
   #   status => undef
   # }

   return $build_info;
}

sub _set_time_prefix {
   my ($self, $start_time) = @_;
   my $time_diff = time - $start_time;
   my $min = int($time_diff / 60);
   my $sec = $time_diff % 60;

   $self->logger->set_prefix( sprintf('(%02u:%02u) ', $min, $sec) );
}

__PACKAGE__->meta->make_immutable;
42;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Travis::TestRelease - makes sure repo passes Travis tests before release

=head1 SYNOPSIS

    ;;; Test DZIL
 
    [Travis::TestRelease]
    ; defaults typically work fine
 
    ;;; Test DZIL+build
 
    [TravisYML]
    support_builddir = 1
    ; (optional) only test with Travis::TestRelease
    dzil_branch = /^release_testing\/.*/
 
    [Travis::TestRelease]
    create_builddir = 1

=head1 DESCRIPTION

Tired of releasing a module only to discover that it failed Travis tests?  This plugin solves that problem.

It pushes a release testing branch to Travis, monitors the testing, and aborts the release if the Travis build fails.  It also
supports testing the non-DZIL build directory directly.

L<TravisYML|Dist::Zilla::Plugin::TravisYML> is not required to use this plugin, even for build testing, but is still recommended.

=head1 DETAILS

Starting the process requires creating and pushing a release testing branch to GitHub.  This is done through a series of git
commands, designed to work with the dirtiest of branch states:

=over

=item 1.

If there are any "dirty files", even untracked files, put them into a git stash.

=item 2.

Create or hard reset the release testing branch to match the main branch.

=item 3.

Apply the stash (if created) and add any new files.

=item 4.

If a build directory is requested, extract it into .buildE<sol>testing, and add it.

=item 5.

Commit the changes.

=item 6.

Force push the testing branch to the repo.

=item 7.

Switch back to the main branch.

=item 8.

If any files were stashed, apply it back to the branch.  This is done by hard resetting the main branch to the stash (don't panic;
it's just a copy of the branch with a few extra commits), and then walking the index back to the refhash it was at originally.

=back

As you may notice, the testing branch is subject to harsh and overwriting changes, so B<don't rely on the branch for anything except
release testing!>

After the branch is pushed, the plugin checks Travis (via API) to make sure it starts testing.  Monitoring stops when Travis says
the build is finished.  Use of L<Travis' Fast Finish option|http://docs.travis-ci.com/user/build-configuration/#Fast-finishing> is
recommended to speed up test results.

=head1 OPTIONS

=head2 remote

Name of the remote repo.

The default is C<<< origin >>>.

=head2 branch

Name of the local release testing branch.  B<Do not use this branch for anything except release testing!>

The default is C<<< release_testing/$current_branch >>>.

=head2 remote_branch

Name of the remote branch.

The default is whatever the C<<< branch >>> option is set to.

=head2 slug

Name of the "slug", or usernameE<sol>repo combo, that will be used to query the test details.  For example, this distro has a slug of
C<<< SineSwiper/Dist-Zilla-TravisCI >>>.

The default is auto-detection of the slug using the remote URL.

=head2 create_builddir

Boolean; determines whether to create a build directory or not.  If turned on, the plugin will create a C<<< .build/testing >>>
directory in the testing branch to be used for build testing.  Whether this is actually used depends on the C<<< .travis.yml >>> file.
For example, L<TravisYML|Dist::Zilla::Plugin::TravisYML>'s C<<< support_builddir >>> switch will create a Travis matrix in the YAML file
to test both DZIL and build directories on the same git branch.  If you're not using that plugin, you should at least implement
something similar to make use of dual DZIL+build tests.

Default is off.

=head2 open_status_url

Boolean; determines whether to automatically open the Travis CI build status URL to a browser, using L<Browser::Open>.

Default is off.

=head1 CAVEATS

Plugin order is important.  Since Travis build testing takes several minutes, this should be one of the last C<<< before_release >>>
plugins in your dist.ini, after plugins like L<TestRelease|Dist::Zilla::Plugin::TestRelease>, but still just before
L<ConfirmRelease|Dist::Zilla::Plugin::ConfirmRelease>.

The amount of git magic and little used switches required to make and push the branch to GitHub may be considered questionable by
some, especially force pushes and hard resets.  But it is all required to make sure testing occurs from any sort of branch state.
And it works.

Furthermore, it's not the job of this plugin to make sure the branch state is clean.  Use plugins like
L<Git::Check|Dist::Zilla::Plugin::Git::Check> for that.

=head1 AVAILABILITY

The project homepage is L<https://github.com/SineSwiper/Dist-Zilla-TravisCI>.

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<https://metacpan.org/module/Dist::Zilla::TravisCI/>.

=head1 AUTHOR

Brendan Byrd <bbyrd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Brendan Byrd.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
