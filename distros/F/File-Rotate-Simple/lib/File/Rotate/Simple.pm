package File::Rotate::Simple;

use v5.8.8;

use Moo 1.001000;
extends 'Exporter';

use Graph;
use List::Util 1.43, qw/ first /;
use Module::Runtime qw/ require_module /;
use Path::Tiny 0.015;
use Ref::Util qw/ is_blessed_ref /;
use Time::Seconds qw/ ONE_DAY /;
use Types::Standard -types;

use namespace::autoclean;

our $VERSION = 'v0.2.5';

# ABSTRACT: no-frills file rotation

# RECOMMEND PREREQ: Class::Load::XS
# RECOMMEND PREREQ: Ref::Util::XS
# RECOMMEND PREREQ: Type::Tiny::XS

our @EXPORT_OK = qw/ rotate_files /;


has age => (
    is      => 'ro',
    isa     => Int,
    default => 0,
);


has max => (
    is      => 'ro',
    isa     => Int,
    default => 0,
);


has file => (
    is       => 'ro',
    isa      => InstanceOf['Path::Tiny'],
    coerce   => \&path,
    required => 1,
);


has start_num => (
    is      => 'ro',
    isa     => Int,
    default => 1,
);


has extension_format => (
    is      => 'ro',
    isa     => Str,
    default => '.%#',
);


has replace_extension => (
    is  => 'ro',
    isa => Maybe[Str],
);


has if_missing => (
    is      => 'ro',
    isa     => Bool,
    default => 1,
);


has touch => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);


has time => (
    is      => 'rw',
    isa     => InstanceOf[qw/ Time::Piece Time::Moment DateTime /],
    lazy    => 1,
    default => sub { require_module('Time::Piece'); Time::Piece::localtime() },
    handles => {
        _strftime => 'strftime',
        _epoch    => 'epoch',
    },
);


sub rotate {
    my $self = shift;

    unless (is_blessed_ref $self) {
        my %args = (@_ == 1) ? %{ $_[0] } : @_;

        if (my $files = delete $args{files}) {
            foreach my $file (@{$files}) {
                $self->new( %args, file => $file )->rotate;
            }
            return;
        }

        $self = $self->new(%args);
    }

    my $max   = $self->max;
    my $age   = ($self->age)
        ? $self->_epoch - ($self->age * ONE_DAY)
        : 0;

    my @files = @{ $self->_build_files_to_rotate };

    my $index = scalar( @files );

    while ($index--) {

        my $file = $files[$index] or next;

        my $current = $file->{current};
        my $rotated    = $file->{rotated};

        unless (defined $rotated) {
            $current->remove;
            next;
        }

        if ($max && $index >= $max) {
            $current->remove;
            next;
        }

        if ($age && $current->stat->mtime < $age) {
            $current->remove;
            next;
        }

        die "Cannot move ${current} -> ${rotated}: file exists"
          if $rotated->exists;

        $current->move($rotated);
    }

    $self->file->touch if $self->touch;

    # TODO: chmod/chown arguments
}


sub _build_files_to_rotate {
    my ($self) = @_;

    my %files;

    my $num = $self->start_num;

    my $file = $self->_rotated_name( $num );
    if ($self->file->exists) {

        $files{ $self->file } = {
            current => $self->file,
            rotated => $file,
        };

    } else {

        return [ ] unless $self->if_missing;

    }

    my $max  = $self->max;
    while ($file->exists || ($max && $num <= $max)) {

        my $rotated = $self->_rotated_name( ++$num );

        last if $rotated eq $file;

        if ($file->exists) {
            $files{ $file } = {
                current => $file,
                rotated => (!$max || $num <= $max) ? $rotated : undef,
            };
        }

        $file = $rotated;

    }

    # Using a topoligical sort is probably overkill, but it allows us
    # to use more complicated filename rotation schemes in a subclass
    # without having to worry about file order.

    my $g = Graph->new;
    foreach my $file (values %files) {
        my $current = $file->{current};
        if (my $rotated = $file->{rotated}) {
            $g->add_edge( $current->stringify,
                          $rotated->stringify );
        } else {
            $g->add_vertex( $current->stringify );
        }
    }

    # Now check that there is not more than one file being rotated to
    # the same name.

    my %rotated;
    $rotated{$_->[1]}++ for ($g->edges);

    if (my $duplicate = first { $rotated{$_} > 1 } keys %rotated) {
        die "multiple files are rotated to '${duplicate}'";
    }

    die "dependency chain is cyclic"
      if $g->has_a_cycle;

    return [
        grep { defined $_ }
        map  { $files{$_} } $g->topological_sort()
        ];

}


sub _rotated_name {
    my ($self, $index) = @_;

    my $format = $self->extension_format;
    {
        no warnings 'uninitialized';
        $format =~ s/\%(\d+)*#/sprintf("\%0$1d", $index)/ge;
    }

    my $file      = $self->file->stringify;
    my $extension = ($format =~ /\%/) ? $self->_strftime($format) : $format;
    my $replace   = $self->replace_extension;

    if (defined $replace) {

        my $re = quotemeta($replace);
        $file =~ s/${re}$/${extension}/;

        return path($file);

    } else {

        return path( $file . $extension );

    }
}


