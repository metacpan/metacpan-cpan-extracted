#!/usr/bin/env perl

use 5.008;
use strict;
use warnings;
use CGI qw(:cgi -debug);
use CGI::Carp 'fatalsToBrowser';
$CGI::POST_MAX=1024 * 1000;		# 1MB maximum request size 
$CGI::DISABLE_UPLOADS = 1;		# the mechanisms we're using aren't the upload
								# the file upload mechanism
use Helios::Job;
use Helios::Service;
use Helios::LogEntry::Levels ':all';

our $VERSION = '2.41';

# FILE CHANGE HISTORY
# 2011-12-15: Complete rewrite to allow requester to send job arg XML in an 
# HTTP POST w/o form encoding.  Also, HELIOS_CLASS_MAP lookup is no longer 
# necessary.

# grab the CGI params (we may not have any)
my $cgi = CGI->new();
my $type = $cgi->param('type');
my $params = $cgi->param('params');

# setup Helios service for config/logging/etc.
my $Service = new Helios::Service;
$Service->prep() or die($Service->errstr);
my $HeliosConfig = $Service->getConfig();

# we're going to fill these in
my $jobClass;
my $argXML;
my $job;
my $jobid;

# we were either given a bunch of XML in POSTDATA
# or a multipart MIME-encoded form
if ( defined($type) && defined($params) ) {
	# ok, the submission was made old-school,
	# via multi-part form
	$jobClass = lookupJobClass($type);
	$argXML = $params;
} elsif ( defined($cgi->param('POSTDATA')) ) {
	# submission was just a POSTed XML stream
	# parse the XML to get the type, then
	# use the type to get the job class
	$argXML = $cgi->param('POSTDATA');
	$type = parseArgXMLForType($argXML);
	$jobClass = lookupJobClass($type);
} else {
	$Service->logMsg(LOG_ERR, 'submitJob.pl ERROR: submit request failed to submit job type and/or arguments');
	die('submitJob.pl ERROR: submit request failed to submit job type and/or arguments');
}

# we have job argument XML and the class it's destined for
# so it's submission time!
eval {
	$job = Helios::Job->new();
	$job->setConfig($HeliosConfig);
	$job->setFuncname($jobClass);	
	$job->setArgXML($argXML);
	$jobid = $job->submit();
} or do {
	my $E = $@;
	$Service->logMsg(LOG_ERR, $E);
	die($E);
};

# if we encountered no errors, the job was submitted successfully
# send a nice response message to the client
print $cgi->header('text/xml');
print <<RESPONSE;
<?xml version="1.0" encoding="UTF-8"?>
<response>
<status>0</status>
<jobid>$jobid</jobid>
</response>
RESPONSE

# DONE!



sub lookupJobClass {
	my $type = shift;
	my $dbh = $Service->dbConnect();
	my $r = $dbh->selectrow_arrayref("select job_class from helios_class_map where job_type = ?", 
			undef, $type);
	if ( defined($r) && defined($r->[0]) ) {
		return $r->[0];
	} else {
		return $type;
	}
}


sub parseArgXMLForType {
	my $parsedXml = Helios::Job->parseArgXML($_[0]);
	my $type;
	if ( defined($parsedXml->{job}->[0]->{type}) ) {
		return $parsedXml->{job}->[0]->{type};
	} else {
		$Service->logMsg(LOG_ERR,"submitJob.pl ERROR: type attribute not specified in XML stream");
		die("submitJob.pl ERROR: type attribute not specified in XML stream");
	}
}


=head1 NAME

submitJob.pl - CGI script to receive jobs for Helios via HTTP POST

=head1 DESCRIPTION

Besides the built-in Perl job submission API and the helios_job_submit.pl 
command line utility, job can be submitted to Helios via an HTTP POST 
request by using the submitJob.pl CGI program.  

=head1 SUPPORTED FORMATS

The job submission request can be submitted either in a form-encoded request or
a simple stream of XML POSTDATA.

=head2 FORM ENCODED

You can submit a job through a form-encoded request.  There are two 
form fields:

=over 4

=item type

The job type, ie the service class that will perform the job

=item params

The job arguments, ie the actual parameters of the job, in XML format

=back

