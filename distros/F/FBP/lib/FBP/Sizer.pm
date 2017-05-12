package FBP::Sizer;

=pod

=head1 NAME

FBP::Sizer - Base class for all sizers

=head1 DESCRIPTION

B<FBP::Sizer> is the base class for a sizer objects in L<Wx>.

=head1 METHODS

=cut

use Mouse;

our $VERSION = '0.41';

extends 'FBP::Object';
with    'FBP::Children';

=pod

=head2 name

The C<name> accessor provides the logical name of the sizer. This must be
named uniquely within each top level wxFormBuilder object, and is a required
field.

Returns the name as a string.

=cut

# Not part of the Wx model, instead was added by FormBuilder
has name => (
	is       => 'ro',
	isa      => 'Str',
	required => 1,
);

=pod

=head2 minimum_size

The C<minimum_size> method returns a comma-separated pair of integers
representing the minimum size for the window, or a zero-length string
if no minimum size is defined for the sizer.

=cut

has minimum_size => (
	is  => 'ro',
	isa => 'Str',
);

no Mouse;
__PACKAGE__->meta->make_immutable;

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=FBP>

For other issues, or commercial enhancement or support, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2009 - 2012 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
