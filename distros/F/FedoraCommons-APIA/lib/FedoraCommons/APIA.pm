# ========================================================================= # 
#
#     FedoraCommons::APIA - interface to Fedora's SOAP based API-A
#
# ========================================================================= # 
#
#  Copyright (c) 2011, Cornell University www.cornell.edu (enhancements)
#  Copyright (c) 2010, Cornell University www.cornell.edu (enhancements)
#  Copyright (c) 2007, The Pennsylvania State University, www.psu.edu
#
#  This library is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2, or (at your option)
#  any later version.
#
#  See pod documentation for further license and copyright information.
#
#  History: APIA interface was developed at PSU in 2006/2007. This code 
#           was built on top of an existing module which used SOAP (Technical 
#           Knowledge Center of Denmark[2006]).
#
#           Cornell University began using the module for scripts
#           to import legacy digital collections into a new cloud-based
#           Archival Repository (2009). During this work the module has been
#           enhanced with several new methods implemented. 
#
#           The module made interacting with a Fedora Commons repository
#           easy thus the decision to share the module on CPAN.
#
#
# Manifest of APIA API methods and APIA Module methods:
#                                                                    POD
# Fedora 3.0 APIA API Methods              Supported    Status    Documented
# ---------------------------              ---------    ------    ----------
#
#   * Repository Access 
#          o describeRepository               No
#   * Object Access 
#          o findObjects                   Supported      OK         Yes
#          o resumeFindObjects             Supported      OK         Yes
#          o getObjectHistory                 No
#          o getObjectProfile                 No
#   * Datastream Access 
#          o getDatastreamDissemination    Supported      OK         Yes
#          o listDatastreams               Supported      OK         Yes (PSU)
#   * Dissemination Access 
#          o getDissemination                 No
#          o listMethods                      No
#
# Local Additions:
#
#   * Datastream Access
#          o datastreamExists              Supported      OK         Yes
#
#
# *PSU - Implemented by Penn State University
#
# ========================================================================= # 
#
#  $Id: APIA.pm,v 1.3 2007/06/25 15:22:25 dlf2 Exp $
#
# ========================================================================= #
#

package FedoraCommons::APIA;

use 5.008005;
use strict;
use warnings;

require SOAP::Lite;
use Time::HiRes qw(time);
use Carp;

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use FedoraCommons::APIA ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(

) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(

);

our $VERSION = '0.5';

our $FEDORA_VERSION = "3.2";

sub import {
  my $pkg = shift;
  while (@_) {
    my $command = shift;
    my $parameter = shift;
    if ($command eq 'version') {

      # Add legal Fedora version numbers as they become available
      if ($parameter eq "3.2") {
        $FEDORA_VERSION = $parameter;
      }

    }
  }
}

my $ERROR_MESSAGE;

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.



# ========================================================================= # 
# 
#  Public Methods
#
# ========================================================================= # 



# Constructor
#
# Args in parameter hash:
#   host :    Fedora host
#   port :    Port
#   usr :     Fedora Admin user
#   pwd :     Fedora Admin password
#   timeout:  Allowed timeout
#
# Return:
#   The Fedora::APIA object
#
sub new {
  my $class = shift;
  my %args = @_;
  my $self = {};
  $self->{'protocol'} = "http";

  foreach my $k (keys %args) {
    if ($k eq 'usr') {
      $self->{$k} = $args{$k}; 
    } elsif ( $k eq 'pwd') {
      $self->{$k} = $args{$k}; 
    } elsif ( $k eq 'host') {
      $self->{$k} = $args{$k}; 
    } elsif ( $k eq 'port') {
      $self->{$k} = $args{$k}; 
    } elsif ( $k eq 'timeout') {
      $self->{$k} = $args{$k}; 
    } elsif ( $k eq 'protocol') {
      $self->{$k} = $args{$k};
    }
  }

  # Check mandatory parameters
  Carp::croak "Initialisation parameter 'host' missing" unless defined($self->{'host'});
  Carp::croak "Initialisation parameter 'port' missing" unless defined($self->{'port'});
  Carp::croak "Initialisation parameter 'usr' missing" unless defined($self->{'usr'});
  Carp::croak "Initialisation parameter 'pwd' missing" unless defined($self->{'pwd'});

  # Bless object
  bless $self;
  
  # Initialise SOAP class
  my $apia=SOAP::Lite
      -> uri("http://www.fedora.info/definitions/api/")
      -> proxy($self->_get_proxy());
  if (defined($self->{timeout})) {
    $apia->proxy->timeout($self->{timeout});
  }
  $self->{apia} = $apia;

  return $self;
}

