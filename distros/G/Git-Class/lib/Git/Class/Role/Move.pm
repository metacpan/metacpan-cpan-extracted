package Git::Class::Role::Move;

use Moo::Role; with 'Git::Class::Role::Execute';
requires 'git';

sub move {
  my $self = shift;

  # my ($options, @args) = $self->_get_options(@_);

  $self->git( mv => @_ );
}

1;

__END__

=head1 NAME

Git::Class::Role::Move

=head1 DESCRIPTION

This is a role that does C<git mv ...>. See L<http://www.kernel.org/pub/software/scm/git-core/docs/git-mv.html> for details.

=head1 METHOD

=head2 move

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
