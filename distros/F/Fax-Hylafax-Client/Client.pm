######################################################################
# Description: Hylafax client that connects directly to the server   #
#              via Hylafax's proprietory FTP protocol                #
# Author:      Alex Rak (arak@cpan.org)                              #
# Copyright:   See COPYRIGHT section in POD text below for usage and #
#              distribution rights                                   #
######################################################################

package Fax::Hylafax::Client;

use 5.006;
use strict;
use warnings;

use Carp;
use Net::FTP;
require Exporter;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(faxinfo faxrm faxstat sendfax sendpage);

our $VERSION = "1.02";

our $Host;
our $Port;
our $User;
our $Password;
our $Passive;
our $Debug;
our $NotifyAddr;


sub faxinfo
{
	shift if $_[0] eq __PACKAGE__;
	my %param  = scalar @_ == 1 ? ('jobid', shift) : @_;
	my $self = {
		TRACE	=> '',
		SUCCESS	=> '',
		CONTENT	=> '',
	};

	##  Set defaults
	$param{host}		||= $Host		|| 'localhost';
	$param{port}		||= $Port		|| '4559';
	$param{user}		||= $User		|| 'anonymous';
	$param{password}	||= $Password	|| 'anonymous';
	$param{passive}		||= $Passive	|| '0';

	##  Basic error checking
	croak __PACKAGE__ . ": *jobid* parameter is missing" unless $param{jobid};

	##  Try to connect
	my $client = Net::FTP->new($param{host}, Port => $param{port}, Passive => $param{passive}) || croak __PACKAGE__ . ": " . $@;
	$client->login($param{user}, $param{password}) || _com_error($client);
	$self->{TRACE} .= $client->message;

	##  Process the task
	$client->quot("job", $param{jobid}) || _com_error($client);
	$self->{TRACE} .= $client->message;

	$client->quot("jparm state") || _com_error($client);
	$self->{TRACE} .= $client->message;
	$self->{CONTENT} = $client->message;

	##  Disconnect
	$client->quit;
	$self->{TRACE} .= $client->message;

	return bless $self, __PACKAGE__ . "::Instant";
}


sub faxrm
{
	shift if $_[0] eq __PACKAGE__;
	my %param  = scalar @_ == 1 ? ('jobid', shift) : @_;
	my $self = {
		TRACE	=> '',
		SUCCESS	=> '',
	};

	##  Set defaults
	$param{host}		||= $Host		|| 'localhost';
	$param{port}		||= $Port		|| '4559';
	$param{user}		||= $User		|| 'anonymous';
	$param{password}	||= $Password	|| 'anonymous';
	$param{passive}		||= $Passive	|| '0';

	##  Basic error checking
	croak __PACKAGE__ . ": *jobid* parameter is missing" unless $param{jobid};

	##  Try to connect
	my $client = Net::FTP->new($param{host}, Port => $param{port}, Passive => $param{passive}) || croak __PACKAGE__ . ": " . $@;
	$client->login($param{user}, $param{password}) || _com_error($client);
	$self->{TRACE} .= $client->message;

	##  Process the task
	$client->quot("jkill", $param{jobid}) || _com_error($client);
	$self->{TRACE} .= $client->message;
	$self->{SUCCESS} = $client->message =~ /failed/i || $client->message =~ /cannot/i ? 0 : 1;

	##  Disconnect
	$client->quit;
	$self->{TRACE} .= $client->message;

	return bless $self, __PACKAGE__ . "::Instant";
}


