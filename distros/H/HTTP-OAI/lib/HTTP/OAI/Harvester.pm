package HTTP::OAI::Harvester;

use base HTTP::OAI::UserAgent;

use strict;

our $VERSION = '4.04';

sub new {
	my ($class,%args) = @_;
	my %ARGS = %args;
	delete @ARGS{qw(baseURL resume repository handlers onRecord)};
	my $self = $class->SUPER::new(%ARGS);

	$self->{doc} = XML::LibXML::Document->new( '1.0', 'UTF-8' );

	$self->{'resume'} = exists($args{resume}) ? $args{resume} : 1;

	$self->agent('OAI-PERL/'.$HTTP::OAI::VERSION);

	# Record the base URL this harvester instance is associated with
	$self->{repository} =
		$args{repository} ||
		HTTP::OAI::Identify->new(baseURL=>$args{baseURL});
	Carp::croak "Requires repository or baseURL" unless $self->repository and $self->repository->baseURL;

	# Canonicalise
	$self->baseURL($self->baseURL);

	return $self;
}

sub resume { shift->_elem('resume',@_) }
sub repository { shift->_elem('repository',@_) }

sub baseURL {
	my $self = shift;
	return @_ ?
		$self->repository->baseURL(URI->new(shift)->canonical) :
		$self->repository->baseURL();
}
sub version { shift->repository->protocolVersion(@_); }

sub ListIdentifiers { shift->_list( @_, verb => "ListIdentifiers" ); }
sub ListRecords { shift->_list( @_, verb => "ListRecords" ); }
sub ListSets { shift->_list( @_, verb => "ListSets" ); }
sub _list
{
	my $self = shift;

	local $self->{recursion};
	my $r = $self->_oai( @_ );

	# resume the partial list?
	# note: noRecordsMatch is a "success" but won't have a resumptionToken
	RESUME: while($self->resume && $r->is_success && !$r->error && defined(my $token = $r->resumptionToken))
	{
		last RESUME if !$token->resumptionToken;
		local $self->{recursion};
		$r = $self->_oai(
			onRecord => $r->{onRecord},
			handlers => $r->handlers,
			verb => $r->verb,
			resumptionToken => $token->resumptionToken,
		);
	}

	$self->version( $r->version ) if $r->is_success;

	return $r;
}

# build the methods for each OAI verb
foreach my $verb (qw( GetRecord Identify ListMetadataFormats ))
{
	no strict "refs";
	*$verb = sub {
		my $self = shift;
		local $self->{recursion};

		my $r = $self->_oai( @_, verb => $verb );

		$self->version( $r->version ) if $r->is_success;

		return $r;
	};
}

1;

__END__

=head1 NAME

HTTP::OAI::Harvester - Agent for harvesting from Open Archives version 1.0, 1.1, 2.0 and static ('2.0s') compatible repositories

=head1 DESCRIPTION

C<HTTP::OAI::Harvester> is the harvesting front-end in the OAI-PERL library.

To harvest from an OAI-PMH compliant repository create an C<HTTP::OAI::Harvester> object using the baseURL option and then call OAI-PMH methods to request data from the repository. To handle version 1.0/1.1 repositories automatically you B<must> request C<Identify()> first.

It is recommended that you request an Identify from the Repository and use the C<repository()> method to update the Identify object used by the harvester.

When making OAI requests the underlying L<HTTP::OAI::UserAgent> module will take care of automatic redirection (http code 302) and retry-after (http code 503). OAI-PMH flow control (i.e. resumption tokens) is handled transparently by C<HTTP::OAI::Response>.

=head2 Static Repository Support

Static repositories are automatically and transparently supported within the existing API. To harvest a static repository specify the repository XML file using the baseURL argument to HTTP::OAI::Harvester. An initial request is made that determines whether the base URL specifies a static repository or a normal OAI 1.x/2.0 CGI repository. To prevent this initial request state the OAI version using an HTTP::OAI::Identify object e.g.

	$h = HTTP::OAI::Harvester->new(
		repository=>HTTP::OAI::Identify->new(
			baseURL => 'http://arXiv.org/oai2',
			version => '2.0',
	));

