package HTML::HTML5::Outline::Outlinee;

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
sub order    { return $_[0]->{document_order}; }
sub outliner { return $_[0]->{outliner}; }
sub sections { return @{ $_[0]->{sections} || [] }; }

sub children
{
	my ($self) = @_;
	return sort { $a->order <=> $b->order } $self->sections;
}

sub to_hashref
{
	my ($self) = @_;

	my $rdf_type = 'Text';
	
	if ($self->element->tagName eq 'figure'
	||  ($self->element->getAttribute('class')||'') =~ /\bfigure\b/)
	{
		$rdf_type = 'Image';
	}
	elsif ($self->element->tagName =~ /^(ul|ol)$/i
	&&     ($self->element->getAttribute('class')||'') =~ /\bxoxo\b/)
	{
		$rdf_type = 'Dataset';
	}

	my $outline_node = {
		class    => 'Outline',
		type     => $rdf_type,
		tag      => $self->element->tagName,
		};
	
	foreach my $section (@{$self->{sections}})
	{
		push @{ $outline_node->{children} }, $section->to_hashref;
	}
	
	return $outline_node;
}

1;


__END__

=head1 NAME

HTML::HTML5::Outline::Outlinee - an element with an independent outline

=head1 DESCRIPTION

Elements like E<lt>blockquoteE<gt> have their own independent outline,
which is nested within the primary outline somewhere.

=head2 Methods

=over

=item * C<< element >>

An L<XML::LibXML::Element> for the outlinee.

=item * C<< order >>

The order of the outlinee relative to sections and other outlinees.

=item * C<< sections >>

Sections of this outlinee.

=item * C<< children >>

Sections of this outlinee, sorted in document order.

=back

=head1 SEE ALSO

L<HTML::HTML5::Outline::Section>,
L<HTML::HTML5::Outline>.

=head1 AUTHOR

Toby Inkster, E<lt>tobyink@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENCE

Copyright (C) 2008-2011 by Toby Inkster

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