sub faxstat
{
	shift if $_[0] eq __PACKAGE__;
	my %param  = @_;
	my $self = {
		TRACE	=> '',
		SUCCESS	=> '',
		CONTENT	=> '',
	};

	##  Set defaults
	$param{host}		||= $Host		|| 'localhost';
	$param{port}		||= $Port		|| '4559';
	$param{user}		||= $User		|| 'anonymous';
	$param{password}	||= $Password	|| 'anonymous';
	$param{passive}		||= $Passive	|| '0';
	$param{filefmt}		||= '';
	$param{jobfmt}		||= '%-4j %3i %1a %6.6o %-12.12e %5P %5D %7z %.25s';
	$param{rcvfmt}		||= '%-7m %4p%1z %-8.8o %14.14s %7t %f';
	$param{info}		||= '0';  #  -i flag
	$param{files}		||= '0';  #  -f flag
	$param{queue}		||= '0';  #  -s flag
	$param{done}		||= '0';  #  -d flag
	$param{received}	||= '0';  #  -r flag

	##  Try to connect
	my $client = Net::FTP->new($param{host}, Port => $param{port}, Passive => $param{passive}) || croak __PACKAGE__ . ": " . $@;
	$client->login($param{user}, $param{password}) || _com_error($client);
	$self->{TRACE} .= $client->message;

	##  Process the task
	if ($param{info})
	{
		my $dataconn = $client->retr("status/any.info") || _com_error($client);
		while ($dataconn->read(my $buffer, 1024))
		{
			$self->{CONTENT} .= $buffer;
		}
		$dataconn->close;
		$self->{TRACE} .= $client->message;
	}

	my $dataconn = $client->list("status") || _com_error($client);
	while ($dataconn->read(my $buffer, 1024))
	{
		$self->{CONTENT} .= $buffer;
	}
	$dataconn->close;
	$self->{TRACE} .= $client->message;

	if ($param{files})
	{
		$client->quot("filefmt", $param{filefmt}) || _com_error($client);
		my $dataconn = $client->list("docq") || _com_error($client);
		my $content;
		while ($dataconn->read(my $buffer, 1024))
		{
			$content .= $buffer;
		}
		$dataconn->close;
		$self->{CONTENT} .= "\n$content" if $content;
		$self->{TRACE} .= $client->message;
	}

	if ($param{queue})
	{
		$client->quot("jobfmt", $param{jobfmt}) || _com_error($client);
		my $dataconn = $client->list("sendq") || _com_error($client);
		my $content;
		while ($dataconn->read(my $buffer, 1024))
		{
			$content .= $buffer;
		}
		$dataconn->close;
		$self->{CONTENT} .= "\n$content" if $content;
		$self->{TRACE} .= $client->message;
	}

	if ($param{done})
	{
		$client->quot("jobfmt", $param{jobfmt}) || _com_error($client);
		my $dataconn = $client->list("doneq") || _com_error($client);
		my $content;
		while ($dataconn->read(my $buffer, 1024))
		{
			$content .= $buffer;
		}
		$dataconn->close;
		$self->{CONTENT} .= "\n$content" if $content;
		$self->{TRACE} .= $client->message;
	}

	if ($param{received})
	{
		$client->quot("rcvfmt", $param{rcvfmt}) || _com_error($client);
		my $dataconn = $client->list("recvq") || _com_error($client);
		my $content;
		while ($dataconn->read(my $buffer, 1024))
		{
			$content .= $buffer;
		}
		$dataconn->close;
		$self->{CONTENT} .= "\n$content" if $content;
		$self->{TRACE} .= $client->message;
	}

	##  Disconnect
	$client->quit;
	$self->{TRACE} .= $client->message;

	return bless $self, __PACKAGE__ . "::Instant";
}


