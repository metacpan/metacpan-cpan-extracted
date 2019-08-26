#!/usr/bin/perl

use HTTP::OAI;
use Getopt::Long;
use Pod::Usage;
use XML::LibXML;

=head1 NAME

oai_pmh.pl - pipe OAI-PMH to the command-line

=head1 SYNOPSIS

	oai_pmh.pl <options> [baseURL]

=head1 OPTIONS

=over 8

=item --help

=item --man

=item --verbose

Be more verbose (repeatable).

=item --force

Force a non-conformant OAI request.

=item --from <ISO datetime>

=item --identifier <identifier>

OAI identifier to GetRecord or ListMetadataFormats.

=item --metadataPrefix <mdp>

Specify format of metadata to retrieve.

=item -X/--request <command>

Verb to request, defaults to ListRecords.

=item --set <oai set>

Request only those records in a set.

=item --until <ISO datetime>

=back

=head1 DESCRIPTION

Retrieve data from OAI-PMH endpoints. The output format is:

	<headers>

	<content>
	<FORMFEED>

Where <headers> are in HTTP header format. Content will be the raw XML as exposed by the repository. Each record is separated by a FORMFEED character.

For example:

	oai_pmh.pl -X GetRecord --metadataPrefix oai_dc \
		--identifier oai:eprints.soton.ac.uk:20 http://eprints.soton.ac.uk/cgi/oai2

=cut

my %opts = (
	verbose => 1,
);

GetOptions(\%opts,
	'help',
	'man',
	'metadataPrefix=s',
	'request|X=s',
	'identifier=s',
	'set=s',
	'verbose+',
	'force',
	'from=s',
	'until=s',
) or pod2usage(2);
pod2usage(1) if $opts{help};
pod2usage({-verbose => 2}) if $opts{man};

my $noise = delete $opts{verbose};

if (!exists $opts{request}) {
	$opts{request} = 'ListRecords';
	$opts{metadataPrefix} = 'oai_dc';
}

my $base_url = pop @ARGV;
pod2usage(1) if !$base_url;

my $ha = HTTP::OAI::Harvester->new(baseURL => $base_url);

my $f = delete $opts{request};
debug("Requesting $f", 2);
my $r = $ha->$f(
	%opts,
	onRecord => \&output_record,
);
if( $f eq "ListMetadataFormats" )
{
	foreach my $mdf ($r->metadataFormat) {
		print "metadataPrefix: " . $mdf->metadataPrefix . "\n";
		print "schema: " . $mdf->schema . "\n";
		print "metadataNamespace: " . $mdf->metadataNamespace . "\n";
		print "\n";
		print "\f";
	}
}

if( !$r->is_success )
{
	die "Error in response: " . $r->message . "\n";
}

sub debug
{
	my( $msg, $level ) = @_;

	warn "$msg\n" if $noise >= $level;
}

sub output_record
{
	my( $rec ) = @_;

	my $header = $rec->isa( 'HTTP::OAI::Header' ) ? $rec : $rec->header;

	print "identifier: " . $header->identifier . "\n";
	print "datestamp: " . $header->datestamp . "\n";
	print "status: " . $header->status . "\n";
	foreach my $set ($header->setSpec) {
		print "setSpec: " . $set . "\n";
	}
	print "\n";

	if ($rec->can( "metadata" ) && defined(my $metadata = $rec->metadata)) {
		print $metadata->dom->toString( 1 );
	}

	print "\f";
}