sub rotate_files {
  __PACKAGE__->rotate( @_ );
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

File::Rotate::Simple - no-frills file rotation

=head1 VERSION

version v0.2.5

=head1 SYNOPSIS

  use File::Rotate::Simple qw/ rotate_files /;

  rotate_files(
      file => '/foo/bar/backup.tar.gz',
      age  => 7,
      max  => 30,
  );

  rotate_files(
      files => [ qw{ /var/log/foo.log /var/log/bar.log } ],
      max   => 7,
  );

or the legacy interface:

  File::Rotate::Simple->rotate(
      file => '/foo/bar/backup.tar.gz',
      age  => 7,
      max  => 30,
  );

or the object-oriented interface:

  my $r = File::Rotate::Simple->new(
      file => '/foo/bar/backup.tar.gz',
      age  => 7,
      max  => 30,
  );

  $r->rotate;

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

The maximum age of files (in days), relative to the L</time>
attribute.  Older files will be deleted.

A value C<0> (default) means there is no maximum age.

=head2 C<max>

The maximum number of files to keep.  Numbered files larger than this
will be deleted.

A value of C<0> (default) means that there is no maximum number.

Note that it does not track whether intermediate files are missing.

=head2 C<file>

The file to rotate. This can be a string or L<Path::Tiny> object.

=head2 C<files>

When L</rotate> is called as a constructor, you can specify an array
reference of files to rotate:

  File::Rotate::Simple->rotate(
     files => \@files,
     ...
  );

=head2 C<start_num>

The starting number to use when rotating files. Defaults to C<1>.

Added in v0.2.0.

=head2 C<extension_format>

The extension to add when rotating. This is a string that is passed to
L<Time::Piece/strftime> with the following addition of the C<%#> code,
which corresponds to the rotation number of the file.

Added in v0.2.0.

=head2 C<replace_extension>

If defined, it replaces the extension with the one specified by
L</extension_format> rather than appending it.  Use this when you want
to preserve the existing extension in a rotated backup, e.g.

    my $r = File::Rotate::Simple->new(
        file              => 'myapp.log',
        extension_format  => '.%#.log',
        replace_extension => '.log',
    );

will rotate the log as F<myapp.1.log>.

Added in v0.2.0.

=head2 C<if_missing>

When true, rotate the files even when L</file> is missing. True by
default, for backwards compatability.

Added in v0.2.0.

=head2 C<touch>

Touch L</file> after rotating.

=head2 C<time>

A time object corresponding to the time used for generating
timestamped extensions in L</extension_format>.  It defaults to a
L<Time::Piece> object with the current local time.

You can specify an alternative time (including time zone) in the
constructor, e.g.

    use Time::Piece;

    my $r = File::Rotate::Simple->new(
        file              => 'myapp.log',
        time              => gmtime(),
        extension_format  => '.%Y%m%d',
    );

L<Time::Moment> and L<DateTime> objects can also be given.

Unlike other attributes, L</time> is read-write, so that it can be
updated between calls to L</rotate>:

    use Time::Piece;

    $r->time( localtime );
    $r->rotate;

Added in v0.2.0.

=head1 METHODS

=head2 C<rotate>

Rotates the files.

This can be called as a constructor.

=begin internal

=head1 INTERNAL METHODS

=head2 C<_build_files_to_rotate>

This method builds a reverse-ordered list of files to rotate.

It gathers a list of files to rotate using L</_rotated_name> and
L</file> and topoligically sorts them based on what the files will be
renamed to.
=head2 C<_rotated_name>

  my $rotated = $r->_rotated_name( $index );

This method generates a L<Path::Tiny> object of the rotated filename
from the L</file>, L</extension_format>, and L</replace_extension>
attributes, using the C<$index> (a positive integer).

For example, given the default values and a L</file> called
F</var/log/myapp.log> and C<$index = 12>, it will return the file
F</var/log/myapp.log.12>.

If the L</extension_format> refers to formats other than C<%#> (for
the C<$index>), then it will use the L</time> to generate the new file
name.


=end internal

=head1 EXPORTS

None by default. All exports must be made manually.

=head2 C<rotate_files>

This is an optionally exported function for rotating files.

  use File::Rotate::Simple qw/ rotate_files /;

  rotate_files(
      file => '/foo/bar/backup.tar.gz',
      age  => 7,
      max  => 30,
  );

Added in v0.2.0.

=for readme continue

=head1 SEE ALSO

The following modules have similar functionality:

=over

=item * L<File::Rotate::Backup>

=item * L<File::Write::Rotate>

=back

There are also several logging modueles that support log rotation.

=head1 SOURCE

The development version is on github at L<https://github.com/robrwo/File-Rotate-Simple>
and may be cloned from L<git://github.com/robrwo/File-Rotate-Simple.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/robrwo/File-Rotate-Simple/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 CONTRIBUTOR

=for stopwords Mohammad S Anwar

Mohammad S Anwar <mohammad.anwar@yahoo.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015-2020 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
