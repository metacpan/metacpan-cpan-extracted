package File::Tasks::Remove;

# See POD at end for docs

use strict;
use base 'File::Tasks::Task';
use File::Flat ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.07';	
}





#####################################################################
# File::Tasks::Task

sub type { 'Remove' }

sub test {
	my $self = shift;
	File::Flat->isaFile( $self->path ) and File::Flat->canRemove( $self->path );
}

sub execute {
	File::Flat->remove( shift()->path );
}

1;

__END__

=pod

=head1 NAME

File::Tasks::Remove - A File::Tasks delete task (deletes a file)

=head1 DESCRIPTION

The C<File::Tasks::Delete> task provides a mechanism for the L<File::Tasks>
to know about existing files, and instruct that they are no longer needed.

=head1 METHODS

=head2 new $Tasks, $path, $source

Creates a new C<File::Tasks::Edit> object, although you probably won't
be creating this object directly from here.

Returns a new C<File::Tasks::Edit> object, or C<undef> on error.

=head2 type

Returns the task type, which is always 'Remove'.

=head2 path

The C<path> accessor returns the path to the file within the set
of tasks.

=head2 source

The C<source> accessor returns the content source, which could be
anything supported by L<File::Tasks::Provider>.

=head2 test

The C<test> methods checks to see that the file on the filesystem exists,
and that it can be removed.

Returns true if so, or false if not.

=head2 execute

The C<execute> method executes the task, removing the existing file.

Returns true on success or C<undef> on error.

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
