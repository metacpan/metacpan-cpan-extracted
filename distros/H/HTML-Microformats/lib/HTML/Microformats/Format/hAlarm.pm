=head1 NAME

HTML::Microformats::Format::hAlarm - an hCalendar alarm component

=head1 SYNOPSIS

 use Data::Dumper;
 use HTML::Microformats::DocumentContext;
 use HTML::Microformats::Format::hCalendar;

 my $context = HTML::Microformats::DocumentContext->new($dom, $uri);
 my @cals    = HTML::Microformats::Format::hCalendar->extract_all(
                   $dom->documentElement, $context);
 foreach my $cal (@cals)
 {
   foreach my $ev ($cal->get_vevent)
   {
     foreach my $alarm ($ev->get_valarm)
     {
       print $alarm->get_description . "\n";
	   }
   }
 }

=head1 DESCRIPTION

HTML::Microformats::Format::hAlarm is a helper module for HTML::Microformats::Format::hCalendar.
This class is used to represent alarm components within calendars. Generally speaking,
you want to use HTML::Microformats::Format::hCalendar instead.

HTML::Microformats::Format::hAlarm inherits from HTML::Microformats::Format. See the
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

package HTML::Microformats::Format::hAlarm;

use base qw(HTML::Microformats::Format HTML::Microformats::Mixin::Parser);
use strict qw(subs vars); no warnings;
use 5.010;

use Object::AUTHORITY;

BEGIN {
	$HTML::Microformats::Format::hAlarm::AUTHORITY = 'cpan:TOBYINK';
	$HTML::Microformats::Format::hAlarm::VERSION   = '0.105';
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

	$cache->set($context, $element, $class, $self)
		if defined $cache;

	return $self;
}

sub format_signature
{
	my $ical  = 'http://www.w3.org/2002/12/cal/icaltzd#';
	my $icalx = 'http://buzzword.org.uk/rdf/icaltzdx#';

	return {
		'root' => 'valarm',
		'classes' => [
			['action',       '?',  {'value-title'=>'allow'}],
			['attach',       'U?'],
			['attendee',     'M*', {'embedded'=>'hCard', 'is-in-cal'=>1}],
			['description',  '?'],
			['duration',     'D?'],
			['repeat',       'n?', {'value-title'=>'allow'}],
			['summary',      '1'],
			['trigger',      'D?'] # TODO: should really allow 'related' subproperty and allow datetime values too. post-0.001
		],
		'options' => {
			'rel-enclosure'  => 'attach',
		},
		'rdf:type' => ["${ical}Valarm"] ,
		'rdf:property' => {
			'action'           => { 'literal'  => ["${ical}action"] } ,
#			'attach'           => { 'resource' => ["${ical}attach"] } ,
			'attendee'         => { 'resource' => ["${ical}attendee"], 'literal'  => ["${icalx}attendee"] } ,
			'description'      => { 'literal'  => ["${ical}description"] } ,
			'duration'         => { 'literal'  => ["${ical}duration"] } ,
			'repeat'           => { 'literal'  => ["${ical}repeat"] , 'literal_datatype'=>'integer' } ,
			'summary'          => { 'literal'  => ["${ical}summary"] } ,
			'trigger'          => { 'literal'  => ["${ical}trigger"] } ,
		},
	};
}

sub add_to_model
{
	my $self  = shift;
	my $model = shift;

	my $ical  = 'http://www.w3.org/2002/12/cal/icaltzd#';
	
	$self->_simple_rdf($model);

	foreach my $val ( @{ $self->data->{attach} } )
	{
		$model->add_statement(RDF::Trine::Statement->new(
			$self->id(1),
			RDF::Trine::Node::Resource->new("${ical}attach"),
			RDF::Trine::Node::Resource->new($val->data->{href}),
			));
		$val->add_to_model($model);
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

