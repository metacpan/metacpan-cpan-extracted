#-----------------------------------------------------------------
# MOSES::MOBY::Package
# Author: Edward Kawas <edward.kawas@gmail.com>,
#         Martin Senger <martin.senger@gmail.com>
# For copyright and disclaimer see below.
#
# $Id: Package.pm,v 1.4 2008/04/29 19:45:01 kawas Exp $
#-----------------------------------------------------------------

#-----------------------------------------------------------------
#
# MOSES::MOBY::Package
#
#-----------------------------------------------------------------
package MOSES::MOBY::Package;
use base qw( MOSES::MOBY::Base );
use XML::LibXML;
use MOSES::MOBY::Tags;
use MOSES::MOBY::ServiceException;
use strict;

# add versioning to this module
use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.4 $ =~ /: (\d+)\.(\d+)/;

#-----------------------------------------------------------------
# A list of allowed attribute names. See MOSES::MOBY::Base for details.
#-----------------------------------------------------------------
{
    my %_allowed =
	(
	 authority     => undef,
	 jobs          => {type => 'MOSES::MOBY::Job', is_array => 1},
	 exceptions    => {type => 'MOSES::MOBY::ServiceException', is_array => 1},
	 serviceNotes  => undef,
         cdata         => {type => MOSES::MOBY::Base->BOOLEAN},
	 );

    sub _accessible {
	my ($self, $attr) = @_;
	exists $_allowed{$attr} or $self->SUPER::_accessible ($attr);
    }
    sub _attr_prop {
	my ($self, $attr_name, $prop_name) = @_;
	my $attr = $_allowed {$attr_name};
	return ref ($attr) ? $attr->{$prop_name} : $attr if $attr;
	return $self->SUPER::_attr_prop ($attr_name, $prop_name);
    }
}

#-----------------------------------------------------------------
# init
#-----------------------------------------------------------------
sub init {
    my ($self) = shift;
    $self->SUPER::init();
    $self->cdata ('no');
}

#-----------------------------------------------------------------
# job_by_id
#-----------------------------------------------------------------

=head2 job_by_id

In this package, find and return a C<MOSES::MOBY::Job> object with the given
ID. Or throw an exception if such job does not exist. (TBD)

=cut

sub job_by_id {
    my ($self, $jobId) = @_;
    foreach my $job (@{ $self->jobs }) {
	return $job if $job->jid eq $jobId;
    }
    $self->throw ("Job '$jobId' not found.");
}


#-----------------------------------------------------------------
# size
#-----------------------------------------------------------------
sub size {
    my $self = shift;
    return 0 unless $self->jobs;
    return 0+@{ $self->jobs };
}

#-----------------------------------------------------------------
# toXML
#-----------------------------------------------------------------
sub toXML {
    my $self = shift;
    $self->increaseXMLCounter;
    my $root = $self->createXMLElement (MOBY);
    my $elemContent = $self->createXMLElement (MOBYCONTENT);
    $self->setXMLAttribute ($elemContent, AUTHORITY, $self->authority);

    if ($self->serviceNotes or $self->{exceptions}) {
	my $sNotes = $self->createXMLElement (SERVICENOTES);
	if ($self->serviceNotes) {
	    my $notes =	$self->createXMLElement (NOTES);
	    if ($self->cdata) {
		$notes->appendChild (XML::LibXML::CDATASection->new ($self->serviceNotes));
	    } else {
		$notes->appendText ($self->serviceNotes);
	    }
	    $sNotes->appendChild ($notes);
	}
	if ($self->exceptions) {
	    foreach my $exception (@{ $self->exceptions }) {
		$sNotes->appendChild ($exception->toXML);
	    }
	}
	$elemContent->appendChild ($sNotes);
    }
    
    if ($self->jobs) {
	foreach my $job (@{ $self->jobs }) {
	    $elemContent->appendChild ($job->toXML);
	}
    }

    $root->appendChild ($elemContent);
    return $self->closeXML ($root);
}


#-----------------------------------------------------------------
#
# MOSES::MOBY::DataElement
#
#-----------------------------------------------------------------
package MOSES::MOBY::DataElement;
use base qw( MOSES::MOBY::Base );
use XML::LibXML;
use MOSES::MOBY::Tags;
use strict;

