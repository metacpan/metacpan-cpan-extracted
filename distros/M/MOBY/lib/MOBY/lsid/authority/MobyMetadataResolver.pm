#!/usr/bin/perl
#-----------------------------------------------------------------
# MOBY::lsid::authority::MobyMetadataResolver
# Author: Edward Kawas <edward.kawas@gmail.com>,
# For copyright and disclaimer see below.
#
# $Id: MobyMetadataResolver.pm,v 1.4 2008/11/17 15:27:02 kawas Exp $
#-----------------------------------------------------------------

package MobyNamespaceType;

use strict;
use warnings;

use LS::ID;
use LS::Service::Response;
use LS::Service::Fault;

use MOBY::RDF::Ontologies::Namespaces;

use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.4 $ =~ /: (\d+)\.(\d+)/;

use base 'LS::Service::Namespace';

=head1 NAME

MobyNamespaceType - LSID Metadata Handler

=head1 SYNOPSIS

	use MOBY::lsid::authority::MobyMetadataResolver;

	# create a LS::Service::DataService and pass it our handler
	my $metadata = LS::Service::DataService->new();
	$metadata->addNamespace( MobyNamespaceType->new() );

=head1 DESCRIPTION

This module implements the subroutines needed to implement
an LSID authority service that handles this namespace. 

=cut

=head1 AUTHORS

 Edward Kawas (edward.kawas [at] gmail [dot] com)

=cut

#
# new - no parameters
#
sub new {

	my ( $self, %options ) = @_;
	
	my $CONF  = MOBY::Config->new;
	
	$options{'name'} = $CONF->{mobynamespace}->{lsid_namespace} || 'namespacetype';

	$self = $self->SUPER::new(%options);
	
	
	$self->{mobyconf} = $CONF->{mobynamespace};
	$self->{moby_data_handler} = $CONF-> getDataAdaptor( source => "mobynamespace" )->dbh;
	
	return $self;
}

#-----------------------------------------------------------------
# getMetadata
#-----------------------------------------------------------------

=head2 getMetadata

This subroutine is the handler that actually performs
the action when getMetadata is called on an LSID under this namespace

This routine has 2 parameters:
	lsid - the LSID
	format - output format <optional>

 Example: getMetadata(LS::ID->new('urn:lsid:authority:namespace:object'));	

A LS::Service::Response is returned if getMetadata is successful.

=cut


sub getMetadata {
	my ( $self, $lsid, $format ) = @_;
	$lsid = $lsid->canonical();

	return LS::Service::Fault->fault('Unknown LSID')
	  unless (
		$self->lsidExists(
			$lsid->namespace, $lsid->object, $lsid->revision
		)
	  );

	my $latest =
	  $self->isLatest( $lsid->namespace, $lsid->object,
		$lsid->revision );
	do {
		my $data = MOBY::RDF::Ontologies::Namespaces->new;
		$format = 'application/xml' if ( !$format );
		return LS::Service::Response->new(
			response => $data->createByName( { term => $lsid->object } ),
			format   => $format
		);
	} unless $latest;

	return LS::Service::Fault->serverFault( 'Unable to load metadata', 600 )
	  if ( $latest eq "" );

	my $object = $lsid->object();
	my $uri = MOBY::RDF::Ontologies::Namespaces->new();
	$uri = $uri->{uri} || "http://biomoby.org/RESOURCES/MOBY-S/Namespaces#$object";
	my $data   = <<END;
<?xml version="1.0" encoding="UTF-8"?>
<rdf:RDF
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:lsid="http://lsid.omg.org/predicates#"
    xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#">
     <rdf:Description rdf:about="$uri">
          <rdfs:comment>The Namespace described by the LSID: $lsid has since been modified. Please update your lsid.</rdfs:comment>
          <lsid:latest>$latest</lsid:latest>
     </rdf:Description>
</rdf:RDF>
END

	$format = 'application/xml' if ( !$format );
	return LS::Service::Response->new(
		response => $data,
		format   => $format
	);

}

