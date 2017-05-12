package FBP::Window;

=pod

=head1 NAME

FBP::Window - Base class for all graphical wxWindow objects

=cut

use Mouse;
use Scalar::Util ();

our $VERSION = '0.41';

extends 'FBP::Object';
with    'FBP::KeyEvent';
with    'FBP::MouseEvent';
with    'FBP::FocusEvent';





######################################################################
# Direct Properties

=pod

=head2 id

The C<id> method returns the numeric wxWidgets identifier for the window.

=cut

has id => (
	is  => 'ro',
	isa => 'Str',
);

=pod

=head2 name

The C<name> method returns the logical name of the object.

=cut

has name => (
	is  => 'ro',
	isa => 'Str',
);

=pod

=head2 enabled

The C<enabled> method indicates if the object is enabled or not.

=cut

has enabled => (
	is  => 'ro',
	isa => 'Bool',
);

=pod

=head2 hidden

The C<hidden> method indicates if the object is true if the shown is removed
from view, or false if the window is shown.

=cut

has hidden => (
	is  => 'ro',
	isa => 'Bool',
);

=pod

=head2 subclass

The C<subclass> method returns the literal C-style 'subclass' property
produced by wxFormBuilder.

The format of this raw version is 'ClassName;headerfile.h'.

=cut

has subclass => (
	is       => 'ro',
	isa      => 'Str',
	required => 1,
	default  => '',
);

=pod

=head2 pos

The C<pos> method returns the position of the window.

=cut

has pos => (
	is  => 'ro',
	isa => 'Str',
);

=pod

=head2 size

The C<size> method returns the size of the window, if it has a specific
strict size.

=cut

has size => (
	is  => 'ro',
	isa => 'Str',
);

=pod

=head2 fg

The C<fg> method returns a colour string for any custom foreground colour
that should be applied to the window.

=cut

has fg => (
	is  => 'ro',
	isa => 'Str',
);

=pod

=head2 bg

The C<bg> method returns a colour string for any custom background colour
that should be applied to the window.

=cut

has bg => (
	is  => 'ro',
	isa => 'Str',
);

=pod

=head2 font

The C<font> method returns a string containing a comma-separated list of
wxFont constructor params if the wxWindow uses a custom font, or null if it
uses the default system font.

=cut

has font => (
	is  => 'ro',
	isa => 'Str',
);

=pod

=head2 tooltip

The C<tooltip> method returns a tooltip string for the window, if it has one.

=cut

has tooltip => (
	is  => 'ro',
	isa => 'Str',
);

=pod

=head2 window_style

The C<window_style> method returns a set of Wx style flags that are common
to all window types.

=cut

has window_style => (
	is  => 'ro',
	isa => 'Str',
);

=pod

=head2 minimum_size

The C<minimum_size> method returns a comma-separated pair of integers
representing the minimum size for the window, or a zero-length string
if no minimum size is defined.

=cut

has minimum_size => (
	is  => 'ro',
	isa => 'Str',
);

=pod

=head2 maximum_size

The C<maximum_size> method returns a comma-separated pair of integers
representing the maximum size for the window, or a zero-length string
if no minimum size is defined.

=cut

has maximum_size => (
	is  => 'ro',
	isa => 'Str',
);





######################################################################
# Derived Values

=pod

=head2 styles

The C<styles> method returns the merged set of all constructor style flags
for the object.

You should generally call this method if you are writing code generators,
rather than calling C<style> or C<window_style> methods specifically.

=cut

sub styles {
	my $self   = shift;
	my @styles = grep { length $_ } (
		$self->can('style') ? $self->style : (),
		$self->window_style,
	) or return '';
	return join '|', @styles;
}

=pod

=head2 wxclass

The C<wxclass> method determines the class that should be used to
instantiate this window. Most of the time this will be a standard class,
but it may be different if a custom C<subclass> property has been set.

Note this class is only used as part of the constructor, and does not assume
that this is also the value that any program should load. That value is con

=cut

sub wxclass {
	my $self = shift;

	# If a custom class is defined, use it literally
	my $subclass = $self->subclass;
	if ( length $subclass ) {
		my ($wxclass, $header) = split /\s*;\s*/, $subclass;
		if ( defined $wxclass and length $wxclass ) {
			return $wxclass;
		}
	}

	# Fall through to the default.
	# For now, derive it automatically from the FBP child object.
	my $wxclass = Scalar::Util::blessed($self);
	if ( $wxclass =~ s/^FBP::/Wx::/ ) {
		return $wxclass;
	}

	# No idea what to do at this point...
	die 'Failed to derive Wx class from FBP class';
}

=pod

=head2 header

The C<header> method returns the header file (or in the Perl world, module)
that needs to be loaded in order to make use of a custom subclass window class
for an element.

=cut

sub header {
	my $self = shift;

	# If a custom class is defined, use it literally
	my $subclass = $self->subclass;
	if ( length $subclass ) {
		my ($wxclass, $header) = split /\s*;\s*/, $subclass;
		if ( defined $header and length $header ) {
			return $header;
		}
	}

	# If there is no explicit header to load, don't load anything
	return;
}





######################################################################
# Events

has OnEraseBackground => (
	is  => 'ro',
	isa => 'Str',
);

has OnPaint => (
	is  => 'ro',
	isa => 'Str',
);

has OnSize => (
	is  => 'ro',
	isa => 'Str',
);

has OnUpdateUI => (
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
