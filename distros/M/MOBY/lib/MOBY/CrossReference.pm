package MOBY::CrossReference;

#$Id: CrossReference.pm,v 1.3 2008/09/02 13:14:18 kawas Exp $
use strict;
use Carp;
use vars qw($AUTOLOAD @ISA);

use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.3 $ =~ /: (\d+)\.(\d+)/;

=head1 NAME

MOBY::Client::CrossReference - a small object describing a MOBY Simple input/output article

=head1 SYNOPSIS

   use MOBY::CrossReference;
   # do stuff with xref ... read below


=cut

=head1 DESCRIPTION

This holds all of the relevant information for a MOBY cross reference
of either the Xref type, or the Object type.  Object cross-references
have only namespace and id attributes, while Xref cross-references
have namespace, id, authURI, serviceName, xref_type, and evidence_code
attributes.  To determine which type of cross-reference you have
in-hand, call the "type" method.

=head1 AUTHORS

Mark Wilkinson (markw at illuminae dot com)

=head1 METHODS

=head2 new

 Usage     :	my $XR = MOBY::Client::CrossReference->new(%args)
 Function  :	create SimpleArticle object
 Returns   :	MOBY::Client::CrossReference object
 Args      :    type      => object || xref (required)
                namespace => $ns            (required)
                id        => $id            (required)
                authURI   => $authURI
                serviceName => $serviceName
                evidence_code => $evidence_code
                xref_type=> $xref_ontology_term
                Object  =>  The XML of a base MOBY Object in this ns/id


=head2 type

 Usage     :	$type = $XR->type($name)
 Function  :	get/set type attribute
 Returns   :	string;  returns last value if new value set
 Arguments :    (required)one of "xref" or "object", depending on the
                type of cross-ref you are making (new, or v0.5 API)

=head2 namespace

 Usage     :	$ns = $XR->namespace($ns)
 Function  :	get/set namespace
 Returns   :	string; returns last value if new value set
 Arguments :    (optional) string representing namespace to set

=head2 id

 Usage     :	$id = $XR->id($id)
 Function  :	get/set id for the cross-reference
 Returns   :	string; returns last value if new value set
 Arguments :    (optional) the id of the cross-reference

=head2 authURI

 Usage     :	$auth = $XR->authURI($auth)
 Function  :	get/set id for the authority for the xref
 Returns   :	string; returns last value if new value set
 Arguments :    (optional) the new authority of the xref type reference

=head2 serviceName

 Usage     :	$name = $XR->serviceName($name)
 Function  :	get/set serviceName for the cross-reference
 Returns   :	string; returns last value if new value set
 Arguments :    (optional) the new serviceName of the cross-reference

=head2 evidence_code

 Usage     :	$code = $XR->evidence_code($code)
 Function  :	get/set evidence_code for the cross-reference
 Returns   :	string; returns last value if new value set
 Arguments :    (optional) the evidence_code of the cross-reference

=head2 xref_type

 Usage     :	$xreftype = $XR->xref_type($xreftype)
 Function  :	get/set xref_type for the cross-reference
 Returns   :	string; returns last value if new value set
 Arguments :    (optional) the xref_type of the cross-reference

=head2 Object

 Usage     : $XML = $XR->Object()
 Function  : retrieve a base MOBY Object XML (e.g. to send to a service)
 Returns   : XML or empty string if there is no namespace or id value

=cut

{

# Why do these methods return the PREVIOUS value of their respective variables?
# How would that be useful?
# Seems more intuitive to return new value, or perhaps even the object itself.
  sub type {
    # only two types are permitted.
    my ( $self, $type ) = @_;
    if ($type && ($type =~ /^(xref|object)$/)) {
      my $old = $self->{_type};
      $self->{_type} = $type;
      return $old;
    }
    return $self->{_type};
  }

  sub namespace {
    my ( $self, $type ) = @_;
    if ($type) {
      my $old = $self->{_namespace};
      $self->{_namespace} = $type;
      return $old;
    }
    return $self->{_namespace};
  }

  sub id {
    my ( $self, $type ) = @_;
    if ($type) {
      my $old = $self->{_id};
      $self->{_id} = $type;
      return $old;
    }
    return $self->{_id};
  }

  sub authURI {
    my ( $self, $type ) = @_;
    if ($type) {
      my $old = $self->{_authURI};
      $self->{_authURI} = $type;
      return $old;
    }
    return $self->{_authURI};
  }

  sub serviceName {
    my ( $self, $type ) = @_;
    if ($type) {
      my $old = $self->{_serviceName};
      $self->{_serviceName} = $type;
      return $old;
    }
    return $self->{_serviceName};
  }

  sub evidence_code {
    my ( $self, $type ) = @_;
    if ($type) {
      my $old = $self->{_evidenceCode};
      $self->{_evidenceCode} = $type;
      return $old;
    }
    return $self->{_evidenceCode};
  }

  sub xref_type {
    my ( $self, $type ) = @_;
    if ($type) {
      my $old = $self->{_xref_type};
      $self->{_xref_type} = $type;
      return $old;
    }
    return $self->{_xref_type};
  }
}

sub new {
  my ( $caller, %args ) = @_;
  my $caller_is_obj = ref($caller);
  return $caller if $caller_is_obj;
  my $class = $caller_is_obj || $caller;
  my $proxy;
  my $self = bless {}, $class;
  while ( my ( $key, $value ) = each %args ) {
    $self->$key($value);
  }
  return undef unless ( $self->type && $self->namespace && $self->id );
  return $self;
}

sub Object {
  my ($self) = @_;
  return "" unless ( $self->namespace && $self->id );
  return "<moby:Object moby:namespace='"
    . ( $self->namespace )
      . "' moby:id='"
	. ( $self->id ) . "'/>";
}
sub DESTROY { }
1;