#-----------------------------------------------------------------
# lsidExists
#-----------------------------------------------------------------

=head2 lsidExists

This subroutine checks to see whether the thing that the LSID points to
exists at all.

This routine has 3 parameters:
	namespace - the LSID namespace
	id - the LSID object
	revision - the LSID revision

 Example: lsidExists('someNamespace','someObject','someRevision');	

If the thing pointed at by the lsid exists, then 1 is returned. Otherwise undef is returned.

=cut

sub lsidExists {
	my ( $self, $namespace, $id, $revision ) = @_;
	return 1 if ( $id =~ /^Namespace$/ );

	my $db = $self->{moby_data_handler};
	my $query = <<END;
SELECT namespace_lsid 
FROM namespace 
WHERE namespace_type = ?
ORDER BY namespace_lsid asc
END
	my $sth = $db->prepare($query);
	$sth->execute( ($id) );

	# returns an array of hash references
	while ( my $ref = $sth->fetchrow_arrayref ) {

		#if we are here, it means the namespace exists!
		return 1;
	}

	# doesnt exist
	return undef;
}

#-----------------------------------------------------------------
# isLatest
#-----------------------------------------------------------------

=head2 isLatest

This subroutine checks to see whether the LSID is the latest, based on the  revision.

This routine has 3 parameters:
	namespace - the LSID namespace
	id - the LSID object
	revision - the LSID revision

 Example: isLatest('someNamespace','someObject','someRevision');	

If the lsid is the latest, then undef is returned. 
If the lsid doesnt exist, then an empty string is returned.
And if the lsid isnt the latest, then the latest lsid is returned. 

=cut

sub isLatest {
	my ( $self, $namespace, $id, $revision ) = @_;
	$revision = "__invalid__" unless $revision;
	return undef if ( $id =~ /^Namespace$/ );

	my $db = $self->{moby_data_handler};
	my $query = <<END;
SELECT namespace_lsid 
FROM namespace 
WHERE namespace_type = ?
ORDER BY namespace_lsid asc
END
	my $sth = $db->prepare($query);
	$sth->execute( ($id) );

	# returns an array of hash references
	while ( my $ref = $sth->fetchrow_arrayref ) {

		#if we are here, it means the namespace exists!
		my $lsid = LS::ID->new( $$ref[0] );
		return undef if $lsid->revision() and $lsid->revision() eq $revision;
		return $$ref[0];
	}

	# doesnt exist
	return "";
}

package MobyServiceType;
use strict;
use warnings;
use LS::ID;
use LS::Service::Response;
use LS::Service::Fault;

use MOBY::RDF::Ontologies::ServiceTypes;

use base 'LS::Service::Namespace';

=head1 NAME

MobyServiceType - LSID Metadata Handler

=head1 SYNOPSIS

	use MOBY::lsid::authority::MobyMetadataResolver;

	# create a LS::Service::DataService and pass it our handler
	my $metadata = LS::Service::DataService->new();
	$metadata->addNamespace( MobyServiceType->new() );

=head1 DESCRIPTION

This module implements the subroutines needed to implement
an LSID authority service that handles this namespace. 

=cut

=head1 AUTHORS

 Edward Kawas (edward.kawas [at] gmail [dot] com)

=cut

#
# new - no parameters
#

sub new {

	my ( $self, %options ) = @_;

	my $CONF  = MOBY::Config->new;
	
	$options{'name'} = $CONF->{mobyservice}->{lsid_namespace} || 'servicetype';

	$self = $self->SUPER::new(%options);
	
	$self->{mobyconf} = $CONF->{mobyservice};
	$self->{moby_data_handler} = $CONF-> getDataAdaptor( source => "mobyservice" )->dbh;
	
	return $self;
}

