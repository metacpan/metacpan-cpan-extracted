package HTML::HTML5::Outline::Section;

use 5.008;
use strict;

our $VERSION = '0.006';

sub new
{
	my ($class, %data) = @_;
	
	$data{header}   ||= undef;
	$data{parent}   ||= undef;
	$data{elements} ||= [];
	
	bless { %data }, $class;
}

sub element  { return $_[0]->{element}; }
sub elements { return @{ $_[0]->{elements} || [] }; }
sub header   { return $_[0]->{header}; }
sub heading  { return $_[0]->{heading}; }
sub order    { return $_[0]->{document_order}; }
sub outliner { return $_[0]->{outliner}; }
sub sections { return @{ $_[0]->{sections} || [] }; }

sub children
{
	my ($self) = @_;
	my @rv = $self->sections;
	
	foreach my $e ($self->elements)
	{
		my $E = HTML::HTML5::Outline::k($e);
		if ($self->outliner->{outlines}->{$E})
		{
			push @rv, $self->outliner->{outlines}->{$E};
		}
	}

	return sort { $a->order <=> $b->order } @rv;
}

sub to_hashref
{
	my ($self) = @_;

	my $header_node  = {
		class      => 'Header',
		tag        => $self->header->tagName,
		content    => $self->heading,
		lang       => $self->outliner->_node_lang($self->header),
		};
	my $section_node = {
		class      => 'Section',
		type       => 'Text',
		header     => $header_node,
		};

	$self->{hashref_node}            = $section_node;
	$self->{hashref_node_for_header} = $header_node;
	
	$section_node->{children} = [ map { $_->to_hashref } $self->children ];

	return $section_node;
}

1;


__END__

=head1 NAME

HTML::HTML5::Outline::Section - represents a document section

=head1 DESCRIPTION

=head2 Methods

=over

=item * C<< element >>

An L<XML::LibXML::Element> for the section.

=item * C<< elements >>

Various L<XML::LibXML::Element> objects which are within the section.

=item * C<< header >>

The L<XML::LibXML::Element> which represents the heading for the section.

=item * C<< heading >>

The text of the heading for the section.

=item * C<< order >>

The order of the section relative to other sections and outlinees.

=item * C<< sections >>

Child sections of this section.

=item * C<< children >>

Child sections of this section, and outlinees within this section,
sorted in document order.

=back

=head1 SEE ALSO

L<HTML::HTML5::Outline::Outlinee>,
L<HTML::HTML5::Outline>.

=head1 AUTHOR

Toby Inkster, E<lt>tobyink@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENCE

Copyright (C) 2008-2011 by Toby Inkster

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
