package File::Tasks::Add;

# See POD at end for docs

use strict;
use base 'File::Tasks::Task';
use File::Flat   ();
use Params::Util '_INSTANCE';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.07';	
}





#####################################################################
# Constructor and Accessors

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_) or return undef;

	# Check the content source
	my $Script = _INSTANCE(shift, 'File::Tasks') or return undef;
	$self->{source} = $Script->provider->compatible(shift) or return undef;

	$self;
}

sub source  { $_[0]->{source} }





#####################################################################
# File::Tasks::Task

sub type { 'Add' }

sub test {
	File::Flat->canWrite( shift->path );
}

sub content {
	my $self = shift;
	$self->provider->content( $self->source );
}

sub execute {
	my $self    = shift;
	my $content = $self->content or return undef;
	File::Flat->write( $self->path, $content );
}

1;

__END__

=pod

=head1 NAME

File::Tasks::Add - A File::Tasks task to add a new file

=head1 DESCRIPTION

Objects of this class represent the addition of a new file to the
filesystem. Specifically, they mean the creation of a new file
where no existing file should exist.

Thus, when applying the task to a filesystem, it is first checked
to ensure there is no existing file accidentally in the way.

=head1 METHODS

=head2 new $Tasks, $path, $source

Creates a new C<File::Tasks::Add> object, although you probably won't
be creating this object directly from here.

Returns a new C<File::Tasks::Add> object, or C<undef> on error.

=head2 type

Returns the task type, which is always 'Add'.

=head2 path

The C<path> accessor returns the path to the file within the set
of tasks.

=head2 source

The C<source> accessor returns the content source, which could be
anything supported by L<File::Tasks::Provider>.

=head2 test

The C<test> method checks to see if the file can be added.

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