#-----------------------------------------------------------------
# A list of allowed attribute names. See MOSES::MOBY::Base for details.
#-----------------------------------------------------------------
{
    my %_allowed =
	(
	 name => undef,
	 );

    sub _accessible {
	my ($self, $attr) = @_;
	exists $_allowed{$attr} or $self->SUPER::_accessible ($attr);
    }
    sub _attr_prop {
	my ($self, $attr_name, $prop_name) = @_;
	my $attr = $_allowed {$attr_name};
	return ref ($attr) ? $attr->{$prop_name} : $attr if $attr;
	return $self->SUPER::_attr_prop ($attr_name, $prop_name);
    }
}

sub init {
    my ($self) = shift;
    $self->SUPER::init();
    $self->name ('');
}

#-----------------------------------------------------------------
# toXML
#    return a LibXML::Element called _dummy_ (it will be later
#    changed either to Simple or to Collection)
#-----------------------------------------------------------------
sub toXML {
    my $self = shift;
    $self->increaseXMLCounter;

    my $root = XML::LibXML::Element->new ('_dummy_');
    $root->setNamespace (MOBY_XML_NS, MOBY_XML_NS_PREFIX);
    $root->setAttributeNS (MOBY_XML_NS, ARTICLENAME, $self->name)
	if $self->name;
    
    return $self->closeXML ($root);
}

#-----------------------------------------------------------------
#
# MOSES::MOBY::Simple
#
#-----------------------------------------------------------------
package MOSES::MOBY::Simple;
use base qw( MOSES::MOBY::DataElement );
use XML::LibXML;
use MOSES::MOBY::Tags;
use strict;

#-----------------------------------------------------------------
# A list of allowed attribute names. See MOSES::MOBY::Base for details.
#-----------------------------------------------------------------
{
    my %_allowed =
	(
	 data  => {type => 'MOSES::MOBY::Data::Object'},
	 );

    sub _accessible {
	my ($self, $attr) = @_;
	exists $_allowed{$attr} or $self->SUPER::_accessible ($attr);
    }
    sub _attr_prop {
	my ($self, $attr_name, $prop_name) = @_;
	my $attr = $_allowed {$attr_name};
	return ref ($attr) ? $attr->{$prop_name} : $attr if $attr;
	return $self->SUPER::_attr_prop ($attr_name, $prop_name);
    }
}

#-----------------------------------------------------------------
# toXML
#-----------------------------------------------------------------
sub toXML {
    my $self = shift;
    $self->increaseXMLCounter;
    my $root = $self->SUPER::toXML;
    $root->setNodeName (MOBY_XML_NS_PREFIX . ':' . SIMPLE);
    $root->appendChild ($self->data->toXML)
	if $self->data;
    return $self->closeXML ($root);
}


#-----------------------------------------------------------------
#
# MOSES::MOBY::Collection
#
#-----------------------------------------------------------------
package MOSES::MOBY::Collection;
use base qw( MOSES::MOBY::DataElement );
use XML::LibXML;
use MOSES::MOBY::Tags;
use strict;

#-----------------------------------------------------------------
# A list of allowed attribute names. See MOSES::MOBY::Base for details.
#-----------------------------------------------------------------
{
    my %_allowed =
	(
	 data  => {type => 'MOSES::MOBY::Simple', is_array => 1},
	 );

    sub _accessible {
	my ($self, $attr) = @_;
	exists $_allowed{$attr} or $self->SUPER::_accessible ($attr);
    }
    sub _attr_prop {
	my ($self, $attr_name, $prop_name) = @_;
	my $attr = $_allowed {$attr_name};
	return ref ($attr) ? $attr->{$prop_name} : $attr if $attr;
	return $self->SUPER::_attr_prop ($attr_name, $prop_name);
    }
}

#-----------------------------------------------------------------
# toXML
#-----------------------------------------------------------------
sub toXML {
    my $self = shift;
    $self->increaseXMLCounter;
    my $root = $self->SUPER::toXML;
    $root->setNodeName (MOBY_XML_NS_PREFIX . ':' . COLLECTION);
    if ($self->data) {
	foreach my $simple (@{ $self->data }) {
	    $root->appendChild ($simple->toXML);
	}
    }
    return $self->closeXML ($root);
}


#-----------------------------------------------------------------
#
# MOSES::MOBY::Parameter
#
#-----------------------------------------------------------------
package MOSES::MOBY::Parameter;
use base qw( MOSES::MOBY::DataElement );
use XML::LibXML;
use MOSES::MOBY::Tags;
use strict;