# Error from most recent operation
sub error {
  my $self = shift;
  return $self->{ERROR_MESSAGE};
}

# Elapsed time of most recent operation
sub get_time {
  my $self = shift;
  return $self->{TIME};
}

# Statistics 
sub get_stat {
  my $self = shift;
  return $self->{STAT};
}

sub get_proxy {
  my $self = shift;
  return $self->_get_proxy();
}

# Start statistic gathering over
sub start_stat {
  my $self = shift;
  $self->{STAT} = {};
  return;
}

# findObjects 
#
# Args in parameter hash:
#   maxResults:        Max number of results returned 
#   fldsrchProperty:   The field (aka property) being searched		 
#   fldsrchValue:      Operator for comparing a property to a value
#   fldsrchOperator:   The value of the field being searched		 
#   searchRes_ref:     Reference to scalar to hold search results
#
# Return:
#
#   0 = success
#   1 = Error
#   2 = Error on remote server
#
sub findObjects{
  my $self = shift;
  my %args = @_;

  $self->{ERROR_MESSAGE}=undef;
  $self->{TIME}=undef;

  Carp::croak "Parameter 'maxResults' missing" unless defined($args{maxResults});
  Carp::croak "Parameter 'fldsrchProperty' missing" unless defined($args{fldsrchProperty});
  Carp::croak "Parameter 'fldsrchOperator' missing" unless defined($args{fldsrchOperator});
  Carp::croak "Parameter 'fldsrchValue' missing" unless defined($args{fldsrchValue});
  Carp::croak "Parameter 'searchRes_ref' missing" unless defined($args{searchRes_ref})
;

  # List Datastreams 
  my $findobjs_result;
  eval {
    my $start=time;
    $findobjs_result = $self->{apia}->findObjects(
      SOAP::Data->name('resultFields'=> \SOAP::Data->value('pid')),
      SOAP::Data->name('maxResults')->value($args{maxResults})->type('xsd:nonNegativeInteger'),
      SOAP::Data->name('query'=> \SOAP::Data->value(
        SOAP::Data->name("conditions" => \SOAP::Data->value(
	  SOAP::Data->name("condition" => \SOAP::Data->value(
            SOAP::Data->name("property" => $args{fldsrchProperty}),
            SOAP::Data->name("operator" => $args{fldsrchOperator})->type('xsd:enumeration'),
            SOAP::Data->name("value" => $args{fldsrchValue})))))))
     );
    my $elapse_time = time - $start;
    $self->{TIME} = $elapse_time;
    $self->{STAT}->{'findObjects'}{count}++;
    $self->{STAT}->{'findObjects'}{time} += $elapse_time;
  };
  if ($@) {
    $self->{ERROR_MESSAGE}=$self->_handle_exceptions($@);
    return 1;
  }

  # Handle error from Fedora target
  if ($findobjs_result->fault) {
    $self->{ERROR_MESSAGE}=
           $findobjs_result->faultcode."; ".
           $findobjs_result->faultstring."; ".
           $findobjs_result->faultdetail;
    return 2;
  }

  # Handle success
  ${$args{searchRes_ref}} = $findobjs_result->result();
  return 0;

}


