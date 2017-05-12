package Git::Class::Role::Config;

use Moo::Role; with 'Git::Class::Role::Execute';
requires 'git';

sub config {
  my $self = shift;

  # my ($options, @args) = $self->_get_options(@_);

  $self->git( config => @_ );
}

1;

__END__

=head1 NAME

Git::Class::Role::Config

=head1 DESCRIPTION

This is a role that does C<git config ...>. See L<http://www.kernel.org/pub/software/scm/git-core/docs/git-config.html> for details.

=head1 METHODS

=head2 config

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
