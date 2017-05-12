# ========================================================================= # 
#
#     FedoraCommons::APIM - interface to Fedora's SOAP based API-M
#
# ========================================================================= # 
#
#  Copyright (c) 2011, Cornell University www.cornell.edu (enhancements)
#  Copyright (c) 2010, Cornell University www.cornell.edu (enhancements)
#  Copyright (c) 2009, Cornell University www.cornell.edu (enhancements)
#  Copyright (c) 2007, The Pennsylvania State University, www.psu.edu 
#  Copyright (c) 2006, Technical Knowledge Center of Denmark, www.dtv.dk
#
#  This library is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2, or (at your option)
#  any later version.
#
#  See pod documentation for further license and copyright information.
#
#  History: APIM interface was developed at PSU in 2006/2007. This code 
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
# Manifest of APIM API methods and APIM Module methods:
#                                                                    POD
# Fedora 3.0 APIM API Methods              Supported    Status    Documented
# ---------------------------              ---------    ------    ----------
#    * Datastream Management
#          o addDatastream                 Supported      OK        Yes
#          o compareDatastreamChecksum     Supported      New       Yes (C)
#          o getDatastream                 Supported      OK        Yes
#          o getDatastreamHistory             No
#          o getDatastreams                   No
#          o modifyDatastreamByReference   Supported      OK        Yes (PSU)
#          o modifyDatastreamByValue          No
#          o setDatastreamState               No
#          o setDatastreamVersionable      Supported      New       Yes (C)
#          o purgeDatastream               Supported      OK        Yes (PSU)
#    * Relationship Management
#          o addRelationship               Supported      New       Yes (C)
#          o getRelationships              Development    Broken
#          o purgeRelationship             Supported      New       Yes (C)
#    * Object Management
#          o modifyObject
#          o purgeObject                   Supported      OK        Yes
#          o export
#          o getNextPID                    Supported      Fixed??   Yes
#          o getObjectXML
#          o ingest                        Supported      OK        Yes (PSU)
#    * Miscellaneous Methods
#          o uploadFile (APIM-Lite api)                   OK        Yes (PSU)
#    * Non-API Methods
#          o createObject (not part of API)               New       Yes  (C)
#          o uploadNewDatastream (not part of API)        New       Yes  (C)
#
# Allow client to automatically set POLICY datastream 
# each time a new object is created. (*C)
#
#          o set_policy_url
#          o get_policy_url
#          o set_policy_path
#          o get_policy_path
#          o set_policy_label
#          o get_policy_label
#
# Enhancements/Additions:
# *PSU - Implemented by Penn State University
# *C   - Implemented by Cornell Univeersity
#
# ========================================================================= # 
#
#  $Id: APIM.pm,v 1.2 2007/06/25 15:22:53 dlf2 Exp $ 
#
# ========================================================================= # 
#

package FedoraCommons::APIM;

use strict;
use warnings;

require MIME::Base64;
require SOAP::Lite;
use Time::HiRes qw(time);
use Carp;
use LWP;
use POSIX;
use HTML::Template;

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use FedoraCommons::APIM ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(

) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(

);

our $VERSION = '0.6';


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

my $default_foxml = "";

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
#   The Fedora::APIM object
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
    } elsif ( $k eq 'replace') {
      $self->{$k} = $args{$k}; 
    } elsif ( $k eq 'reload') {
      $self->{$k} = $args{$k}; 
    } elsif ( $k eq 'debug') {
      $self->{$k} = $args{$k}; 
    } elsif ( $k eq 'policy_url') {
      $self->{$k} = $args{$k}; 
      $self->{'policy_path'} = "";# ensure only one is set
    } elsif ( $k eq 'policy_path') {
      $self->{$k} = $args{$k}; 
      $self->{'policy_url'} = ""; # ensure only one is set
    } elsif ( $k eq 'policy_label') {
      $self->{$k} = $args{$k}; 
    } elsif ($k eq 'protocol') {
      $self->{$k} = $args{$k};
    }
  }

  # Check mandatory parameters
  Carp::croak "Initialization parameter 'host' missing" unless defined($self->{'host'});
  Carp::croak "Initialization parameter 'port' missing" unless defined($self->{'port'});
  Carp::croak "Initialization parameter 'usr' missing" unless defined($self->{'usr'});
  Carp::croak "Initialization parameter 'pwd' missing" unless defined($self->{'pwd'});

  # Bless object
  bless $self;

  # Initialise SOAP class
  my $apim=SOAP::Lite
      -> uri('http://www.fedora.info/definitions/api/')
      -> proxy($self->_get_proxy());
  if (defined($self->{timeout})) {
    $apim->proxy->timeout($self->{timeout});
  }
  $self->{apim} = $apim;
  $self->{ERROR_MESSAGE} = "";

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

# Start statistic gathering over
sub start_stat {
  my $self = shift;
  $self->{STAT} = {};
  return;
}

sub get_default_foxml {
  return $default_foxml;
}

sub set_policy_url {
  my $self = shift;
  my $url  = shift;
  $self->{'policy_url'} = $url;
  $self->{'policy_path'} = ""; # Allow only one of url/path to be set
  return 1;
}
sub get_policy_url {
  my $self = shift;
  return $self->{'policy_url'};
}
sub set_policy_path {
  my $self = shift;
  my $url  = shift;
  $self->{'policy_path'} = $url;
  $self->{'policy_url'} = ""; # Allow only one of url/path to be set
  return 1;
}
sub get_policy_path {
  my $self = shift;
  return $self->{'policy_path'};
}
sub set_policy_label {
  my $self  = shift;
  my $label = shift;
  $self->{'policy_label'} = $label;
  return 1;
}
sub get_policy_label {
  my $self  = shift;
  return $self->{'policy_label'};
}

# uploadFile 
#
# Args in parameter hash:
#   filename:   File to upload 
#   file_ref    Reference to scalar to hold resulting filename
#
# Return:
#
#   0 = success
#   1 = Error
#   2 = Error on remote server
#
sub uploadFile {
  my $self = shift;
  my %args = @_;

  Carp::croak "Parameter 'filename' missing" unless defined($args{filename});
  Carp::croak "Parameter 'file_ref' missing" unless defined($args{file_ref});

   my $url = "http://".
           	$self->{usr}.":".$self->{pwd}.
           	"\@".$self->{host}.":".$self->{port};
   $url .= "/fedora/management/upload";

   my $agent = new LWP::UserAgent;
   my $result = $agent->post( $url, 
                              Content_Type => 'form-data',
                              Content => [ file => [$args{filename}] ] );

    if (! $result->is_success) {
##      $self->{ERROR_MESSAGE} = $result->content;
      return 2;
    }

    ${$args{file_ref}} = $result->content;
    return 0;
}


# Ingest
#
# Args in parameter hash:
#   XML_ref:     Reference to variable holding the foxml record to be ingested
#   logMessage:  Optional log message
#   pid_ref:     Reference to scalar to hold resulting pid
#
# Return:
#
#   0 = success
#   1 = Error
#   2 = Error on remote server
#
sub ingest {
  my $self = shift;
  my %args = @_;

  $self->{ERROR_MESSAGE}=undef;
  $self->{TIME}=undef;

  Carp::croak "Parameter 'XML_ref' missing" unless defined($args{XML_ref});
  Carp::croak "Parameter 'pid_ref' missing" unless defined($args{pid_ref});

  # Encode FOXML record
  my $foxml_encoded = MIME::Base64::encode_base64(${$args{XML_ref}});

  # Ingest FOXML record
  my $ingest_result;
  eval {
    my $start=time;
    $ingest_result = $self->{apim}->ingest(
      SOAP::Data->value($foxml_encoded)->type('xsd:base64Binary'),
        "info:fedora/fedora-system:FOXML-1.1",       # Format
        $args{logMessage} # Log message
      );
    my $elapse_time = time - $start;
    $self->{TIME} = $elapse_time;
    $self->{STAT}->{'ingest'}{count}++;
    $self->{STAT}->{'ingest'}{time} += $elapse_time;
  };
  if ($@) {
    $self->{ERROR_MESSAGE}=$self->_handle_exceptions($@);
    return 1; 
  }

  # New DLF2

  # We will automatically purge the object and try to recreate the object
  if ($ingest_result->fault && $self->{replace} && 
      $ingest_result->faultstring =~/already exists in the registry/) {
    $ingest_result->faultstring =~/The PID \'([^\']*)\' already/;
    if ($self->{debug}) {
      print "APIM: PID Exists: $1\n";
      print "APIM: Purge Object: $1\n";
    }
    my $ts;
    if ($self->purgeObject(pid => $1,
			   logMessage=>"Purge Object (replace)",
			   timestamp_ref =>\$ts) == 0) {
      if ($self->ingest(XML_ref =>   $args{XML_ref},
			logMessage=> $args{logMessage},
			pid_ref =>   $args{pid_ref}) == 0) {
	if ($self->{debug}) {
	  print "APIM: Ingested New Monograph Object(2): $1\n\n";
	}
	return 0;
      } else {
	if ($self->{debug}) {
	  print "APIM: Ingest: Object exists: Purge: re-Ingest FAILED: " .
	    $self->{ERROR_MESSAGE} . "\n";
	}
      }
    } else {
      if ($self->{debug}) {
	print "APIM: Ingest: Object exists: Purge FAILED: " .
	  $self->{ERROR_MESSAGE} . "\n";
      }
    }


  } elsif ($ingest_result->fault && $self->{reload} && 
	   $ingest_result->faultstring =~/already exists in the registry/) {
    #
    $ingest_result->faultstring =~/The PID \'([^\']*)\' already/;
    ${$args{pid_ref}} = $1;
    if ($self->{debug}) {
      print "APIM: Reload: exists: OKAY\n\n";
    }
    return 0;
  }

  # Handle error from Fedora target
  if ($ingest_result->fault) {
    $self->{ERROR_MESSAGE}=
           $ingest_result->faultcode."; ".
           $ingest_result->faultstring."; ".
           $ingest_result->faultdetail;
    return 2;
  }

  # Handle success
  ${$args{pid_ref}} = $ingest_result->result();
  return 0;

}