You can submit requests in this format via a browser using the following 
HTML form as a guide:

 <form method="post" action="http://host/cgi-bin/jobSubmit.pl">
 <b>Job Type (Service Class)</b> <br />
 <input type="text" name="type" />
 <br />
 <br />
 <b>Job Arguments</b> <br />
 <textarea rows="10" cols="80" name="params"></textarea>
 <br />
 <input type="submit" value="Submit Job" />
 </form>

The params field should contain the job arguments in XML format, like the 
following example:

 <job>
 	<params>
 		<arg1>value1</arg1>
 		<id>value2</id>
 		<email>root@somewhere.com</email>
 	</params>
 </job>

The <arg1>, <id>, etc. tags will be parsed into Perl hash values by Helios 
when the job is run.  Inside the <params> section, the tag names are up to you; 
though Helios does checks to make sure the job XML is well-formed, there is no 
DTD that the text is validated against.  Thus, you have a certain amount of 
freedom when deciding what information to pass to Helios as a job argument.  
However, it is generally a good idea to keep things short and simple.  

=head2 XML POSTDATA

Instead of encoding your request as a form, you can simply POST a stream of 
XML text.  In this type of request, the job argument XML is in the same format 
as above, with the addition that the job type is specified as a property of the 
<job> tag:

 <?xml version="1.0" encoding="UTF-8"?>
 <job type="Helios::TestService">
 	<params>
 		<arg1>a job submitted via HTTP</arg1>
 		<note>this one was posted as an XML stream</note>
 	</params>
 </job>

To POST the above XML stream with Perl using LWP::UserAgent, use the following 
script as an example:

 #!/usr/bin/env perl 
 use strict;
 use warnings;
 use LWP::UserAgent;
 use HTTP::Request::Common;
 my $ua = LWP::UserAgent->new();
 my $jobXML = <<ENDXML;
 <?xml version="1.0" encoding="UTF-8"?>
 <job type="Helios::TestService">
 	<params> 
 		<arg1>a job submitted via HTTP</arg1>
 		<note>this one was posted as an XML stream</note>
 	</params>
 </job>
 ENDXML

 my $r = $ua->request(POST 'http://localhost/cgi-bin/submitJob.pl',
 		Content_Type => 'text/xml',
 		Content => $jobXML
 );
 print $r->as_string;

=head1 RESPONSE

Regardless of which encoding method you use for your request, if your job was 
submitted successfully you'll receive a response like the following:

 HTTP/1.1 200 OK
 Connection: close
 Date: Fri, 16 Dec 2011 04:24:30 GMT
 Server: Apache/2.2.14 (Ubuntu)
 Vary: Accept-Encoding
 Content-Type: text/xml; charset=ISO-8859-1
 Client-Date: Fri, 16 Dec 2011 04:24:30 GMT
 Client-Peer: 127.0.0.1:80
 Client-Response-Num: 1
 Client-Transfer-Encoding: chunked

 <?xml version="1.0" encoding="UTF-8"?>
 <response>
 <status>0</status>
 <jobid>42</jobid>
 </response>

If your job was submitted successfully, the <status> section will contain a 0,
and the <jobid> section will contain the jobid of the submitted job.  If there 
was an error during the job submission process, a 500 Internal Server Error 
will be returned.

=head1 FUNCTIONS

=head2 lookupJobClass($type)

Given a job type, lookupJobClass() queries the HELIOS_CLASS_MAP table to 
determine if a Helios service class is associated with that job type.  If 
there is, the function returns that service class.  If it isn't, the original 
type is assumed to be the name of the desired service class, and it is 
returned to the caller instead.

=head2 parseArgXMLForType($xmlstring)

Given a string of job arguments in XML format, parseArgXMLForType() 
returns the value of the type attribute of the <job> tag, if specified.

=head1 SEE ALSO

L<helios_job_submit.pl>, L<helios.pl>, L<Helios::Service>, L<Helios::Job>

=head1 AUTHOR

Andrew Johnson, E<lt>lajandy at cpan dot orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011-2 Andrew Johnson.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.0 or,
at your option, any later version of Perl 5 you may have available.

=head1 WARRANTY

This software comes with no warranty of any kind.

=cut