# resumeFindObjects 
#
# Args in parameter hash:
#   sessionToken:        
#   searchRes_ref:     Reference to scalar to hold search results
#
# Return:
#
#   0 = success
#   1 = Error
#   2 = Error on remote server
#
sub resumeFindObjects{
  my $self = shift;
  my %args = @_;

  $self->{ERROR_MESSAGE}=undef;
  $self->{TIME}=undef;

  Carp::croak "Parameter 'sessionToken' missing" unless defined($args{sessionToken});
  Carp::croak "Parameter 'searchRes_ref' missing" unless defined($args{searchRes_ref})
;

  # List Datastreams 
  my $resumefindobjs_result;
  eval {
    my $start=time;
    $resumefindobjs_result = $self->{apia}->resumeFindObjects($args{sessionToken});
    my $elapse_time = time - $start;
    $self->{TIME} = $elapse_time;
    $self->{STAT}->{'resumeFindObjects'}{count}++;
    $self->{STAT}->{'resumeFindObjects'}{time} += $elapse_time;
  };
  if ($@) {
    $self->{ERROR_MESSAGE}=$self->_handle_exceptions($@);
    return 1;
  }

  # Handle error from Fedora target
  if ($resumefindobjs_result->fault) {
    $self->{ERROR_MESSAGE}=
           $resumefindobjs_result->faultcode."; ".
           $resumefindobjs_result->faultstring."; ".
           $resumefindobjs_result->faultdetail;
    return 2;
  }

  # Handle success
  ${$args{searchRes_ref}} = $resumefindobjs_result->result();
  return 0;

}


# getDatastreamDissemination 
#
# Args in parameter hash:
#   pid:          Record PID in fedora
#   dsID:         Datastream PID
#   asOfDateTime 
#   stream_ref    Reference to scalar to hold resulting stream  
#
# Return:
#
#   0 = success
#   1 = Error
#   2 = Error on remote server
#
sub getDatastreamDissemination {
  my $self = shift;
  my %args = @_;

  $self->{ERROR_MESSAGE}=undef;
  $self->{TIME}=undef;

  Carp::croak "Parameter 'pid' missing" unless defined($args{pid});
  Carp::croak "Parameter 'dsID' missing" unless defined($args{dsID});
  Carp::croak "Parameter 'stream_ref' missing" unless defined($args{stream_ref})
;

  # Set Defaults
  if (!defined($args{asOfDateTime})) {
    $args{asOfDateTime} = "undef";
  }

  # Get Datastream Dissemination
  my $gdd_result;
  eval {
    my $start=time;
    $gdd_result = $self->{apia}->getDatastreamDissemination(
      $args{pid},
      $args{dsID},
     # $args{asOfDateTime},
      undef,
    );
    my $elapse_time = time - $start;
    $self->{TIME} = $elapse_time;
    $self->{STAT}->{'getDatastreamDissemination'}{count}++;
    $self->{STAT}->{'getDatastreamDissemination'}{time} += $elapse_time;
  };
  if ($@) {
    $self->{ERROR_MESSAGE}=$self->_handle_exceptions($@);
    return 1;
  }

  # Handle error from Fedora target
  if ($gdd_result->fault) {
    $self->{ERROR_MESSAGE}=
           $gdd_result->faultcode."; ".
           $gdd_result->faultstring."; ".
           $gdd_result->faultdetail;
    return 2;
  }

  # Handle success
  # Decode Stream
  ${$args{stream_ref}} = MIME::Base64::decode_base64($gdd_result->result()->{'stream'});
 
  return 0;

}