# createObject [NEW]             THIS IS NOT A FEDORA APIM REQUEST
#
# Create a simple Fedora object [empty]
#
# Args in parameter hash:
#   XML_ref:       Reference to variable holding the foxml record to be 
#                  ingested.
#   XML_file:      Reference to foxml path to be munged and ingested
#   params:        Hash reference containing parameters to substitute into 
#                  FOXML template. [Use when file
#   policy_params: Hash reference containing parameters for adding policy
#                  datastream to newly created object. POLICY Datastream 
#                  is set according to the arguments you provide.
#                  Datastream label is optional (policy_label).
#                  Client must provide URL that resolves to the 
#                  policy (policy_url) or a path to the policy in 
#                  the filesystem (policy_path).
#   logMessage:    Optional log message
#   pid_ref:       Reference to scalar to hold resulting pid
#
# Return:
#
#   0 = success
#   1 = Error
#   2 = Error on remote server
#
sub createObject {
  my $self = shift;
  my %args = @_;

  $self->{ERROR_MESSAGE}=undef;
  $self->{TIME}=undef;

  # XML_ref object is optional. Will read in default FOXML when missing.
  if (! defined $args{XML_ref} && ! defined $args{XML_file} ) {
    $self->{ERROR_MESSAGE} = "Parameter 'XML_ref' or XML_file missing.";
    return 1;
  }

  my ($foxml_ref, $foxml_template_file, $pid);
  my (@temp_files) = ();

  # Use in-line FOXML when defaul FOXML file is not present.
  if (! $args{XML_ref} && ($args{XML_file} && ! -s $args{XML_file})) {
    $args{XML_ref} = \$default_foxml;
  }

  if ($args{XML_ref}) {
    $foxml_ref = $args{XML_ref};
    my $inputFOXMLfile = POSIX::tmpnam() . 'inputFOXML';
    open my $fh, ">", $inputFOXMLfile;
    binmode $fh, ":utf8";
    if (defined $fh) {
      print $fh $$foxml_ref;
      $foxml_template_file = $inputFOXMLfile;
      push @temp_files, $inputFOXMLfile;
    }
  } elsif ($args{XML_file}) {
    $foxml_template_file = $args{XML_file};
  } else {
    $foxml_template_file = "./ingesttemplate.xml";
  }

  if (! -s $foxml_template_file) {
    $self->{ERROR_MESSAGE} = "FOXML template file does not exist.";
    return 1;
  }

  # Perform template substitutions (when necessary)
  if ($foxml_template_file) {

    # Manage template operations (Read XML as template, substitute, write out)
    # Instantiate Template object
    my $template = HTML::Template->new (filename => "$foxml_template_file");

    if (! defined $template) {
      my $mes = "Failed to instantiate Fedora template.";
      $self->{ERROR_MESSAGE} = "Failed to create FOXML template instance.";
      return 1;
    }

    # Create temporary file (to be deleted)
    my $tempFOXMLfile = POSIX::tmpnam() . 'tempFOXML';

    open my $fh, ">", $tempFOXMLfile;
    if (defined $fh) {
      my %params = ();

      if (defined $args{params}) {
	%params = %{$args{params}};
      }

      foreach my $param (keys %params) {
	$template->param($param => $params{$param});
      }

      print $fh $template->output;
      close $fh;
      push @temp_files, $tempFOXMLfile;
    } else {
      # Error creating template file
      $self->{ERROR_MESSAGE} = "Failed to create temp FOXML template file.";
      return 1;
    }
    # template written to temp file

    # Read in FOXML
    open $fh, "<", $tempFOXMLfile;
    binmode $fh, ":utf8";

    if (defined $fh) {
      my $foxml;
      while (<$fh>) { $foxml .= $_; }
      close($fh);
      $foxml_ref = \$foxml;
    }
  } # end template processing

  # Proceed if we have successfully created the FOXML
  if ($foxml_ref) {

    my $logMessage = $args{logMessage} || "Create New Object";

    # Now create the object
    if ($self->ingest(XML_ref => $foxml_ref,
			      logMessage => "$logMessage",
			      pid_ref => \$pid) == 0) {
      if ($self->{debug}) {
	print "SUB: Ingested New Monograph Object: $pid\n\n";
      }

      # Finished creating new object. Now deal with adding policy
      # datastream (if specified)

      # Support setting simple external policy link
      my %policy_params = ();

      my ($path, $url, $label, $cg, $filename);
      $path = "";
      $url = "";

      # Give arguments to method precidence over instance settings
      if (defined $args{policy_params}) {
	%policy_params = %{$args{policy_params}};

	$path  = $policy_params{'policy_path'};
	$url   = $policy_params{'policy_url'};
	$label = $policy_params{'policy_label'};
      } elsif ($self->{'policy_path'} || $self->{'policy_url'}) {
	$path  = $self->{'policy_path'};
	$url   = $self->{'policy_url'};
	$label = $self->{'policy_label'};
      }

      # Can't have both set - return error
      if ($path && $url) {
	if ($self->{debug}) {
	  print "ERROR adding POLICY Datastream FAILED: Set one of \n"
	    . "policy_url or policy_path, not both."
	      . "Object ID: $pid\n";
	}
	$self->{ERROR_MESSAGE} = "Bad policy arguments. Set only one of ."
	  . "policy_url or policy_path";
	return 1;
      }

      # Make sure file exists
      if ($path && ! -s $path) {
	$self->{ERROR_MESSAGE} = "ERROR: Bad policy path: $path"
	  . " File does not exist.";
	return 1;
      }

      # For path we must upload the XACML file first and set url to file ref.
      # For url (external reference, we are all set)
      if ($path && -s $path) {
	$filename = $path;
	if (! $label) { $label = "Policy Datastream";}
	$cg = 'M';
      } elsif ($url) {
	if (! $label) { $label = "External Policy Datastream Reference";}
	$cg = 'E';
      }

      # Add policy datastream - this is a new object so we shouldn't need
      # to worry about existing policy 
      if (defined $url && $url) {
	if ($self->{debug}) {
	  print "*** Adding POLICY datastream to object $pid.\n";
	}
	my $dsID = "POLICY";
	my $altids = '';
	my $v = 'true';
	my $mime = "text/plain";
	my $uri = '';
	my $state = 'A';
	my $msg    = "Adding policy to new object.";
	my ($dsid, $ts);

	if ($self->uploadNewDatastream ( pid => $pid,
					 dsID => $dsID,
					 altIDs => $altids,
					 dsLabel => $label,
					 versionable => $v,
					 filename => $filename,
					 MIMEType => $mime,
					 formatURI => $uri,
					 dsLocation => $url,
					 controlGroup => $cg,
					 dsState => $state,
					 logMessage => $msg,
					 dsid_ref => \$dsid,
					 timestamp_ref => \$ts, ) == 0) {
	  if ($self->{debug}) {
	    print "Added POLICY Datastream Reference: $dsid to object: $pid\n";
	  }
	} else {
	  my $error = $self->error();
	  if ($self->{debug}) {
	    print "Adding POLICY Datastream Reference FAILED: "
	      . "$dsID to object: $pid\n$error\n";
	  }
	  $self->{ERROR_MESSAGE} = "Failed to add POLICY datastream. $error";
	  return 1;
	}
      } # if policy parameters

    } else {
      if ($self->{debug}) {
	print "SUB: ERROR: Injesting NEW object FAILED: " 
	  . $self->{apim}->error() 
	    . "\n\n";
      }
      $self->{ERROR_MESSAGE} =  $self->{ERROR_MESSAGE} . 
	"ERROR: Injesting NEW object FAILED: " 
	  . $self->{apim}->error();

      return 1;
    }
  } else {
    $self->{ERROR_MESSAGE} = "Failed to open FOXML file (internal).";
    return 1;
  }

  # Get rid of temporary files
  unlink @temp_files;

  # Handle success
  ${$args{pid_ref}} = $pid;
  return 0;
}


# purgeObject
#
# Args in parameter hash:
#   pid:         PID of object to be purged
#   logMessage:  Optional log message
#   timestamp_ref:  Reference to scalar to hold the timestamp of operation 
#
# Return:
#
#   0 = success
#   1 = Error
#   2 = Error on remote server
#

