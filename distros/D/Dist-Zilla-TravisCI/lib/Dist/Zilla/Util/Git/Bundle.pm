package Dist::Zilla::Util::Git::Bundle;

our $AUTHORITY = 'cpan:BBYRD'; # AUTHORITY
our $VERSION = '1.15'; # VERSION
# ABSTRACT: Helper class with misc git methods

use v5.10;
use Moose;

use List::AllUtils 'first';
use File::pushd ();
use File::Copy ();
use Archive::Tar;
use Try::Tiny;

use Dist::Zilla::Util::Git::Wrapper;

has zilla => (
   isa      => 'Dist::Zilla',
   is       => 'ro',
   required => 1,
);

has logger => (
   is      => 'ro',
   lazy    => 1,
   handles => [ qw(log log_debug log_fatal) ],
   default => sub { shift->zilla->logger },
);

has branch => (
   isa     => 'Str',
   is      => 'rw',
   lazy    => 1,
   default => sub { shift->current_branch },
);

has _git_wrapper_util => (
   isa     => 'Dist::Zilla::Util::Git::Wrapper',
   is      => 'ro',
   lazy    => 1,
   handles => [ qw(git) ],
   default => sub { Dist::Zilla::Util::Git::Wrapper->new( zilla => shift->zilla ); },
);

### HACK: Needed for DirtyFiles, though this is really only used for Plugins ###
sub mvp_multivalue_args { }
### HACK: Ditto for ...::Git::Repo (expects 'Dist::Zilla::Role::ConfigDumper').
sub dump_config { return {} }

with 'Dist::Zilla::Role::Git::Repo';
with 'Dist::Zilla::Role::Git::DirtyFiles';
sub _build_allow_dirty { [ ] }  # overload

with 'Dist::Zilla::Role::Git::Remote';
with 'Dist::Zilla::Role::Git::Remote::Branch';
with 'Dist::Zilla::Role::Git::Remote::Check';

has '+_remote_branch' => ( lazy => 1, default => sub { shift->branch } );

sub current_branch {
   my ($branch) = shift->git->symbolic_ref({ quiet => 1 }, 'HEAD');
   $branch =~ s|^refs/heads/||;
   return $branch;
}

### LAZY: This is pretty much a straight copy of Dist::Zilla::Plugin::Git::Check. ###
sub check_local {
   my $self = shift;
   my $git = $self->git;
   my @output;

   # fetch current branch
   my $branch = $self->current_branch;

   # check if some changes are staged for commit
   @output = $git->diff( { cached=>1, 'name-status'=>1 } );
   if ( @output ) {
      my $errmsg =
         "branch $branch has some changes staged for commit:\n" .
         join "\n", map { "\t$_" } @output;
      $self->log_fatal($errmsg);
   }

   # everything but files listed in allow_dirty should be in a
   # clean state
   @output = $self->list_dirty_files($git);
   if ( @output ) {
      my $errmsg =
         "branch $branch has some uncommitted files:\n" .
         join "\n", map { "\t$_" } @output;
      $self->log_fatal($errmsg);
   }

   # no files should be untracked
   @output = $git->ls_files( { others=>1, 'exclude-standard'=>1 } );
   if ( @output ) {
      my $errmsg =
         "branch $branch has some untracked files:\n" .
         join "\n", map { "\t$_" } @output;
      $self->log_fatal($errmsg);
   }
}

