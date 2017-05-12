use strict;
use warnings;

package Dist::Zilla::Role::Git::LocalRepository;
BEGIN {
  $Dist::Zilla::Role::Git::LocalRepository::AUTHORITY = 'cpan:KENTNL';
}
{
  $Dist::Zilla::Role::Git::LocalRepository::VERSION = '0.1.2';
}

# FILENAME: LocalRepository.pm
# CREATED: 12/10/11 16:47:31 by Kent Fredric (kentnl) <kentfredric@gmail.com>
# ABSTRACT: A plugin which works with a local git repository as its Dist::Zilla source.

use Moose::Role;



requires 'zilla';


has 'git' => (
  isa        => 'Object',
  is         => 'ro',
  lazy_build => 1,
  init_arg   => undef,
);

sub _build_git {
  require Git::Wrapper;
  my $self = shift;
  return Git::Wrapper->new( $self->zilla->root );
}

no Moose::Role;
1;


__END__
=pod

=head1 NAME

Dist::Zilla::Role::Git::LocalRepository - A plugin which works with a local git repository as its Dist::Zilla source.

=head1 VERSION

version 0.1.2

=head1 SYNOPSIS

  package Foo;

  use Moose;
  with 'Dist::Zilla::Role::BeforeRelease';
  with 'Dist::Zilla::Role::Git::LocalRepository';

  sub before_release {
    my $self = shift;
    print for $self->git->version;
  }

=head1 METHODS

=head2 git

Returns a L<Git::Wrapper> instance representing the repository
of the current L<Dist::Zilla> projects' root.

=head1 REQUIRED METHODS

=head2 zilla

Available from:

=over 4

=item * L<Dist::Zilla::Role::Plugin>

=back

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Kent Fredric <kentnl@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

