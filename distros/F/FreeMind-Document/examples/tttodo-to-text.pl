#!/usr/bin/env perl

use v5.10.1;
use strict;
use warnings;

use FreeMind::Document;

my $document = "FreeMind::Document"->load(location => "examples/tttodo.mm");
say $document->toText;
