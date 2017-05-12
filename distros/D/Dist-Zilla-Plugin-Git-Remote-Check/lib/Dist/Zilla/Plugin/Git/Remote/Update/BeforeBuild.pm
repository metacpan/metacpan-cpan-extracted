use strict;
use warnings;

package Dist::Zilla::Plugin::Git::Remote::Update::BeforeBuild;
BEGIN {
  $Dist::Zilla::Plugin::Git::Remote::Update::BeforeBuild::AUTHORITY = 'cpan:KENTNL';
}
{
  $Dist::Zilla::Plugin::Git::Remote::Update::BeforeBuild::VERSION = '0.1.2';
}

# FILENAME: BeforeBuild.pm
# CREATED: 13/10/11 05:17:02 by Kent Fredric (kentnl) <kentfredric@gmail.com>
# ABSTRACT: Update a remote with Git before build.

use Moose;



with 'Dist::Zilla::Role::BeforeBuild';


sub before_build {
  my $self = shift;
  $self->remote_update;
  return 1;
}


with 'Dist::Zilla::Role::Git::LocalRepository';



with 'Dist::Zilla::Role::Git::Remote';


with 'Dist::Zilla::Role::Git::Remote::Update';

no Moose;
__PACKAGE__->meta->make_immutable;
1;


__END__
=pod

=head1 NAME

Dist::Zilla::Plugin::Git::Remote::Update::BeforeBuild - Update a remote with Git before build.

=head1 VERSION

version 0.1.2

=head1 SYNOPSIS

This Module is mostly intended to be used in conjunction with other things,
and won't on its own provide a lot of useful results.

Having this in your configuration will effectively cause git to run C<git remote update $remotename>
before you build, and remotes don't usually have any impact on things in the rest of DZil-land.

  [Git::Remote::Update::BeforeBuild]
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

=head1 PARAMETERS

=head2 C<remote_name>

The name of the repository to use as specified in C<.git/config>.

Defaults to C<origin>, which is usually what you want.

=head2 C<do_update>

A boolean value that specifies whether or not to execute the update.

Default value is C<1> / true.

=head1 METHODS

=head2 C<before_build>

Updates the L</remote> via L<Dist::Zilla::Role::Git::Remote::Update/remote_update>, before Building the release.

=head2 C<git>

Returns a L<Git::Wrapper> instance for the current L<Dist::Zilla> projects
C<git> Repository.

=head2 C<remote>

Returns a validated remote name. Configured via L</remote_name> parameter.

=head2 C<remote_update>

Performs C<git remote update $remote_name> on L</git> for the remote L</remote>

=head1 ROLES

=head2 C<Dist::Zilla::Role::BeforeBuild>

Causes this plugin to be executed during L<Dist::Zilla>'s "Before Build" phase.
( L</before_build> )

=head2 C<Dist::Zilla::Role::Git::LocalRepository>

Provides a L</git> method that returns a C<Git::Wrapper> instance for the
current C<Dist::Zilla> project.

=head2 C<Dist::Zilla::Role::Git::Remote>

Provides a L</remote> method which always returns a validated C<remote> name,
optionally accepting it being specified manually to something other than
C<origin> via the parameter L</remote_name>

=head2 C<Dist::Zilla::Role::Git::Remote::Update>

Provides a L</remote_update> method which updates a L</remote> in L</git>

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Kent Fredric <kentnl@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

