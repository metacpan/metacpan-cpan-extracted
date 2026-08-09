#!/usr/bin/perl -w 

use strict;
use warnings;
use v5.10;
use lib 'lib', '../lib'; # able to run prove in project dir and .t locally

use Test::More tests => 4;

use_ok('File::URIList');
is(File::URIList->media_subtype, 'text/uri-list', 'media subtype as string');
my $media_subtype = File::URIList->media_subtype('Data::Identifier');
isa_ok($media_subtype, 'Data::Identifier');
is($media_subtype->ise, 'ceecde0d-4fbe-595f-92a5-b792692d341f', 'ISE for media subtype');

exit 0;
