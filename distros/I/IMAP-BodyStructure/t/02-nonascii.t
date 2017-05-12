#! /usr/bin/perl -w
use strict;

use Test::NoWarnings;
use Test::More tests => 3;

use IMAP::BodyStructure;

ok(my $bs = IMAP::BodyStructure->new(qq|(("text" "plain" ("charset" "KOI8-R") NIL NIL "8bit" 265 7 NIL NIL NIL)("application" "msword" ("name" {16}\r\n?? ??? ?????.doc) NIL NIL "base64" 30130 NIL ("attachment" ("filename" {16}\r\n?? ??? ?????.doc)) NIL) "mixed" ("boundary" "----yhZZhMGe-nrBcxM6r3syK6tCK:1045583399") NIL NIL)|), 'parse body with unencoded literal filenames');
is($bs->parts(1)->filename, '?? ??? ?????.doc', 'filename');
