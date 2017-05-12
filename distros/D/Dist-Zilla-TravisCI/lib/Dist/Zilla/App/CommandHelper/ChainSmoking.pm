package Dist::Zilla::App::CommandHelper::ChainSmoking;

our $AUTHORITY = 'cpan:BBYRD'; # AUTHORITY
our $VERSION = '1.15'; # VERSION
# ABSTRACT: Helper class for chainsmoke command

use v5.10;
use Moose;

use List::AllUtils 'first';

use Dist::Zilla::Util::Git::Bundle;

# dzil chainsmoke has to pass this, and we can figure out the rest
has app => ( isa => 'Object', is => 'ro', required => 1 );

sub zilla { shift->app->zilla }

has logger => (
   is      => 'ro',
   lazy    => 1,
   handles => [ qw(log log_debug log_fatal) ],
   default => sub { shift->zilla->logger },
);

has git_bundle => (
   is      => 'ro',
   isa     => 'Dist::Zilla::Util::Git::Bundle',
   lazy    => 1,
   handles => [ qw( git ) ],
   default => sub {
      my $self = shift;
      Dist::Zilla::Util::Git::Bundle->new( zilla => $self->zilla );
   },
);

with 'Dist::Zilla::Role::TravisYML';

sub chainsmoke {
   my ($self, $opt) = @_;
   my $gb = $self->git_bundle;

   # have Git::Check verify there are no dirty files, etc.
   $gb->check_local;

   # have Git::Remote::Check verify the branch is up to date
   unless ($gb->is_remote_branch_new) {
      $self->git->remote('update', $gb->remote);
      $gb->check_remote;
   }

   # checks are done, so create the YML
   my $yml_creator = first { $_->isa('Dist::Zilla::Plugin::TravisYML') } @{$self->zilla->plugins};

   # doesn't appear to be in dist.ini, so set based on $opt
   $self->build_branch('');
   unless ($yml_creator) {
      if ($opt->silentci) {
         $self->notify_email([0]);
         $self->notify_irc  ([0]);
      }
      $self->mvdt(1) if $opt->mvdt;
   }
   # else modify the options via the plugin
   else {
      $self->notify_email ($opt->silentci ? [0] : $yml_creator->notify_email );
      $self->notify_irc   ($opt->silentci ? [0] : $yml_creator->notify_irc   );
      $self->mvdt         ($opt->mvdt     ? 1   : $yml_creator->mvdt         );
   }

   # in order to access the prereqs and distmeta in general,
   # we need to partially run through the build process

   ### TODO: Make some extra checks to see if we even need the distmeta object. ###
   ###       We only need it for notification detection and MVDT.               ###
   $self->log("\nStarting pre-build...");
   $self->prebuild;
   $self->log("Done with pre-build\n");

   # actual creation
   $self->build_travis_yml;
   $self->log("YML file built");

   # now for the Git commit/push
   $self->git->add('.travis.yml');
   $self->log_debug($_) for $self->git->commit(
      { message => 'Chain smoking for local branch '.$gb->branch },
      '--allow-empty',  # because it might be ran multiple times without changes
   );
   $self->log('Committed');

   $self->log_debug($_) for $self->git->push( $gb->remote, 'HEAD:'.$gb->_remote_branch );
   $self->log('Pushed');
}

### FIXME: Mostly a copy from D:Z:D:B->build_in; will put in ticket to add in a separate method ###
sub prebuild {
   my $self = shift;
   my $zilla = $self->zilla;

   $_->before_build     for @{ $zilla->plugins_with(-BeforeBuild ) };
   $_->gather_files     for @{ $zilla->plugins_with(-FileGatherer) };
   $_->prune_files      for @{ $zilla->plugins_with(-FilePruner  ) };
   $_->munge_files      for @{ $zilla->plugins_with(-FileMunger  ) };
   $_->register_prereqs for @{ $zilla->plugins_with(-PrereqSource) };

   $zilla->prereqs->finalize;
}

42;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::App::CommandHelper::ChainSmoking - Helper class for chainsmoke command

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