# listDatastreams
#
# Args in parameter hash:
#   pid:              Record PID in fedora
#   asOfDateTime:
#   datastream_ref:   Reference to scalar to hold result
#   list:             Reference to list. When provides will create list of
#                     datastream ids.
#
# Return:
#
#   0 = success
#   1 = Error
#   2 = Error on remote server
#
sub listDatastreams{
  my $self = shift;
  my %args = @_;

  $self->{ERROR_MESSAGE}=undef;
  $self->{TIME}=undef;

  Carp::croak "Parameter 'pid' missing" unless defined($args{pid});
  Carp::croak "Parameter 'datastream_ref' missing" unless defined($args{datastream_ref});

  # Set Defaults
  if (!defined($args{asOfDateTime})) {
    $args{asOfDateTime} = "undef";
  }

  # List Datastreams
  my $lds_result;
  eval {
    my $start=time;
    $lds_result = $self->{apia}->listDatastreams(
      $args{pid},
     # $args{asOfDateTime},
      undef
    );
    my $elapse_time = time - $start;
    $self->{TIME} = $elapse_time;
    $self->{STAT}->{'listDatastreams'}{count}++;
    $self->{STAT}->{'listDatastreams'}{time} += $elapse_time;
  };
  if ($@) {
    $self->{ERROR_MESSAGE}=$self->_handle_exceptions($@);
    return 1;
  }

  # Handle error from Fedora target
  if ($lds_result->fault) {
    $self->{ERROR_MESSAGE}=
           $lds_result->faultcode."; ".
           $lds_result->faultstring."; ".
           $lds_result->faultdetail;
    return 2;
  }

  # Does the user want a list of datastream identifiers.
  if ($args{list}) {

    my $datastreams;
    $datastreams = $lds_result;

    foreach my $ds ($datastreams->valueof('//datastreamDef')) {
      push(@{$args{list}},$ds->{ID});
    }
  }

  # Handle success
  ${$args{datastream_ref}} = $lds_result;
  return 0;

}

# datastreamExists (Boolean)
#
# Args in parameter hash:
#   pid:              Record PID in fedora
#   dsID:             Datastream identifier. Will check 
#                     existence of datastream.
#
# Return:
#
#   0 = False, datastream does not exist
#   1 = True, datastream exists
#
sub datastreamExists {
  my $self = shift;
  my %args = @_;

  Carp::croak "Parameter 'pid' missing" unless defined($args{pid});
  Carp::croak "Parameter 'dsID' missing" unless defined($args{dsID});



  my $pid  = $args{'pid'};
  my $dsID = $args{'dsID'};
  my $datastreams;

  if ($self->listDatastreams(pid=>$pid, 
			     datastream_ref =>\$datastreams) == 0) {
    my @dslist = ();

    foreach my $ds ($datastreams->valueof('//datastreamDef')) {
      push(@dslist,$ds->{ID});
    }
    if (grep $dsID eq $_, @dslist) {
      return 1;
    } else {
      return 0;
    }
  }
  return 0;
}



# getObjectProfile
#
# Args in parameter hash:
#   pid:          PID of the object 
#   asOfDateTime:
#   profile_ref: reference to return metadata profile
#
# Return:
#
#   0 = success
#   1 = Error
#   2 = Error on remote server
#
sub getObjectProfile {
  my $self = shift;
  my %args = @_;

  $self->{ERROR_MESSAGE}=undef;
  $self->{TIME}=undef;

  Carp::croak "Parameter 'pid' missing" unless defined($args{pid});
  Carp::croak "Parameter 'profile_ref' missing" unless defined($args{profile_ref});

  # Set Defaults
  if (!defined($args{asOfDateTime})) {
    $args{asOfDateTime} = "undef";
  }
  my $gds_result;
  eval {
    my $start=time;
    $gds_result = $self->{apia}->getObjectProfile (
      $args{pid},
      );
    my $elapse_time = time - $start;
    $self->{TIME} = $elapse_time;
    $self->{STAT}->{'getDatastream'}{count}++;
    $self->{STAT}->{'getDatastream'}{time} += $elapse_time;
  };
  if ($@) {
    $self->{ERROR_MESSAGE}=$self->_handle_exceptions($@);
    return 1; 
  }

  # Handle error from Fedora target
  if ($gds_result->fault) {
    $self->{ERROR_MESSAGE}=
           $gds_result->faultcode."; ".
           $gds_result->faultstring."; ".
           $gds_result->faultdetail;
    return 2;
  }

  my $data = $gds_result->result();

  # Handle success
  ${$args{profile_ref}} = $gds_result->result();
  return 0;

} # getObjectProfile