sub purgeObject {
  my $self = shift;
  my %args = @_;

  $self->{ERROR_MESSAGE}=undef;
  $self->{TIME}=undef;

  Carp::croak "Parameter 'pid' missing" unless defined($args{pid});
  Carp::croak "Parameter 'timestamp_ref' missing" 
    unless defined($args{timestamp_ref});

  # Set Defaults
  $args{force} = "false";  # To be customizable in future fedora versions

  #if (!defined($args{force})) {
  #  $args{force} = "false";
  #}

  # purge object
  my $purge_result;
  eval {
    my $start=time;
    $purge_result = $self->{apim}->purgeObject(
        $args{pid},
        $args{logMessage},
        SOAP::Data->value($args{force})->type('xsd:boolean'),
      );
    my $elapse_time = time - $start;
    $self->{TIME} = $elapse_time;
    $self->{STAT}->{'purgeObject'}{count}++;
    $self->{STAT}->{'purgeObject'}{time} += $elapse_time;
  };
  if ($@) {
    $self->{ERROR_MESSAGE}=$self->_handle_exceptions($@);
    return 1; 
  }

  # Handle error from Fedora target
  if ($purge_result->fault) {
    $self->{ERROR_MESSAGE}=
           $purge_result->faultcode."; ".
           $purge_result->faultstring."; ".
           $purge_result->faultdetail;
    return 2;
  }

  # Handle success
  ${$args{timestamp_ref}} = $purge_result->result();
  return 0;

}


# getNextPID
#
# Args in parameter hash:
#   numPids:     MNumber of PIDs
#   pidNamespace: Namespace for PIDs 
#   pidlist_ref:  Reference to list to hold resulting pids
#
# Return:
#
#   0 = success
#   1 = Error
#   2 = Error on remote server
#
sub getNextPID {
  my $self = shift;
  my %args = @_;

  $self->{ERROR_MESSAGE}=undef;
  $self->{TIME}=undef;

  Carp::croak "Parameter 'numPids' missing" 
    unless defined($args{numPids});
  Carp::croak "Parameter 'pidNamespace' missing" 
    unless defined($args{pidNamespace});
  Carp::croak "Parameter 'pidlist_ref' missing" 
    unless defined($args{pidlist_ref});

  my $getnextpid_result;
  eval {
    my $start=time;
    $getnextpid_result = $self->{apim}->getNextPID(
        SOAP::Data->value($args{numPids})
                  ->type('xsd:nonNegativeInteger'), # numPids
        $args{pidNamespace},   # pidNamespace
      );
    my $elapse_time = time - $start;
    $self->{TIME} = $elapse_time;
    $self->{STAT}->{'getNextPID'}{count}++;
    $self->{STAT}->{'getNextPID'}{time} += $elapse_time;
  };
  if ($@) {
    $self->{ERROR_MESSAGE}=$self->_handle_exceptions($@);
    return 1; 
  }

  # Handle error from Fedora target
  if ($getnextpid_result->fault) {
    $self->{ERROR_MESSAGE}=
              $getnextpid_result->faultcode."; ".
              $getnextpid_result->faultstring."; ".
              $getnextpid_result->faultdetail;
    return 2;
  }

  my $result_ref = $getnextpid_result->result();
  push @{$args{pidlist_ref}},$result_ref; 

  my @pids = $getnextpid_result->paramsout();

  foreach my $p (@pids) {
    push @{$args{pidlist_ref}}, $p;
  }

  return 0;
}


# addDatastream
#
# Args in parameter hash: 
#   pid:          PID of the object
#   dsID:         ID of the datastream
#   altIDs:       Alternertive ID's  (optional)
#   dsLabel:      Datastream Label
#   versionable:  "true" or "false" 
#   MIMEType:     The mimetype of the datastream
#   formatURI:    A URI for the namespace of the record
#   dsLocation:   Location where fedora can retrieve the
#                 content of the datastream
#   controlGroup: "X", "M", "R", or "E"
#   dsState:      "A", "I" or "D"
#   checksumType: the checksum algorithm to use in computing
#                 the checksum value 
#   checksum:	  value of the checksum in hexadecimal string 
#   logMessage:   Log message (optional)
#   dsid_ref:     Reference to scalar to hold the resulting datastream id
#
# Return:
#
#   0 = success
#   1 = Error
#   2 = Error on remote server
#
sub addDatastream {
  my $self = shift;
  my %args = @_;

  $self->{ERROR_MESSAGE}=undef;
  $self->{TIME}=undef;

  Carp::croak "Parameter 'pid' missing" unless defined($args{pid});
  Carp::croak "Parameter 'dsID' missing" unless defined($args{dsID});
  Carp::croak "Parameter 'dsLabel' missing" unless defined($args{dsLabel});
  Carp::croak "Parameter 'versionable' missing" unless defined($args{versionable});
  Carp::croak 
    "Illegal value '".$args{versionable}."' for parameter 'versionable'" 
  unless (($args{versionable} eq "true") || ($args{versionable} eq "false"));
  Carp::croak "Parameter 'MIMEType' missing" unless defined($args{MIMEType});
  Carp::croak "Parameter 'formatURI' missing" unless defined($args{formatURI});
  Carp::croak "Parameter 'dsLocation' missing" unless defined($args{dsLocation});
  Carp::croak "Parameter 'controlGroup' missing" unless defined($args{controlGroup});
  Carp::croak 
    "Illegal value '".$args{controlGroup}."' for parameter 'controlGroup'"
  unless (  ($args{controlGroup} eq "X") || 
            ($args{controlGroup} eq "M") || 
            ($args{controlGroup} eq "R") ||
            ($args{controlGroup} eq "E") );
  Carp::croak "Parameter 'dsState' missing" unless defined($args{dsState});
  Carp::croak 
    "Illegal value '".$args{dsState}."' for parameter 'dsState'"
  unless (  ($args{dsState} eq "A") || 
            ($args{dsState} eq "I") || 
            ($args{dsState} eq "D") );
  Carp::croak "Parameter 'dsid_ref' missing" unless defined($args{dsid_ref});

  # Set Defaults
  if (!defined($args{altIDs})) {
    $args{altIDs} = "";
  }

  # Set Defaults
  if (! defined($args{checksumType})) {
    $args{checksumType} = undef;
  }

  # Set Defaults
  if (!defined($args{checksum})) {
    $args{checksum} = undef;
  }

  # If replace (datastream) is set we TURN OFF versioning
  # regardless of user specified argument.
  if ($self->{replace}) {
    $args{versionable} = 'false';
  }


  # Since many datastreams were added with the versionable flag set to
  # false we must change this using the setDatastreamVersionable APIM
  # request to make this active
  my $ts;
  if ($self->setDatastreamVersionable
      ( pid => $args{pid},
	dsID => $args{dsID},
	versionable => $args{versionable},
	timestamp_ref => \$ts,
      ) == 0) {

    if ($self->{debug}) { 
      print "Set Datastream Versionable '$args{versionable}' SUCCEEDED: "
	. "DSID:$args{dsID} TS:$ts for object: $args{pid}\n"; }

  } else {
    if ($self->{debug}) {
      print "Set Datastream Versionable FAILED: PID:$args{pid} "
	. "DSID:$args{dsID}" . $self->error() . "\n"; 
    }
  }
  # Finished setDatastreamVersionable

  # Add Datastream
  my $ads_result;
  eval {
    my $start=time;
    $ads_result = $self->{apim}->addDatastream(
      $args{pid},
      $args{dsID},
      $args{altIDs},
      $args{dsLabel},
      SOAP::Data->value($args{versionable})->type('xsd:boolean'),
      $args{MIMEType},
      $args{formatURI},
      SOAP::Data->value($args{dsLocation})->type('xsd:string'),
      $args{controlGroup},
      $args{dsState},
      $args{checksumType},
      $args{checksum},
      $args{logMessage},
    );
    my $elapse_time = time - $start;
    $self->{TIME} = $elapse_time;
    $self->{STAT}->{'addDatastream'}{count}++;
    $self->{STAT}->{'addDatastream'}{time} += $elapse_time;
  };
  if ($@) {
    $self->{ERROR_MESSAGE}=$self->_handle_exceptions($@);
    return 1; 
  }

  # Handle error from Fedora target
  if ($ads_result->fault) {
    $self->{ERROR_MESSAGE}=
           $ads_result->faultcode."; ".
           $ads_result->faultstring."; ".
           $ads_result->faultdetail;
    return 2;
  }

  # Handle success
  ${$args{dsid_ref}} = $ads_result->result();
  return 0;

}