#-----------------------------------------------------------------
# getMetadata
#-----------------------------------------------------------------

=head2 getMetadata

This subroutine is the handler that actually performs
the action when getMetadata is called on an LSID under this namespace

This routine has 2 parameters:
	lsid - the LSID
	format - output format <optional>

 Example: getMetadata(LS::ID->new('urn:lsid:authority:namespace:object'));	

A LS::Service::Response is returned if getMetadata is successful.

=cut

sub getMetadata {

	my ( $self, $lsid, $format ) = @_;

	$lsid = $lsid->canonical();

	return LS::Service::Fault->fault('Unknown LSID')
	  unless (
		$self->lsidExists(
			$lsid->namespace, $lsid->object, $lsid->revision
		)
	  );

	my $latest =
	  $self->isLatest( $lsid->namespace, $lsid->object, $lsid->revision );
	do {
		my $data = MOBY::RDF::Ontologies::ServiceTypes->new;
		$format = 'application/xml' if ( !$format );
		return LS::Service::Response->new(
			response => $data->createByName( { term => $lsid->object } ),
			format   => $format
		);
	} unless $latest;

	return LS::Service::Fault->serverFault( 'Unable to load metadata', 600 )
	  if ( $latest eq "" );

	my $object = $lsid->object();
	my $uri = MOBY::RDF::Ontologies::ServiceTypes->new();
	$uri = $uri->{uri} || "http://biomoby.org/RESOURCES/MOBY-S/Services#$object";
	my $data   = <<END;
<?xml version="1.0" encoding="UTF-8"?>
<rdf:RDF
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:lsid="http://lsid.omg.org/predicates#"
    xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#">
     <rdf:Description rdf:about="$uri">
          <rdfs:comment>The ServiceType described by the LSID: $lsid has since been modified. Please update your lsid.</rdfs:comment>
          <lsid:latest>$latest</lsid:latest>
     </rdf:Description>
</rdf:RDF>
END

	$format = 'application/xml' if ( !$format );
	return LS::Service::Response->new(
		response => $data,
		format   => $format
	);
}

#-----------------------------------------------------------------
# lsidExists
#-----------------------------------------------------------------

=head2 lsidExists

This subroutine checks to see whether the thing that the LSID points to
exists at all.

This routine has 3 parameters:
	namespace - the LSID namespace
	id - the LSID object
	revision - the LSID revision

 Example: lsidExists('someNamespace','someObject','someRevision');	

If the thing pointed at by the lsid exists, then 1 is returned. Otherwise undef is returned.

=cut

sub lsidExists {
	my ( $self, $namespace, $id, $revision ) = @_;
	my $db = $self->{moby_data_handler};
	my $query = <<END;
SELECT service_lsid 
FROM service 
WHERE service_type = ? 
order by service_lsid
END
	my $sth = $db->prepare($query);
	$sth->execute( ($id) );

	# returns an array of hash references
	while ( my $ref = $sth->fetchrow_arrayref ) {

		#if we are here, it means the namespace exists!
		return 1;
	}

	# doesnt exist
	return undef;
}

#-----------------------------------------------------------------
# isLatest
#-----------------------------------------------------------------

=head2 isLatest

This subroutine checks to see whether the LSID is the latest, based on the  revision.

This routine has 3 parameters:
	namespace - the LSID namespace
	id - the LSID object
	revision - the LSID revision

 Example: isLatest('someNamespace','someObject','someRevision');	

If the lsid is the latest, then undef is returned. 
If the lsid doesnt exist, then an empty string is returned.
And if the lsid isnt the latest, then the latest lsid is returned. 

=cut


