package Dist::Zilla::Role::ExecFiles 6.015;
# ABSTRACT: something that finds files to install as executables

use Moose::Role;
with 'Dist::Zilla::Role::FileFinder';

use namespace::autoclean;

requires 'dir';

sub find_files {
  my ($self) = @_;

  my $dir = $self->dir;
  my $files = [
    grep { index($_->name, "$dir/") == 0 }
      @{ $self->zilla->files }
  ];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Role::ExecFiles - something that finds files to install as executables

=head1 VERSION

version 6.015

=head1 AUTHOR

Ricardo SIGNES 😏 <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
