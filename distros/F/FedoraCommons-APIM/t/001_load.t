# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 17;
use SOAP::Lite;
use MIME::Base64;
use POSIX;

BEGIN { use_ok( 'FedoraCommons::APIM' ); }

my $host = $ENV{FEDORA_HOST} || "";
my $port = $ENV{FEDORA_PORT} || "";
my $user = $ENV{FEDORA_USER} || "";
my $pwd  = $ENV{FEDORA_PWD} || "";

my $skip_deletions = 0;
my @temp_files = ();

SKIP: {
    skip "No Fedora server environment settings found (FEDORA_HOST,"
	. "FEDORA_PORT,FEDORA_USER,FEDORA_PWD).", 
    16 if (! $host || ! $port || ! $user || ! $pwd);

    #1 Check Fedora server arguments
    ok ($host && $port && $user && $pwd, 
	'Fedora server Environment variables not set');

    if (! $host || ! $port || ! $user || ! $pwd) {
	my $msg = "Fedora server environment variables not set properly.";
	diag ("$msg");
	BAIL_OUT ("$msg");
    } 

    diag ("Host: $host Port: $port User: $user Pwd: XXXX\n");

    my $timeout = 100;

    # Create APIM Object
    my $apim = new FedoraCommons::APIM
	( host => $host, 
	  port => $port, 
	  usr  => $user, 
	  pwd  => $pwd, 
	  timeout => $timeout, 
	  replace => 1, 
	  reload => 0,
	  debug => 1,
	  );

    my $error = $apim->error() || "";
    my $ref   = ref $apim || "";

    #2 Check APIM object
    isa_ok ($apim, 'FedoraCommons::APIM');

    if (ref ($apim) ne 'FedoraCommons::APIM') {
	my $msg = "Unable to instantiate APIM object properly. Error: $error";
	diag ("$msg");
	BAIL_OUT ("$msg");
    } else {
	my $msg = "Instantiated APIM object OK";
	diag ("$msg");
    }

    #3
    ok ($apim, "Failed to instantiate APIM object.");

    # Test createObject
    my $pid = "CPAN:TestObject";
    my $collection = "CPAN Test Collection";

    my $result = $apim->createObject 
	(
	 XML_file=> "./ingesttemplate.xml",
	 params => {pid_in => $pid,
		    title_in => "Test object: $collection",
		    collection_in => "CPAN:Test"},
	 pid_ref =>\$pid);
    
    $error = $apim->error() || "";
    #4
    ok ($result == 0, "Fedora createObject() FAILED: $error");

    if ($result == 0) { diag ("createObject() OK");}

    my $pid2 = "CPAN:TestObject2";

  SKIP: {
      skip "Create Object Failed", 6 if $result != 0;
      
      # Let's create file to upload as datastream
      my $data = $apim->get_default_foxml();
      my $testFile = POSIX::tmpnam() . 'testFile';
      open my $fh, ">", $testFile;
      if (defined $fh) {
	  binmode $fh, ":utf8";
	  print $fh $data;
	  close $fh;
      }
      push @temp_files, $testFile;

      # Test uploadNewDatastream (addDatastream, setDatastreamVersionable)
      #     Relies on test object, test several methods
      my $mime = "text/xml";
      my ($dsid, $ts, $dsLabel);
      my $dsID = "TEST_DATASTREAM";
      $dsLabel = "Test Datastream";
      $ts = "";
      $result = $apim->uploadNewDatastream( pid => $pid,
					    dsID => $dsID,
					    filename => $testFile,
					    MIMEType => $mime,
					    dsid_ref => \$dsid,
					    timestamp_ref => \$ts,
					    );
      $error = $apim->error() || "";
      if ($result == 0) {
	  diag ("uploadNewDatastream (addDatastream) OK");
      }
      # A
      ok ($result == 0, "Fedora uploadNewDatastream() FAILED: $error");

      # Upload second datastream (should get timestamp this time)
      $mime = "text/xml";
      $dsID = "TEST_DATASTREAM";
      $dsLabel = "Test Datastream";
      $ts = "";
      $result = $apim->uploadNewDatastream( pid => $pid,
					    dsID => $dsID,
					    filename => $testFile,
					    MIMEType => $mime,
					    dsid_ref => \$dsid,
					    timestamp_ref => \$ts,
					    );
      $error = $apim->error() || "";
      if ($result == 0) {
	  diag ("uploadNewDatastream (modifyDatastreamByReference) OK ");
      }
      # A
      ok ($result == 0, "Fedora uploadNewDatastream() FAILED: $error");



      # Test compareDatastreamChecksum
      #     Relies on test object
      my $checksum_result;
      $dsID = "TEST_DATASTREAM";
      my $versionDate = undef;
      $result = $apim->compareDatastreamChecksum 
	  ( pid => $pid,
	    dsID => $dsID,
	    versionDate => $versionDate,
	    checksum_result =>\$checksum_result,
	    );
      $error = $apim->error() || "";
      # B
      ok ($result == 0, "Fedora compareDatastreamChecksum() FAILED: $error");

      if ($result == 0) {
	  diag ("compareDatastreamChecksum(): OK");
      }

      # Test getDatastream
      #     Relies on test object
      my $stream;
      $result = $apim->getDatastream 
	  ( pid => $pid,
	    dsID => $dsID,
	    ds_ref => \$stream,
	    );
      $error = $apim->error() || "";
      # C
      ok ($result == 0, "Fedora getDatastream() FAILED: $error");
      
      if ($result == 0) {
	  diag ("getDatastream() OK");
      }

      # Test addRelationship 
      #     Relies on test object
      my $base = "info:fedora/fedora-system:def/relations-external#";
      my $relation = "$base"."isMetadataFor";
      $result = $apim->addRelationship( pid => $pid,
					relationship => $relation,
					object => "$pid2",
					isLiteral => 'false',
					datatype => "",
					);
      $error = $apim->error() || "";
      # D
      ok ($result == 0, "Fedora addRelationship() FAILED: $error");
      
      if ($result == 0) {
	  diag ("addRelationship() OK");
      }

      # Test purgeDatastream
      #     Relies on test object
    SKIP: {
	skip "Deletions disabled: purgeDatastream()", 1 
	    if ($skip_deletions == 1);
	my $force = 0;
	my ($startDT, $endDT, $ts);
	$result = $apim->purgeDatastream
	    (pid =>  $pid,
	     dsID => $dsID,
	     startDT => $startDT,
	     endDT => $endDT,
	     logMessage => "Test of purgeDatastream()",
	     timestamp_ref => \$ts,
	     );
	$error = $apim->error() || "";
	# E
	ok ($result == 0, "Fedora purgeDatastream() FAILED: $error");
	
	if ($result == 0) {
	    diag ("purgeDatastream() OK");
	}
    }
      # Test purgeRelationship
      #     Relies on test object
    SKIP: { 
	skip "Deletions disabled: purgeRelationship()", 1 
	    if ($skip_deletions == 1);
	my $return;
	$result = $apim->purgeRelationship( pid => $pid,
					    relationship => $relation,
					    object => "$pid2",
					    isLiteral => 'false',
					    datatype => "",
					    result => \$return,
					    );
	$error = $apim->error() || "";
	# F
	ok ($result == 0, "Fedora purgeRelationship() FAILED: $error");

	if ($result == 0) {
	    diag ("purgeRelationship() OK");
	}
    }

      # Test purgeObject - clear out test objects
      #     Relies on test object
    SKIP: { 
	skip "Deletions disabled: purgeRelationship()", 1 
	    if ($skip_deletions == 1);
	my $timestamp_ref;
	
	$result = $apim->purgeObject (pid => $pid,
				      logMessage => "Purge Test Object",
				      force => "",
				      timestamp_ref => \$timestamp_ref,
				      );
	$error = $apim->error() || "";
	# G
	ok ($result == 0, "Fedora purgeObject FAILED: $error");

	if ($result == 0) {
	    diag ("purgeObject() OK");
	}
    }
  }

    # Tests that do not require test object

    # Test getNextPID - standalone
    my @pids = ();
    $result =  $apim->getNextPID (numPids      => 1,
				  pidNamespace => "TestA",
				  ##                    pidlist_ref  => \@pids,
				  pidlist_ref  => \@pids,
				  );
    $error = $apim->error() || "";
    #5
    ok ($result == 0, "Fedora getNextPID(numPids => 1) FAILED: $error");
    $count = $#pids + 1;
    #6
    ok ($count == 1, "Fedora getNextPID(numPids => 1) FAILED: $error");

    if ($result == 0 && $count == 1) {
	diag ("getNextPID(numPids => 1) OK");
    }

    @pids = ();
    $result =  $apim->getNextPID (numPids      => 10,
				  pidNamespace => "TestB",
				  ##                    pidlist_ref  => \@pids,
				  pidlist_ref  => \@pids,
				  );
    $error = $apim->error() || "";
    #7
    ok ($result == 0, "Fedora getNextPID(numPids => 10) FAILED: $error");

    #8
    $count = $#pids + 1;
    ok ($count == 10, "Fedora getNextPID(numPids => 10) FAILED: $error");

    if ($result == 0 && $count == 10) {
	diag ("getNextPID(numPids => 10) OK");
    }

} # No Fedora server environment settings found.

1;