sub isLatest {
	my ( $self, $namespace, $id, $revision ) = @_;
	$revision = "__invalid__" unless $revision;
	my $db = $self->{moby_data_handler};
	my $query = <<END;
SELECT service_lsid 
FROM service 
WHERE service_type = ? 
order by service_lsid
END
	my $sth = $db->prepare($query);
	$sth->execute( ($id) );

	# returns an array of hash references
	while ( my $ref = $sth->fetchrow_arrayref ) {

		#if we are here, it means the namespace exists!
		my $lsid = LS::ID->new( $$ref[0] );
		return undef if $lsid->revision() and $lsid->revision() eq $revision;
		return $$ref[0];
	}

	# doesnt exist
	return "";
}

package MobyObjectClass;

use strict;
use warnings;

use LS::ID;
use LS::Service::Response;
use LS::Service::Fault;

use MOBY::RDF::Ontologies::Objects;

use base 'LS::Service::Namespace';

=head1 NAME

MobyObjectClass - LSID Metadata Handler

=head1 SYNOPSIS

	use MOBY::lsid::authority::MobyMetadataResolver;

	# create a LS::Service::DataService and pass it our handler
	my $metadata = LS::Service::DataService->new();
	$metadata->addNamespace( MobyObjectClass->new() );

=head1 DESCRIPTION

This module implements the subroutines needed to implement
an LSID authority service that handles this namespace. 

=cut

=head1 AUTHORS

 Edward Kawas (edward.kawas [at] gmail [dot] com)

=cut

#
# new - no parameters
#
sub new {

	my ( $self, %options ) = @_;

	my $CONF  = MOBY::Config->new;
	
	$options{'name'} = $CONF->{mobyobject}->{lsid_namespace} || 'objectclass';

	$self = $self->SUPER::new(%options);
	
	
	$self->{mobyconf} = $CONF->{mobyobject};
	$self->{moby_data_handler} = $CONF-> getDataAdaptor( source => "mobyobject" )->dbh;
	
	return $self;
}

#-----------------------------------------------------------------
# getMetadata
#-----------------------------------------------------------------

=head2 getMetadata

This subroutine is the handler that actually performs
the action when getMetadata is called on an LSID under this namespace

This routine has 2 parameters:
	lsid - the LSID
	format - output format <optional>

 Example: getMetadata(LS::ID->new('urn:lsid:authority:namespace:object'));	

A LS::Service::Response is returned if getMetadata is successful.

=cut

sub getMetadata {

	my ( $self, $lsid, $format ) = @_;

	$lsid = $lsid->canonical();

	return LS::Service::Fault->fault('Unknown LSID')
	  unless (
		$self->lsidExists(
			$lsid->namespace, $lsid->object, $lsid->revision
		)
	  );

	my $latest =
	  $self->isLatest( $lsid->namespace, $lsid->object, $lsid->revision );
	do {
		my $data = MOBY::RDF::Ontologies::Objects->new;
		$format = 'application/xml' if ( !$format );
		return LS::Service::Response->new(
			response => $data->createByName( { term => $lsid->object } ),
			format   => $format
		);
	} unless $latest;

	return LS::Service::Fault->serverFault( 'Unable to load metadata', 600 )
	  if ( $latest eq "" );

	my $object = $lsid->object();
	my $uri = MOBY::RDF::Ontologies::Objects->new();
	$uri = $uri->{uri} || "http://biomoby.org/RESOURCES/MOBY-S/Objects#$object";
	my $data   = <<END;
<?xml version="1.0" encoding="UTF-8"?>
<rdf:RDF
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:lsid="http://lsid.omg.org/predicates#"
    xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#">
     <rdf:Description rdf:about="$uri">
          <rdfs:comment>The Datatype described by the LSID: $lsid has since been modified. Please update your lsid.</rdfs:comment>
          <lsid:latest>$latest</lsid:latest>
     </rdf:Description>
</rdf:RDF>
END

	$format = 'application/xml' if ( !$format );
	return LS::Service::Response->new(
		response => $data,
		format   => $format
	);
}

#-----------------------------------------------------------------
# lsidExists
#-----------------------------------------------------------------

=head2 lsidExists

