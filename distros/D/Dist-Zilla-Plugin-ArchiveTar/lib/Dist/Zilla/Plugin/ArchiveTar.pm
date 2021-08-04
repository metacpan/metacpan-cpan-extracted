use strict;
use warnings;
use 5.020;
use experimental qw( postderef );

package Dist::Zilla::Plugin::ArchiveTar 0.03 {

  use Moose;
  use Archive::Tar;
  use Path::Tiny ();
  use Moose::Util::TypeConstraints;
  use namespace::autoclean;
  use experimental qw( signatures postderef );

  # ABSTRACT: Create dist archives using  Archive::Tar


  with 'Dist::Zilla::Role::ArchiveBuilder';

  enum ArchiveFormat => [qw/ tar tar.gz tar.bz2 tar.xz /];

  has format => (
    is       => 'ro',
    isa      => 'ArchiveFormat',
    required => 1,
    default  => 'tar.gz',
  );

  our $VERBOSE;

  sub build_archive ($self, $archive_basename, $built_in, $basedir)
  {
    my $archive = Archive::Tar->new;

    my $archive_path = Path::Tiny->new(join '.', $archive_basename, $self->format);

    my %dirs;
    my $verbose = $VERBOSE || $self->zilla->logger->get_debug;

    my $now = time;
    foreach my $distfile (sort { $a->name cmp $b->name } $self->zilla->files->@*)
    {
      {
        my @parts = split /\//, $distfile->name;
        pop @parts;

        my $dir = '';
        foreach my $part ('', @parts)
        {
          $dir .= "/$part";
          next if $dirs{$dir};
          $dirs{$dir} = 1;

          $self->log("DIR  @{[ $basedir->child($dir) ]}") if $verbose;
          $archive->add_data(
            $basedir->child($dir),
            '',
            {
              type  => Archive::Tar::Constant::DIR(),
              mode  => oct('0755'),
              mtime => $now,
              uid   => 0,
              gid   => 0,
              uname => 'root',
              gname => 'root',
            }
          );
        }
      }

      $self->log("FILE @{[ $basedir->child($distfile->name) ]}") if $verbose;
      $archive->add_data(
        $basedir->child($distfile->name),
        $built_in->child($distfile->name)->slurp_raw,
        {
          mode  => -x $built_in->child($distfile->name) ? oct('0755') : oct('0644'),
          mtime => $now,
          uid   => 0,
          gid   => 0,
          uname => 'root',
          gname => 'root',
        },
      );
    }

    $self->log("writing archive to $archive_path");

    if($self->format eq 'tar.gz')
    {
      $archive->write("$archive_path", Archive::Tar::COMPRESS_GZIP());
    }
    elsif($self->format eq 'tar')
    {
      $archive->write("$archive_path");
    }
    elsif($self->format eq 'tar.bz2')
    {
      $archive->write("$archive_path", Archive::Tar::COMPRESS_BZIP());
    }
    elsif($self->format eq 'tar.xz')
    {
      $archive->write("$archive_path", Archive::Tar::COMPRESS_XZ());
    }

    return $archive_path;
  }

  __PACKAGE__->meta->make_immutable;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::ArchiveTar - Create dist archives using  Archive::Tar

=head1 VERSION

version 0.03

=head1 SYNOPSIS

In your C<dist.ini>

 [ArchiveTar]

=head1 DESCRIPTION

This L<Dist::Zilla> plugin overrides the build in archive builder and uses L<Archive::Tar> only.
Although L<Dist::Zilla> does frequently use L<Archive::Tar> itself, it is different from the built
in version in the following ways:

=over 4

=item Predictable

The built in behavior will sometimes use L<Archive::Tar> or L<Archive::Tar::Wrapper>.  The problem with L<Archive::Tar::Wrapper>
is that it depends on the system implementation of tar, which in some cases can produce archives that are not readable by older
implementations of tar.  In particular GNU tar which is typically the default on Linux systems includes unnecessary features that
break tar on HP-UX.  (You should probably be getting off HP-UX if you are still using it in 2021 as I write this).

=item Sorted by name

The contents of the archive are sorted by name instead of being sorted by filename length.  While sorting by length makes for
a pretty display when they are unpacked, I find it harder to find stuff when the content is listed.

=item Additional formats

This plugin supports the use of compression formats supported by L<Archive::Tar>.

=back

=head1 PROPERTIES

=head2 format

 [ArchiveTar]
 format = tar.gz

Sets the output format.  The default, most common and easiest to unpack for cpan clients is C<tar.gz>.  You should consider
carefully before not using the default.  Supported formats:

=over 4

=item C<tar>

=item C<tar.gz>

=item C<tar.bz2>

=item C<tar.xz>

=back

=head1 SEE ALSO

=over 4

=item L<Archive::Libarchive>

=item L<Dist::Zilla>

=item L<Dist::Zilla::Plugin::Libarchive>

=item L<Dist::Zilla::Role::ArchiveBuilder>

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