sub sendfax
{
	shift if $_[0] eq __PACKAGE__;
	my %param  = @_;
	my $hostname = `hostname`; chomp $hostname;
	my $self = {
		JOB_ID	=> '',
		TRACE	=> '',
		SUCCESS	=> '',
	};

	##  Set defaults
	$param{host}			||= $Host		|| 'localhost';
	$param{port}			||= $Port		|| '4559';
	$param{user}			||= $User		|| 'anonymous';
	$param{password}		||= $Password	|| 'anonymous';
	$param{passive}			||= $Passive	|| '0';
	$param{debug}			||= $Debug		|| '0';
	$param{lasttime}		||= '000259';
	$param{maxdials}		||= '12';
	$param{maxtries}		||= '3';
	$param{pagewidth}		||= '216';
	$param{pagelength}		||= '279';
	$param{vres}			||= '196';
	$param{schedpri}		||= '127';
	$param{chopthreshold}	||= '3';
	$param{notify}			||= 'none';
	$param{notifyaddr}		||= $NotifyAddr	|| $param{'user'} . '@' . $hostname;
	$param{sendtime}		||= 'now';

	$self->{PARAM} = \%param;

	##  Basic error checking
	croak __PACKAGE__ . ": *dialstring* parameter is missing" unless $param{dialstring};
	croak __PACKAGE__ . ": *docfile* parameter is missing" if (! $param{docfile} && ! $param{poll});
	croak __PACKAGE__ . ": $param{coverfile} does not exist" if ($param{coverfile} && ! -e $param{coverfile});

	if (ref(\$param{docfile}) eq 'SCALAR')
	{
		$param{docfiles} = [ $param{docfile} ];
	}
	elsif (ref($param{docfile}) eq 'ARRAY')
	{
		$param{docfiles} = $param{docfile};
	}
	else
	{
		croak __PACKAGE__ . ": *docfile* parameter must be a SCALAR or an ARRAY REFERENCE";
	}

	foreach my $docfile (@{$param{docfiles}})
	{
		croak __PACKAGE__ . ": $docfile does not exist" if (! -e $docfile);
	}

	delete $param{docfile};

	##  Try to connect
	my $client = Net::FTP->new($param{'host'}, Port => $param{'port'}, Passive => $param{'passive'}, Debug => $param{'debug'}) || croak __PACKAGE__ . ": " . $@;
	$client->login($param{'user'}, $param{'password'}) || _com_error($client);
	$self->{TRACE} .= $client->message;
	$client->binary || _com_error($client);
	$self->{TRACE} .= $client->message;

	##  Process the job
	my @tempfiles = ();

	if ($param{coverfile})
	{
		my $unique = time . sprintf('%05d', $$) . sprintf('%04d', int(rand 10000));
		my $remote = '/tmp/cover.' . $hostname . '.' . $unique;

		$client->put($param{coverfile}, $remote) || _com_error($client);	# (STOT would be nice, but Net::FTP doesn`t support it and STOU is broken)
		$self->{TRACE} .= $client->message;

		push (@tempfiles, $remote);
	}

	foreach my $docfile (@{$param{docfiles}})
	{
		my $unique = time . sprintf('%05d', $$) . sprintf('%04d', int(rand 10000));
		my $remote = '/tmp/doc.' . $hostname . '.' . $unique;

		$client->put($docfile, $remote) || _com_error($client);
		$self->{TRACE} .= $client->message;

		push (@tempfiles, $remote);
	}

	$client->quot("jnew") || _com_error($client);
	$self->{TRACE} .= $client->message;
	$client->message =~ /jobid: (\d+)/i;
	$self->{JOB_ID} = $1 if $1;
	$self->{PARAM}->{jobid} = $self->{JOB_ID};

	$client->quot("jparm fromuser", $param{'user'}) || _com_error($client);
	$self->{TRACE} .= $client->message;

	$client->quot("jparm lasttime", $param{lasttime}) || _com_error($client);
	$self->{TRACE} .= $client->message;

	$client->quot("jparm maxdials", $param{maxdials}) || _com_error($client);
	$self->{TRACE} .= $client->message;

	$client->quot("jparm maxtries", $param{maxtries}) || _com_error($client);
	$self->{TRACE} .= $client->message;

	$client->quot("jparm schedpri", $param{schedpri}) || _com_error($client);
	$self->{TRACE} .= $client->message;

	$client->quot("jparm dialstring", $param{dialstring}) || _com_error($client);
	$self->{TRACE} .= $client->message;

	$client->quot("jparm sendtime", $param{sendtime}) || _com_error($client);
	$self->{TRACE} .= $client->message;

	$client->quot("jparm notifyaddr", $param{notifyaddr}) || _com_error($client);
	$self->{TRACE} .= $client->message;

	$client->quot("jparm vres", $param{vres}) || _com_error($client);
	$self->{TRACE} .= $client->message;

	$client->quot("jparm pagewidth", $param{pagewidth}) || _com_error($client);
	$self->{TRACE} .= $client->message;

	$client->quot("jparm pagelength", $param{pagelength}) || _com_error($client);
	$self->{TRACE} .= $client->message;

	$client->quot("jparm notify", $param{notify}) || _com_error($client);
	$self->{TRACE} .= $client->message;

	$client->quot("jparm pagechop", "default") || _com_error($client);
	$self->{TRACE} .= $client->message;

	$client->quot("jparm chopthreshold", $param{chopthreshold}) || _com_error($client);
	$self->{TRACE} .= $client->message;

	foreach my $docfile (@tempfiles)
	{
		if ($param{coverfile} && $docfile eq $tempfiles[0])
		{
			$client->quot("jparm cover", $docfile) or _com_error($client);
		}
		else
		{
			$client->quot("jparm document", $docfile) or _com_error($client);
		}

		$self->{TRACE} .= $client->message;
	}

	if (defined $param{poll})
	{
		my ($selector, $passwd) = split(" ", $param{poll});
		$client->quot("jparm poll", $selector || "", $passwd || "") || _com_error($client);
		$self->{TRACE} .= $client->message;
	}

	$client->quot("jsubm") || _com_error($client);
	$self->{TRACE} .= $client->message;
	$self->{SUCCESS} = $client->message =~ /failed/i || $client->message =~ /failed/i? 0 : 1;

	##  Disconnect
	$client->quit;
	$self->{TRACE} .= $client->message;

	return bless $self, __PACKAGE__ . "::Queued";
}