#-----------------------------------------------------------------
# A list of allowed attribute names. See MOSES::MOBY::Base for details.
#-----------------------------------------------------------------
{
    my %_allowed =
	(
	 value  => undef,
	 );

    sub _accessible {
	my ($self, $attr) = @_;
	exists $_allowed{$attr} or $self->SUPER::_accessible ($attr);
    }
    sub _attr_prop {
	my ($self, $attr_name, $prop_name) = @_;
	my $attr = $_allowed {$attr_name};
	return ref ($attr) ? $attr->{$prop_name} : $attr if $attr;
	return $self->SUPER::_attr_prop ($attr_name, $prop_name);
    }
}

#-----------------------------------------------------------------
# toXML
#-----------------------------------------------------------------
sub toXML {
    my $self = shift;
    $self->increaseXMLCounter;

    my $root = XML::LibXML::Element->new (PARAMETER);
    $root->setNamespace (MOBY_XML_NS, MOBY_XML_NS_PREFIX);
    $root->setAttributeNS (MOBY_XML_NS, ARTICLENAME, $self->name)
	if $self->name;
    if ($self->value)  {
	my $val = XML::LibXML::Element->new (VALUE);
	$val->setNamespace (MOBY_XML_NS, MOBY_XML_NS_PREFIX);
	$val->appendText ($self->value);
	$root->appendChild ($val);
    }
    return $self->closeXML ($root);
}

#-----------------------------------------------------------------
#
# MOSES::MOBY::Job
#
#-----------------------------------------------------------------
package MOSES::MOBY::Job;
use base qw( MOSES::MOBY::Base );
use XML::LibXML;
use MOSES::MOBY::Tags;
use strict;

#-----------------------------------------------------------------
# A list of allowed attribute names. See MOSES::MOBY::Base for details.
#-----------------------------------------------------------------
{
    my %_allowed =
	(
	 jid           => undef,
	 dataElements  => {type => 'MOSES::MOBY::DataElement', is_array => 1},

	 # used internally (which context this job belongs to)
         _context      => {type => 'MOSES::MOBY::Package'},
	 );

    sub _accessible {
	my ($self, $attr) = @_;
	exists $_allowed{$attr} or $self->SUPER::_accessible ($attr);
    }
    sub _attr_prop {
	my ($self, $attr_name, $prop_name) = @_;
	my $attr = $_allowed {$attr_name};
	return ref ($attr) ? $attr->{$prop_name} : $attr if $attr;
	return $self->SUPER::_attr_prop ($attr_name, $prop_name);
    }
}

#-----------------------------------------------------------------
# record things into this job's context
#-----------------------------------------------------------------
sub record_info {
    shift->_record (MOSES::MOBY::ServiceException->info (@_));
}

sub record_warning {
    shift->_record (MOSES::MOBY::ServiceException->warning (@_));
}

sub record_error {
    shift->_record (MOSES::MOBY::ServiceException->error (@_));
}

sub _record {
    my ($self, $exception) = @_;
    return unless defined $self->_context;
    $exception->jobId ($self->jid);
    $self->_context->add_exceptions ($exception);
}

#-----------------------------------------------------------------
# toXML
#-----------------------------------------------------------------
sub toXML {
    my $self = shift;
    $self->increaseXMLCounter;
    my $root = XML::LibXML::Element->new (MOBYDATA);
    $root->setNamespace (MOBY_XML_NS, MOBY_XML_NS_PREFIX);
    $root->setAttributeNS (MOBY_XML_NS, QUERYID, $self->jid)
	if $self->jid;
    if ($self->dataElements) {
	foreach my $element (@{ $self->dataElements }) {
	    $root->appendChild ($element->toXML);
	}
    }
    return $self->closeXML ($root);
}

#-----------------------------------------------------------------
# getData
#    return a data element by its name (an element can be a Simple or
#    a Collection); or the first data element if no $element_name was
#    given; or throw an exception if there is no such element
#-----------------------------------------------------------------
sub getData {
    my ($self, $element_name) = @_;
    $self->throw ('Job does not have any data, at all.')
	unless $self->dataElements;
    return ${ $self->dataElements }[0] unless ($element_name);
    foreach my $elem (@{ $self->dataElements }) {
	next unless $elem->name;
	return $elem if $elem->name eq $element_name;
    }
    $self->throw ("Job does not have data element '$element_name'.");
}

