# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 11;
##use Test::More 'no_plan';

BEGIN { use_ok( 'FedoraCommons::APIA' ); }

my $host = $ENV{FEDORA_HOST} || "";
my $port = $ENV{FEDORA_PORT} || "";
my $user = $ENV{FEDORA_USER} || "";
my $pwd  = $ENV{FEDORA_PWD} || "";

 SKIP: {
     skip "No Fedora server environment settings found (FEDORA_HOST,"
	 . "FEDORA_PORT,FEDORA_USER,FEDORA_PWD).", 
	 10 if (! $host || ! $port || ! $user || ! $pwd);

     #1 Check Fedora server arguments
     ok ( $host && $port && $user && $pwd, 
	  'Fedora server Environment variables not set');

     if (! $host || ! $port || ! $user || ! $pwd) {
	 my $msg = "Fedora server environment variables not set properly.";
	 diag ("$msg");
	 BAIL_OUT ("$msg");
     } 

     my $timeout = 100;

     # Instantiate top level object
     my $object = FedoraCommons::APIA->new (
					    host    => "$host",
					    port    => "$port",
					    usr     => "$user",
					    pwd     => "$pwd",
					    timeout => $timeout,
					    );
     my $error = $object->error() || "";
     my $ref   = ref $object || "";

     #2 Check APIA object
     isa_ok ($object, "FedoraCommons::APIA");

     if (ref ($object) ne 'FedoraCommons::APIA') {
	 my $msg = "Unable to instantiate APIA object properly. Error: $error";
	 diag ("$msg");
	 BAIL_OUT ("$msg");
     } else {
	 my $msg = "Instantiated APIA object OK";
	 diag ("$msg");
     }

     # Try wildcard search

     my $maxRes = 500;
     my $fldsrchProp = 'title';
     my $fldsrchOp = 'has';
     my $fldsrchVal = '*';
     my $searchRes = "";



     my $result = $object->findObjects(maxResults => $maxRes, 
				       fldsrchProperty => $fldsrchProp,
				       fldsrchOperator => $fldsrchOp,
				       fldsrchValue => $fldsrchVal,
				       searchRes_ref => \$searchRes);
     
     #3
     ok ($result == 0, "Fedora findObjects search request FAILED: $result");

     if ($result == 1) {
	 my $error = $object->error();
	 my $msg = "Error findObjects(): $error";
	 diag ( "$msg" );
	 BAIL_OUT ( "$msg" );
     } else {
	 my $msg = "Test findObjects() OK";
	 diag ("$msg");
     }

     my @pidlist = ();
     my ($count, $pid);

     #4 & #5
   SKIP: {
       skip "Search Failed", 1 if $result != 0;
       #4
       ok ( $searchRes->{'resultList'} ne '', 
	    'Fedora findObjects failled to find objects');
       if ($searchRes->{'resultList'} eq '') {
	   my $msg = "No hits returned from search.";
	   diag ("$msg");
	   BAIL_OUT ("$msg");
       } else {
	   ##   my @pidlist = ();
	   my $test_resume = 0;

	   my $sessionToken;
	   while (! $test_resume && 
		  ($sessionToken = $searchRes->{'listSession'}{'token'})) {
	       print "Resume Token: $sessionToken\n";
	       $test_resume = 1;
	       for my $entry_hashref 
		   (@{$searchRes->{'resultList'}{'objectFields'}}) {
		       print "PID: $entry_hashref->{'pid'}\n";
		       push(@pidlist, $entry_hashref->{'pid'});
		   }
	       my $result = $object->resumeFindObjects
		   (sessionToken => $sessionToken,
		    searchRes_ref => \$searchRes);
	       my $error = $object->error() || "";
	       # 5
	       ok ($result == 0,
		   "ERROR: Error Fedora resumefindObjects: " 
		   . $error . "\n");
	   }
       }

       for my $entry_hashref (@{$searchRes->{'resultList'}{'objectFields'}}) {
	   print "PID: $entry_hashref->{'pid'}\n";
	   push(@pidlist,$entry_hashref->{'pid'});
       }

       $count = $#pidlist + 1;

       # 6
       ok ($count > 0, "Search returned zero hits.");
       if ($count <= 0) {
	   my $msg = "Error: No hits returned from search. Exiting.";
	   diag ("$msg");
	   BAIL_OUT ("$msg");
       }  else {
	   $pid = $pidlist[$count - 1];
	   diag("Test using object identifier: $pid");
       }

   } # End processing results




     # List datastreams
     my $datastreams;
     my $status = $object->listDatastreams(pid=>$pid,
					   datastream_ref =>\$datastreams);

     # 6: List datastreams
     ok ($status == 0, "ListDatastreams() failed to return anything.");
     if ($status != 0) {
	 my $msg = "Error: No datastreams returned for pid $pid. Exiting.";
	 diag ("$msg");
	 BAIL_OUT ("$msg");
     } else {
	 my $msg = "ListDatastreams() OK";
	 diag ("$msg");
     }

     my @dslist = ();

     foreach my $ds ($datastreams->valueof('//datastreamDef')) {
	 push(@dslist,$ds->{ID});
     }

     my $dcount;

     $dcount = $#dslist + 1;

     #7
     ok ($dcount > 0, "Collect Datastreams() failed to return anything.");
     if ($dcount <= 0) {
	 my $msg = "Error: No datastreams returned for pid $pid. Exiting.";
	 diag ("$msg");
	 BAIL_OUT ("$msg");
     }

     # Get object profile
     my $info;
     $status = $object->getObjectProfile (pid => $pid, 
					  profile_ref => \$info,
					  );
     $error = $object->error() || "";
     #8 
     ok ($result == 0, "getObjectProfile() FAILED: $error");
     if ($result == 0) {
	 my $msg = "getObjectProfile() OK.";
	 diag ("$msg");
     }

     #6 # Get a datastream
     my $stream;
     $dsID = "RELS-EXT";
     $status = $object->getDatastreamDissemination(pid => $pid,
						   dsID => $dsID,
						   stream_ref => \$stream);

     ok ($status == 0, 
	 "getDatastreamsDissemination() failed to return anything.");
     if ($status != 0) {
	 my $msg = "Error: getDatastreamDissemination failed "
	     . "for pid $pid.Exiting.";
	 diag ("$msg");
	 BAIL_OUT ("$msg");
     } else {
	 my $msg = "getDatastreamsDissemination() OK.";
	 diag ("$msg");
     }
 } # Skip

1;