sub sendpage
{
	shift if $_[0] eq __PACKAGE__;
	my %param  = @_;
	my $hostname = `hostname`; chomp $hostname;
	my $unique = time . $$ . int(rand 10000);
	my $self = {
		JOB_ID	=> '',
		TRACE	=> '',
		SUCCESS	=> '',
	};

	##  Set defaults
	$param{host}		||= $Host		|| 'localhost';
	$param{port}		||= $Port		|| '444';
	$param{user}		||= $User		|| 'anonymous';
	$param{password}	||= $Password	|| 'anonymous';
	$param{passive}		||= $Passive	|| '0';
	$param{maxdials}	||= '12';
	$param{maxtries}	||= '3';
	$param{notify}		||= 'none';
	$param{notifyaddr}	||= $NotifyAddr	|| $param{'user'} . '@' . $hostname;
	$param{level}		||= '1';

	$self->{PARAM} = \%param;

	##  Basic error checking
	croak __PACKAGE__ . ": *pin* parameter is missing" unless $param{pin};

	##  Try to connect
	my $client = Net::FTP->new($param{'host'}, Port => $param{'port'}, Passive => $param{'passive'}) || croak __PACKAGE__ . ": " . $@;
	$client->quot("logi", $param{user}, $param{password}) || _com_error($client);
	$self->{TRACE} .= $client->message;

	##  Process the job
	$client->quot("site help", "notify") || _com_error($client);
	$self->{TRACE} .= $client->message;

	$client->quot("leve", $param{level}) || _com_error($client);
	$self->{TRACE} .= $client->message;

	$client->quot("site fromuser", $param{'user'}) || _com_error($client);
	$self->{TRACE} .= $client->message;

	$client->quot("site maxdials", $param{maxdials}) || _com_error($client);
	$self->{TRACE} .= $client->message;

	$client->quot("site maxtries", $param{maxtries}) || _com_error($client);
	$self->{TRACE} .= $client->message;

	$client->quot("site mailaddr", $param{notifyaddr}) || _com_error($client);
	$self->{TRACE} .= $client->message;

	$client->quot("site notify", $param{notify}) || _com_error($client);
	$self->{TRACE} .= $client->message;

	$client->quot("site jqueue", "yes") || _com_error($client);
	$self->{TRACE} .= $client->message;

	$client->quot("page", $param{pin}) || _com_error($client);
	$self->{TRACE} .= $client->message;
	$client->message =~ /jobid: (\d+)\./i;
	$self->{JOB_ID} = $1 if $1;
	$self->{PARAM}->{jobid} = $self->{JOB_ID};

	if ($param{message})
	{
		$client->quot("mess", $param{message}) || _com_error($client);
		$self->{TRACE} .= $client->message;
	}

	$client->quot("send") || _com_error($client);
	$self->{TRACE} .= $client->message;
	$self->{SUCCESS} = $client->message =~ /success/i ? 1 : 0;

	##  Disconnect
	$client->quit;
	$self->{TRACE} .= $client->message;

	return bless $self, __PACKAGE__ . "::Queued";
}