###

# ========================================================================= # 
# 
#  Private Methods
#
# ========================================================================= # 



# Map die exceptions from SOAP::Lite calls to Fedora::APIA error messages
sub _handle_exceptions {
  my ($self, $exception_text) = @_;
  if ($exception_text =~ m{^401 Unauthorized}) { return "401 Unauthorized"; }
  return $exception_text;
}

# Method for constructing proxy URL
sub _get_proxy {
  my ($self) = @_;
  return "$self->{'protocol'}://".
           $self->{usr}.":".$self->{pwd}.
           "\@".$self->{host}.":".$self->{port}.
           "/fedora/services/access";
}

1;
__END__


# ========================================================================= # 
# 
#  Documentation (pod)
#
# ========================================================================= # 


=head1 NAME

FedoraCommons::APIA - Interface for interaction with Fedora's Access API

=head1 VERSION

=head1 SYNOPSIS

  use FedoraCommons::APIA;

  my $apia=new Fedora::APIA(
              host    => "my.fedora.host",
              port    => "8080",
              usr     => "fedoraAdmin",
              pwd     => "foobarbaz",
              timeout => 100); 

  $status = $apia->findObjects( 
              resultFields => @resFlds,
	      maxResults => $maxRes,
              fldsrchValue => $fldsrchVal,
      	      fldsrchProperty => $fldsrchProp,
      	      fldsrchOperator => $fldsrchOp,
              searchRes_ref => \$searchRes);

  $status = $apia->resumeFindObjects(
              sessionToken => $sessionToken,
              searchRes_ref => \$searchRes);

  $status = $apia->getDatastreamDissemination(
              pid => $pid,
              dsID => $dsID,
              stream_ref => \$stream);

  $status = $apia->listDatastreams(
              pid=>$pid, 
              datastream_ref =>\$datastreams);

  $status = $apia->listDatastreams(
              pid=>$pid, 
              datastream_ref =>\$datastreams,
              list => \@dsList);

  Return Status for above methods:

   0 = success
   1 = Error
   2 = Error on remote server

   $bool   = $apia->datastreamExists(
               pid => $pid,
               dsID => $dsID);

   datastreamExists returns 1 (True) or 0 (False).


=head1 DESCRIPTION

