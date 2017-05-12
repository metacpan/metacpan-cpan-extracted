package Dist::Zilla::App::Command::chainsmoke;

our $AUTHORITY = 'cpan:BBYRD'; # AUTHORITY
our $VERSION = '1.15'; # VERSION
# ABSTRACT: continuously smoke your dist on your CI server

use v5.10;
use strict;
use warnings;

use Dist::Zilla::App -command;

sub opt_spec {
   return (
      [ 'mvdt'            => 'enables minimum version dependency testing (if not already enabled in dist.ini)', { default => 0 }  ],
      [ 'silentci'        => 'disables any CI notification',                                                    { default => 0 }  ],
      [ 'remote_branch=s' => 'specify a different remote branch, instead of "origin/{local_branch}"',           { default => '' } ],
   );
}

sub abstract { 'continuously smoke your dist on your CI server' }

sub execute {
   my ($self, $opt) = @_;

   require Dist::Zilla::App::CommandHelper::ChainSmoking;

   my $cs = Dist::Zilla::App::CommandHelper::ChainSmoking->new( app => $self->app );
   my $gb = $cs->git_bundle;

   # Remote branch option negotating
   if ($opt->remote_branch) {
      my ($remote, $rbranch) = split(qr|/|, $opt->remote_branch, 2);
      die "The --remote_branch option must be in {remote}/{branch} format!"
         unless $rbranch;

      $gb->_remote_name($remote);
      $gb->_remote_branch($rbranch);
   }
   elsif ($gb->branch =~ /^(?:master|stable)$/) {
      $gb->_remote_branch('chainsmoking/'.($opt->mvdt ? 'mvdt' : $gb->branch));
   }

   # Surgeon General's warning regardless of --remote_branch option
   if ($gb->branch =~ /^(?:master|stable)$/) {
      my $confirmed = $self->zilla->chrome->prompt_yn(
        "Caution: Chain smoking while on branch '".$gb->branch."' may be hazardous to your health.\n".
        "The remote branch has been set to '".$gb->remote_branch."'.\n".
        "Do you want to continue anyway?",
        { default => 0 }
      );

      exit unless $confirmed;
   }

   $cs->chainsmoke($opt);
}

42;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::App::Command::chainsmoke - continuously smoke your dist on your CI server

=head1 SYNOPSIS

   dzil chainsmoke [ --mvdt ] [ --silentci ] [ --remote_branch {remote}/{branch} ]

=head1 DESCRIPTION

This command smokes the distribution on TravisCI, by rebuilding the YML file, adding a commit,
and pushing the branch.  The branch is checked for dirty files and remote freshness prior to
chain smoking, as a safeguard against Git mistakes.  Unlike the plugin version, this doesn't
add anything to the build directory.

Of course, you still need to turn on TravisCI and the remote still needs to be a GitHub repo
for any of this to work.

=head1 OPTIONS

=head2 --mvdt

This enables the L<minimum version dependency testing feature|Dist::Zilla::TravisCI::MVDT>
from the plugin.  It is HIGHLY recommended that you read up on this feature first, and if this
is the first time doing these tests on this distro (which the option implies), you should
start a new topic branch first, to prevent history pollution on your master/stable branch.

=head2 --silentci

This will turn off all notification (email or IRC) from Travis-CI for the test.  Useful if
you are running through MVDT and you don't want a lot of spam from it.  You will, of course,
need to watch for test results from Travis as they happen.

=head2 --remote_branch {remote/branch}

This allows you to specify a remote branch to push to.  The default is the same branch that
your currently in, via 'origin'.

As a safeguard, the default is changed to 'origin/chainsmoking/{local}' while on 'master' or
'stable', or 'origin/chainsmoking/mvdt' if you specify C<--mvdt> without a C<--remote_branch>
option.  But, you should really just create/switch the local branch yourself to keep from
polluting your local repo's master history.

=head1 CHAIN SMOKING?

   SineSwiper: rjbs: so, I think I'm going to make this Travis-CI plugin I'm making add in a command called "smokeci"
   SineSwiper: any comments on implementation?
   SineSwiper: the potential exists that other plugins could be made (which would be mutually exclusive, of course) that
               could interface with other CIs
   PerlJam: SineSwiper: what's smokeci do?  Is that like continuous smoking?  I'd call it "burn" or something if so :)
   SineSwiper: smoke testing on the CI
   SineSwiper: PerlJam: heh, continuous smoking
   SineSwiper: maybe I should call it chainsmoke
   PerlJam: SineSwiper++  yes! :)
   rjbs: haha
   SineSwiper: okay, that will be the command name
   SineSwiper: I hated the lack of punct between smoke and ci, anyway

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
