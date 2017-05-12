=head1 NAME

HTML::Microformats::Format::hCalendar - the hCalendar microformat

=head1 SYNOPSIS

 use HTML::Microformats::DocumentContext;
 use HTML::Microformats::Format::hCalendar;

 my $context = HTML::Microformats::DocumentContext->new($dom, $uri);
 my @cals    = HTML::Microformats::Format::hCalendar->extract_all(
                   $dom->documentElement, $context);
 foreach my $cal (@cals)
 {
   foreach my $event ($cal->get_vevent)
   {
     printf("%s: %s\n", $ev->get_dtstart, $ev->get_summary);
   }
 }

=head1 DESCRIPTION

HTML::Microformats::Format::hCalendar inherits from HTML::Microformats::Format. See the
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

package HTML::Microformats::Format::hCalendar;

use base qw(HTML::Microformats::Format HTML::Microformats::Mixin::Parser);
use strict qw(subs vars); no warnings;
use 5.010;

use HTML::Microformats::Utilities qw(searchClass searchAncestorClass);
use HTML::Microformats::Format::hEntry;
use HTML::Microformats::Format::hEvent;
use HTML::Microformats::Format::hTodo;
use HTML::Microformats::Format::hAlarm;
use HTML::Microformats::Format::hFreebusy;

use Object::AUTHORITY;

BEGIN {
	$HTML::Microformats::Format::hCalendar::AUTHORITY = 'cpan:TOBYINK';
	$HTML::Microformats::Format::hCalendar::VERSION   = '0.105';
}
our $HAS_ICAL_EXPORT;
BEGIN
{
	local $@ = undef;
	eval 'use RDF::iCalendar;';
	$HAS_ICAL_EXPORT = 1
		if RDF::iCalendar::Exporter->can('new'); 
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
	
	foreach my $todolist (searchClass('vtodo-list', $element))
	{
		my $holder_calendar = searchAncestorClass('vcalendar', $todolist);
		if (!defined $holder_calendar or
		$element->getAttribute('data-cpan-html-microformats-nodepath') eq $holder_calendar->getAttribute('data-cpan-html-microformats-nodepath'))
		{
			push @{$self->{'DATA'}->{'vtodo'}},
				HTML::Microformats::Format::hTodo->extract_all_xoxo($todolist, $context);
		}
	}
	
	$self->_calculate_relationships;
	$self->_cement_relationships;

	$cache->set($context, $element, $class, $self)
		if defined $cache;

	return $self;
}

sub _calculate_relationships
{
	my $self = shift;
	
	my %xpath;
	foreach my $component (qw(vevent vtodo vjournal))
	{
		foreach my $object (@{ $self->data->{$component} })
		{
			my $xp = $object->element->getAttribute('data-cpan-html-microformats-nodepath');
			$xpath{$xp} = $object;
		}
	}
	my @xpaths = keys %xpath;
	foreach my $xp (@xpaths)
	{
		unless (defined $xpath{$xp}->{'related'}->{'parent'}
		or defined $xpath{$xp}->data->{'parent'})
		{
			my $parent = __findParent($xp, @xpaths);
			if ($parent)
			{
				$xpath{$xp}->{'related'}->{'parent'} = $xpath{$parent};
				push @{ $xpath{$parent}->{'related'}->{'child'} }, $xpath{$xp};
			}
		}
	}
}

sub __findParent
{
	my $x = shift;
	my $longest = '';
	
	foreach my $potential (@_)
	{
		if (__ancestorOf($potential, $x))
		{
			$longest = $potential
				if (length($potential) > length($longest));
		}
	}
	
	return $longest;
}

sub __ancestorOf
{
	my ($a, $b) = @_;
	return if ($a eq $b);
	return (substr($b, 0, length($a)) eq $a);
}

