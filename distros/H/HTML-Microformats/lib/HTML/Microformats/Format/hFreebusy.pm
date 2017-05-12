=head1 NAME

HTML::Microformats::Format::hFreebusy - an hCalendar free/busy component

=head1 SYNOPSIS

 use Data::Dumper;
 use HTML::Microformats::DocumentContext;
 use HTML::Microformats::Format::hCalendar;

 my $context = HTML::Microformats::DocumentContext->new($dom, $uri);
 my @cals    = HTML::Microformats::Format::hCalendar->extract_all(
                   $dom->documentElement, $context);
 foreach my $cal (@cals)
 {
   foreach my $fb ($cal->get_vfreebusy)
   {
     printf("%s\n", $fb->get_summary);
   }
 }

=head1 DESCRIPTION

HTML::Microformats::Format::hFreebusy is a helper module for HTML::Microformats::hCalendar.
This class is used to represent free/busy scheduling components within calendars, which (in practice)
are never really published as hCalendar. Generally speaking, you want to use
HTML::Microformats::hCalendar instead.

HTML::Microformats::Format::hFreebusy inherits from HTML::Microformats::Format. See the
base class definition for a description of property getter/setter methods,
constructors, etc.

=head2 Additional Method

=over

=item * C<< to_icalendar >>

This method exports the data in iCalendar format. It requires
L<RDF::iCalendar> to work, and will throw an error at run-time
if it's not available.

=back

=cut

package HTML::Microformats::Format::hFreebusy;

use base qw(HTML::Microformats::Format HTML::Microformats::Mixin::Parser);
use strict qw(subs vars); no warnings;
use 5.010;

use HTML::Microformats::Utilities qw(searchClass stringify);
use HTML::Microformats::Datatype::Interval;
use RDF::Trine;

use Object::AUTHORITY;

BEGIN {
	$HTML::Microformats::Format::hFreebusy::AUTHORITY = 'cpan:TOBYINK';
	$HTML::Microformats::Format::hFreebusy::VERSION   = '0.105';
}

sub new
{
	my ($class, $element, $context) = @_;
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
	$self->_parse_freebusy($clone);

	$cache->set($context, $element, $class, $self)
		if defined $cache;

	return $self;
}

sub _parse_freebusy
{
	my ($self, $elem) = @_;
	
	FREEBUSY: foreach my $fb (searchClass('freebusy', $elem))
	{
		my @fbtype_nodes = searchClass('fbtype', $fb);
		next FREEBUSY unless @fbtype_nodes;
		my $FB = { fbtype => stringify($fbtype_nodes[0],  {'value-title'=>'allow'}) };
		
		my @value_nodes = searchClass('value', $fb);
		VALUE: foreach my $v (@value_nodes)
		{
			my $val = HTML::Microformats::Datatype::Interval->parse(stringify($v), $v, $self->context);
			push @{$FB->{'value'}}, $val if defined $val;
		}
		push @{$self->{'DATA'}->{'freebusy'}}, $FB;
	}
	
	return $self;
}

sub format_signature
{
	my $ical  = 'http://www.w3.org/2002/12/cal/icaltzd#';
	my $icalx = 'http://buzzword.org.uk/rdf/icaltzdx#';

	return {
		'root' => 'vtodo',
		'classes' => [
			['attendee',         'M*',  {embedded=>'hCard !person', 'is-in-cal'=>1}],
			['contact',          'M*',  {embedded=>'hCard !person', 'is-in-cal'=>1}],
			['comment',          '*'],
			['dtend',            'd?'],
			['dtstamp',          'd?'],
			['dtstart',          'd1'],
			['duration',         'D?'],
			['freebusy',         '#+'],
			['organizer',        'M?',  {embedded=>'hCard !person', 'is-in-cal'=>1}],
			['summary',          '1'],
			['uid',              'U?'],
			['url',              'U?'],
		],
		'options' => {
		},
		'rdf:type' => ["${ical}Vfreebusy"] ,
		'rdf:property' => {
			'attendee'         => { 'resource' => ["${ical}attendee"],  'literal'  => ["${icalx}attendee-literal"] } ,
			'comment'          => { 'literal'  => ["${ical}comment"] } ,
			'contact'          => { 'resource' => ["${icalx}contact"],  'literal'  => ["${ical}contact"] } ,
			'dtend'            => { 'literal'  => ["${ical}dtend"] } ,
			'dtstamp'          => { 'literal'  => ["${ical}dtstamp"] } ,
			'dtstart'          => { 'literal'  => ["${ical}dtstart"] } ,
			'duration'         => { 'literal'  => ["${ical}duration"] } ,
			'organizer'        => { 'resource' => ["${ical}organizer"], 'literal'  => ["${icalx}organizer-literal"] } ,
			'summary'          => { 'literal'  => ["${ical}summary"] } ,
			'uid'              => { 'resource' => ["${ical}uid"] ,      'literal'  => ["${ical}uid"] , 'literal_datatype' => 'string' } ,
			'url'              => { 'resource' => ["${ical}url"] } ,
		},
	};
}

sub add_to_model
{
	my $self  = shift;
	my $model = shift;

	my $ical  = 'http://www.w3.org/2002/12/cal/icaltzd#';
	
	$self->_simple_rdf($model);
	
	foreach my $fb (@{$self->data->{'freebusy'}})
	{
		$fb->{'_id'} = $self->context->make_bnode
			unless defined $fb->{'_id'};
		
		$model->add_statement(RDF::Trine::Statement->new(
			$self->id(1),
			RDF::Trine::Node::Resource->new("${ical}freebusy"),
			RDF::Trine::Node::Blank->new(substr $fb->{'_id'}, 2),
			));
			
		$model->add_statement(RDF::Trine::Statement->new(
			RDF::Trine::Node::Blank->new(substr $fb->{'_id'}, 2),
			RDF::Trine::Node::Resource->new("${ical}fbtype"),
			RDF::Trine::Node::Literal->new($fb->{'fbtype'}, undef, 'http://www.w3.org/2001/XMLSchema#string'),
			));

		foreach my $val (@{$fb->{'value'}})
		{
			$model->add_statement(RDF::Trine::Statement->new(
				RDF::Trine::Node::Blank->new(substr $fb->{'_id'}, 2),
				RDF::Trine::Node::Resource->new("http://www.w3.org/1999/02/22-rdf-syntax-ns#value"),
				RDF::Trine::Node::Literal->new($val->to_string, undef, $val->datatype),
				));
		}
	}

	return $self;
}

sub profiles
{
	return HTML::Microformats::Format::hCalendar::profiles(@_);
}

sub to_icalendar
{
	my ($self) = @_;
	die "Need RDF::iCalendar to export iCalendar data.\n"
		unless $HTML::Microformats::Format::hCalendar::HAS_ICAL_EXPORT;
	my $exporter = RDF::iCalendar::Exporter->new;
	return $exporter->export_component($self->model, $self->id(1))->to_string;
}

1;

=head1 BUGS

Please report any bugs to L<http://rt.cpan.org/>.

=head1 SEE ALSO

L<HTML::Microformats::Format::hCalendar>,
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