sub is_local_branch_new {
   my ($self, $lb) = @_;
   my $git  = $self->git;
   $lb //= $self->branch;
   return ( first { s/^\*?\s+//; $_ eq $lb } $git->branch ) ? 0 : 1;
}

sub is_remote_branch_new {
   my ($self, $rb) = @_;
   my $git  = $self->git;
   $rb //= $self->remote_branch;
   return ( first { /^\s*\Q$rb\E\s*$/ } $git->branch({ remotes => 1 }) ) ? 0 : 1;
}

# Stolen and warped from Dist::Zilla::Plugin::GithubMeta
sub acquire_github_repo_info {
   my $self = shift;

   my $git_url;
   my $remote = $self->remote;

   # Missing remotes expand to the same value as they were input
   unless ($git_url = $self->url_for_remote($remote) and $remote ne $git_url) {
      $self->log(["A remote named '%s' was specified, but does not appear to exist.", $remote]);
      return;
   }

   # Not a Github Repository?
   unless ($git_url =~ m!\bgithub\.com[:/]!) {
      $self->log([
         'Specified remote \'%s\' expanded to \'%s\', which is not a github repository URL',
         $remote, $git_url,
      ]);
      return;
   }

   my ($user, $repo) = $git_url =~ m{
      github\.com              # the domain
      [:/] ([^/]+)             # the username (: for ssh, / for http)
      /    ([^/]+?) (?:\.git)? # the repo name
      $
   }ix;

   $self->log(['No user could be discerned from URL: \'%s\'',       $git_url]) unless defined $user;
   $self->log(['No repository could be discerned from URL: \'%s\'', $git_url]) unless defined $repo;
   return unless defined $user and defined $repo;

   return ($user, $repo);
}

sub url_for_remote {
   my ($self, $remote) = @_;
   foreach my $line ( $self->git->remote('show', { n => 1 }, $remote) ) {
      chomp $line;
      return $1 if ($line =~ /^\s*(?:Fetch)?\s*URL:\s*(.*)/);
   }
   return;
}

# Copies the current branch to a different local branch, and force pushes it to the remote
sub dirty_branch_push {
   my ($self, %params) = @_;

   my $create_builddir = $params{create_builddir} || 0;
   my $commit_reason   = $params{commit_reason} || 'Travis testing';
   my $tgz             = $params{tgz} || Path::Class::file( $self->zilla->name.'-'.$self->zilla->version.'.tar.gz' );
   my $pre_remote_code = $params{pre_remote_code};

   my $git = $self->git;

   ### Sanity checks

   my $current_branch = $self->current_branch;
   my $testing_branch = $self->branch;

   $self->log_fatal('Must be in a branch!') unless $current_branch;
   $self->log_fatal('Must not be in the testing branch!') if ($current_branch eq $testing_branch);

   ### Local setup

   ### TODO: Replace all of these log_debugs with an overloaded Git::Wrapper object

   # Get the last refhash, as we'll need it for our "hard stash pop"
   my ($refhash) = $git->rev_parse({ verify => 1 }, 'HEAD');

   # Stash any leftover files
   $self->log("Stashing any files and switching to '$testing_branch' branch...");
   my $has_changed_files = scalar (
      $git->diff({ cached => 1, name_status => 1 }),
      $git->ls_files({
         modified => 1,
         deleted  => 1,
         others   => 1,
      }),
   );
   if ($has_changed_files) {
      $self->log_debug($_) for $git->stash(save => {
         # save everything, including untracked and ignored files
         all               => 1,
      }, "Stash of changed/untracked files for $commit_reason");
   }

   # Entering a try/catch, so that we can back out any git changes before we die
   try {
      # Sync up the release_testing branch with the main branch
      if ($self->is_local_branch_new) {
         $self->log_debug($_) for $git->checkout({ b => 1 }, $testing_branch, $current_branch);
      }
      else {
         $self->log_debug($_) for $git->checkout($testing_branch);
         $self->log_debug($_) for $git->reset({ hard => 1 }, $current_branch);
      }

      if ($has_changed_files) {
         $self->log_debug($_) for $git->stash('apply');
         $self->log_debug($_) for $git->add({ all => 1 }, '.');
      }

      # Add in the build directory, if requested
      if ($create_builddir && -e $tgz) {
         my $build_dir = $self->zilla->root->subdir('.build');
         $build_dir->mkpath unless -d $build_dir;

         $self->log("Extracting $tgz to ".$build_dir->subdir('testing')->stringify);

         $tgz = $tgz->absolute;
         my @files = do {
            my $wd = File::pushd::pushd($build_dir);
            Archive::Tar->extract_archive("$tgz");
            File::Copy::move( $self->zilla->dist_basename, 'testing' );
            undef $wd;  # just to satisfy unused-vars.t
         };

         $self->log_fatal([ "Failed to extract archive: %s", Archive::Tar->error ]) unless @files;

         $self->log_debug($_) for $git->add({
            all   => 1,
            force => 1,  # this is probably already on the .gitignore list
         }, $build_dir->relative->stringify);
      }

      $self->log_debug($_) for $git->commit({
         all         => 1,
         allow_empty => 1,  # because it might be ran multiple times without changes
         message     => ucfirst($commit_reason)." for local branch $current_branch",
      });

      # final check
      $self->check_local;
      $self->log("Local branch cleanup complete!");

      $pre_remote_code->() if $pre_remote_code;

      ### Remote setup

      # Verify the branch is up to date
      $git->remote('update', $self->remote) unless $self->is_remote_branch_new;

      # Push it to the remote
      # (force because we are probably overwriting history of the testing branch)
      $self->log_debug($_) for $git->push({ force => 1 }, $self->remote, 'HEAD:'.$self->_remote_branch);
      $self->log('Pushed to remote repo!');

      $self->log("Switching back to '$current_branch' branch...");
      $self->log_debug($_) for $git->checkout($current_branch);

      ### XXX: Okay, so "git stash pop" just won't work when the files already exist.  However, we just stashed this thing and we
      ### know it was copied from the current branch.  A stash is the same as the branch except with a few extra commits.

      ### Let's force the branch to the stash itself, and then walk the index back a few steps.

      if ($has_changed_files) {
         $self->log_debug($_) for $git->reset({ hard => 1 }, 'stash@{0}');
         $self->log_debug($_) for $git->reset($refhash);
         $self->log_debug($_) for $git->stash('drop', 'stash@{0}');
      }
   }
   catch {
      # make sure nothing is dangling, get back to the old checkout, and reverse the stash
      my $error = $_;

      $self->log('Caught an error; backing out...');
      $self->log_debug($_) for $git->reset({ hard => 1 });
      $self->log_debug($_) for $git->checkout($current_branch);
      if ($has_changed_files) {
         $self->log_debug($_) for $git->reset({ hard => 1 }, 'stash@{0}');
         $self->log_debug($_) for $git->reset($refhash);
         $self->log_debug($_) for $git->stash('drop', 'stash@{0}');
      }
      $self->log('Backout complete!');

      die $error;
   };

}

42;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Util::Git::Bundle - Helper class with misc git methods

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
