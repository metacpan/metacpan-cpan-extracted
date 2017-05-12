use strict;
use warnings;

package Dist::Zilla::Role::Git::Remote::Branch;
BEGIN {
  $Dist::Zilla::Role::Git::Remote::Branch::AUTHORITY = 'cpan:KENTNL';
}
{
  $Dist::Zilla::Role::Git::Remote::Branch::VERSION = '0.1.2';
}

# FILENAME: RemoteBranch.pm
# CREATED: 12/10/11 16:46:21 by Kent Fredric (kentnl) <kentfredric@gmail.com>
# ABSTRACT: Parts to enable aggregated specification of remote branches.

use Moose::Role;


requires 'git';


requires 'remote';


has '_remote_branch' => (
  isa      => 'Str',
  is       => 'rw',
  default  => 'master',
  init_arg => 'remote_branch',
);


sub remote_branch {
  my $self = shift;
  return $self->remote . q{/} . $self->_remote_branch;
}

no Moose::Role;
1;


__END__
=pod

=head1 NAME

Dist::Zilla::Role::Git::Remote::Branch - Parts to enable aggregated specification of remote branches.

=head1 VERSION

version 0.1.2

=head1 PARAMETERS

=head2 C<remote_branch>

The name of the branch as it is on the remote side, in String form.

e.g: C<master>

=head1 METHODS

=head2 C<remote_branch>

If used in conjunction with L<Dist::Zilla::Role::Git::Remote> to provide C<remote>,
then this method will expand the passed parameter C<remote_branch> in transit to a qualified one.

=head1 REQUIRED METHODS

=head2 C<git>

Must return a L<Git::Wrapper> or compatible instance.

Available from:

=over 4

=item * L<Dist::Zilla::Role::Git::LocalRepository>

=back

=head2 C<remote>

Must return a String value representing a remote name ( as displayed in C<git remote> ).

Available from:

=over 4

=item * L<Dist::Zilla::Role::Git::Remote>

=back

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Kent Fredric <kentnl@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

