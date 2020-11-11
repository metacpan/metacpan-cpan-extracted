package Dist::Zilla::Role::FileInjector 6.017;
# ABSTRACT: something that can add files to the distribution

use Moose::Role;

use namespace::autoclean;

#pod =head1 DESCRIPTION
#pod
#pod This role should be implemented by any plugin that plans to add files into the
#pod distribution.  It provides one method (C<L</add_file>>, documented below),
#pod which adds a file to the distribution, noting the place of addition.
#pod
#pod =method add_file
#pod
#pod   $plugin->add_file($dzil_file);
#pod
#pod This adds a file to the distribution, setting the file's C<added_by> attribute
#pod as it does so.
#pod
#pod =cut

sub add_file {
  my ($self, $file) = @_;
  my ($pkg, undef, $line) = caller;

  $file->_set_added_by(
    sprintf("%s (%s line %s)", $self->plugin_name, $pkg, $line),
  );

  $self->log_debug([ 'adding file %s', $file->name ]);
  push @{ $self->zilla->files }, $file;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Role::FileInjector - something that can add files to the distribution

=head1 VERSION

version 6.017

=head1 DESCRIPTION

This role should be implemented by any plugin that plans to add files into the
distribution.  It provides one method (C<L</add_file>>, documented below),
which adds a file to the distribution, noting the place of addition.

=head1 METHODS

=head2 add_file

  $plugin->add_file($dzil_file);

This adds a file to the distribution, setting the file's C<added_by> attribute
as it does so.

=head1 AUTHOR

Ricardo SIGNES 😏 <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
