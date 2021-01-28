package Dist::Zilla::Plugin::ShareDir 6.017;
# ABSTRACT: install a directory's contents as "ShareDir" content

use Moose;

use namespace::autoclean;

#pod =head1 SYNOPSIS
#pod
#pod In your F<dist.ini>:
#pod
#pod   [ShareDir]
#pod   dir = share
#pod
#pod If no C<dir> is provided, the default is F<share>.
#pod
#pod =cut

has dir => (
  is   => 'ro',
  isa  => 'Str',
  default => 'share',
);

sub find_files {
  my ($self) = @_;

  my $dir = $self->dir;
  my $files = [
    grep { index($_->name, "$dir/") == 0 }
      @{ $self->zilla->files }
  ];
}

sub share_dir_map {
  my ($self) = @_;
  my $files = $self->find_files;
  return unless @$files;

  return { dist => $self->dir };
}

with 'Dist::Zilla::Role::ShareDir';
__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::ShareDir - install a directory's contents as "ShareDir" content

=head1 VERSION

version 6.017

=head1 SYNOPSIS

In your F<dist.ini>:

  [ShareDir]
  dir = share

If no C<dir> is provided, the default is F<share>.

=head1 AUTHOR

Ricardo SIGNES 😏 <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