# uploadNewDatastream [NEW]             THIS IS NOT A FEDORA APIM REQUEST
#
# This routine combines the upload operation and the add datastream operation
# into one single call. This routine also sets reasonable defaults for many
# of the parameters to addDatastream.
#
# Only addition parameter (on top of addDatastream parameters) is the filename.
#
# Only required parameters are filename, mime type, pid, and ds_id.
#
# Args in parameter hash:                                  R - Required
#   pid:          PID of the object                            R
#   dsID:         ID of the datastream                         R
#   altIDs:       Alternertive ID's  (optional)                O
#   dsLabel:      Datastream Label                             O
#   versionable:  "true" or "false"                            Default: false
#   filename:     Filename to upload and attach to object      R
#   MIMEType:     The mimetype of the datastream               R
#   formatURI:    A URI for the namespace of the record        [internal]
#   dsLocation:   Location where fedora can retrieve the       [internal]
#                 content of the datastream
#   controlGroup: "X", "M", "R", or "E"                        Default: M
#   dsState:      "A", "I" or "D"                              Default: A
#   checksumType: the checksum algorithm to use in computing the checksum  
#   checksum:	  value of the checksum in hexadecimal string 
#   logMessage:   Log message (optional)
#   dsid_ref:     Reference to scalar to hold the resulting datastream id
#
# Return:
#
#   0 = success
#   1 = Error
#   2 = Error on remote server
#
# Notes:
#   This routine has been modified to add external reference datastreams
# as POLICY datastreams to objects. The 'filename' argument
# is no longer 'require' to allow external reference to be passed in the
# argument 'dsLocation'. 'dsLocation' may contain external link of reference
# to uploaded file.
#
sub uploadNewDatastream {
  my $self = shift;
  my %args = @_;

  $self->{ERROR_MESSAGE}=undef;
  $self->{TIME}=undef;

  # Check for required arguments
  if (! defined $args{filename} && ! defined $args{dsLocation} ) {
    $self->{ERROR_MESSAGE} = "Parameter 'filename' or 'dsLocation' missing.";
    return 1;
  }
  if (defined $args{filename} && defined $args{dsLocation} ) {
    $self->{ERROR_MESSAGE} = "Invalid arguments: Specify only ONE of "
      ."either 'filename' or 'dsLocation'.";
    return 1;
  }
  if (! defined $args{MIMEType}) {
    $self->{ERROR_MESSAGE} = "Parameter 'MIMEType' missing.";
    return 1;
  } 
  if (! defined $args{pid}) {
    $self->{ERROR_MESSAGE} = "Parameter 'pid' missing.";
    return 1;
  }
  if (! defined $args{dsID}) {
    $self->{ERROR_MESSAGE} = "Parameter 'dsID' missing.";
    return 1;
  }

  # Fill in optional arguments
  if (! defined $args{dsLabel}) {
    $args{dsLabel} = '';
  }
  if (! defined $args{versionable}) {
##    $args{versionable} = "true";
    $args{versionable} = "true";
  }
  if (! defined $args{controlGroup}) {
    $args{controlGroup} = "M";
  }
  if (! defined $args{dsState}) {
    $args{dsState} = "A";
  }
  if (! defined $args{checksumType}) {
    $args{checksumType} = "SHA-1";
  }
  if (! defined $args{logMessage}) {
    $args{logMessage} = "Add datastream.";
  }

  # Do we need to set other arguments to null?

  # Now upload datastream or reference
  # Support uploading filename and external reference (URL)
  #
  my ($file_ref, $dsid, $url, $uri);
  $uri = '';
  $url = "";

  if ($args{filename} && -s $args{filename}) {
    if ($self->uploadFile(
			   filename => $args{filename},
			   file_ref => \$file_ref
			  ) == 0 ) {
      # mesage file_ref
      $url = $file_ref;
    } else {
      if ($self->error()) {
	print "ERROR: " . $self->error() . "'$file_ref'\n";
      } else {
	print "ERROR: Unknown error uploadFile().\n";
      }
    }
  }

  if ($args{dsLocation}) {
    # This value is either an external link or a reference to
    # a file that has been already uploaded via the uploadFile
    # method. These are both valid values for the argument dsLocation.
    $url = $args{dsLocation};
  }

  # Remove trailing spaces
  $url =~ s/\s+$//;

  if ($url) {

    # Add datastream to object
    if ($self->addDatastream( pid => $args{pid},
			      dsID => $args{dsID},
			      altIDs => $args{altIDs},
			      dsLabel => $args{dsLabel},
			      versionable => $args{versionable},
			      MIMEType => $args{MIMEType},
			      formatURI => $uri,
			      dsLocation => $url,
			      controlGroup => $args{controlGroup},
			      dsState => $args{dsState},
			      checksumType => $args{checksumType},
			      checksum => undef,
			      logMessage => $args{logMessage},
			      dsid_ref => \$dsid ) == 0) {

      ${$args{dsid_ref}} = $dsid;
      return 0;
    } else {
      # addDatastream call failed
      if ($self->{debug}) {
	print "Error: Adding datastream: $args{dsLabel}:" 
	  . $self->error() . "\n"; 
      }
      if ($self->error() =~ /A datastream already exists with/) {
	if ($self->{debug}) {
	  print "ERROR: Datastream exists: Will use modify datastream "
	    . "method\n";
	}

	# Modify Datastream
	my $ts;
	my $force = "true"; 
	my $msg = 'DPubS modifyDatastream';
	if ($self->modifyDatastreamByReference
	    ( pid => $args{pid},
	      dsID => $args{dsID},
	      altIDs => $args{altIDs},
	      dsLabel => $args{dsLabel},
	      MIMEType => $args{MIMEType},
	      formatURI => $uri,
	      dsLocation => $url,
	      checksumType => $args{checksumType},
	      checksum => undef,
	      logMessage => $args{logMessage},
	      force => $force,
	      timestamp_ref => \$ts) == 0) {

	  if ($self->{debug}) {
	    print "Successfully modified datastream: $ts.\n";
	  }

	  ${$args{timestamp_ref}} = $ts;
	  return 0;
	} else {
	  # An error occurred in trying to modify datastream
	  $self->{ERROR_MESSAGE} = ($self->{ERROR_MESSAGE} || "")
	    . "Failed to modify datastream.";
	  return 1;
	}
      } # end datastream exists code

      # Rely on addDatastream to set error string
      return 1;
    }

  } else { # $url was not set properly, failed to upload or specify link
    # Failed to upload file
    # Rely on uploadFile to set error string.
    $self->{ERROR_MESSAGE} = ($self->{ERROR_MESSAGE} || "")
      . "Failed to upload datastream file.";
    return 1;
  }
}

