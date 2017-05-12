=head1 NAME

HTML::Microformats::Format::RelLicense - the rel-license microformat

=head1 SYNOPSIS

 my @licences = HTML::Microformats::Format::RelLicense->extract_all(
                   $doc->documentElement, $context);
 foreach my $licence (@licences)
 {
   print $licence->get_href . "\n";
 }

=head1 DESCRIPTION

HTML::Microformats::Format::RelLicense inherits from HTML::Microformats::Format_Rel. See the
base class definition for a description of property getter/setter methods,
constructors, etc.

=cut

package HTML::Microformats::Format::RelLicense;

use base qw(HTML::Microformats::Format_Rel);
use strict qw(subs vars); no warnings;
use 5.010;

use Object::AUTHORITY;

BEGIN {
	$HTML::Microformats::Format::RelLicense::AUTHORITY = 'cpan:TOBYINK';
	$HTML::Microformats::Format::RelLicense::VERSION   = '0.105';
}

sub format_signature
{
	return {
		'rel'      => 'license' ,
		'classes'  => [
				['href',     '1#'] ,
				['label',    '1#'] ,
				['title',    '1#'] ,
			] ,
		'rdf:type' => [] ,
		'rdf:property' => {} ,
		}
}

sub profiles
{
	return qw(http://microformats.org/profile/rel-license
		http://ufs.cc/x/rel-license
		http://microformats.org/profile/specs
		http://ufs.cc/x/specs
		http://purl.org/uF/rel-license/1.0/
		http://purl.org/uF/2008/03/);
}

sub add_to_model
{
	my $self  = shift;
	my $model = shift;
	
	$model->add_statement(RDF::Trine::Statement->new(
		RDF::Trine::Node::Resource->new($self->context->document_uri),
		RDF::Trine::Node::Resource->new("http://www.w3.org/1999/02/22-rdf-syntax-ns#type"),
		RDF::Trine::Node::Resource->new("http://creativecommons.org/ns#Work"),
		));
		
	$model->add_statement(RDF::Trine::Statement->new(
		RDF::Trine::Node::Resource->new($self->data->{'href'}),
		RDF::Trine::Node::Resource->new("http://www.w3.org/1999/02/22-rdf-syntax-ns#type"),
		RDF::Trine::Node::Resource->new("http://creativecommons.org/ns#License"),
		));

	foreach my $uri (qw(http://creativecommons.org/ns#license
		http://www.w3.org/1999/xhtml/vocab#license
		http://purl.org/dc/terms/license))
	{
		$model->add_statement(RDF::Trine::Statement->new(
			RDF::Trine::Node::Resource->new($self->context->document_uri),
			RDF::Trine::Node::Resource->new($uri),
			RDF::Trine::Node::Resource->new($self->data->{'href'}),
			));
	}
		
	return $self;
}

1;

=head1 MICROFORMAT

HTML::Microformats::Format::RelLicense supports rel-license as described at
L<http://microformats.org/wiki/rel-license>.

=head1 RDF OUTPUT

Data is returned using the Creative Commons vocabulary
(L<http://creativecommons.org/ns#>) and occasional other terms.

=head1 BUGS

Please report any bugs to L<http://rt.cpan.org/>.

=head1 SEE ALSO

L<HTML::Microformats::Format_Rel>,
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

