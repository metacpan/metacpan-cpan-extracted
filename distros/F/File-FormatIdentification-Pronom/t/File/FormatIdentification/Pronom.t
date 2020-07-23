#!/usr/bin/perl -w
use strict;
use warnings;
use diagnostics;

use Test::More tests => 9;
use Test::Exception;
use Test::File;
use Path::Tiny;
my $sigfile = path("t/DROID_SignatureFile_V93.xml");
my $ymlfile = path("t/DROID_SignatureFile_V93.xml.yaml");

### tests
BEGIN { use_ok("File::FormatIdentification::Pronom"); }
new_ok(
    "File::FormatIdentification::Pronom" =>
      [ { "droid_signature_filename" => $sigfile->absolute } ],
    "object 1"
);
file_exists_ok( $ymlfile->absolute, "'object 1' has auto stored file" );
$ymlfile->remove;
new_ok(
    "File::FormatIdentification::Pronom" => [
        {
            "droid_signature_filename" => $sigfile->absolute,
            "auto_store"               => 0
        }
    ],
    "object 2"
);
file_not_exists_ok( $ymlfile->absolute, "'object 2' has no auto stored file" );
my $obj3a = new_ok(
    "File::FormatIdentification::Pronom" => [
        {
            "droid_signature_filename" => $sigfile->absolute,
            "auto_store"               => 1
        }
    ],
    "object 3a"
);
file_exists_ok( $ymlfile->absolute, "'object 3a' has auto stored file" );
my $obj3b = new_ok(
    "File::FormatIdentification::Pronom" =>
      [ { "droid_signature_filename" => $sigfile->absolute } ],
    "object 3b'"
);
$ymlfile->remove;
is_deeply( $obj3b, $obj3a, "ensure 'obj3a' equals 'obj3b'" );
1;
