package File::Tasks::Task;

# See POD at end for docs

use strict;
use overload 'bool' => sub () { 1 };
use overload '""'   => 'path';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.07';	
}





#####################################################################
# Constructor and Accessors

sub new {
	my $class  = shift;
	my $path   = defined $_[1] ? $_[1] : return undef;
	bless { path => $path }, $class;
}

sub path { $_[0]->{path} }

1;

__END__

=pod

=head1 NAME

File::Tasks::Task - Base class for File::Tasks tasks

=head1 DESCRIPTION

The C<File::Tasks::Task> class provides a base class for the various types
of tasks.

By default, it provides a new constructor that takes a path.

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