If a static repository is found the response is cached, and further requests are served by that cache. Static repositories do not support sets, and will result in a noSetHierarchy error if you try to use sets. You can determine whether the repository is static by checking the version ($ha->repository->version), which will be "2.0s" for static repositories.

=head1 FURTHER READING

You should refer to the Open Archives Protocol version 2.0 and other OAI documentation, available from http://www.openarchives.org/.

Note OAI-PMH 1.0 and 1.1 are deprecated.

=head1 BEFORE USING EXAMPLES

In the examples I use arXiv.org's and cogprints OAI interfaces. To avoid causing annoyance to their server administrators please contact them before performing testing or large downloads (or use other, less loaded, servers for testing).

=head1 SYNOPSIS

	use HTTP::OAI;

	my $h = new HTTP::OAI::Harvester(baseURL=>'http://arXiv.org/oai2');
	my $response = $h->repository($h->Identify)
	if( $response->is_error ) {
		print "Error requesting Identify:\n",
			$response->code . " " . $response->message, "\n";
		exit;
	}

	# Note: repositoryVersion will always be 2.0, $r->version returns
	# the actual version the repository is running
	print "Repository supports protocol version ", $response->version, "\n";

	# Version 1.x repositories don't support metadataPrefix,
	# but OAI-PERL will drop the prefix automatically
	# if an Identify was requested first (as above)
	$response = $h->ListIdentifiers(
		metadataPrefix=>'oai_dc',
		from=>'2001-02-03',
		until=>'2001-04-10'
	);

	if( $response->is_error ) {
		die("Error harvesting: " . $response->message . "\n");
	}

	print "responseDate => ", $response->responseDate, "\n",
		"requestURL => ", $response->requestURL, "\n";

	while( my $id = $response->next ) {
		print "identifier => ", $id->identifier;
		# Only available from OAI 2.0 repositories
		print " (", $id->datestamp, ")" if $id->datestamp;
		print " (", $id->status, ")" if $id->status;
		print "\n";
		# Only available from OAI 2.0 repositories
		for( $id->setSpec ) {
			print "\t", $_, "\n";
		}
	}

	# Using a handler
	$response = $h->ListRecords(
		metadataPrefix=>'oai_dc',
		handlers=>{metadata=>'HTTP::OAI::Metadata::OAI_DC'},
	);
	while( my $rec = $response->next ) {
		print $rec->identifier, "\t",
			$rec->datestamp, "\n",
			$rec->metadata, "\n";
		print join(',', @{$rec->metadata->dc->{'title'}}), "\n";
	}
	if( $rec->is_error ) {
		die $response->message;
	}

	# Offline parsing
	$I = HTTP::OAI::Identify->new();
	$I->parse_string($content);
	$I->parse_file($fh);

=head1 METHODS

=over 4

=item HTTP::OAI::Harvester->new( %params )

This constructor method returns a new instance of C<HTTP::OAI::Harvester>. Requires either an L<HTTP::OAI::Identify> object, which in turn must contain a baseURL, or a baseURL from which to construct an Identify object.

Any other parameters are passed to the L<HTTP::OAI::UserAgent> module, and from there to the L<LWP::UserAgent> module.

	$h = HTTP::OAI::Harvester->new(
		baseURL	=>	'http://arXiv.org/oai2',
		resume=>0, # Suppress automatic resumption
	)
	$id = $h->repository();
	$h->repository($h->Identify);

	$h = HTTP::OAI::Harvester->new(
		HTTP::OAI::Identify->new(
			baseURL => 'http://arXiv.org/oai2',
	));

=item $h->repository()

Returns and optionally sets the L<HTTP::OAI::Identify> object used by the Harvester agent.

