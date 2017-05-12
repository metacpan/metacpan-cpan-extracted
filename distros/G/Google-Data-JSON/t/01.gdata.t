#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 51;
#use Test::NoWarnings;
use File::Slurp;
use Google::Data::JSON qw( gdata );

## From XML

my $gdata = Google::Data::JSON->new(file => 't/samples/feed.atom');
isa_ok $gdata, 'Google::Data::JSON';

my $atom = $gdata->as_atom;
is $atom->title, 'Test Feed';
my @entries = $atom->entries;
is $entries[0]->title, 'Test Entry 1';
is $entries[1]->title, 'Test Entry 2';

my $hash = $gdata->as_hash;
is $hash->{feed}{title}{'$t'}, 'Test Feed';
is $hash->{feed}{'openSearch$startIndex'}{'$t'}, '1';
is $hash->{feed}{entry}[0]{title}{'$t'}, 'Test Entry 1';
is $hash->{feed}{entry}[1]{title}{'$t'}, 'Test Entry 2';

my $json = $gdata->as_json;
like $json, qr{"title":\{"\$t":"Test Feed"\}};
like $json, qr{"openSearch\$startIndex":\{"\$t":"1"\}};
like $json, qr{"title":\{"\$t":"Test Entry 1"\}};
like $json, qr{"title":\{"\$t":"Test Entry 2"\}};

my $xml = read_file 't/samples/feed.atom';
$gdata = Google::Data::JSON->new(xml => $xml);
isa_ok $gdata, 'Google::Data::JSON';


## From XML::Atom object

$gdata = Google::Data::JSON->new(atom => $atom);
isa_ok $gdata, 'Google::Data::JSON';

$xml = $gdata->as_xml;
like $xml, qr{<title>Test Feed</title>};
like $xml, qr{<openSearch:startIndex>1</openSearch:startIndex>};
like $xml, qr{<title>Test Entry 1</title>};
like $xml, qr{<title>Test Entry 1</title>};

$hash = $gdata->as_hash;
is $hash->{feed}{title}{'$t'}, 'Test Feed';
is $hash->{feed}{'openSearch$startIndex'}{'$t'}, '1';
is $hash->{feed}{entry}[0]{title}{'$t'}, 'Test Entry 1';
is $hash->{feed}{entry}[1]{title}{'$t'}, 'Test Entry 2';

$json = $gdata->as_json;
like $json, qr{"title":\{"\$t":"Test Feed"\}};
like $json, qr{"openSearch\$startIndex":\{"\$t":"1"\}};
like $json, qr{"title":\{"\$t":"Test Entry 1"\}};
like $json, qr{"title":\{"\$t":"Test Entry 2"\}};


## From JSON

$gdata = Google::Data::JSON->new(file => 't/samples/feed.json');
isa_ok $gdata, 'Google::Data::JSON';

$hash = $gdata->as_hash;
is $hash->{feed}{title}{'$t'}, 'Test Feed';
is $hash->{feed}{'openSearch$startIndex'}{'$t'}, '1';
is $hash->{feed}{entry}[0]{title}{'$t'}, 'Test Entry 1';
is $hash->{feed}{entry}[1]{title}{'$t'}, 'Test Entry 2';

$xml = $gdata->as_xml;
like $xml, qr{<title>Test Feed</title>};
like $xml, qr{<openSearch:startIndex>1</openSearch:startIndex>};
like $xml, qr{<title>Test Entry 1</title>};
like $xml, qr{<title>Test Entry 1</title>};

$atom = $gdata->as_atom;
is $atom->title, 'Test Feed';
@entries = $atom->entries;
is $entries[0]->title, 'Test Entry 1';
is $entries[1]->title, 'Test Entry 2';

$json = read_file 't/samples/feed.json';
$gdata = Google::Data::JSON->new(json => $json);
isa_ok $gdata, 'Google::Data::JSON';


## From Perl HASH

$gdata = Google::Data::JSON->new(hash => $hash);
isa_ok $gdata, 'Google::Data::JSON';

$json = $gdata->as_json;
like $json, qr{"title":\{"\$t":"Test Feed"\}};
like $json, qr{"openSearch\$startIndex":\{"\$t":"1"\}};
like $json, qr{"title":\{"\$t":"Test Entry 1"\}};
like $json, qr{"title":\{"\$t":"Test Entry 2"\}};

$xml = $gdata->as_xml;
like $xml, qr{<title>Test Feed</title>};
like $xml, qr{<openSearch:startIndex>1</openSearch:startIndex>};
like $xml, qr{<title>Test Entry 1</title>};
like $xml, qr{<title>Test Entry 1</title>};

$atom = $gdata->as_atom;
is $atom->title, 'Test Feed';
@entries = $atom->entries;
is $entries[0]->title, 'Test Entry 1';
is $entries[1]->title, 'Test Entry 2';
