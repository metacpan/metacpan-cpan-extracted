=head1 NAME

HTML::Microformats::Format::XMDP - the XMDP microformat

=head1 SYNOPSIS

 use HTML::Microformats;
 use LWP::Simple qw[get];
 use RDF::TrineShortcuts;
 
 my $uri  = 'http://microformats.org/profile/hcard';
 my $html = get($uri);
 my $doc  = HTML::Microformats->new_document($html, $uri);
 $doc->assume_all_profiles;
 
 my @xmdp_objects = $doc->objects('XMDP');
 foreach my $xo (@xmdp_objects)
 {
   print $xo->serialise_model(
       as         => 'Turtle',
       namespaces => {
           rdfs  => 'http://www.w3.org/2000/01/rdf-schema#',
           hcard => 'http://microformats.org/profile/hcard#',
           },
       );
   print "########\n\n";
 }

=head1 DESCRIPTION

HTML::Microformats::Format::XMDP inherits from HTML::Microformats::Format. See the
base class definition for a description of property getter/setter methods,
constructors, etc.

HTML::Microformats::Format::XMDP also inherits from HTML::Microformats::Format::XOXO, and
the C<data> method returns the same structure.

=cut

package HTML::Microformats::Format::XMDP;

use base qw(HTML::Microformats::Format::XOXO);
use strict qw(subs vars); no warnings;
use 5.010;

use Object::AUTHORITY;

BEGIN {
	$HTML::Microformats::Format::XMDP::AUTHORITY = 'cpan:TOBYINK';
	$HTML::Microformats::Format::XMDP::VERSION   = '0.105';
}

sub new
{
	my $class = shift;
	my $self  = $class->SUPER::new(@_);
	
	return $self;
}

sub format_signature
{
	return {
		'root'         => ['profile'] ,
		'classes'      => [] ,
		'rdf:type'     => [] ,
		'rdf:property' => {} ,
		}
}

sub profiles
{
	return qw(http://gmpg.org/xmdp/1);
}

sub add_to_model
{
	my $self  = shift;
	my $model = shift;
	
	$self->SUPER::add_to_model($model);

	while (my ($term, $data) = each %{ $self->data })
	{
		$self->_add_term_to_model($model, $term, $data);
	}
	
	return $self;
}

sub _add_term_to_model
{
	my ($self, $model, $term, $data) = @_;
	
	my $rdfs  = 'http://www.w3.org/2000/01/rdf-schema#';
	
	my $ident = RDF::Trine::Node::Blank->new(
		substr($self->context->make_bnode, 2));
	if (defined $data->{'id'})
	{
		$ident = RDF::Trine::Node::Resource->new(
			$self->context->uri('#'.$data->{'id'}));
	}
	
	$model->add_statement(RDF::Trine::Statement->new(
		$ident,
		RDF::Trine::Node::Resource->new("${rdfs}label"),
		$self->_make_literal($term),
		));

	$model->add_statement(RDF::Trine::Statement->new(
		$ident,
		RDF::Trine::Node::Resource->new("${rdfs}isDefinedBy"),
		$self->id(1),
		));

	foreach my $item (@{$data->{'items'}})
	{
		$model->add_statement(RDF::Trine::Statement->new(
			$ident,
			RDF::Trine::Node::Resource->new("${rdfs}comment"),
			$self->_make_literal($item->{'text'}),
			))
			if defined $item->{'text'};

		if ($item->{'rel'} =~ /^(help|glossary)$/ && defined $item->{'url'})
		{
			$model->add_statement(RDF::Trine::Statement->new(
				$ident,
				RDF::Trine::Node::Resource->new("http://www.w3.org/1999/xhtml/vocab#".lc $1),
				RDF::Trine::Node::Resource->new($item->{'url'}),
				));
		}
		
		while (my ($child_term, $child_data) = each %{ $item->{'properties'} })
		{
			my $child_ident = $self->_add_term_to_model($model, $child_term, $child_data);
			$model->add_statement(RDF::Trine::Statement->new(
				$ident,
				RDF::Trine::Node::Resource->new("${rdfs}seeAlso"),
				$child_ident,
				));
		}
	}
		
	return $ident;
}

1;

=head1 MICROFORMAT

HTML::Microformats::Format::XMDP supports XMDP as described at
L<http://gmpg.org/xmdp/>.

=head1 RDF OUTPUT

Data is returned using RDFS.

=head1 BUGS

A limitation is that for any E<lt>ddE<gt> element with
E<lt>dlE<gt> children, only the first such E<lt>dlE<gt>
is looked at. This means that the XFN 1.1 profile document
is only partially parsable; most other microformat profile
document can be properly parsed though.

Please report any bugs to L<http://rt.cpan.org/>.

=head1 SEE ALSO

L<HTML::Microformats::Format>,
L<HTML::Microformats>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

Copyright 2008-2012 Toby Inkster

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.


=cut