This subroutine checks to see whether the thing that the LSID points to
exists at all.

This routine has 3 parameters:
	namespace - the LSID namespace
	id - the LSID object
	revision - the LSID revision

 Example: lsidExists('someNamespace','someObject','someRevision');	

If the thing pointed at by the lsid exists, then 1 is returned. Otherwise undef is returned.

=cut

sub lsidExists {
	my ( $self, $namespace, $id, $revision ) = @_;
	my $db = $self->{moby_data_handler};
	my $query = <<END;
SELECT object_lsid  
FROM object  
WHERE object_type = ? 
ORDER BY object_lsid
END
	my $sth = $db->prepare($query);
	$sth->execute( ($id) );

	# returns an array of hash references
	while ( my $ref = $sth->fetchrow_arrayref ) {

		#if we are here, it means the namespace exists!
		return 1;
	}

	# doesnt exist
	return undef;
}
#-----------------------------------------------------------------
# isLatest
#-----------------------------------------------------------------

=head2 isLatest

This subroutine checks to see whether the LSID is the latest, based on the  revision.

This routine has 3 parameters:
	namespace - the LSID namespace
	id - the LSID object
	revision - the LSID revision

 Example: isLatest('someNamespace','someObject','someRevision');	

If the lsid is the latest, then undef is returned. 
If the lsid doesnt exist, then an empty string is returned.
And if the lsid isnt the latest, then the latest lsid is returned. 

=cut

sub isLatest {
	my ( $self, $namespace, $id, $revision ) = @_;
	$revision = "__invalid__" unless $revision;
	my $db = $self->{moby_data_handler};
	my $query = <<END;
SELECT object_lsid  
FROM object  
WHERE object_type = ? 
ORDER BY object_lsid
END
	my $sth = $db->prepare($query);
	$sth->execute( ($id) );

	# returns an array of hash references
	while ( my $ref = $sth->fetchrow_arrayref ) {

		#if we are here, it means the namespace exists!
		my $lsid = LS::ID->new( $$ref[0] );
		return undef if $lsid->revision() and $lsid->revision() eq $revision;
		return $$ref[0];
	}

	# doesnt exist
	return "";
}

package MobyServiceInstance;

use strict;
use warnings;

use LS::ID;
use LS::Service::Response;
use LS::Service::Fault;
use MOBY::Client::Service;
use MOBY::Client::Central;
use MOBY::Config;
use MOBY::RDF::Ontologies::Services;

use base 'LS::Service::Namespace';

=head1 NAME

MobyServiceInstance - LSID Metadata Handler

=head1 SYNOPSIS

	use MOBY::lsid::authority::MobyMetadataResolver;

	# create a LS::Service::DataService and pass it our handler
	my $metadata = LS::Service::DataService->new();
	$metadata->addNamespace( MobyServiceInstance->new() );

=head1 DESCRIPTION

This module implements the subroutines needed to implement
an LSID authority service that handles this namespace. 

=cut

=head1 AUTHORS

 Edward Kawas (edward.kawas [at] gmail [dot] com)

=cut

#
# new - no parameters
#
sub new {

	my ( $self, %options ) = @_;
	
	my $CONF  = MOBY::Config->new;
	
	$options{'name'} = $CONF->{mobycentral}->{lsid_namespace} || 'serviceinstance';

	$self = $self->SUPER::new(%options);
	
	
	$self->{mobyconf} = $CONF->{mobycentral};
	$self->{moby_data_handler} = $CONF-> getDataAdaptor( source => "mobycentral" )->dbh;
	
	return $self;
}

#-----------------------------------------------------------------
# getData
#-----------------------------------------------------------------

=head2 getData

This subroutine is the handler that actually performs
the action when getData is called on an LSID under this namespace

This routine has 2 parameters:
        lsid - the LSID
        format - output format <optional>

 Example: getData(LS::ID->new('urn:lsid:authority:namespace:object'));

