package Linux::TempFile;
use 5.008001;
use strict;
use warnings;
use base 'IO::Handle';

our $VERSION = "0.02";

require XSLoader;
XSLoader::load('Linux::TempFile', $VERSION);

use Carp ();
use File::Spec;

sub new {
    my ($class, $dir) = @_;
    $dir = File::Spec->tmpdir unless defined $dir;
    my $fd = _open_tmpfile($dir);
    my $self = $class->SUPER::new();
    $self->fdopen($fd, '+>');
}

sub link {
    my ($self, $newpath) = @_;
    Carp::croak("path required") unless length $newpath;
    my $oldpath = '/proc/self/fd/' . fileno $self;
    _linkat($oldpath => $newpath);
}

1;
__END__

=encoding utf-8

=head1 NAME

Linux::TempFile - Creates a temporary file using O_TMPFILE

=head1 SYNOPSIS

    use Linux::TempFile;
    my $file = Linux::TempFile->new;
    # do something with $file (eg: print, chmod)
    $file->link('/path/to/file');

=head1 DESCRIPTION

Linux::TempFile is a module to create a temporary file using O_TMPFILE.

This module is only available on GNU/Linux 3.11 or higher.

=head1 METHODS

=over 4

=item Linux::TempFile->new([$dir])

Creates a temporary file using O_TMPFILE.

Returns an instance of this class (inherits L<IO::Handle>).

=item $self->link($path)

Creates a new filename linked to the temporary file by calling linkat(2).

=back

=head1 SEE ALSO

L<File::Temp>, L<IO::Handle>, B<open(2)>, B<linkat(2)>

=head1 LICENSE

Copyright (C) Jiro Nishiguchi.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Jiro Nishiguchi E<lt>jiro@cpan.orgE<gt>

=cut
