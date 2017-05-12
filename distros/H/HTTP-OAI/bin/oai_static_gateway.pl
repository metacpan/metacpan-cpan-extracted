#!/usr/bin/perl -w

# Change this to the location of your static repository
# XML file
my $STATIC_REPO = 'file:../examples/repository.xml';

use strict;
use HTTP::OAI;
use HTTP::OAI::Repository qw/:validate/;
use XML::SAX::Writer;
use CGI qw/:standard -oldstyle_urls/;

use vars qw( $GZIP );

BEGIN {
	eval { require PerlIO::gzip };
	$GZIP = $@ ? 0 : 1;
}

# Create a new harvester object to read the xml file
my $h = HTTP::OAI::Harvester->new(baseURL=>$STATIC_REPO);

binmode(STDOUT,':utf8');

my @encodings = http('HTTP_ACCEPT_ENCODING');
if( $GZIP && grep { defined($_) && $_ eq 'gzip' } @encodings ) {
	print header(
		-type=>'text/xml; charset=utf-8',
		-charset=>'utf-8',
		'-Content-Encoding'=>'gzip',
	);
	binmode(STDOUT, ":gzip");
} else {
	print header(
		-type=>'text/xml; charset=utf-8',
		-charset=>'utf-8',
	);
}

# Check for grammatical errors in the request
my @errs = validate_request(CGI::Vars());

my $mdp = param('metadataPrefix') || '';
my @mdfs = $h->ListMetadataFormats()->metadataFormat;
if( $mdp && !grep { $_->metadataPrefix } @mdfs ) {
	push @errs, new HTTP::OAI::Error(code=>'cannotDisseminateFormat',message=>"Dissemination as '$mdp' is not supported");
}
if( param('resumptionToken') ) {
	push @errs, new HTTP::OAI::Error(code=>'badArgument',message=>'This repository does not support flow-control');
}

my $r;
if( @errs ) {
	$r = HTTP::OAI::Response->new(
		requestURL=>self_url()
	);
	$r->errors(@errs);
} else {
	my %attr = CGI::Vars();
	my $verb = delete($attr{'verb'});
	$r = $h->$verb(%attr);
	$r->requestURL(self_url());
	if( 'Identify' eq $verb && ref($r) eq 'HTTP::OAI::Identify' ) {
		$r->baseURL(url());
	}
}

$r->set_handler(XML::SAX::Writer->new(Output=>\*STDOUT));
$r->generate;