A LS::Service::Response is returned if getData is successful.

=cut

sub getData {

        my ( $self, $lsid, $format ) = @_;
        $lsid = $lsid->canonical();
        my $length = length( $lsid->object() );

        # some error conditions
        return LS::Service::Fault->fault('malformed LSID') unless $length > 0;
        return LS::Service::Fault->fault('malformed LSID')
          unless index( $lsid->object(), ',' ) > 0;

        my $servicename =
          substr( $lsid->object(), index( $lsid->object(), ',' ) + 1, $length );
        my $authURI = substr( $lsid->object(), 0, index( $lsid->object(), ',' ) );

        return LS::Service::Fault->fault('Unknown LSID')
          unless (
                $self->lsidExists(
                        $lsid->namespace, $lsid->object, $lsid->revision
                )
          );

        my $latest =
          $self->isLatest( $lsid->namespace, $lsid->object,
                $lsid->revision );
        do {
                my $data = MOBY::RDF::Ontologies::Services->new;
                $format = 'application/xml' if ( !$format );
		my $wsdl = $self->_getServiceWSDL($authURI, $servicename);
		print STDERR $wsdl;
                return LS::Service::Response->new(
                        response => $wsdl,
                        format => $format
                	);
        } unless $latest;

        return LS::Service::Fault->serverFault( 'Unable to load Data', 600 )
          if ( $latest eq "" );

        $format = 'text/plain';
        return LS::Service::Response->new(
                response => "",
                format   => $format
        );


}
#-----------------------------------------------------------------
# _getServiceWSDL
#-----------------------------------------------------------------

=head2 _getServiceWSDL

This subroutine obtains the wsdl for moby services given the name/auth
combination. It uses the registry that is set in the enviroment.
TODO - might have to change this behaviour, if we think of a good 
reason!

=cut

sub _getServiceWSDL {
	my ( $self, $authority, $servicename ) = @_;
	my $moby = MOBY::Client::Central->new();
	my ( $services, $RegObject ) = $moby->findService(
              		                  authURI     => $authority,
                        		  serviceName => $servicename
                        	       );
	unless ($services && @{$services}[0] ) {
		return "";
	};
	# should only be one ...
	foreach my $ServiceInstance ( @{ $services } ) {
		return $moby->retrieveService($ServiceInstance);
	}
	return ""
}

#-----------------------------------------------------------------
# getMetadata
#-----------------------------------------------------------------

=head2 getMetadata

This subroutine is the handler that actually performs
the action when getMetadata is called on an LSID under this namespace

This routine has 2 parameters:
	lsid - the LSID
	format - output format <optional>

 Example: getMetadata(LS::ID->new('urn:lsid:authority:namespace:object'));	

A LS::Service::Response is returned if getMetadata is successful.

=cut

sub getMetadata {

	my ( $self, $lsid, $format ) = @_;
	$lsid = $lsid->canonical();

	my $length = length( $lsid->object() );

	# some error conditions
	return LS::Service::Fault->fault('malformed LSID') unless $length > 0;
	return LS::Service::Fault->fault('malformed LSID')
	  unless index( $lsid->object(), ',' ) > 0;

	my $servicename =
	  substr( $lsid->object(), index( $lsid->object(), ',' ) + 1, $length );
	my $authURI = substr( $lsid->object(), 0, index( $lsid->object(), ',' ) );

	return LS::Service::Fault->fault('Unknown LSID')
	  unless (
		$self->lsidExists(
			$lsid->namespace, $lsid->object, $lsid->revision
		)
	  );

	my $latest =
	  $self->isLatest( $lsid->namespace, $lsid->object,
		$lsid->revision );
	do {
		my $data = MOBY::RDF::Ontologies::Services->new;
		$format = 'application/xml' if ( !$format );
		return LS::Service::Response->new(
			response => $data->findService(
				{
					serviceName => $servicename,
					authURI     => $authURI
				}
			),
			format => $format
		);
	} unless $latest;

	return LS::Service::Fault->serverFault( 'Unable to load metadata', 600 )
	  if ( $latest eq "" );

	my $object = $lsid->object();
	my $data   = <<END;
<?xml version="1.0" encoding="UTF-8"?>
<rdf:RDF
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:lsid="http://lsid.omg.org/predicates#"
    xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#">
     <rdf:Description rdf:about="$lsid">
          <rdfs:comment>The service instance described by the LSID: $lsid has since been modified. Please update your lsid.</rdfs:comment>
          <lsid:latest>$latest</lsid:latest>
     </rdf:Description>
</rdf:RDF>
END

	$format = 'application/xml' if ( !$format );
	return LS::Service::Response->new(
		response => $data,
		format   => $format
	);
}

