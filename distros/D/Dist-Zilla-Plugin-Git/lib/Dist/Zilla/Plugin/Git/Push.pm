#
# This file is part of Dist-Zilla-Plugin-Git
#
# This software is copyright (c) 2009 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use 5.008;
use strict;
use warnings;

package Dist::Zilla::Plugin::Git::Push;
# ABSTRACT: Push current branch

our $VERSION = '2.042';

use Moose;
use MooseX::Has::Sugar;
use MooseX::Types::Moose qw{ ArrayRef Str Bool };

use namespace::autoclean;

with 'Dist::Zilla::Role::BeforeRelease',
    'Dist::Zilla::Role::AfterRelease';
with 'Dist::Zilla::Role::Git::Repo',
    'Dist::Zilla::Role::GitConfig';

sub mvp_multivalue_args { qw(push_to) }

sub _git_config_mapping { +{
   push_to => '%{remote}s %{local_branch}s:%{remote_branch}s',
} }

# -- attributes

has remotes_must_exist => ( ro, isa=>Bool, default=>1 );

has push_to => (
  is   => 'ro',
  isa  => ArrayRef[Str],
  lazy => 1,
  default => sub { [ qw(origin) ] },
);

around dump_config => sub
{
    my $orig = shift;
    my $self = shift;

    my $config = $self->$orig;

    $config->{+__PACKAGE__} = {
        push_to => $self->push_to,
        remotes_must_exist => $self->remotes_must_exist ? 1 : 0,
    };

    return $config;
};

sub before_release {
    my $self = shift;

    return unless $self->remotes_must_exist;

    my %valid_remote = map { $_ => 1 } $self->git->remote;
    my @bad_remotes;

    # Make sure the remotes we'll be pushing to exist
    for my $remote_spec ( @{ $self->push_to } ) {
      (my $remote = $remote_spec) =~ s/\s.*//s; # Discard branch (if specified)
      if ($remote =~ m![:/]!) {
        # Appears to be a URL or path, don't check it
        $self->log("Will push to $remote (not checked)");
      } else {
        # Named remotes must exist
        push @bad_remotes, $remote unless $valid_remote{$remote};
      }
    }

    $self->log_fatal("These remotes do not exist: @bad_remotes")
        if @bad_remotes;
}


sub after_release {
    my $self = shift;
    my $git  = $self->git;

    # push everything on remote branch
    for my $remote ( @{ $self->push_to } ) {
      $self->log("pushing to $remote");
      my @remote = split(/\s+/,$remote);
      if (@remote == 1) {
        # Newer versions of Git may not push the current branch automatically.
        # Append the current branch since the remote didn't specify a branch.
        my $branch = $self->current_git_branch;
        unless (defined $branch) {
          $self->log("skipped push to @remote (can't determine branch to push)");
          next;
        }
        push @remote, $branch;
      }
      $self->log_debug($_) for $git->push( @remote );
      $self->log_debug($_) for $git->push( { tags=>1 },  $remote[0] );
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Git::Push - Push current branch

=head1 VERSION

version 2.042

=head1 SYNOPSIS

In your F<dist.ini>:

    [Git::Push]
    push_to = origin       ; this is the default
    push_to = origin HEAD:refs/heads/released ; also push to released branch
    remotes_must_exist = 1 ; this is the default

=head1 DESCRIPTION

Once the release is done, this plugin will push current git branch to
remote end, with the associated tags.

The plugin accepts the following options:

=over 4

=item *

push_to - the name of the a remote to push to. The default is F<origin>.
This may be specified multiple times to push to multiple repositories.

=item *

remotes_must_exist - if true, then Git::Push checks before a release
to ensure that all named remotes specified in C<push_to> are
configured in your repo.  The default is true.  Remotes specified as a
URL or path are not checked, but will produce a
C<Will push to %s (not checked)> message.

=back

=for Pod::Coverage after_release
    before_release
    mvp_multivalue_args

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-Git>
(or L<bug-Dist-Zilla-Plugin-Git@rt.cpan.org|mailto:bug-Dist-Zilla-Plugin-Git@rt.cpan.org>).

There is also a mailing list available for users of this distribution, at
L<http://dzil.org/#mailing-list>.

There is also an irc channel available for users of this distribution, at
L<C<#distzilla> on C<irc.perl.org>|irc://irc.perl.org/#distzilla>.

I am also usually active on irc, as 'ether' at C<irc.perl.org>.

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2009 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
