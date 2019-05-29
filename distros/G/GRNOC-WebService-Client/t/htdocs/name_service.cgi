#!/usr/bin/perl
#--------------------------------------------------------------------
#----- NameService.cgi 
#-----
#----- Copyright(C) 2007 The Trustees of Indiana University
#--------------------------------------------------------------------
#----- $LastChangedBy: ebalas@GRNOC.IU.EDU $
#----- $LastChangedRevision: 970 $
#----- $LastChangedDate: 2007-10-04 13:28:46 -0400 (Thu, 04 Oct 2007) $
#----- $HeadURL: https://dev.grnoc.iu.edu/subversion/grndb/perl/GRNOC/GRNOC_DB/Query.pm $
#----- $Id: Query.pm 970 2007-10-04 17:28:46Z ebalas@GRNOC.IU.EDU $
#-----
#----- Core Data Service's NameService
#-----
#---------------------------------------------------------------------
use strict;
use GRNOC::WebService;
use GRNOC::Config;
use Data::Dumper;
use FindBin;
$ENV{"PATH"} = "";

our %perl_ref;
if(!defined($perl_ref{'config'})){   
    $perl_ref{'config'} = GRNOC::Config->new(config_file => $FindBin::Bin . "/../conf/name_service.xml") or die "unable to open " . $FindBin::Bin . "/t/conf/name_service.xml: $!\n";
}

our $web_svc;

if(!defined($web_svc)){
    
    $web_svc = GRNOC::WebService::Dispatcher->new(allowed_proxy_users => $perl_ref{'config'}->get("/config/remote_user/\@name"));
   
    #----- returns the list of available services----------------------------------
    sub list_services{
	my $m_ref      = shift;
	my $params     = shift;
	my $state_ref  = shift;

	my $cfg = $state_ref->{'config'};

	my %results;

	my $config = $cfg->get("/config/cloud");

	$results{'results'} = $config;
	return \%results;
    }


    my $ls_meth = GRNOC::WebService::Method->new(
						 name		=> 'list_services',
						 description	=> 'provices list of available services',
						 expires		=> "-1d",
						 callback        =>  \&list_services,
						 );
    
    
    $web_svc->register_method($ls_meth);

    #get_clouds
    #returns a list of all clouds listed in this nameservice instance

    sub get_clouds{
	my $method_ref = shift;
	my $p_ref      = shift;
	my $state_ref  = shift;
	
	my %results;
	my $cfg = $state_ref->{'config'};
	my $clouds = $cfg->get("/config/cloud/\@id");
	$results{'results'} = $clouds;
	return \%results;
    }
    
    my $get_clouds = GRNOC::WebService::Method->new(
						    name           => 'get_clouds',
						    description    => 'provide available clouds',
						    expires        => "-1d",
						    callback       =>  \&get_clouds,
						    );
    

    $web_svc->register_method($get_clouds);

    #get_cloud_classes
    #returns a list of all classes inside of a given cloud

    sub get_cloud_classes{
	my $method_ref = shift;
	my $p_ref      = shift;
	my $state_ref  = shift;
	
	my %results;
	my $cfg= $state_ref->{'config'};
	my $apps = $cfg->get("/config/cloud[\@id='" . $p_ref->{'cloud_id'}{'value'} . "']/class/\@id");
	$results{'results'} = $apps;
	return \%results;
    }
    
    my $get_classes = GRNOC::WebService::Method->new(
						     name           => 'get_classes',
						     description    => 'provide available classes',
						     expires        => "-1d",
						     callback       =>  \&get_cloud_classes,
						     );
    
    $get_classes->add_input_parameter( name=> 'cloud_id',
				       description => 'the ID of the cloud',
				       pattern => '^(\S+)$',
				       required => 1
				       );
    
    $web_svc->register_method($get_classes);

    #get_class_version
    #returns a list of all version of a class and cloud
    sub get_class_version{
	my $method_ref = shift;
	my $p_ref      = shift;
	my $state_ref  = shift;

	my %results;
	my $cfg= $state_ref->{'config'};
        my $versions = $cfg->get("/config/cloud[\@id='" . $p_ref->{'cloud_id'}{'value'} . "']/class[\@id='" . $p_ref->{'class_id'}{'value'} . "']/version/\@value");
	$results{'results'} = $versions;
        return \%results;
    }

    my $get_versions = GRNOC::WebService::Method->new(
						      name           => 'get_versions',
						      description    => 'provide available versions of a class',
						      expires        => "-1d",
						      callback       =>  \&get_cloud_classes,
						      );
    
    $get_versions->add_input_parameter( name=> 'cloud_id',
				       description => 'the ID of the cloud',
				       pattern => '^(\S+)$',
				       required => 1
				       );

    $get_versions->add_input_parameter( name=> 'class_id',
                                       description => 'the ID of the class to get versions for',
                                       pattern => '^(\S+)$',
                                       required => 1
                                       );
    
    $web_svc->register_method($get_versions);
    

    #get_locations_by_urn
    #returns a list of all URLs and their weights when given a urn

    sub get_locations_by_urn{
	my $method_ref = shift;
	my $p_ref      = shift;
	my $state_ref  = shift;
	
	my %results;
	my $cfg= $state_ref->{'config'};
	
	my $urn = $p_ref->{'urn'}{'value'};
	#we have defined a URN to look like
	#urn:publicid:IDN+grnoc.iu.edu:<cloud_id>:<class id>:<version>:<service_id>
	my @parts = split(':',$urn);
	
	if($parts[2] ne 'IDN+grnoc.iu.edu'){
	    return {success => 0, results => {error => 'Incorrect URN'}};
	}

	my $locations = $cfg->get("/config/cloud[\@id='" . $parts[3] . "']/class[\@id='" . $parts[4] . "']/version[\@value='" . $parts[5] . "']/service[\@id='" . $parts[6] . "']/location");
	$results{'results'} = $locations;
	return \%results;
    }
    
    my $get_locations_by_urn = GRNOC::WebService::Method->new(
							      name           => 'get_locations_by_urn',
							      description    => 'provide available locations for a URN',
							      expires        => "-1d",
							      callback       =>  \&get_locations_by_urn,
							      );
    
    $get_locations_by_urn->add_input_parameter( name=> 'urn',
						description=> 'the ID of the cloud',
						pattern => '^(.*)$',
						required =>1
						);
    
    $web_svc->register_method($get_locations_by_urn);

}
#---- go into loop
my $status = $web_svc->handle_request(\%perl_ref);