#-----------------------------------------------------------------
# lsidExists
#-----------------------------------------------------------------

=head2 lsidExists

This subroutine checks to see whether the thing that the LSID points to
exists at all.

This routine has 3 parameters:
	namespace - the LSID namespace
	id - the LSID object
	revision - the LSID revision

 Example: lsidExists('someNamespace','someObject','someRevision');	

If the thing pointed at by the lsid exists, then 1 is returned. Otherwise undef is returned.

=cut

sub lsidExists {
	my ( $self, $namespace, $id, $revision ) = @_;

	my $length = length($id);

	# some error conditions
	return "" unless $length > 0;
	return "" unless index( $id, ',' ) > 0;

	my $servicename = substr( $id, index( $id, ',' ) + 1, $length );
	my $authURI = substr( $id, 0, index( $id, ',' ) );
	my $db = $self->{moby_data_handler};
	my $query = <<END;
SELECT si.lsid 
FROM service_instance as si, authority as a  
WHERE si.servicename = ? AND si.authority_id = a.authority_id AND a.authority_uri = ? 
END
	my $sth = $db->prepare($query);
	$sth->execute( ( $servicename, $authURI ) );

	# returns an array of hash references
	while ( my $ref = $sth->fetchrow_arrayref ) {

		#if we are here, it means the namespace exists!
		return 1;
	}

	# doesnt exist
	return undef;

}

#-----------------------------------------------------------------
# isLatest
#-----------------------------------------------------------------

=head2 isLatest

This subroutine checks to see whether the LSID is the latest, based on the  revision.

This routine has 3 parameters:
	namespace - the LSID namespace
	id - the LSID object
	revision - the LSID revision

 Example: isLatest('someNamespace','someObject','someRevision');	

If the lsid is the latest, then undef is returned. 
If the lsid doesnt exist, then an empty string is returned.
And if the lsid isnt the latest, then the latest lsid is returned. 

=cut

sub isLatest {
	my ( $self, $namespace, $id, $revision ) = @_;
	$revision = "__invalid__" unless $revision;

	my $length = length($id);

	# some error conditions
	return "" unless $length > 0;
	return "" unless index( $id, ',' ) > 0;

	my $servicename = substr( $id, index( $id, ',' ) + 1, $length );
	my $authURI = substr( $id, 0, index( $id, ',' ) );

	my $db = $self->{moby_data_handler};
	my $query = <<END;
SELECT si.lsid 
FROM service_instance as si, authority as a  
WHERE si.servicename = ? AND si.authority_id = a.authority_id AND a.authority_uri = ?
END
	my $sth = $db->prepare($query);
	$sth->execute( ( $servicename, $authURI ) );

	# returns an array of hash references
	while ( my $ref = $sth->fetchrow_arrayref ) {

		#if we are here, it means the namespace exists!
		my $lsid = LS::ID->new( $$ref[0] );
		return undef if $lsid->revision() and $lsid->revision() eq $revision;
		return $$ref[0];
	}

	# doesnt exist
	return "";
}

1;
