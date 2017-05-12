=head1 NAME

HTML::Microformats::Format::hResume - the hResume microformat

=head1 SYNOPSIS

 use HTML::Microformats::DocumentContext;
 use HTML::Microformats::Format::hResume;

 my $context = HTML::Microformats::DocumentContext->new($dom, $uri);
 my @resumes = HTML::Microformats::Format::hResume->extract_all(
                   $dom->documentElement, $context);
 foreach my $resume (@resumes)
 {
   print $resume->get_contact->get_fn . "\n";
 }

=head1 DESCRIPTION

HTML::Microformats::Format::hResume inherits from HTML::Microformats::Format. See the
base class definition for a description of property getter/setter methods,
constructors, etc.

=cut

package HTML::Microformats::Format::hResume;

use base qw(HTML::Microformats::Format HTML::Microformats::Mixin::Parser);
use strict qw(subs vars); no warnings;
use 5.010;

use Object::AUTHORITY;

BEGIN {
	$HTML::Microformats::Format::hResume::AUTHORITY = 'cpan:TOBYINK';
	$HTML::Microformats::Format::hResume::VERSION   = '0.105';
}

sub new
{
	my ($class, $element, $context, %options) = @_;
	my $cache = $context->cache;
	
	return $cache->get($context, $element, $class)
		if defined $cache && $cache->get($context, $element, $class);
	
	my $self = {
		'element'    => $element ,
		'context'    => $context ,
		'cache'      => $cache ,
		'id'         => $context->make_bnode($element) ,
		};
	
	bless $self, $class;
	
	my $clone = $element->cloneNode(1);	
	$self->_expand_patterns($clone);
	$self->_simple_parse($clone);
	
	$self->{'DATA'}->{'contact'} = $self->{'DATA'}->{'address'}
		unless defined $self->{'DATA'}->{'contact'};
	
	if (defined $self->{'DATA'}->{'contact'})
	{
		$self->{'id.holder'} = $self->{'DATA'}->{'contact'}->id(0, 'holder');
	}
	else
	{
		$self->{'id.holder'} = $context->make_bnode;
	}
	
#	# Create links between hCard and hCalendar events found within!
#	foreach my $prop (qw(education experience))
#	{
#		foreach my $e ( @{$self->{'DATA'}->{$prop}} )
#		{
#			foreach my $ehc ( @{$self->{'DATA'}->{$prop.'-hcard'}} )
#			{
#				my $ehcxp = $ehc->{'parent_property_node'}->getAttribute('data-cpan-html-microformats-nodepath');
#				if ($ehcxp eq $e->{'parent_property_node'}->getAttribute('data-cpan-html-microformats-nodepath'))
#				{
#					$e   -> {'associated_hcard'}   = $ehc;
#					$ehc -> {'associated_hevent'}  = $e;
#				}
#			}
#		}
#		
#		foreach my $card ( @{$self->{'DATA'}->{$prop.'-hcard'}} )
#		{
#			$card->{'id.holder'} = $self->id(0, 'holder');
#		}
#		
#		delete $self->{'DATA'}->{$prop.'-hcard'};
#	}

	$cache->set($context, $element, $class, $self)
		if defined $cache;
	
	return $self;
}

