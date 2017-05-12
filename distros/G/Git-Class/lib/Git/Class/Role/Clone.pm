package Git::Class::Role::Clone;

use Moo::Role; with 'Git::Class::Role::Execute';
requires 'git';

use Git::Class::Worktree;
use URI::Escape;

sub clone {
  my $self = shift;

  my ($options, @args) = $self->_get_options(@_);

  my ($out) = $self->git( clone => $options, @args );
  Carp::croak $self->_error if $self->_error;

  my $dir = $args[-1];
  if ($dir =~ m{([^/]+)/?\.git/?$}i) {
    $dir = uri_unescape($1);
  }
  $self->_error("work directory is not found") unless -d $dir;

  Git::Class::Worktree->new( path => $dir, cmd => $self );
}

1;

__END__

=head1 NAME

Git::Class::Role::Clone

=head1 DESCRIPTION

This is a role that does C<git clone ...>. See L<http://www.kernel.org/pub/software/scm/git-core/docs/git-clone.html> for details.

=head1 METHOD

=head2 clone

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