# getDatastream
#
# Args in parameter hash:
#   pid:          PID of the object 
#   dsID:         Datastream PID
#   asOfDateTime:
#   ds_ref:     Reference to scalar to hold the resulting datastream
#
# Return:
#
#   0 = success
#   1 = Error
#   2 = Error on remote server
#
sub getDatastream {
  my $self = shift;
  my %args = @_;

  $self->{ERROR_MESSAGE}=undef;
  $self->{TIME}=undef;

  Carp::croak "Parameter 'pid' missing" unless defined($args{pid});
  Carp::croak "Parameter 'dsID' missing" unless defined($args{dsID});
  Carp::croak "Parameter 'ds_ref' missing" unless defined($args{ds_ref});

  # Set Defaults
  if (!defined($args{asOfDateTime})) {
    $args{asOfDateTime} = "undef";
  }

  # Add Datastream
  my $gds_result;
  eval {
    my $start=time;
    $gds_result = $self->{apim}->getDatastream(
      $args{pid},
      $args{dsID},
     # $args{asOfDateTime},
      undef,
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

  # Handle success
  ${$args{ds_ref}} = $gds_result->result();
  return 0;

}


# modifyDatastreamByReference
#
# Args in parameter hash:
#   pid:            PID of the object 
#   dsID:           Datastream PID
#   altIDs:         Alternertive ID's  (optional)
#   dsLabel:        Datastream Label
#   MIMEType:       The mimetype of the datastream
#   formatURI:      A URI for the namespace of the record
#   dsLocation:     Location where fedora can retrieve the 
#                   content of the datastream
#   logMessage:     Log message (optional)
#   force:	    "true" or "false" 
#   timestamp_ref:  Reference to scalar to hold timestamp of the operation 
#
# Return:
#
#   0 = success
#   1 = Error
#   2 = Error on remote server
#
sub modifyDatastreamByReference{
  my $self = shift;
  my %args = @_;

  $self->{ERROR_MESSAGE}=undef;
  $self->{TIME}=undef;

  Carp::croak "Parameter 'pid' missing" unless defined($args{pid});
  Carp::croak "Parameter 'dsID' missing" unless defined($args{dsID});
  Carp::croak "Parameter 'dsLabel' missing" unless defined($args{dsLabel});
  Carp::croak "Parameter 'MIMEType' missing" unless defined($args{MIMEType});
  Carp::croak "Parameter 'formatURI' missing" unless defined($args{formatURI});
  Carp::croak "Parameter 'dsLocation' missing" unless defined($args{dsLocation});
  Carp::croak "Parameter 'force' missing" unless defined($args{force});
  Carp::croak 
    "Illegal value '".$args{force}."' for parameter 'force'" 
  unless (($args{force} eq "true") || ($args{force} eq "false"));
  Carp::croak "Parameter 'timestamp_ref' missing" 
    unless defined($args{timestamp_ref});

  # Set Defaults
  if (!defined($args{altIDs})) {
    $args{altIDs} = "";
  }

  # Set Defaults
  if (!defined($args{checksumType})) {
    $args{checksumType} = undef;
  }

  # Set Defaults
  if (!defined($args{checksum})) {
    $args{checksum} = undef;
  }

  # Modify Datastream By Reference
  my $mdbr_result;
  eval {
    my $start=time;
    $mdbr_result = $self->{apim}->modifyDatastreamByReference(
      $args{pid},
      $args{dsID},
      $args{altIDs},
      $args{dsLabel},
      $args{MIMEType},
      $args{formatURI},
      SOAP::Data->value($args{dsLocation})->type('xsd:string'),
      $args{checksumType},
      $args{checksum},
      $args{logMessage},
      SOAP::Data->value($args{force})->type('xsd:boolean'),
    );
    my $elapse_time = time - $start;
    $self->{TIME} = $elapse_time;
    $self->{STAT}->{'modifyDatastreambyReference'}{count}++;
    $self->{STAT}->{'modifyDatastreambyReference'}{time} += $elapse_time;
  };
  if ($@) {
    $self->{ERROR_MESSAGE}=$self->_handle_exceptions($@);
    return 1; 
  }

  # Handle error from Fedora target
  if ($mdbr_result->fault) {
    $self->{ERROR_MESSAGE}=
           $mdbr_result->faultcode."; ".
           $mdbr_result->faultstring."; ".
           $mdbr_result->faultdetail;
    return 2;
  }

  # Handle success
  ${$args{timestamp_ref}} = $mdbr_result->result();
  return 0;

}

# setDatastreamVersionable
#
# Args in parameter hash:
#   pid:            PID of object 
#   dsID:           ID of the datastream 
#   versionable:    "true" or "false" (boolean)
#   logMessage:     Log message (optional)
#
# Returns:
#   timestamp_ref   timestamp
#

sub setDatastreamVersionable {
  my $self = shift;
  my %args = @_;

  Carp::croak "Parameter 'pid' missing" unless defined($args{pid});
  Carp::croak "Parameter 'dsID' missing" unless defined($args{dsID});
  Carp::croak "Parameter 'versionable' missing" 
      unless defined($args{versionable});
  Carp::croak 
      "Illegal value '".$args{versionable}."' for parameter 'versionable'"
    unless (($args{versionable} eq "true") || ($args{versionable} eq "false"));

  if (! defined $args{logMessage}) {
    $args{logMessage} = "Set datastream versionable attribute.";
  }

  my $setDV_result;
  eval {
    my $start=time;
    $setDV_result = $self->{apim}->setDatastreamVersionable
      (
       $args{pid},
       $args{dsID},
       SOAP::Data->value($args{versionable})->type('xsd:boolean'),
       $args{logMessage},
      );
    my $elapse_time = time - $start;
    $self->{TIME} = $elapse_time;
    $self->{STAT}->{'setDatastreamVersionable'}{count}++;
    $self->{STAT}->{'setDatastreamVersionable'}{time} += $elapse_time;
  };
  if ($@) {
    $self->{ERROR_MESSAGE}=$self->_handle_exceptions($@);
    return 1;
  }

  # Handle error from Fedora target
  if ($setDV_result->fault) {
    $self->{ERROR_MESSAGE}=
           $setDV_result->faultcode."; ".
           $setDV_result->faultstring."; ".
           $setDV_result->faultdetail;
    return 2;
  }

  # Handle success
  ${$args{timestamp_ref}} = $setDV_result->result();
  return 0;

}

# purgeDatastream
#
# Args in parameter hash:
#   pid:            PID of object 
#   dsID:           ID of the datastream 
#   startDT:        Starting date-time stamp of the range 
#   endDT:          Ending date-time stamp of the range 
#   logMessage:     Optional log message
#   timestamp_ref:  Reference to scalar to hold the timestamp of operation 
#
# Return:
#
#   0 = success
#   1 = Error
#   2 = Error on remote server
#

sub purgeDatastream{
  my $self = shift;
  my %args = @_;

  $self->{ERROR_MESSAGE}=undef;
  $self->{TIME}=undef;

  Carp::croak "Parameter 'pid' missing" unless defined($args{pid});
  Carp::croak "Parameter 'dsID' missing" unless defined($args{dsID});
  Carp::croak "Parameter 'timestamp_ref' missing" 
    unless defined($args{timestamp_ref});

  # Set Defaults
  if (!defined($args{startDT})) {
    $args{startDT} = "undef";
  }

  # Set Defaults
  if (!defined($args{endDT})) {
    $args{endDT} = "undef";
  }

  # Set Defaults
  $args{force} = "false";  # To be customizable in future fedora versions

  # Purge datastream from an object 
  my $purge_result;
  eval {
    my $start=time;
    $purge_result = $self->{apim}->purgeDatastream(
        $args{pid},
        $args{dsID},
        $args{startDT},
        $args{endDT},
        $args{logMessage},
        SOAP::Data->value($args{force})->type('xsd:boolean'),
      );
    my $elapse_time = time - $start;
    $self->{TIME} = $elapse_time;
    $self->{STAT}->{'purgeDatastream'}{count}++;
    $self->{STAT}->{'purgeDatastream'}{time} += $elapse_time;
  };
  if ($@) {
    $self->{ERROR_MESSAGE}=$self->_handle_exceptions($@);
    return 1; 
  }

  # Handle error from Fedora target
  if ($purge_result->fault) {
    $self->{ERROR_MESSAGE}=
           $purge_result->faultcode."; ".
           $purge_result->faultstring."; ".
           $purge_result->faultdetail;
    return 2;
  }

  # Handle success
  ${$args{timestamp_ref}} = $purge_result->result();
  return 0;

}


# compareDatastreamChecksum
#
# Args in parameter hash:
#   pid:          PID of object to check datastream checksum
#   dsID:         ID of the datastream
#   versionDate:  A dateTime indicating the version of the datastream to 
#                 verify. If null, Fedora will use the most recent version.
#
# Return:
#
#   0 = success
#   1 = Error
#   2 = Error on remote server
#
sub compareDatastreamChecksum {
  my $self = shift;
  my %args = @_;

  $self->{ERROR_MESSAGE}=undef;
  $self->{TIME}=undef;

  Carp::croak "Parameter 'pid' missing" 
    unless defined($args{pid});
  Carp::croak "Parameter 'dsID' missing" 
    unless defined($args{dsID});
##  Carp::croak "Parameter 'versionDate' missing" 
##    unless defined($args{versionDate});

  # Set Defaults
  if (!defined($args{versionDate})) {
    $args{versionDate} = "undef";
  }

  my $compareChecksum_result;
  eval {
    my $start=time;
    $compareChecksum_result = $self->{apim}->compareDatastreamChecksum (
                                $args{pid},
                                $args{dsID},
                                $args{versionDate});
    my $elapse_time = time - $start;
    $self->{TIME} = $elapse_time;
    $self->{STAT}->{'getNextPID'}{count}++;
    $self->{STAT}->{'getNextPID'}{time} += $elapse_time;
  };
  if ($@) {
    $self->{ERROR_MESSAGE}=$self->_handle_exceptions($@);
    return 1; 
  }

  # Handle error from Fedora target
  if ($compareChecksum_result->fault) {
    $self->{ERROR_MESSAGE}=
      $compareChecksum_result->faultcode."; ".
	$compareChecksum_result->faultstring."; ".
	  $compareChecksum_result->faultdetail;
    return 2;
  }

  my $result_ref = $compareChecksum_result->result();

  ${$args{checksum_result}} = $result_ref;

  if ($result_ref =~ /Checksum validation error/) {
    return 3;
  }
  return 0;
}

# addRelationship
#
# Args in parameter hash:
#   pid:           PID of the object
#   relationship: The predicate
#   object:        The object.
#   isLiteral:     A boolean value indicating whether the object is a literal.
#   datatype:      The datatype of the literal. Optional.
#
# Return:
#
#   0 = success
#   1 = Error
#   2 = Error on remote server
#
sub addRelationship {
  my $self = shift;
  my %args = @_;

  $self->{ERROR_MESSAGE}=undef;  $self->{TIME}=undef;

  Carp::croak "Parameter 'pid' missing" unless defined($args{pid});
  Carp::croak "Parameter 'relationship' missing" unless defined($args{relationship});
  Carp::croak "Parameter 'object' missing" unless defined($args{object});

  if (! defined($args{isLiteral})) {
    $args{isLiteral} = 'false';
  }

  if (! defined($args{datatype})) {
    $args{datatype} = "";
  }

  my $arel_result;
  eval {
    my $start=time;
    $arel_result = $self->{apim}->addRelationship(
      $args{pid},
      $args{relationship},
      $args{object},
      SOAP::Data->value($args{isLiteral})->type('xsd:boolean'),
      $args{datatype},
    );
    my $elapse_time = time - $start;
    $self->{TIME} = $elapse_time;
    $self->{STAT}->{'addRelation'}{count}++;
    $self->{STAT}->{'addRelation'}{time} += $elapse_time;
  };
  if ($@) {
    $self->{ERROR_MESSAGE}=$self->_handle_exceptions($@);
    return 1; 
  }

 # Handle error from Fedora target
  if ($arel_result->fault) {
    $self->{ERROR_MESSAGE}=
           $arel_result->faultcode."; ".
           $arel_result->faultstring."; ".
           $arel_result->faultdetail;
    return 2;
  }

  # Handle success
  ${$args{result}} = $arel_result->result();

  if ( $arel_result->result() eq 'false') {
    # Assume that the relation exists already. If we are supporting
    # reloads then we must deal with this error even if it indicates 
    # that the relation already exists.
    if ($self->{reload}) {
      # Accept that the relation was loaded previously - but we don't
      # know this for certain since the context of addRelationship
      # returning 'false' is not defined.
      my $result;
      if ($self->purgeRelationship( pid => $args{pid},
				    relationship => $args{relationship},
				    object => $args{object},
				    isLiteral => $args{isLiteral},
				    datatype => $args{datatype},
				    result => \$result,
				  ) == 0) {
      } else {
	my $msg = $self->{ERROR_MESSAGE} || "";
	$self->{ERROR_MESSAGE}="purgeRelationship failed:" . $msg;
	return 2;
      }
      # Now add the relationship
      my $arel_result;
      eval {
	my $start=time;
	$arel_result = $self->{apim}->addRelationship
	  (
	   $args{pid},
	   $args{relationship},
	   $args{object},
	   SOAP::Data->value($args{isLiteral})->type('xsd:boolean'),
	   $args{datatype},
	  );
	my $elapse_time = time - $start;
	$self->{TIME} = $elapse_time;
	$self->{STAT}->{'addRelation'}{count}++;
	$self->{STAT}->{'addRelation'}{time} += $elapse_time;
      };
      if ($@) {
	$self->{ERROR_MESSAGE}=$self->_handle_exceptions($@);
	return 1; 
      }
      if ($arel_result->result() eq 'false') {
	return 2;
      } else {
	return 0;
      }
    } else { # AddRelationship failed and Reload flag not set
      my $msg = $self->{ERROR_MESSAGE} || "";

      $self->{ERROR_MESSAGE}="addRelationship failed (may exist already):"
	. $msg;
      return 2;
    }
    return 2;
  }

  return 0;
}

# getRelationships [DOES NOT WORK - FEDORA SERVER RETURNS INTERNAL ERROR]
#
# Args in parameter hash:
#   pid:           PID of the object
#   relationship: The predicate
#
# Return:
#
#   0 = success
#   1 = Error
#   2 = Error on remote server
#
sub getRelationships {
  my $self = shift;
  my %args = @_;

  $self->{ERROR_MESSAGE}=undef;
  $self->{TIME}=undef;

  Carp::croak "Parameter 'pid' missing" unless defined($args{pid});
  Carp::croak "Parameter 'relationship' missing" unless defined($args{relationship});

  my $grel_result;
  eval {
    my $start=time;
    $grel_result = $self->{apim}->getRelationships 
      (
       $args{pid},
       "$args{relationship}",
    );
    my $elapse_time = time - $start;
    $self->{TIME} = $elapse_time;
    $self->{STAT}->{'addRelation'}{count}++;
    $self->{STAT}->{'addRelation'}{time} += $elapse_time;
  };
  if ($@) {
    $self->{ERROR_MESSAGE}=$self->_handle_exceptions($@);
    return 1; 
  }

 # Handle error from Fedora target
  if ($grel_result->fault) {
    $self->{ERROR_MESSAGE}=
           $grel_result->faultcode."; ".
           $grel_result->faultstring."; ".
           $grel_result->faultdetail;
    return 2;
  }

  # Handle success
  ${$args{result_ref}} = $grel_result->result();

  return 0;
}

# purgeRelationship
#
# Args in parameter hash:
#   pid:           PID of the object
#   relationship:  The predicate, null matches any predicate.
#   object:        The object, null matches any object.
#   isLiteral:     A boolean value indicating whether the object is a literal.
#   datatype:      The datatype of the literal. Optional.
#
# Return:
#
#   0 = success
#   1 = Error
#   2 = Error on remote server
#
sub purgeRelationship {
  my $self = shift;
  my %args = @_;

  $self->{ERROR_MESSAGE}=undef;
  $self->{TIME}=undef;

  Carp::croak "Parameter 'pid' missing" unless defined($args{pid});
  Carp::croak "Parameter 'relationship' missing" unless defined($args{relationship});
  Carp::croak "Parameter 'object' missing" unless defined($args{object});

  if (! defined($args{isLiteral})) {
    $args{isLiteral} = 'false';
  }
  if (! defined($args{datatype})) {
    $args{datatype} = "";
  }



  my $prel_result;
  eval {
    my $start=time;
    $prel_result = $self->{apim}->purgeRelationship (
      $args{pid},
      $args{relationship},
      $args{object},
      SOAP::Data->value($args{isLiteral})->type('xsd:boolean'),
      $args{datatype},
    );
    my $elapse_time = time - $start;
    $self->{TIME} = $elapse_time;
    $self->{STAT}->{'addRelation'}{count}++;
    $self->{STAT}->{'addRelation'}{time} += $elapse_time;
  };
  if ($@) {
    $self->{ERROR_MESSAGE}=$self->_handle_exceptions($@);
    return 1; 
  }

 # Handle error from Fedora target
  if ($prel_result->fault) {
    $self->{ERROR_MESSAGE}=
           $prel_result->faultcode."; ".
           $prel_result->faultstring."; ".
           $prel_result->faultdetail;
    return 2;
  }

  # Handle success
  ${$args{result}} = $prel_result->result();
  return 0;
}


# ========================================================================= # 
# 
#  Private Methods
# ========================================================================= # 
# 
#  Private Methods
#
# ========================================================================= # 



# Map die exceptions from SOAP::Lite calls to Fedora::APIM error messages
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
           "/fedora/services/management";
}

# ========================================================================= # 
#
# Store ingest FOXML template in case user doesn't have it.
#
# ========================================================================= # 

$default_foxml = <<'DEFAULT_FOXML';
<?xml version="1.0" encoding="UTF-8"?>
<foxml:digitalObject VERSION="1.1" PID="<TMPL_VAR NAME="pid_in">" xmlns:foxml="info:fedora/fedora-system:def/foxml#" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="info:fedora/fedora-system:def/foxml# http://www.fedora.info/definitions/1/0/foxml1-1.xsd">
  <foxml:objectProperties>
  <foxml:property NAME="info:fedora/fedora-system:def/model#state" VALUE="Active"/>
  <foxml:property NAME="info:fedora/fedora-system:def/model#label" VALUE="<TMPL_VAR NAME="title_in">"/>
  <foxml:property NAME="info:fedora/fedora-system:def/model#ownerId" VALUE="fedoraAdmin"/>
  <!-- Note: The value for createdDate is assigned dynamically by the Fedora server at ingest time if the createdDate property is not      -->
  <!-- present in the object being ingested. Therefore, it is recommended that this property be omitted from the object template so this   -->
  <!-- date will be assigned dynamically by the Fedora server. If included in the template file, this value will be carried through to the        -->
  <!-- built objects and will result in the specified static date being used at ingest time by the Fedora server rather than dynamically         -->
  <!-- assigning createdDate at ingest time. The same is true for object components like datastreams and disseminators. The                -->
  <!-- datastreamVersion and disseminatorVersion elements contain an optional CREATED attribute that defines a createdDate for     -->
  <!-- these components. If the CREATED attribute is omitted, a createdDate is assinged dynamically at ingest time. If included in the   -->
  <!-- template object, the specified values will be carried through to all built objects resulting in the specified static dates being used     -->
  <!-- rather than than the Fedora server assigning component createdDates. -->
  <!--                                                                      -->
  <!-- Uncomment the next line only if you want all objects built with this template to retain the specified creation date after ingest.            -->
  <!-- <foxml:property NAME="info:fedora/fedora-system:def/model#createdDate" VALUE="2005-03-15T12:57:07.241Z"/>                   -->
  <foxml:property NAME="info:fedora/fedora-system:def/view#lastModifiedDate" VALUE="2005-03-15T12:57:07.702Z"/>
  </foxml:objectProperties>
  <foxml:datastream CONTROL_GROUP="X" ID="DC" STATE="A" VERSIONABLE="true">
  <!-- Note: The value for createdDate is assigned dynamically by the Fedora server at ingest time if the CREATED attribute is not        -->
  <!-- present on the component in the object being ingested. Therefore, it is recommended that this attribute be omitted from the          -->
  <!-- object template so this date will be assigned dynamically by the Fedora server. If included in the template file, this value will be    -->
  <!-- carried through to the built objects and will result in the specified static date being used at ingest time by the Fedora server          -->
  <!-- rather than dynamically assigning createdDate at ingest time. -->
  <!--                                                                    -->
  <!-- Uncomment the the following line if you want the DC datastream for all abjects built with this template to retain the specified         -->
  <!-- createdDate after ingest.                                                                                                                                                                                -->
  <!-- <foxml:datastreamVersion CREATED="2005-03-15T12:57:07.241Z" ID="DC.0" LABEL="template: Dublin Core Record for this object" MIMETYPE="text/xml"> -->
  <foxml:datastreamVersion FORMAT_URI="http://www.openarchives.org/OAI/2.0/oai_dc/" ID="DC.0" LABEL="template: Dublin Core Record for this object" MIMETYPE="text/xml">
  <foxml:xmlContent>
  <oai_dc:dc xmlns:oai_dc="http://www.openarchives.org/OAI/2.0/oai_dc/" xmlns:dc="http://purl.org/dc/elements/1.1/">
  <dc:title><TMPL_VAR NAME="title_in"></dc:title>
  <dc:identifier><TMPL_VAR NAME="pid_in"></dc:identifier>
  <dc:relation>dpubs</dc:relation>
  <dc:relation><TMPL_VAR NAME="collection_in"></dc:relation>
  </oai_dc:dc>
  </foxml:xmlContent>
  </foxml:datastreamVersion>
  </foxml:datastream>
  <!--
  <foxml:datastream CONTROL_GROUP="X" ID="DESC" STATE="A" VERSIONABLE="true">
  <foxml:datastreamVersion ID="DESC.0" LABEL="template: UVA descriptive metadata" MIMETYPE="text/xml">
  <foxml:xmlContent>
  <dummy/>
  </foxml:xmlContent>
  </foxml:datastreamVersion>
  </foxml:datastream>
  -->
  </foxml:digitalObject>

DEFAULT_FOXML

1;

__END__


# ========================================================================= # 
# 
#  Documentation (pod)
#
# ========================================================================= # 


=head1 NAME

FedoraCommons::APIM - Interface for interaction with Fedoras Management API

=head1 VERSION

This documentation describes version 0.1.

=head1 SYNOPSIS

  use Fedora::APIM;

  my $apim=new Fedora::APIM(
         host    => "my.fedora.host",
         port    => "8080",
         usr     => "fedoraAdmin",
         pwd     => "foobarbaz",
         timeout => 100); 

  if ($apim->ingest(XML_ref=>\$foxml, logMessage=>"Ingesting", \$pid)) {
    print "Ingested FOXML Record:\n".$foxml."\n\nFedora PID: $pid";
  } else {
    print "Error ingesting: ".$apim->error();
  }

=head1 DESCRIPTION

Fedora::APIM provides an interface to the SOAP::Lite based management API
(API-M) of the Fedora repository architecture (L<http://www.fedora.info/>).

It exposes a subset of the API-M operations and handles errors and
elapsed-time profiling.

=head1 OPTIONS

Fedora::APIM may be invoked with an option

=over 5

=item version

Fedora::APIM supports multiple versions of the Fedora API-M.  Specifying the
version of the Fedora API-M is done at invocation time by

  use FedoraCommons::APIM version=>3.2;

Supported versions of the Fedora API-M: 3.2.

=back

=head1 METHODS

Parameters for each method is passed as an anonymous hash.  Below is a
description of required and optional hash keys for each method. Methods will
croak if mandatory keys are missing.  Most keys corresponds to paramter names
to the equivalent API-M operation described at
L<http://www.fedora.info/definitions/1/0/api/Fedora-API-M.html>.

=head2 Constructor

=over 3 

=item new()

Constructor.  Called as 

    my $apim = new Fedora::APIM(
      protocol => "https",        # Enables SSL protocol
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

=head2 Methods representing API-M operations

Each method returns 0 upon success and 1 upon failure.  Method error() may be
used to get back a textual description of the error of the most recent method
call.

=over 3

=item ingest()

Ingest a FOXML record into Fedora and return the PID.  Called as

    my $pid;
    $apim->ingest(
      XML_ref => \$foxml_record,  # Required. Reference to scalar 
                                  #   holding FOXML record
      logMessage => $msg,         # Optional.  Log message
      pid_ref => \$pid            # Required. Reference to scalar
                                  #   to hold pid returned from
                                  #   fedora 
    );

The createObject() method encapsulates the ingest and addDatastream
methods into a single call. See createObject().

=item purgeObject()

Purge a Fedora object and return the timestamp of that operation.  Called as 

    my $ts;
    $apim->purgeObject(
      pid => $pid,                # Required. Scalar holding
                                  #   PID of object to be purged
      logMessage => $msg,         # Optional.  Log message
      timestamp_ref => \$ts       # Required. Reference to scalar
                                  #   to hold timestamp returned
                                  #   from fedora 
    );

=item uploadFile()

Uploading a file via multipart HTTP POST to /fedora/management/upload.
This allows adding a datastream from a local file (url not required).

This is a method from the API-M Lite api. Allows you to upload a local
file and avoid having to specify a URL when adding a datastream. This 
method is used by uploadNewDatastream() which combines uploadFile()
and addDatastream() into one method.

    $apim->uploadFile(filename => $filename,
                      file_ref => \$file_ref)

  then supply $file_ref to addDatastream() call:

    my $url = $file_ref;
    # Remove trailing spaces
    $url =~ s/\s+$//;

    $apim->addDatastream( 
      pid => $pid,
      dsID => $dsID,
      altIDs => $altids,
      dsLabel => $label,
      versionable => $v,
      MIMEType => $mime,
      formatURI => $uri,
      dsLocation => $url, # file_ref
      controlGroup => $cg,
      dsState => $state,
      logMessage => $msg,
      dsid_ref => \$dsid )

=item addDatastream()

Add a datastream to a Fedora object and return the datastream id.  Called as 

    my $dsid;
    $apim->addDatastream(
      pid => $pid,                # Required. PID of object 
      dsID => $dsID,              # Required. ID of the datastream 
      altIDs => $altids,          # Optional.  Alternative id's
      dsLabel => $label,          # Required. Datastream label 
      versionable => $v,          # Required. "false" or "true"
      MIMEType =>, $mime,         # Required. Mime type of datastream
      formatURI => $uri,          # Required. 
      dsLocation => $url,         # Required. URL from where 
                                  #   fedora can fetch datastream 
      controlGroup => $cg,        # Required. Must have value 
                                  #   "X", "M", "R" or "E"
      dsState => $state,          # Required. Must have value
                                  #   "A", "I" or "D"
      checksumType => $checksumType, # Optional. Checksum algorithm 
      checksum => $checksum 	  # Optional. Checksum value
      logMessage => $msg,         # Optional.  Log message
      dsid_ref => \$dsid          # Required. Reference to scalar
                                  #   to hold datastream ID returned
                                  #   from fedora 
    );

=item compareDatastreamChecksum()

Verifies that the Datastream content has not changed since the checksum was initially computed.

    $apim->compareDatastreamChecksum (
      pid => $pid,                        # Required.  PID of object
      dsID => $dsID,                      # Required. datastream ID
      versionDate => $versionDate,        # Optional. 0 or 1
      checksum_result =>\$checksum_result,# Required. Returns checksum
                                          # or error message.
    );


=item getDatastream()

Get a datastream from a Fedora object and returns the datastream.  Called as 

    my $ds_ref;
    $apim->getDatastream(
      pid => $pid,                # Required. Scalar holding
                                  #   PID of object to be purged
      dsID => $dsID,              # Required. 
      ds_ref => \$ds_ref          # Required. Reference to scalar
                                  #   to hold datastream returned
                                  #   from fedora 
    );

=item modifyDatastreamByReference()

Modifies an existing datastream in an object, by reference and returns the timestamp.  Called as 

    my $ts;
    $apim->modifyDatastreamByReference(
      pid => $pid,                # Required. PID of object 
      dsID => $dsID,              # Required. ID of the datastream 
      altIDs => $altids,             # Optional.  Alternative id's
      dsLabel => $label,          # Required. Datastream label 
      MIMEType =>, $mime,         # Required. Mime type of datastream
      formatURI => $uri,          # Required. 
      dsLocation => $url,         # Required. URL from where 
                                  #   fedora can fetch datastream 
      checksumType => $checksumType, # Optional.Checksum algorithm 
      checksum => $checksum 	  # Optional. Checksum value 
      logMessage => $msg,         # Optional.  Log message
      force => $force,            # Required. "false" or "true"
      timestamp_ref => \$ts       # Required. Reference to scalar
                                  #   to hold timestamp returned
                                  #   from fedora 
    );

=item setDatastreamVersionable()

Selectively turn versioning on or off for selected datastream. When versioning is disabled, subsequent modifications to the datastream replace the current datastream contents and no versioning history is preserved. To put it another way: No new datastream versions will be made, but all the existing versions will be retained. All changes to the datastream will be to the current version.

    $apim->setDatastreamVersionable (
      pid => $pid,                # Required.  PID of object
      dsID => $dsID,              # Required. ID of the datastream 
      versionable => $versionable,# Required. versionable setting 0 or 1
      timestamp_ref => \$ts,      # Required. Reference to scalar
                                  #   to hold timestamp returned
                                  #   from fedora 
    );

=item purgeDatastream()

Purge a datastream from a Fedora object and return the timestamp of that operation.  Called as 

    my $ts;
    $apim->purgeDatastream(
      pid => $pid,                # Required.  PID of object to be purged
      dsID => $dsID,              # Required. ID of the datastream 
      startDT => $startDT,        # Optional. 
      endDT => $endDT,            # Optional. 
      logMessage => $msg,         # Optional.  Log message
      force => $force,            # Required. "false" or "true"
      timestamp_ref => \$ts       # Required. Reference to scalar
                                  #   to hold timestamp returned
                                  #   from fedora 
    );

=item addRelationship()

Creates a new relationship in the object.

  $apim->addRelationship( 
    pid => $pid,                  # Required. PID of object
    relationship => $relation,    # Required. Relation to add.
    object => $object,            # Required. Target object.
    isLiteral => 'false',         # Optional. Is object a literal? 
                                  # Default: 'false'
    datatype => "",               # Optional. Datatype of literal.
                                  # Default: ''
    );

=item purgeRelationship()

Delete the specified relationship.

    $apim->purgeRelationship( 
      pid => $pid,                # Required. PID of object
      relationship => $relation,  # Required. Relation to delete.
                                  # Note: null matches any relationship
      object => "$object",        # Required. Target object.
                                  # Note: null matches any object.
      isLiteral => 'false',       # Optional. Is object a literal?
      datatype => "",             # Optional. Datatype of literal.
      result => \$result,         # Required. Result of purge.
      );

=item getNextPID()

Get next PID(s) from Fedora in a given PID namespace. Called as 

    my @pids;
    $apim->getNextPID (
      numPids => $n,              # Required.  Number of pids.
      pidNamespace => $ns,        # Required. Namespace for pids.
      pidlist_ref  => \@pids      # Required. Reference to list
                                  #   into which resulting pids
                                  #   are put
    );

=back

=head2 Methods Currently Not Implemented

=over 3


=item getDatastreamHistory()

Gets all versions of a datastream, sorted from most to least recent.

=item getDatastreams()

Gets all datastreams in the object.

=item modifyDatastreamByValue()

Modifies an existing Datastream in an object, by value.

=item setDatastreamState()

Sets the state of a Datastream to the specified state value.

=item getRelationships()

Get the relationships asserted in the object's RELS-EXT Datastream 
that match the given criteria.

=item modifyObject()

Modify an object.

=item export()

Exports the entire digital object in the specified XML format, 
and encoded appropriately for the specified export context.

=item getObjectXML()

Gets the serialization of the digital object to XML appropriate for 
persistent storage in the repository, ensuring that any URLs that 
are relative to the local repository are stored with the Fedora 
local URL syntax.

=back

=head2 Additional NON-APIM Methods 

These methods often consolidate several APIM methods into a single
method. The idea is to encapsulate functionality where several APIM methods
are normally used together in client code into a single method.

=over 3

=item createObject()

This method takes care of creating the FOXML and the new object [normally two APIM steps].

Creating an object requires FOXML for the object you are creating.
You must install the default ingest template (available) in the 
default file path location [/ingesttemplate.xml] or you must provide 
a path to the method as an argument.

The params are values in the FOXML template that will be substitutes
before being ingested. You may create your own FOXML template and supply
the appropriate values to be substituted. The current default template
accepts the values: pid_in, title_in, owner_in, and collection_in.

Support has been added to set the POLICY datastream for an object within
the createObject() method. This eliminates the need to execute addDatastream()
to add a POLICY after you create an object with createObject(). This operation
will happen automatically when you set the APIM instance policy_url or
policy_path using the
set_policy_url() [external reference] or set_policy_path() [managed]. 
You may also set the policy label with set_policy_label(). When either
policy_url or policy_path are set all objects will have the POLICY 
datastream added to the object. See policy methods below.

Typical createObject() method call:

    $apim->createObject (
      XML_file=> "./ingesttemplate.xml", 
      params => { pid_in => $idno,
                  title_in => "$title",
                  owner_in => "$owner",
                  collection_in => "$collection"},
      pid_ref =>\$pid 
    );

To use default ingest template:

    $apim->createObject (
      params => { pid_in => $idno,
                  title_in => "$title",
                  collection_in => "$collection"},
      pid_ref =>\$pid 

To specify FOXML template that's already stored in memory:

    $apim->createObject (
      XML_ref => "$foxml",
      params => { pid_in => $idno,
                  title_in => "$title",
                  collection_in => "$collection"},
      pid_ref =>\$pid 

=item uploadNewDatastream()
This method combines the upload operation and the add datastream operation
into a single call and sets reasonable defaults (which the caller may
override) for several parameters.

Full method call looks like:

  $apim->uploadNewDatastream( 
    pid => $pid,                  # Required. PID of object
    dsID => $dsID,                # Required. ID of the datastream 
    altIDs => $altids,            # Optional. Alternative id's
    dsLabel => $dsLabel,          # Optional. Datastream label.
                                  # Default: null string
    versionable => $versionable,  # Optional. Is datastream versionable?
                                  # Default: true
    filename => $filename,        # Required. Datastream file to upload.
    MIMEType => $mime,            # Required. Mime type of datastream
    controlGroup => $cgroup,      # Optional. Control group.
                                  # Default: 'M', for managed content.
    dsState => $dsState,          # Optional. Datastream state.
                                  # Default: 'A', for active.

    checksumType => $checksumType,# Optional. Checksum type.
                                  # Default: SHA-1
    checksum => $checksum,        # Optional. Actual checksum.
                                  # Default: null, calculated 
                                  # automatically by repository
    logMessage => $logMessage,    # Optional. Log message.
                                  # Default: "Add datastream."
    dsid_ref => \$dsid,           # Required. Reference to scalar
                                  #   to hold datastream ID returned
                                  #   from fedora 
    timestamp_ref => \$ts,        # Required. Reference to scalar
                                  #   to hold timestamp returned
                                  #   from fedora 
    );

Typical call looks like:

    $apim->uploadNewDatastream( pid => $pid,
                                dsID => $dsID,
                                filename => $filename,
                                MIMEType => $mime,
                                dsid_ref => \$dsid,
                                timestamp_ref => \$ts,
                                );


=back

=head2 policy methods

These methods directly impact the createObject() method. These methods
are intended for cases where
you would like to store a common XACML policy for the objects created
by your script. You set these policy_*() methods once instead of calling
createObject() followed by addDatastream() to add the POLICY datastream.
Once set the createObject() method adds the POLICY datastream you specified.

Set either set_policy_url() or set_policy_path() not both. Setting one of
these will remove the other setting to avoid potential conflicts.

=over 3

=item set_policy_url()

Set the policy URL for the APIM instance. This will create an external
reference POLICY datastream.

=item get_policy_url()

Returned the policy URL.

=item set_policy_path()

Set path to an XACML policy file to be loaded into each new object.

=item get_policy_path()

Return the policy path.

=item set_policy_label()

Set the POLICY datastream label.

=item get_policy_label()

Return the POLICY datastream label.

=back


=head2 Other methods

=over 3

=item error()

Return error of most recent API-M method.

=item get_time()

Return the elapsed time of the most recent SOAP::Lite call to the fedora
API-M.

=item get_stat()

Return reference to hash describing total elapsed time and number of calls -
since instantiation or since most recent call to start_stat() - of all
SOAP::Lite calls to the fedora API-M.  

=item start_stat()

Start over the collection of elapsed times and number of calls statistics.

=item get_default_foxml()

The APIM module stores a default FOXML internally. This is used when the client
does not provide the createObject with raw FOXML or a file path to custom 
FOXML.

The get_default_foxml() method will return the internal FOXML template
so that you may customize it for your purposes.

If you save the FOXML template in the location './ingesttemplate.xml' it
will be detected automatically when you call createObject() without specifying
a FOXML argument.

=back

=head1 DEPENDENCIES

MIME::Base64, SOAP::Lite, Time::HiRes, Carp

=head1 KNOWN BUGS, LIMITATIONS AND ISSUES
 
In its current implementation, Fedora::APIM represents a wrapping of the SOAP
based interface in which most of the parameters for the SOAP operations are
required parameters to the corresponding wrapping method, even though
parameters may be optional in the SOAP interface.

In future versions, parameters should become optional in the methods if
they are optional in the corresponding SOAP operation; or suitable defaults
may be used with SOAP for some of the parameters, should they be missing as
parameters to the wrapping method.

=head1 SEE ALSO

Fedora documentation: L<http://fedora-commons.org/confluence/display/FCR30/Fedora+Repository+3.2.1+Documentation>.

Fedora API-M documentation:
L<http://www.fedora-commons.org/confluence/display/FCR30/API-M>.

=head1 AUTHOR

The Fedora::APIM module is based on a module written by Christian 
Tønsberg, E<lt>ct@dtv.dkE<gt>, in 2006. Christian no longer supports
or distributes the module he developed.

Maryam Kutchemeshgi (Penn State University) put together the initial
version of Fedora::APIM. This module was originally developed (circa 2007) 
in a collaboration between Cornell University and Penn State University 
as part of a project to develop an interface to support the use of the 
Fedora Repository as the underlying repository for DPubS [Digital 
Publishing System] L<http://dpubs.org>. Maryam Kutchemeshgi 
E<lt>mxk128@psu.eduE<gt> is no longer involved with maintaining this module.

David L. Fielding (E<lt>dlf2@cornell.edu<gt>) is responsible for recent
enhancements along with packaging up the module and placing it on CPAN. 
To avoid confusion between Fedora (the Linux operating system) and
Fedora (the repository) I changed the name of the module package from
Fedora to FedoraCommons (the qualified name of the Fedora repository).
I have modified the modules to work with the Fedora Commons 3.2 APIs. 

This module implements a subset of the requests supported by the API-M 
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

Note: The APIM module supports methods that modify the repository. The
'make test' operation below will create objects in the repository
in order to test methods. The last step will be to remove the
test objects. Be ware that this test will attempt to modify the
target repository.

=item perl Makefile.PL

=item make

=item make test

=item make install

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008, 2009 by Cornell University, L<http://www.cornell.edu/> 
Copyright (C) 2006 by PSU, L<http://www.psu.edu/>
Copyright (C) 2006 by DTV, L<http://www.dtv.dk/>

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
