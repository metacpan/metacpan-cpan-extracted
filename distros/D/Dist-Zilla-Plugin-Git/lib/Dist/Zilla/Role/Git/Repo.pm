#
# This file is part of Dist-Zilla-Plugin-Git
#
# This software is copyright (c) 2009 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package Dist::Zilla::Role::Git::Repo;
# ABSTRACT: Provide repository information for Git plugins

our $VERSION = '2.042';

use Moose::Role;
use MooseX::Types::Moose qw(Str Maybe);
use namespace::autoclean;

has 'repo_root'   => ( is => 'ro', isa => Str, default => '.' );

#pod =method current_git_branch
#pod
#pod   $branch = $plugin->current_git_branch;
#pod
#pod The current branch in the repository, or C<undef> if the repository
#pod has a detached HEAD.  Note: This value is cached; it will not
#pod be updated if the branch is changed during the run.
#pod
#pod =cut

has current_git_branch => (
    is => 'ro',
    isa => Maybe[Str],
    lazy => 1,
    builder => '_build_current_git_branch',
    init_arg => undef,          # Not configurable
);

sub _build_current_git_branch
{
  my $self = shift;

  # Git 1.7+ allows "rev-parse --abbrev-ref HEAD", but we want to support 1.5.4
  my ($branch) = $self->git->RUN(qw(symbolic-ref -q HEAD));

  no warnings 'uninitialized';
  undef $branch unless $branch =~ s!^refs/heads/!!;

  $branch;
} # end _build_current_git_branch

#pod =method git
#pod
#pod   $git = $plugin->git;
#pod
#pod This method returns a Git::Wrapper object for the C<repo_root>
#pod directory, constructing one if necessary.  The object is shared
#pod between all plugins that consume this role (if they have the same
#pod C<repo_root>).
#pod
#pod =cut

my %cached_wrapper;

around dump_config => sub
{
    my $orig = shift;
    my $self = shift;

    my $config = $self->$orig;

    $config->{+__PACKAGE__} = {
        repo_root => $self->repo_root,
        git_version => $self->git->version,
    };

    return $config;
};

sub git {
  my $root = shift->repo_root;

  $cached_wrapper{$root} ||= do {
    require Git::Wrapper;
    Git::Wrapper->new( $root );
  };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Role::Git::Repo - Provide repository information for Git plugins

=head1 VERSION

version 2.042

=head1 DESCRIPTION

This role is used within the Git plugins to get information about the
repository structure, and to create a Git::Wrapper object.

=head1 ATTRIBUTES

=head2 repo_root

The repository root, either as a full path or relative to the distribution root. Default is C<.>.

=head1 METHODS

=head2 current_git_branch

  $branch = $plugin->current_git_branch;

The current branch in the repository, or C<undef> if the repository
has a detached HEAD.  Note: This value is cached; it will not
be updated if the branch is changed during the run.

=head2 git

  $git = $plugin->git;

This method returns a Git::Wrapper object for the C<repo_root>
directory, constructing one if necessary.  The object is shared
between all plugins that consume this role (if they have the same
C<repo_root>).

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
