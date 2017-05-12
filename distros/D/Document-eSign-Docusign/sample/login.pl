#!/usr/bin/perl

use warnings;
use strict;
use Document::eSign::Docusign;

my $ds = Document::eSign::Docusign->new(
	username => $ENV{DS_USERNAME},
	password => $ENV{DS_PASSWORD},
	integratorkey => $ENV{DS_INTEGRATORKEY},
	baseUrl => 'https://demo.docusign.net/restapi'
);

print $ds->accountid, "\n";