#-----------------------------------------------------------------
# setData
#
#    Set $value as a new data element in this job. If an element of
#    the same name already exists it is replaced.
#
#    The name is either from $element_name, or, if $element_name is
#    not given, from the element itself ($value->name). The $value
#    should always have a name (playing the role of an 'article
#    name'). If none has a name, the $value is added at the end - but
#    that should not happen (BioMoby API requires data to be
#    named). Note, however, that adding at the end can be done only
#    with a value that is already a MOSES::MOBY::DataElement (see below).
#
#    Note that except of the ability to replace an existing element,
#    it is equivalent to the add_dataElements ($new_element).
#
#    The $value must be of type MOSES::MOBY::DataElement (actually, of one of
#    its sub-classes: Simple, Collection, or Parameter), or a Moby
#    data object (in which case, it is wrapped in a Simple), or a
#    primitive value (in which case it is first wrapped in a Moby
#    primitive type - its type is chosen according the given
#    $element_type - and then into a Simple).
#
#-----------------------------------------------------------------
sub setData {
    my ($self, $value, $element_name, $element_type) = @_;

    my $value_ref = ref ($value);

    # value may already be a container - in which case just store it
    if ($value_ref and $value->isa ('MOSES::MOBY::DataElement')) {
	$self->_place_value ($value, $element_name);
	return;
    }

    # from now we definitely need an element name
    # (because $value needs to be wrapped in something named)
    $self->throw ("An element name must be given when setting data to a job.")
	unless $element_name;

    # now $value is a moby data type or a primitive value
    $element_type ||= MOSES::MOBY::Base->STRING;
    $self->_place_value ($value_ref ?
			 new MOSES::MOBY::Simple ( data => $value,
					    name => $element_name ) :
			 new MOSES::MOBY::Simple ( data => $self->check_type ($element_name, $element_type, $value),
					    name => $element_name ),
			 $element_name);
}

sub _place_value {
    my ($self, $value, $element_name) = @_;

    # make sure that we have a space where to put value
    $self->dataElements ([])
	unless $self->dataElements;

    my $name = $element_name || $value->name;
    if ($name) {
	foreach my $elem (@{ $self->dataElements }) {
	    if ($name eq $elem->name) {
		$elem = $value;
		return;
	    }
	}
    }
    push (@{ $self->dataElements }, $value);
}

# $value is an ARRAY or a single value; if $value is not already a
# Simple, it will be wrapped in Simple (or Simples). If $value is not
# even a reference (which means that it represents just a value of a
# primitive type) we use $element_type to create first a primitive
# type, and then wrap it into a Simple.

# $element_name is here mandatory (no magic with a potential name in
# $value as in 'setData').

# This is used for adding data to a collection. Therefore, if there is
# no collection named $element_name found, a new collection is
# created.

sub addData {
    my ($self, $element_name, $element_type, @values) = @_;
    return unless @values;
    my $value_ref = ref ($values[0]);

    # just in case somebody sends here a ready collection
    return $self->setData ($values[0], $element_name)
	if $value_ref eq 'MOSES::MOBY::Collection';

    # from now we definitely need an element name
    $self->throw ("An element name must be given when adding things to a job.")
	unless $element_name;

    # make sure that values are Simples
    $element_type ||= MOSES::MOBY::Base->STRING;
#    my @values = $value_ref eq 'ARRAY' ? @$value : $value;
    foreach my $val (@values) {
	next if ref ($val) eq 'MOSES::MOBY::Simple';
	$val = (ref ($val) ?
		new MOSES::MOBY::Simple ( data => $val ) :
		new MOSES::MOBY::Simple ( data => $self->check_type ($element_name, $element_type, $val) ) );
    }

    # find a place where values should be added
    $self->dataElements ([])
	unless $self->dataElements;
    foreach my $elem (@{ $self->dataElements }) {
	if ($element_name eq $elem->name) {
	    $self->throw ("In a job, a collection was expected but found this:\n" .
			  $elem->toString)
		unless ref($elem) eq 'MOSES::MOBY::Collection';
	    push (@{ $elem->{data} }, @values);
	    return;
	}
    }
    $self->setData (new MOSES::MOBY::Collection ( name => $element_name,
					   data => [@values] ),
		    $element_name);
}

#-----------------------------------------------------------------
# getParameter
#    return a value of a secondary parameter given by its name;
#    throw an exception if there is no such parameter
#-----------------------------------------------------------------
sub getParameter {
    my ($self, $element_name) = @_;
    $self->throw ('Job does not have any parameters, at all.')
	unless $self->dataElements;
    foreach my $elem (@{ $self->dataElements }) {
	next unless $elem->name;
	return $elem->value
	    if $elem->name eq $element_name and ref ($elem) eq 'MOSES::MOBY::Parameter';
    }
    $self->throw ("Job does not have parameter '$element_name'.");
}



1;
__END__