######################################################################

sub _com_error
{
	my $client = shift;
	croak __PACKAGE__ . ": Communication error: " . $client->message;
}


sub _content
{
	my $class = shift;
	my $self = shift;
	return $self->{CONTENT} || undef;
}


sub _success
{
	my $class = shift;
	my $self = shift;
	return $self->{SUCCESS} || undef;
}


sub _trace
{
	my $class = shift;
	my $self = shift;
	return $self->{TRACE} || undef;
}

######################################################################

package Fax::Hylafax::Client::Queued;


sub faxinfo
{
	my $self = shift;
	my $conn = Fax::Hylafax::Client->faxinfo(%{$self->{PARAM}});
	$self->{TRACE} = $conn->trace;
	$self->{SUCCESS} = $conn->success;
	return $conn->content;
}


sub faxrm
{
	my $self = shift;
	my $conn = Fax::Hylafax::Client->faxrm(%{$self->{PARAM}});
	$self->{TRACE} = $conn->trace;
	$self->{SUCCESS} = $conn->success;
	return $conn->success;
}


sub jobid
{
	my $self = shift;
	return $self->{JOB_ID};
}


sub success
{
	return Fax::Hylafax::Client->_success(shift);
}


sub trace
{
	return Fax::Hylafax::Client->_trace(shift);
}

######################################################################

package Fax::Hylafax::Client::Instant;


sub content
{
	return Fax::Hylafax::Client->_content(shift);
}


sub success
{
	return Fax::Hylafax::Client->_success(shift);
}


sub trace
{
	return Fax::Hylafax::Client->_trace(shift);
}

######################################################################

1;

__END__

=head1 NAME

Fax::Hylafax::Client - Simple HylaFAX client

=head1 SYNOPSIS

     use Fax::Hylafax::Client qw(sendfax);

     my $fax = sendfax(
          dialstring    => '5555555555',
          docfile       => '/usr/home/test/document.ps',
     );

=head1 DESCRIPTION

This is a simple Perl client for HylaFAX fax server (www.hylafax.org). It communicates
with the server directly through FTP-like protocol and thus does not require any HylaFAX
software components to be installed on the client machine.

=head1 MAIN METHODS AND ATTRIBUTES

=over

=item B<sendfax>

This method sends a fax job to the server. Returns "Client::Queued" object. Takes a hash
of the following attributes:

=over

=item host

Hostname of the server. Defaults to "localhost". [OPTIONAL]

=item port

Connection port of the server. Defaults to "4559". [OPTIONAL]

=item user

Username of the client. Defaults to "anonymous". [MAY BE REQUIRED]

=item password

Password of the client. Defaults to "anonymous". [MAY BE REQUIRED]

=item dialstring

Destination string (number) to dial. [REQUIRED]

=item docfile

Full pathname of the document file. This attribute takes a single filename (scalar)
or a reference to an array of filenames. Document files must be in one of the
native HylaFAX formats, i.e. Plain Text, PostScript, TIFF Class F, or PDF.
[REQUIRED unless you use "poll" option]

=item coverfile

Full pathname of the cover page file. All notes about "docfile" apply, except
it only takes one filename as scalar. [OPTIONAL]

=item notifyaddr

E-mail address of the person to be notified about the status of the job. Defaults to
"user@hostname". [OPTIONAL]

=item notify

Controls the email notification messages from the server. Possible values: "none" - notify
if error only, "done" - notify when done, "requeue" - notify if job is re-queued,
"done+requeue". Defaults to "none". [OPTIONAL]

=item passive

If set to "1" connects to server in PASSIVE mode. Defaults to "0". [OPTIONAL]

=item sendtime

Time when the fax should be sent. Possible values: "now" or date in format "YYYYMMDDHHMM".
It looks like this value must be in GMT time zone. Defaults to "now". [OPTIONAL]

=item lasttime