sub format_signature
{
	my $self  = shift;
	
	my $cv  = "http://purl.org/captsolo/resume-rdf/0.2/cv#";
	my $cvx = "http://ontologi.es/hresume#";

	# parsing hCards seems to do more harm than good!
	my $rv = {
		'root' => 'hresume',
		'classes' => [
			['summary',     '?'],
			['contact',     'm?',  {'embedded'=>'hCard'}],
			['address',     'tm?', {'embedded'=>'hCard'}],
			['education',   'm*',  {'embedded'=>'hEvent', 'allow-interleaved' => ['vcalendar']}], #}],, 'again-again'=>1}],
			#['education',   'm*',  {'embedded'=>'hCard',  'allow-interleaved' => ['vcalendar', 'vevent'], 'use-key'=>'education-hcard'}],
			['experience',  'm*',  {'embedded'=>'hEvent', 'allow-interleaved' => ['vcalendar']}], #}],, 'again-again'=>1}],
			#['experience',  'm*',  {'embedded'=>'hCard',  'allow-interleaved' => ['vcalendar', 'vevent'], 'use-key'=>'experience-hcard'}],
			['skill',       '*'],
			['affiliation', 'M*',  {'embedded'=>'hCard'}],
			['cite',        't',   {'use-key'=>'publication'}]
		],
		'options' => {
		},
		'rdf:type' => ["${cv}CV"] ,
		'rdf:property' => {
			'summary'     => { 'literal'  => ["${cv}cvDescription"] },
			'experience'  => { 'resource' => ["${cvx}experience"] },
			'education'   => { 'resource' => ["${cvx}education"] },
			'contact'     => { 'resource' => ["${cvx}contact"] },
			'affiliation' => { 'resource' => ["${cvx}affiliation"] },
			'publication' => { 'literal'  => ["${cvx}publication"] },
			'skill'       => { 'literal'  => ["${cvx}skill"] },
			},
	};
	
	return $rv;
}

