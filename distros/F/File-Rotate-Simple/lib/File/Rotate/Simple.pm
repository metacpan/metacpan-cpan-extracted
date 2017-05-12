package File::Rotate::Simple;

use Moo 1.001000;

use Path::Tiny;
use Types::Standard -types;

use namespace::autoclean;

use version;
$File::Rotate::Simple::VERSION = version->declare('v0.1.5');

=head1 NAME

File::Rotate::Simple - no-frills file rotation

=head1 SYNOPSIS

  use File::Rotate::Simple;

  File::Rotate::Simple->rotate(
      file => '/foo/bar/backup.tar.gz',
      age  => 7,
      max  => 30,
  );

  File::Rotate::Simple->rotate(
      files => [ qw{ /var/log/foo.log /var/log/bar.log } ],
      max   => 7,
  );

=head1 DESCRIPTION

This module implements simple file rotation.

Files are renamed to have a numeric suffix, e.g. F<backup.tar.gz> is renamed to
F<backup.tar.gz.1>.  Existing file numbers are incremented.

If L</max> is specified, then any files with a larger numeric suffix
are deleted.

If L</age> is specified, then any files older than that number of days
are deleted.

Note that files with the extension C<0> are ignored.

=for readme stop

=head1 ATTRIBUTES

=head2 C<age>

The maximum age of files (in days).  Older files will be deleted.

A value C<0> means there is no maximum age.

=cut

has age => (
    is      => 'ro',
    isa     => Int,
    default => 0,
);

=head2 C<max>

The maximum number of files to keep.  Numbered files larger than this
will be deleted.

A value of C<0> means that there is no maximum number.

Note that it does not track whether intermediate files are missing.

=cut

has max => (
    is      => 'ro',
    isa     => Int,
    default => 0,
);

=head2 C<file>

The file to rotate. This can be a string or L<Path::Tiny> object.

=head2 C<files>

When L</rotate> is called as a constructor, you can specify an array
reference of files to rotate.

=cut

has file => (
    is       => 'ro',
    isa      => InstanceOf['Path::Tiny'],
    coerce   => sub { path(shift) },
    required => 1,
);

=begin internal

=head2 C<files>

This is an array reference of numbered backup files. It is used
internally.

=end internal

=cut

has files => (
    is        => 'lazy',
    isa       => ArrayRef[ Maybe[InstanceOf['Path::Tiny']] ],
    init_args => undef,
);

sub _build_files {
    my $self = shift;

    my $base = quotemeta($self->file->basename);
    my $re   = qr/^${base}(?:[.]([1-9]\d*))?$/;

    my @files;

    my $iter = $self->file->parent->iterator;

    while (my $file = $iter->()) {

        next unless $file->basename =~ $re;

        my $index = $1;

        $files[ $index || 0 ] = $file;

    }

    return \@files;
}

=head1 METHODS

=head2 C<rotate>

Rotates the files.

This can be called as a constructor.

=cut

sub rotate {
    my $self = shift;

  unless (ref $self) {
      my %args = (@_ == 1) ? %{ $_[0] } : @_;

      if (my $files = delete $args{files}) {
          foreach my $file (@{$files}) {
              $self->new( %args, file => $file )->rotate;
          }
          return;
      }

      $self = $self->new(%args);
  }

  my @files = @{ $self->files };
  my $index = scalar( @files );

  my $age   = ($self->age)
      ? time - ($self->age * 86_400)
      : 0;

  while ($index--) {

      my $file = $files[$index] or next;

      if ($self->max && $index >= $self->max) {
          $file->remove;
          next;
      }

      if ($age && $file->stat->mtime < $age) {
          $file->remove;
          next;
      }

      my $next = $index + 1;
      my $new = $file->stringify;

      if ($index) {
          $new =~ s/[.]${index}$/.${next}/;
      } else {
          $new .= '.' . $next;
      }

      $file->move($new);
  }

}

=for readme continue

=head1 SEE ALSO

The following modules have similar functionality:

=over

=item * L<File::Rotate::Backup>

=item * L<File::Write::Rotate>

=back

There are also several logging modueles that support log rotation.

=head1 AUTHOR

Robert Rothenberg, C<rrwo@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright 2015 Robert Rothenberg.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

=for readme stop

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=for readme continue

=cut

1;