Kill the job if not successfully sent after this much time. Format "DDHHSS". Defaults to "000259"
(3 hours). [OPTIONAL]

=item maxdials

The maximum number of times to dial the phone. Defaults to "12". [OPTIONAL]

=item maxtries

The maximum number of times to retry sending a job once connection is established. Defaults to "3". [OPTIONAL]

=item pagewidth

Set the transmitted page width in millimeters. Defaults to "216" (Letter size). [OPTIONAL]

=item pagelength

Set the transmitted page length in millimeters. Defaults to "279" (Letter size). [OPTIONAL]

=item vres

Set the vertical resolution in lines/inch to use when transmitting facsimile. High resolution
equals to "196", low resolution equals to "98". Defaults to "196". [OPTIONAL]

=item chopthreshold

The amount of white space, in inches, that must be present at the bottom of a page before 
HylaFAX will attempt to truncate the page transmission. Defaults to "3". [OPTIONAL]

=item schedpri

The scheduling priority to assign to the job. Defaults to "127" (Normal). [OPTIONAL]

=item poll

Try to poll a fax from remote machine. Value can be an empty string or "selector [passwd]". [OPTIONAL]

=back

=item B<sendpage>

Sends SNPP page job to the server. Returns "Client::Queued" object. Takes a hash
of the following attributes:

=over

=item host

Same as in "sendfax".

=item port

Connection port of the server. Defaults to "444". [OPTIONAL]

=item user

Same as in "sendfax".

=item password

Same as in "sendfax".

=item pin

Pager Identification Number as defined in "pagermap" file on the server. [REQUIRED]

=item message

Text message to be sent (alfa-numeric pagers only). [OPTIONAL]

=item notifyaddr

Same as in "sendfax".

=item notify

Same as in "sendfax".

=item passive

Same as in "sendfax".

=item maxdials

Same as in "sendfax".

=item maxtries

Same as in "sendfax".

=item level

Priority level to assign to the job. Values can be "0-7" (0 being the highest). 
Defaults to "1" (Normal). [OPTIONAL]

=back

=item B<faxinfo>

Request the status of a particular job. Returns "Client::Instant" object. Can take only the number
of the job as an attribute or a hash of the following attributes:

=over

=item host

Same as in "sendfax".

=item port

Same as in "sendfax".

=item user

Same as in "sendfax".

=item password

Same as in "sendfax".

=item jobid

ID of the job. [REQUIRED]

=item passive

Same as in "sendfax".

=back

=item B<faxrm>

Remove job from the server (kill it). Returns "Client::Instant" object. Behaves like and has the same
attributes as "faxinfo".

=item B<faxstat>

Request statistics from the server. Returns "Client::Instant" object. Takes a hash
of the following attributes:

=over

=item host

Same as in "sendfax".

=item port

Same as in "sendfax".

=item user

Same as in "sendfax".

=item password

Same as in "sendfax".

=item passive

Same as in "sendfax".

=item info

If set to "1" displays additional status information for the server. This status typically has 
information such as the HylaFAX version, the physical location of the server machine, and an 
administrative contact for the server. Defaults to "0". [OPTIONAL]

=item files

If set to "1" displays the status of document files located in the docq directory on the server 
machine. The "filefmt" attribute defines the content and format of information reported with 
this option. Defaults to "0". [OPTIONAL]

=item queue

If set to "1" displays the status of jobs in the send queue on the server machine. The "jobjmt" 
attribute defines the content and format of information reported with this option. 
Defaults to "0". [OPTIONAL]

=item done

If set to "1" displays the status of all jobs that have completed; i.e. those jobs located in 
the doneq directory on the server machine. The "jobfmt" attribute defines the content and 
format of information reported with this option. Defaults to "0". [OPTIONAL]

=item received

If set to "1" displays the receive queue status. The "rcvfmt" attribute defines the content and
format of information reported with this option. Defaults to "0". [OPTIONAL]

=item filefmt

The format string to use when returning file status information. See "faxstat" man pages for details.
[OPTIONAL]

=item jobfmt

The format string to use when returning job status information. See "faxstat" man pages for details.
[OPTIONAL]