FedoraCommons::APIA provides an interface to the SOAP-based access API
(API-A) of the Fedora repository architecture (L<http://www.fedora.info/>).

It exposes a subset of the API-A operations and handles errors and
elapsed-time profiling.

=head1 OPTIONS

FedoraCommons::APIA may be invoked with an option

=over 5

=item version

FedoraCommons::APIA supports multiple versions of the Fedora API-A.  
Specifying the version of the Fedora API-A is done at invocation time by

  use Fedora::APIA version=>3.2;

Supported versions of the Fedora API-A: 3.2.

=back

=head1 METHODS

Parameters for each method is passed as an anonymous hash.  Below is a
description of required and optional hash keys for each method. Methods will
croak if mandatory keys are missing.  Most keys corresponds to paramter 
names to the equivalent API-A operation described at
L<http://www.fedora-commons.org/confluence/display/FCR30/API-A>.

=head2 Constructor

=over 3 

=item new()

Constructor.  Called as 

    my $apia = new FedoraCommons::APIA (
      protocol => "https",        # Optional: enables SSL
      host    => "hostname",      # Required. Host name of 
                                  #   fedora installation
      port    => "8080",          # Required. Port number of 
                                  #   fedora installation
      usr     => "fedoraAdmin",   # Required. Fedora admin user
      pwd     => "fedoraAdmin",   # Required. Fedora admin password
      timeout => 100              # Optional. Timeout for
                                  #   SOAP connection
    );

=back

=head2 Methods representing API-A operations

Each method returns 0 upon success and 1 upon failure.  Method error() may be
used to get back a textual description of the error of the most recent method
call.

=over 3

=item findObjects()

Gets requested object fields @resFlds for all objects in the repository matching the given criteria 

    $apia->findObjects (
      resultFields => @resFlds,		# Required. Fields returned
      maxResults=> $maxres,             # Required. Max number of 
					#   results returned.
      fldsrchProperty => $fldsrchProp,  # Required. Field being searched
      fldsrchOperator => $fldsrchOp,    # Required. Operator for 
					#   comparing a property to 
                                        #   a value
      fldsrchValue => $fldsrchval,      # Required. Value of the property
					#   being searched.
      searchres_ref => \$searchres      # Required. Reference to scalar 
					#   into which search results 
                                        #   is put
    );

=item resumeFindObjects()

Gets the next list of results from a truncated findObjects response

    $apia->resumeFindObjects (
      sessionToken => $sessionToken,   # Required. token of the session
				       #   in which the next few 
                                       #   results can be found
      searchres_ref => \$searchres     # Required. Reference to scalar 
				       #   into which search results 
                                       #   is put 
    );

=item getDatastreamDissemination()

Gets a datastream in the digital Fedora object and returns the datastream.  Called as 

    my $mystream;
    $apia->getDatastreamDissemination(
      pid => $pid,                       # Required. Scalar holding
                                         #   PID of object 
      dsID => $dsID,                     # Required. 
      asOfDateTime => $asOfDateTime,     # Optional. 
      stream_ref => \$stream             # Required. Reference to scalar 
                                         #   into which resulting stream 
                                         #   is put
    );

B<Note:> Empty (or null'ed) dsID are currently not supported. 

=item listDatastreams()

Lists all of the datastreams in the digital Fedora object and returns the list of datastreams and associated values in a hash. Called as 

    my $datastreams;
    $apia->listDatastreams(
      pid => $pid,                       # Required. Scalar holding
                                         #   PID of object 
      datastream_ref => \$datastreams    # Required. Reference to scalar 
                                         #   into which resulting 
                                         #   datastreams is put
    );

Used as: [available fields: ID, label, MIMEType]

  if ($apia->listDatastreams(pid=>$pid, 
			     datastream_ref =>\$datastreams) == 0) {
    foreach my $ds ($datastreams->valueof('//datastreamDef')) {
      print "dsID: $ds->{ID} LABEL: $ds->{label} MIME: $ds->{MIMEType}\n";
    }
  }

New list feature added to simplify the common tasks of creating a list of
datastream names. Add a reference to a @list as argument list and the 
method will populate this with the list of the names.

    my $datastreams;
    my @dsList = ();
    $apia->listDatastreams(
      pid => $pid,                       # Required. Scalar holding
                                         #   PID of object 
      datastream_ref => \$datastreams,   # Required. Reference to scalar 
                                         #   into which resulting 
                                         #   datastreams data is returned.
      list => \@dsList,                  # Optional: return list of 
    );                                   #   datastreams.



=item datastreamExists()

Returns 1 (True) if datastream id exists in specified object. Otherwise
returns false which indicates either datastream doesn't exist or there
was an error. Check $apia->error() to determine if an error occurred.

This method is not part of the APIA specification.

    $apia->datastreamExists(
      pid => $pid,                       # Required. Scalar holding
                                         #   PID of object
      dsID => $dsID                      # Required. Datastream name 
                                         # (Examples: DC, RELS-EXT) 
    );


=back

=head2 Methods Currently Not Implemented

The following API-A methods are currently not supported in this module.
The decision to implement methods was based on the specific needs of our
project.

=over 3

=item describeRepository()

Provides information that describes the repository.

=item getObjectHistory()

Gets a list of timestamps that correspond to modification dates of components. This currently includes changes to Datastreams and disseminators.

=item getObjectProfile()

Profile of an object, which includes key metadata fields and URLs for the object Dissemination Index and the object Item Index. Can be thought of as a default view of the object.

=item getDissemination()

Disseminates the content produced by executing the method specified in the service definition associated the specified digital object.

=item listMethods()

Lists all the methods that the object supports.

=back

=head2 Other methods

=over 3

=item error()

Return error of most recent API-A method.

=item get_time()

Return the elapsed time of the most recent SOAP::Lite call to the fedora
API-A.

=item get_stat()

Return reference to hash describing total elapsed time and number of calls -
since instantiation or since most recent call to start_stat() - of all
SOAP::Lite calls to the fedora API-A.  

=item start_stat()

Start over the collection of elapsed times and number of calls statistics.

=back

=head1 DEPENDENCIES

SOAP::Lite, Time::HiRes, Carp

=head1 KNOWN BUGS, LIMITATIONS AND ISSUES

In its current implementation, Fedora::APIA represents a wrapping of the SOAP
based interface in which most of the parameters for the SOAP operations are
required parameters to the corresponding wrapping method, even though
parameters may be optional in the SOAP interface.

In future versions, parameters should become optional in the methods if
they are optional in the corresponding SOAP operation; or suitable defaults
may be used with SOAP for some of the parameters, should they be missing as
parameters to the wrapping method.

=head1 SEE ALSO

Fedora documentation: L<http://fedora-commons.org/confluence/display/FCR30/Fedora+Repository+3.2.1+Documentation>.

Fedora API-A documentation:
L<http://www.fedora-commons.org/confluence/display/FCR30/API-A>.

APIA Method summary descriptions are taken directly from the APIA documentation.

=head1 AUTHOR

The Fedora::APIA module is based on a module written by Christian 
Tønsberg, E<lt>ct at dtv dot dkE<gt> in 2006. Christian no longer supports
or distributes the module he developed.

Maryam Kutchemeshgi (Penn State University) put together the initial
version of Fedora::APIA. This module was originally developed (circa 2007) 
in a collaboration between Cornell University and Penn State University 
as part of a project to develop an interface to support the use of the 
Fedora Repository as the underlying repository for DPubS [Digital 
Publishing System] L<http://dpubs.org>. Maryam Kutchemeshgi 
E<lt>mxk128 at psu dot eduE<gt> is no longer involved with maintaining 
this module.

David L. Fielding (E<lt>dlf2 at cornell dot edu<gt>) is responsible for recent
enhancements along with packaging up the module and placing it on CPAN. 
To avoid confusion between Fedora (the Linux operating system) and
Fedora (the repository) I changed the name of the module package from
Fedora to FedoraCommons (the qualified name of the Fedora repository).
I have modified the modules to work with the Fedora Commons 3.2 APIs. 

This module implements a subset of the requests supported by the API-A 
specification. Additional requests may be implemented upon request. 
Please direct comments, suggestions, and bug
reports (with fixes) to me. The amount of additional development will 
depend directly on how many individuals are using the module.

Please refer to module comments for information on who implemented various
methods.

=head1 INSTALLATION

This module uses the standard method for installing Perl modules. This
module functions as an API for a Fedora server and therefore requires
a functioning Fedora server to run the tests ('make test'). Settings for
the Fedora server are read from the following environment variables:
FEDORA_HOST, FEDORA_PORT, FEDORA_USER, FEDORA_PWD. The tests will not 
run if these environment variable are not set properly.

=item perl Makefile.PL

=item make

=item make test

=item make install



=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008, 2009 by Cornell University, L<http://www.cornell.edu/> 
Copyright (C) 2007 by PSU, L<http://www.psu.edu/> 
Copyright (C) 2006 by DTV, L<http://www.dtv.dk/>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.

This library is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This library is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
details.

You should have received a copy of the GNU General Public License along with
this library; if not, visit http://www.gnu.org/licenses/gpl.txt or write to
the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
MA  02110-1301 USA

=cut