=item $h->resume( [1] )

If set to true (default) resumption tokens will automatically be handled by requesting the next partial list during C<next()> calls.

=back

=head1 OAI-PMH Verbs

The 6 OAI-PMH Verbs are the requests supported by an OAI-PMH interface.

=head2 Error Messages

Use C<is_success()> or C<is_error()> on the returned object to determine whether an error occurred (see L<HTTP::OAI::Response>).

C<code()> and C<message()> return the error code (200 is success) and a human-readable message respectively. L<Errors|HTTP::OAI::Error> returned by the repository can be retrieved using the C<errors()> method:

	foreach my $error ($r->errors) {
		print $error->code, "\t", $error->message, "\n";
	}

Note: C<is_success()> is true for the OAI Error Code C<noRecordsMatch> (i.e. empty set), although C<errors()> will still contain the OAI error.

=head2 Flow Control

If the response contained a L<resumption token|HTTP::OAI::ResumptionToken> this can be retrieved using the $r->resumptionToken method.

=head2 Methods

These methods return an object subclassed from L<HTTP::Response> (where the class corresponds to the verb requested, e.g. C<GetRecord> requests return an C<HTTP::OAI::GetRecord> object).

=over 4

=item $r = $h->GetRecord( %params )

Get a single record from the repository identified by identifier, in format metadataPrefix.

	$gr = $h->GetRecord(
		identifier	=>	'oai:arXiv:hep-th/0001001', # Required
		metadataPrefix	=>	'oai_dc' # Required
	);
	$rec = $gr->next;
	die $rec->message if $rec->is_error;
	printf("%s (%s)\n", $rec->identifier, $rec->datestamp);
	$dom = $rec->metadata->dom;

=item $r = $h->Identify()

Get information about the repository.

	$id = $h->Identify();
	print join ',', $id->adminEmail;

=item $r = $h->ListIdentifiers( %params )

Retrieve the identifiers, datestamps, sets and deleted status for all records within the specified date range (from/until) and set spec (set). 1.x repositories will only return the identifier. Or, resume an existing harvest by specifying resumptionToken.

	$lr = $h->ListIdentifiers(
		metadataPrefix	=>	'oai_dc', # Required
		from		=>		'2001-10-01',
		until		=>		'2001-10-31',
		set=>'physics:hep-th',
	);
	while($rec = $lr->next)
	{
		{ ... do something with $rec ... }
	}
	die $lr->message if $lr->is_error;

=item $r = $h->ListMetadataFormats( %params )

List available metadata formats. Given an identifier the repository should only return those metadata formats for which that item can be disseminated.

	$lmdf = $h->ListMetadataFormats(
		identifier => 'oai:arXiv.org:hep-th/0001001'
	);
	for($lmdf->metadataFormat) {
		print $_->metadataPrefix, "\n";
	}
	die $lmdf->message if $lmdf->is_error;

=item $r = $h->ListRecords( %params )

Return full records within the specified date range (from/until), set and metadata format. Or, specify a resumption token to resume a previous partial harvest.

	$lr = $h->ListRecords(
		metadataPrefix=>'oai_dc', # Required
		from	=>	'2001-10-01',
		until	=>	'2001-10-01',
		set		=>	'physics:hep-th',
	);
	while($rec = $lr->next)
	{
		{ ... do something with $rec ... }
	}
	die $lr->message if $lr->is_error;

=item $r = $h->ListSets( %params )

Return a list of sets provided by the repository. The scope of sets is undefined by OAI-PMH, so therefore may represent any subset of a collection. Optionally provide a resumption token to resume a previous partial request.

	$ls = $h->ListSets();
	while($set = $ls->next)
	{
		print $set->setSpec, "\n";
	}
	die $ls->message if $ls->is_error;

=back

=head1 AUTHOR

These modules have been written by Tim Brody E<lt>tdb01r@ecs.soton.ac.ukE<gt>.