=item rcvfmt

The format string to use when returning status information about received jobs. See "faxstat" man 
pages for details. [OPTIONAL]

=back

=back

=head1 METHODS AND ATTRIBUTES OF ALL Client::* OBJECTS

=over

=item B<success>

Returns true if the task was accepted. This only means the task request was successfully
processed by the server. This does not always mean the task itself was successfully completed. 
Use "faxinfo" to check for that.

=item B<trace>

Returns responses from the last communication with the server. Userful for debugging.

=back

=head1 METHODS AND ATTRIBUTES OF Client::Queued OBJECTS ONLY

=over

=item B<faxinfo>

Returns the status of the job at this particular moment.

=item B<faxrm>

Kills the job.

=item B<jobid>

Returns the ID assigned to the job by the server.

=back

=head1 METHODS AND ATTRIBUTES OF Client::Instant OBJECTS ONLY

=over

=item B<content>

Returns content returned by the server.

=back

=head1 GLOBAL VARIABLES

=over

=item B<$Fax::Hylafax::Client::Host>

Specifies hostname of the server. Used in place of "host" attribute.

=item B<$Fax::Hylafax::Client::Port>

Specifies connection port of the server. Used in place of "port" attribute.

=item B<$Fax::Hylafax::Client::User>

Username of the client. Used in place of "user" attribute.

=item B<$Fax::Hylafax::Client::Password>

Password of the client. Used in place of "password" attribute.

=item B<$Fax::Hylafax::Client::Passive>

Specifies if PASSIVE connections should be used. Used in place of "passive" attribute.

=item B<$Fax::Hylafax::Client::NotifyAddr>

E-mail address where server notifications will be sent. Used in place of "notifyaddr" attribute.

=back

=head1 EXAMPLES

Send a fax

     use Fax::Hylafax::Client qw(sendfax);

     my $fax = sendfax(
          host          => 'remote.host.name',
          dialstring    => '14151234567',
          docfile       => '/usr/home/test/document.ps',
          coverfile     => '/usr/home/test/cover.ps',
          notifyaddr    => 'test@user.com',
     );

     if ($fax->success)
     {
          print "We are OK";
     }
     else
     {
          print $fax->trace;
     }

Misc. examples

     use Fax::Hylafax::Client qw(sendfax sendpage faxstat faxinfo faxrm);

     $Fax::Hylafax::Client::Host       = 'remote.server.hostname';
     $Fax::Hylafax::Client::User       = 'faxuser';
     $Fax::Hylafax::Client::Password   = '*password*';
     $Fax::Hylafax::Client::NotifyAddr = 'client@address.com';

     my $fax = sendfax(
          dialstring    => '14151234567',
          docfile       => [
                              '/usr/home/test/document1.ps',
                              '/usr/home/test/document2.ps',
                           ],
     );

     my $task_succeded = $fax->success ? "YES" : "NO";
     my $server_responses = $fax->trace;
     my $job_id = $fax->jobid;
     my $current_job_status = $fax->faxinfo;

     my $server_stats = faxstat( info => 1, active => 1 )->content;
     if (faxinfo($job_id)->content ne 'DONE')
     {
          print "We're not done yet";

          $fax->faxrm;

          #   or

          faxrm($job_id);

          #   or

          my $task = faxrm(
                host     => 'remote.server.hostname',
                user     => 'faxuser',
                password => '*password*',
                jobid    => $job_id,
          );
          print $task->success ? "We killed it!" : "Server didn't like it: " . $task->trace;
     }

     my $other_server_task = faxstats( host => 'other.server.host', user => 'bob', password => 'whatever' );
     if ($other_server_task->success)
     {
          print $other_server_task->content;
     }
     else
     {
          print "Doh! We failed to get stats from the server: ", $other_server_task->trace;
     }

     my $page = sendpage(
          pin	   => 'bob',
          message  => 'Time to wake up',
     );
     my $task_succeded = $page->success ? "YES" : "NO";


=head1 AUTHOR

Alex Rak B<arak@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2003,2006 Alex Rak.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

HylaFAX man pages L<http://www.hylafax.org/>

=cut