sub add_to_model
{
	my $self  = shift;
	my $model = shift;

	$self->_simple_rdf($model);
	
	my $cv  = "http://purl.org/captsolo/resume-rdf/0.2/cv#";
	my $rdf = "http://www.w3.org/1999/02/22-rdf-syntax-ns#";
	my $cvx = "http://ontologi.es/hresume#";

	if (defined $self->data->{'contact'})
	{
		$model->add_statement(RDF::Trine::Statement->new(
			$self->id(1),
			RDF::Trine::Node::Resource->new("${cv}aboutPerson"),
			$self->id(1, 'holder'),
			));
		
		$self->data->{'contact'}->add_to_model($model);
	}

	foreach my $experience (@{$self->data->{'experience'}})
	{
		$model->add_statement(RDF::Trine::Statement->new(
			$self->id(1),
			RDF::Trine::Node::Resource->new("${cv}hasWorkHistory"),
			$experience->id(1, 'experience'),
			));
			
		$model->add_statement(RDF::Trine::Statement->new(
			$experience->id(1, 'experience'),
			RDF::Trine::Node::Resource->new("${rdf}type"),
			RDF::Trine::Node::Resource->new("${cv}WorkHistory"),
			));
		
		$model->add_statement(RDF::Trine::Statement->new(
			$experience->id(1, 'experience'),
			RDF::Trine::Node::Resource->new("${cvx}ical-component"),
			$experience->id(1),
			));
			
		$model->add_statement(RDF::Trine::Statement->new(
			$experience->id(1, 'experience'),
			RDF::Trine::Node::Resource->new("${cvx}business-card"),
			$experience->{'associated_vcard'}->id(1),
			))
			if defined $experience->{'associated_vcard'};
		
		$model->add_statement(RDF::Trine::Statement->new(
			$self->id(1, 'holder'),
			RDF::Trine::Node::Resource->new("http://purl.org/uF/hCard/terms/hasHistoricCard"),
			$experience->{'associated_vcard'}->id(1),
			))
			if defined $experience->{'associated_vcard'};
			
		$model->add_statement(RDF::Trine::Statement->new(
			$experience->id(1, 'experience'),
			RDF::Trine::Node::Resource->new("${cv}startDate"),
			$self->_make_literal($experience->data->{'dtstart'}, 'dateTime'),
			))
			if defined $experience->data->{'dtstart'};
		
		$model->add_statement(RDF::Trine::Statement->new(
			$experience->id(1, 'experience'),
			RDF::Trine::Node::Resource->new("${cv}endDate"),
			$self->_make_literal($experience->data->{'dtend'}, 'dateTime'),
			))
			if defined $experience->data->{'dtend'};

		if (defined $experience->{'associated_hcard'}
		&& defined $experience->{'associated_hcard'}->data->{'title'})
		{
			$model->add_statement(RDF::Trine::Statement->new(
				$experience->id(1, 'experience'),
				RDF::Trine::Node::Resource->new("${cv}jobTitle"),
				$self->_make_literal($experience->{'associated_hcard'}->data->{'title'}),
				));
		}

		$experience->add_to_model($model);
		$experience->{'associated_hcard'}->add_to_model($model)
			if defined $experience->{'associated_hcard'};
	}

	foreach my $edu (@{$self->data->{'education'}})
	{
		$model->add_statement(RDF::Trine::Statement->new(
			$self->id(1),
			RDF::Trine::Node::Resource->new("${cv}hasEducation"),
			$edu->id(1, 'education'),
			));
			
		$model->add_statement(RDF::Trine::Statement->new(
			$edu->id(1, 'education'),
			RDF::Trine::Node::Resource->new("${rdf}type"),
			RDF::Trine::Node::Resource->new("${cv}Education"),
			));
		
		$model->add_statement(RDF::Trine::Statement->new(
			$edu->id(1, 'education'),
			RDF::Trine::Node::Resource->new("${cvx}ical-component"),
			$edu->id(1),
			));
			
		$model->add_statement(RDF::Trine::Statement->new(
			$edu->id(1, 'education'),
			RDF::Trine::Node::Resource->new("${cvx}business-card"),
			$edu->{'associated_vcard'}->id(1),
			))
			if defined $edu->{'associated_vcard'};
		
		$model->add_statement(RDF::Trine::Statement->new(
			$self->id(1, 'holder'),
			RDF::Trine::Node::Resource->new("http://purl.org/uF/hCard/terms/hasHistoricCard"),
			$edu->{'associated_vcard'}->id(1),
			))
			if defined $edu->{'associated_vcard'};
			
		$model->add_statement(RDF::Trine::Statement->new(
			$edu->id(1, 'education'),
			RDF::Trine::Node::Resource->new("${cv}eduStartDate"),
			$self->_make_literal($edu->data->{'dtstart'}, 'dateTime'),
			))
			if defined $edu->data->{'dtstart'};
		
		$model->add_statement(RDF::Trine::Statement->new(
			$edu->id(1, 'education'),
			RDF::Trine::Node::Resource->new("${cv}eduGradDate"),
			$self->_make_literal($edu->data->{'dtend'}, 'dateTime'),
			))
			if defined $edu->data->{'dtend'};

		$edu->add_to_model($model);
		$edu->{'associated_hcard'}->add_to_model($model)
			if defined $edu->{'associated_hcard'};
	}

	foreach my $skill (@{$self->data->{'skill'}})
	{
		my $skill_bnode = $self->id(1, 'skill.'.$skill);
		
		$model->add_statement(RDF::Trine::Statement->new(
			$self->id(1),
			RDF::Trine::Node::Resource->new("${cv}hasSkill"),
			$skill_bnode,
			));
		$model->add_statement(RDF::Trine::Statement->new(
			$skill_bnode,
			RDF::Trine::Node::Resource->new("${rdf}type"),
			RDF::Trine::Node::Resource->new("${cv}Skill"),
			));
		$model->add_statement(RDF::Trine::Statement->new(
			$skill_bnode,
			RDF::Trine::Node::Resource->new("${cv}skillName"),
			$self->_make_literal($skill),
			));
	}

	return $self;
}

sub profiles
{
	my $class = shift;
	return qw(http://microformats.org/profile/hresume
		http://ufs.cc/x/hresume
		http://purl.org/uF/hResume/0.1/);
}

1;

=head1 MICROFORMAT

HTML::Microformats::Format::hResume supports hResume as described at
L<http://microformats.org/wiki/hresume>.

=head1 RDF OUTPUT

The RDF output is modelled on Uldis Bojars' ResumeRDF Ontology
L<http://purl.org/captsolo/resume-rdf/0.2/cv#>, with some additional
terms from Toby Inkster's hResume vocab <http://ontologi.es/hresume#>.

=head1 BUGS

Please report any bugs to L<http://rt.cpan.org/>.

=head1 SEE ALSO

L<HTML::Microformats::Format>,
L<HTML::Microformats::Format::hCard>,
L<HTML::Microformats::Format::hCalendar>,
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

