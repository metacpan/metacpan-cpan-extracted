package HTTP::OAI;

use strict;

our $VERSION = '4.10';

use constant OAI_NS => 'http://www.openarchives.org/OAI/2.0/';

# perlcore
use Carp;
use Encode;

# http related stuff
use URI;
use HTTP::Headers;
use HTTP::Request;
use HTTP::Response;
require LWP::UserAgent;
require LWP::MemberMixin;

# xml related stuff
use XML::SAX;
use XML::SAX::ParserFactory;
use XML::LibXML;
use XML::LibXML::SAX;
use XML::LibXML::SAX::Parser;
use XML::LibXML::SAX::Builder;

use HTTP::OAI::SAX::Driver;
use HTTP::OAI::SAX::Text;

# debug
use HTTP::OAI::Debug;
use HTTP::OAI::SAX::Trace;

# generic superclasses
use HTTP::OAI::SAX::Base;
use HTTP::OAI::MemberMixin;
use HTTP::OAI::Verb;
use HTTP::OAI::PartialList;

# utility classes
use HTTP::OAI::Response;

# oai data objects
use HTTP::OAI::Metadata; # Super class of all data objects
use HTTP::OAI::Error;
use HTTP::OAI::Header;
use HTTP::OAI::MetadataFormat;
use HTTP::OAI::Record;
use HTTP::OAI::ResumptionToken;
use HTTP::OAI::Set;

# oai verbs
use HTTP::OAI::GetRecord;
use HTTP::OAI::Identify;
use HTTP::OAI::ListIdentifiers;
use HTTP::OAI::ListMetadataFormats;
use HTTP::OAI::ListRecords;
use HTTP::OAI::ListSets;

# oai agents
use HTTP::OAI::UserAgent;
use HTTP::OAI::Harvester;
use HTTP::OAI::Repository;

$HTTP::OAI::Harvester::VERSION = $VERSION;

if( $ENV{HTTP_OAI_TRACE} )
{
	HTTP::OAI::Debug::level( '+trace' );
}
if( $ENV{HTTP_OAI_SAX_TRACE} )
{
	HTTP::OAI::Debug::level( '+sax' );
}

our %VERSIONS = (
	'http://www.openarchives.org/oai/1.0/oai_getrecord' => '1.0',
	'http://www.openarchives.org/oai/1.0/oai_identify' => '1.0',
	'http://www.openarchives.org/oai/1.0/oai_listidentifiers' => '1.0',
	'http://www.openarchives.org/oai/1.0/oai_listmetadataformats' => '1.0',
	'http://www.openarchives.org/oai/1.0/oai_listrecords' => '1.0',
	'http://www.openarchives.org/oai/1.0/oai_listsets' => '1.0',
	'http://www.openarchives.org/oai/1.1/oai_getrecord' => '1.1',
	'http://www.openarchives.org/oai/1.1/oai_identify' => '1.1',
	'http://www.openarchives.org/oai/1.1/oai_listidentifiers' => '1.1',
	'http://www.openarchives.org/oai/1.1/oai_listmetadataformats' => '1.1',
	'http://www.openarchives.org/oai/1.1/oai_listrecords' => '1.1',
	'http://www.openarchives.org/oai/1.1/oai_listsets' => '1.1',
	'http://www.openarchives.org/oai/2.0/' => '2.0',
	'http://www.openarchives.org/oai/2.0/static-repository' => '2.0s',
);

1;

__END__

=head1 NAME

HTTP::OAI - API for the OAI-PMH

=begin markdown

# STATUS

[![Build Status](https://travis-ci.org/LibreCat/perl-oai-lib.svg?branch=master)](https://travis-ci.org/LibreCat/perl-oai-lib)

=end markdown

=head1 DESCRIPTION

This is a stub module, you probably want to look at
L<HTTP::OAI::Harvester|HTTP::OAI::Harvester> or
L<HTTP::OAI::Repository|HTTP::OAI::Repository>.

=head1 SEE ALSO

You can find links to this and other OAI tools (perl, C++, java) at:
http://www.openarchives.org/pmh/tools/.

Ed Summers L<Net::OAI::Harvester> module.

=head1 LICENSE

Copyright 2004-2010 Tim Brody <tdb2@ecs.soton.ac.uk>, University of
Southampton.

This module is free software and is released under the BSD License (see
LICENSE).
