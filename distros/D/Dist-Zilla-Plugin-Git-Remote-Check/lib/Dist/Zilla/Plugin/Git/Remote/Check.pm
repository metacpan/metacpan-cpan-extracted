use strict;
use warnings;

package Dist::Zilla::Plugin::Git::Remote::Check;
BEGIN {
  $Dist::Zilla::Plugin::Git::Remote::Check::AUTHORITY = 'cpan:KENTNL';
}
{
  $Dist::Zilla::Plugin::Git::Remote::Check::VERSION = '0.1.2';
}

# ABSTRACT: Ensure no pending commits on a remote branch before release

use Moose;



with 'Dist::Zilla::Role::BeforeRelease';


sub before_release {
  my $self = shift;
  $self->remote_update;
  $self->check_remote;
  return 1;
}


with 'Dist::Zilla::Role::Git::LocalRepository';



with 'Dist::Zilla::Role::Git::Remote';


with 'Dist::Zilla::Role::Git::Remote::Branch';


with 'Dist::Zilla::Role::Git::Remote::Update';


has 'branch' => ( isa => 'Str', is => 'rw', default => 'master' );


with 'Dist::Zilla::Role::Git::Remote::Check';

has '+_remote_branch' => ( lazy => 1, default => sub { shift->branch } );

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__
=pod

=head1 NAME

Dist::Zilla::Plugin::Git::Remote::Check - Ensure no pending commits on a remote branch before release

=head1 VERSION

version 0.1.2

=head1 SYNOPSIS

  [Git::Remote::Check]
   ; Provided by Dist::Zilla::Role::Git::Remote
  ; String
  ; The name of the remote to update.
  ; Must exist in Git.
  ; default is 'origin'
  remote_name = origin

  ; Provided by Dist::Zilla::Role::Git::Remote::Update
  ; Boolean
  ; turn updating on/off
  ; default is 'on' ( 1 / true )
  do_update = 1

  ; Provided by Dist::Zilla::Role::Git::Remote::Branch
  ; String
  ; the name of the branch on the remote side to check against
  ; default is the same value us 'branch'
  remote_branch = master

  ; String
  ; the name of the branch on the local side to check.
  ; default is 'master'
  branch = master

  ; Provided by Dist::Zilla::Role::Git::Remote::Check;
  ; Int
  ; How many of the most recent commits to dump when we're behind upstream.
  ; default = 5
  report_commits = 5

=head1 PARAMETERS

=head2 C<remote_name>

The name of the repository to use as specified in C<.git/config>.

Defaults to C<origin>, which is usually what you want.

=head2 C<remote_branch>

The branch name on the remote.

e.g.: For C<origin/master> use C<master> with C<remote_name = origin>

Defaults to the same value as L</branch>

=head2 C<do_update>

A boolean value that specifies whether or not to execute the update.

Default value is C<1> / true.

=head2 C<branch>

The local branch to check against the remote one. Defaults to 'master'

=head2 C<report_commits>

In the event the remote is ahead, this C<Int> dictates the maximum number of
commits to print to output.

Defaults to C<5>

=head1 METHODS

=head2 C<before_release>

Executes code before releasing.

=over 4

=item 1.

Updates the L</remote> via L<Dist::Zilla::Role::Git::Remote::Update/remote_update>

=item 2.

Checks the L</remote> via L<Dist::Zilla::Role::Git::Remote::Check/check_remote>

=back

=head2 C<git>

Returns a L<Git::Wrapper> instance for the current L<Dist::Zilla> projects
C<git> Repository.

=head2 C<remote>

Returns a validated remote name. Configured via L</remote_name> parameter.

=head2 C<remote_branch>

Returns a fully qualified branch name for the parameter specified as
C<remote_branch> by combining it with L</remote>, and defaulting to the value of
L</branch> if not assigned explicitly.

=head2 C<remote_update>

Performs C<git remote update $remote_name> on L</git> for the remote L</remote>

=head2 C<branch>

The local branch to check against the remote one. Defaults to 'master'

=head2 C<check_remote>

Compare L</branch> and L</remote_branch> making sure that L</branch> is the more
recent of the 2.

=head1 ROLES

=head2 C<Dist::Zilla::Role::BeforeRelease>

Causes this plugin to be executed during L<Dist::Zilla>'s "Before Re,ease" phase.
( L</before_release> )

=head2 C<Dist::Zilla::Role::Git::LocalRepository>

Provides a L</git> method that returns a C<Git::Wrapper> instance for the
current C<Dist::Zilla> project.

=head2 C<Dist::Zilla::Role::Git::Remote>

Provides a L</remote> method which always returns a validated C<remote> name,
optionally accepting it being specified manually to something other than
C<origin> via the parameter L</remote_name>

=head2 C<Dist::Zilla::Role::Git::Remote::Branch>

Provides a L</remote_branch> method which combines the value returned by
L</remote> with a user specified branch name and returns a fully qualified
remote branch name.

=head2 C<Dist::Zilla::Role::Git::Remote::Update>

Provides a L</remote_update> method which updates a L</remote> in L</git>

=head2 C<Dist::Zilla::Role::Git::Remote::Check>

Provides L</check_remote> which compares L</branch> and L</remote_branch> and
asserts L</remote_branch> is not ahead of L</branch>

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Kent Fredric <kentnl@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

