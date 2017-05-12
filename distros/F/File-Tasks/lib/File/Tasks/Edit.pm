package File::Tasks::Edit;

# See POD at end for docs

use strict;
use base 'File::Tasks::Add';
use File::Flat ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.07';	
}





#####################################################################
# File::Tasks::Task

sub type { 'Edit' }

sub test {
	my $self = shift;
	File::Flat->isaFile( $self->path ) and File::Flat->canWrite( $self->path );
}

1;

__END__

=pod

=head1 NAME

File::Tasks::Edit - A File::Tasks edit task (change a file)

=head1 DESCRIPTION

The C<File::Tasks::Edit> task is similar to the L<File::Tasks::Add> task,
except that it expects a current file to already exists, which it will
change the contents of (without changing permissions).

=head1 METHODS

=head2 new $Tasks, $path, $source

Creates a new C<File::Tasks::Edit> object, although you probably won't
be creating this object directly from here.

Returns a new C<File::Tasks::Edit> object, or C<undef> on error.

=head2 type

Returns the task type, which is always 'Edit'.

=head2 path

The C<path> accessor returns the path to the file within the set
of tasks.

=head2 source

The C<source> accessor returns the content source, which could be
anything supported by L<File::Tasks::Provider>.

=head2 test

The C<test> method checks to see if the file can be edited.

Returns true if so, or false if not.

=head2 execute

The C<execute> method executes the task on the local filesystem.

Returns true on success or C<undef> on error.

=head2 content

The C<content> method returns the content that is to be written
to the file.

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=File-Tasks>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>, L<http://ali.as/>

=head1 COPYRIGHT

Copyright 2005 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
