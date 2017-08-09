package Dist::Zilla::App::Command::installdeps;

use strict;
use warnings;
use Dist::Zilla::App -command;
use String::ShellQuote;

our $VERSION = '0.001';

sub abstract { 'Install author dependencies for a Dist::Zilla dist' }

sub opt_spec {
  [ 'root=s' => 'the root of the dist; defaults to .' ],
  [ 'install-command=s', 'command to run to install dependencies (e.g. "cpanm")' ],
  [ 'recommends!', 'install recommended dependencies', { default => 1 } ],
  [ 'suggests!', 'install suggested dependencies', { default => 0 } ],
}

# these subs mostly stolen from Dist::Zilla::App::Command::listdeps
sub prereqs {
  my ($self, $zilla) = @_;
  
  $_->before_build for @{ $zilla->plugins_with(-BeforeBuild) };
  $_->gather_files for @{ $zilla->plugins_with(-FileGatherer) };
  $_->set_file_encodings for @{ $zilla->plugins_with(-EncodingProvider) };
  $_->prune_files  for @{ $zilla->plugins_with(-FilePruner) };
  $_->munge_files  for @{ $zilla->plugins_with(-FileMunger) };
  $_->register_prereqs for @{ $zilla->plugins_with(-PrereqSource) };
  
  my $prereqs = $zilla->prereqs;
}

sub extract_dependencies {
  my ($self, $zilla, $phases, $opt) = @_;
  
  my $prereqs = $self->prereqs($zilla);
  
  require CPAN::Meta::Requirements;
  my $req = CPAN::Meta::Requirements->new;
  
  for my $phase (@$phases) {
    $req->add_requirements( $prereqs->requirements_for($phase, 'requires') );
    $req->add_requirements( $prereqs->requirements_for($phase, 'recommends') ) if $opt->recommends;
    $req->add_requirements( $prereqs->requirements_for($phase, 'suggests') )   if $opt->suggests;
  }
  
  my @required = grep { $_ ne 'perl' } $req->required_modules;
  require Module::Runtime;
  @required =
    grep {
      # Keep modules that can't be loaded or that don't have a $VERSION
      # matching our requirements
      ! eval {
        my $m = $_;
        # Will die if module is not installed
        Module::Runtime::require_module($m);
        # Returns true if $VERSION matches, so we will exclude the module
        $req->accepts_module($m => $m->VERSION)
      }
    } @required;
  
  my $versions = $req->as_string_hash;
  return map { $_ => $versions->{$_} } @required;
}

sub execute {
  my ($self, $opt, $arg) = @_;
  
  my $cmd = $opt->install_command || 'cpanm';
  
  # do authordeps pass in a fork so loaded modules aren't used in later build
  my $pid = fork // die "Fork failed: $!";
  if ($pid) {
    waitpid $pid, 0;
    exit $?>>8 if $?;
  } else {
    require Dist::Zilla::Path;
    require Dist::Zilla::Util::AuthorDeps;
    my $authordeps = Dist::Zilla::Util::AuthorDeps::extract_author_deps(
      Dist::Zilla::Path::path($opt->root // '.'), 1 # missing deps only
    );
    my @install_author;
    foreach my $rec (@$authordeps) {
      push @install_author, map "$_~$rec->{$_}", keys %$rec;
    }
    
    if (@install_author) {
      # user provided command needs to be passed to the shell
      my $author_cmd = $cmd . ' ' . shell_quote @install_author;
      # can't use zilla until after authordeps are satisfied
      $self->app->chrome->logger->log_debug("[DZ] installing author deps: $author_cmd");
      my $rc = system $author_cmd;
      die "Failed to execute $cmd: $!" if $rc < 0;
      die "Author deps installation failed with exit code " . ($rc >> 8) if $rc;
    }
    
    exit 0;
  }
  
  my @phases = qw(build test configure runtime develop);
  
  my %distdeps = $self->extract_dependencies($self->zilla, \@phases, $opt);
  my @install_dist = map "$_~$distdeps{$_}", keys %distdeps;
  
  if (@install_dist) {
    # user provided command needs to be passed to the shell
    my $dist_cmd = $cmd . ' ' . shell_quote @install_dist;
    $self->zilla->log_debug("installing distribution deps: $dist_cmd");
    my $rc = system $dist_cmd;
    die "Failed to execute $cmd: $!" if $rc < 0;
    die "Dependency installation failed with exit code " . ($rc >> 8) if $rc;
  }
}

1;

=head1 NAME

Dist::Zilla::App::Command::installdeps - Install author dependencies for a
Dist::Zilla dist

=head1 SYNOPSIS

  dzil installdeps [--install-command="cmd"] [--no-recommends] [--suggests]

=head1 DESCRIPTION

Installs all dependencies needed for building, testing, and releasing a
distribution managed by L<Dist::Zilla>. First authordeps needed to build the
distribution from F<dist.ini> are installed, then the distribution's
dependencies are installed, including the develop phase. Similar to running:

  dzil authordeps --missing | cpanm
  dzil listdeps --missing --author --cpanm-versions | cpanm

=head1 OPTIONS

=head2 --install-command

Command to run to install dependencies. Dependencies will be appended to the
end of the command in the L<format expected by cpanm|cpanm/"(arguments)">.
Defaults to just C<cpanm>.

=head2 --recommends / --no-recommends

Install recommended dependencies (or don't). Defaults to on.

=head2 --suggests / --no-suggests

Install suggested dependencies (or don't). Defaults to off.

=head1 BUGS

Report any issues on the public bugtracker.

=head1 AUTHOR

Dan Book <dbook@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Dan Book.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=head1 SEE ALSO

L<Dist::Zilla::App::Command::authordeps>,
L<Dist::Zilla::App::Command::listdeps>, L<Dist::Zilla::App::Command::stale>