sub _cement_relationships
{
	my $self = shift;
	
	my @objects;
	foreach my $component (qw(vevent vtodo vjournal))
	{
		push @objects, @{ $self->data->{$component} };
	}
	
	foreach my $object (@objects)
	{
		# Share parent data between $obj->{'DATA'} and $obj->{'related'}.
		if (defined $object->{'related'}->{'parent'}
		and !defined $object->{'DATA'}->{'parent'})
		{
			$object->{'DATA'}->{'parent'} = $object->{'related'}->{'parent'}->get_uid;
		}
		elsif (!defined $object->{'related'}->{'parent'}
		and defined $object->{'DATA'}->{'parent'})
		{
			$object->{'related'}->{'parent'} =
				grep {$_->get_uid eq $object->{'DATA'}->{'parent'}} @objects;
		}
		
		# Share other data similarly.
		foreach my $relationship (qw(sibling other child))
		{
			foreach my $related (@{ $object->{'related'}->{$relationship} })
			{
				next unless defined $related->get_uid;
				
				push @{$object->{'DATA'}->{$relationship}},
					$related->get_uid
					unless grep { $_ eq $related->get_uid } @{$object->{'DATA'}->{$relationship}};
				
				$object->{'DATA'}->{$relationship} = undef
					unless @{ $object->{'DATA'}->{$relationship} };
			}
			foreach my $related (@{ $object->{'DATA'}->{$relationship} })
			{
				push @{$object->{'related'}->{$relationship}},
					(grep { $_->get_uid eq $related } @objects);
				
				$object->{'related'}->{$relationship} = undef
					unless @{$object->{'related'}->{$relationship}};
			}
		}
	}
	
	return $self;
}

sub extract_all
{
	my ($class, $element, $context) = @_;
	
	my @cals = HTML::Microformats::Format::extract_all($class, $element, $context);
	
	if ($element->tagName eq 'html' || !@cals)
	{
		my @components  = HTML::Microformats::Format::hEvent->extract_all($element, $context);
		push @components, HTML::Microformats::Format::hTodo->extract_all($element, $context);
		push @components, HTML::Microformats::Format::hFreebusy->extract_all($element, $context);
		push @components, HTML::Microformats::Format::hEntry->extract_all($element, $context);
		
		my $orphans = 0;
		foreach my $c (@components)
		{
			$orphans++ unless searchAncestorClass('hcalendar', $c->element);
		}
		if ($orphans)
		{
			my $slurpy = $class->new($element, $context);
			unshift @cals, $slurpy;
		}
	}
	
	return @cals;
}

sub format_signature
{
	my $ical  = 'http://www.w3.org/2002/12/cal/icaltzd#';
	
	return {
		'root' => 'vcalendar',
		'classes' => [
			['vevent',           'M*',  {embedded=>'hEvent'}],
			['vtodo',            'M*',  {embedded=>'hTodo'}],
			['hentry',           'M*',  {embedded=>'hEntry', 'use-key'=>'vjournal'}],
			['vfreebusy',        'M*',  {embedded=>'hFreebusy'}],
			['calscale',         '?'],
			['method',           '?'],
		],
		'options' => {
		},
		'rdf:type' => ["${ical}Vcalendar"] ,
		'rdf:property' => {
			'vevent'           => { 'resource' => ["${ical}component"] } ,
			'vtodo'            => { 'resource' => ["${ical}component"] } ,
			'vfreebusy'        => { 'resource' => ["${ical}component"] } ,
			'vjournal'         => { 'resource' => ["${ical}component"] } ,
			'calscale'         => { 'literal'  => ["${ical}calscale"] , 'literal_datatype' => 'string'} ,
			'method'           => { 'literal'  => ["${ical}method"] ,   'literal_datatype' => 'string'} ,
		},
	};
}

sub add_to_model
{
	my $self  = shift;
	my $model = shift;
	
	$self->_simple_rdf($model);

	foreach my $journal (@{ $self->data->{vjournal} })
	{
		$journal->add_to_model_ical($model);
	}
	
	return $self;
}

sub profiles
{
	return qw(http://purl.org/uF/hCalendar/1.1/
		http://microformats.org/profile/hcalendar
		http://ufs.cc/x/hcalendar
		http://microformats.org/profile/specs
		http://ufs.cc/x/specs
		http://dannyayers.com/microformats/hcalendar-profile
		http://www.w3.org/2002/12/cal/hcal
		http://purl.org/uF/hCalendar/1.0/
		http://purl.org/uF/2008/03/);
}

sub to_icalendar
{
	my ($self) = @_;
	die "Need RDF::iCalendar to export iCalendar data.\n" unless $HAS_ICAL_EXPORT;
	my $exporter = RDF::iCalendar::Exporter->new;
	return $exporter->export_calendar($self->model, $self->id(1))->to_string;
}

1;

=head1 MICROFORMAT

HTML::Microformats::Format::hCalendar supports hCalendar as described at
L<http://microformats.org/wiki/User:TobyInk/hcalendar-1.1>.

=head1 RDF OUTPUT

Data is returned using the W3C's revised iCalendar vocabulary
(L<http://www.w3.org/2002/12/cal/icaltzd#>) with some supplemental
terms from Toby Inkster's revised iCalendar extensions vocabulary
(L<http://buzzword.org.uk/rdf/icaltzdx#>) and occasional other terms.

=head1 BUGS

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

