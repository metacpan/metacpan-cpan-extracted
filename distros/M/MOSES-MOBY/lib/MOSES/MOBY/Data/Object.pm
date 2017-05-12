#-----------------------------------------------------------------
# MOSES::MOBY::Data::Object
# Author: Edward Kawas <edward.kawas@gmail.com>,
#         Martin Senger <martin.senger@gmail.com>
# For copyright and disclaimer see below.
#
# $Id: Object.pm,v 1.5 2010/12/08 16:14:13 kawas Exp $
#-----------------------------------------------------------------

package MOSES::MOBY::Data::Object;
use base ("MOSES::MOBY::Base");
use MOSES::MOBY::Tags;
use strict;

# add versioning to this module
use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.5 $ =~ /: (\d+)\.(\d+)/;

#-----------------------------------------------------------------
# load all modules needed for my attributes
#-----------------------------------------------------------------
use MOSES::MOBY::Data::Xref;
use MOSES::MOBY::Data::ProvisionInformation;


=head1 NAME

MOSES::MOBY::Data::Object - A base Moby data type

=head1 SYNOPSIS

 use MOSES::MOBY::Data::Object;

 # create a Moby object with a namespace of NCBI_gi and id 545454
 my $data = MOSES::MOBY::Data::Object->new (namespace=>"NCBI_gi", id=>"545454");
 
 # set/get an article name for this data object
 $data->name ('myObject');
 print $data->name;
 
 # set/get an id for this data object
 $data->id ('myID');
 print $data->id;
 
 # check if this data object is a primitive type
 print "a primitive" if $data->primitive;
 print "not a primitive" if not $data->primitive;
 
 # set an array of cross references
 my $xref = new MOSES::MOBY::Data::Xref;
 $xref->description ('He is looking at you, kid...');
 $data->xrefs ($xref);
 # set more cross referneces for this data object
 my $xref1 = ... 
 my $xref2 = ... 
 my $xref3 = ... 
 $data->xrefs ($xref1, $xref2, $xref3);
 # or:
 $data->xrefs ([$xref1, $xref2, $xref3]);

 # add cross references
 my $xref4 = ... 
 my $xref5 = ... 
 $data->add_xrefs ($xref4, $xref5);
 # or:
 $data->add_xrefs ([$xref4, $xref5]);

 # finally, get cross references back
 foreach $xref (@{ $data->xrefs }) {
    print $xref->toString;
 }

 # get a formatted string representation of this data object
 print $data->toString;
 
 # retrieve an XML::LibXML::Element representing the data object
 $xml = $data->toXML();
 print $xml->toString;
 
=head1 DESCRIPTION

An object representing a Moby object, a Moby base data type for all
other Moby data types.

=head1 AUTHORS

 Edward Kawas (edward.kawas [at] gmail [dot] com)
 Martin Senger (martin.senger [at] gmail [dot] com)

=cut

#-----------------------------------------------------------------
# A list of allowed attribute names. See MOSES::MOBY::Base for details.
#-----------------------------------------------------------------

=head1 ACCESSIBLE ATTRIBUTES

Details are in L<MOSES::MOBY::Base>. Here just a list of them:

=over

=item B<namespace>

=item B<id>

=item B<name>

An article name for this datatype. Note that the article name depends
on the context where this object is used.

=item B<provision>

A I<provision information>. A scalar of type
C<MOSES::MOBY::Data::ProvisionInformation>.

=item B<xrefs>

Cross-references. Can be a scalar (of type
C<MOSES::MOBY::Data::Xref>, an array, or a array
reference. 

=item B<primitive>

A boolean property indicating if this data type is a primitive Moby
type or not.

=back

=cut

{
    my %_allowed =
	(
	 id                  => undef,
	 namespace           => undef,
	 mobyname            => undef,
	 provision           => {type => 'MOSES::MOBY::Data::ProvisionInformation'},
	 xrefs               => {type => 'MOSES::MOBY::Data::Xref', is_array => 1},
         primitive           => {type => MOSES::MOBY::Base->BOOLEAN},
	 original_memberName => undef,
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

=head1 SUBROUTINES

=cut

#-----------------------------------------------------------------
# init
#-----------------------------------------------------------------
sub init {
    my ($self) = shift;
    $self->SUPER::init();
    $self->id ('');
    $self->namespace ('');
    $self->xrefs ([]);
    $self->primitive ('no');
}

#-----------------------------------------------------------------
# toXML
#-----------------------------------------------------------------

=head2 toXML

Return an XML::LibXML::Element representing this data object.  An
optional attribute is an articleName that should be given to this
object (in its XML representation).

=cut

sub toXML {
    my ($self, $articleName) = @_;
    $self->increaseXMLCounter;

    my $moby_name = $self->mobyname;
    unless ($moby_name) {  # backup plan
	$moby_name = ref $self;
	$moby_name =~ s/.*:://;
    }

    my $root = XML::LibXML::Element->new ($moby_name);
    $root->setNamespace (MOBY_XML_NS, MOBY_XML_NS_PREFIX);

    $root->setAttributeNS (MOBY_XML_NS, OBJ_ID, $self->id);
    $root->setAttributeNS (MOBY_XML_NS, OBJ_NAMESPACE, $self->namespace);
    $root->setAttributeNS (MOBY_XML_NS, ARTICLENAME, $articleName)
	if $articleName;

    $root->appendChild ($self->provision->toXML)
	if $self->provision;
    
    # cross-references
    if ($self->xrefs and @{ $self->xrefs } > 0) {
	my $crElem = $root->addNewChild (MOBY_XML_NS, CROSSREFERENCE);
	$crElem->setNamespace (MOBY_XML_NS, MOBY_XML_NS_PREFIX);
	foreach my $xref (@{ $self->xrefs }) {
	    $crElem->appendChild ($xref->toXML);
	}
    }

    # iterate over all members
    my ($key, $value);
    while (($key, $value) = each %$self) {
	if (ref ($value) eq 'ARRAY') {
	    foreach my $elem (@{ $value }) {
		$self->_add_XML_element ($key, $elem, $root);
	    }
	} else {
	    $self->_add_XML_element ($key, $value, $root);
	}
    }

    # return it  (TBD: cleaning namespaces happens several times...)
    return $self->closeXML ($root);
}

# create an XML element, add it to the $root; ignore some priviledged
# names (such as 'xrefs'), and most (except 'value' for primitive
# types) of the names whose values are not object references

sub _add_XML_element {
    my ($self, $name, $value, $root) = @_;
    my (%special_names) =
	(xrefs     => 1,
	 provision => 1,
	 );
    if ($name eq 'value' and $self->primitive) {
	if (defined $value) {
	    if ($self->{cdata}) {  # don't use: $self->cdata because not everybody has it
		$root->appendChild (XML::LibXML::CDATASection->new ($self->_express_value ($value)));
	    } else {
		$root->appendText ($self->_express_value ($value));
	    }
	}
	return;
    }
    if (ref ($value)) {
	if ($special_names{$name}) {
	    return;
	}
	my $xmlElem = $value->toXML ($name);
	$root->appendChild ($xmlElem) if $xmlElem;
    }
}

# return the same value as given (but others may override it - eg,
# Boolean changes here 1 to 'true'

sub _express_value {
    shift;
    shift;
}


1;
__END__
