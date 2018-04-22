package Dist::Zilla::Role::FileMunger 6.012;
# ABSTRACT: something that alters a file's destination or content

use Moose::Role;
with 'Dist::Zilla::Role::Plugin';

use namespace::autoclean;

#pod =head1 DESCRIPTION
#pod
#pod A FileMunger has an opportunity to mess around with each file that will be
#pod included in the distribution.  Each FileMunger's C<munge_files> method is
#pod called once.  By default, this method will just call the C<munge_file> method
#pod (note the missing terminal 's') once for each file, excluding files with an
#pod encoding attribute of 'bytes'.
#pod
#pod The C<munge_file> method is expected to change attributes about the file before
#pod it is written out to the built distribution.
#pod
#pod If you want to modify all files (including ones with an encoding of 'bytes') or
#pod want to select a more limited set of files, you can provide your own
#pod C<munge_files> method.
#pod
#pod =cut

sub munge_files {
  my ($self) = @_;

  $self->log_fatal("no munge_file behavior implemented!")
    unless $self->can('munge_file');

  my @files = @{ $self->zilla->files };
  for my $file ( @files ) {
    if ($file->is_bytes) {
      $self->log_debug($file->name . " has 'bytes' encoding, skipping...");
      next;
    }

    $self->munge_file($file);
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Role::FileMunger - something that alters a file's destination or content

=head1 VERSION

version 6.012

=head1 DESCRIPTION

A FileMunger has an opportunity to mess around with each file that will be
included in the distribution.  Each FileMunger's C<munge_files> method is
called once.  By default, this method will just call the C<munge_file> method
(note the missing terminal 's') once for each file, excluding files with an
encoding attribute of 'bytes'.

The C<munge_file> method is expected to change attributes about the file before
it is written out to the built distribution.

If you want to modify all files (including ones with an encoding of 'bytes') or
want to select a more limited set of files, you can provide your own
C<munge_files> method.

=head1 AUTHOR

Ricardo SIGNES 😏 <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
