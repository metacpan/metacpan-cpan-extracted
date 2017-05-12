#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 44;

use utf8;
BEGIN {
    use lib 'lib';
    use_ok('IMS::CP::Manifest');
}

my $manifest = IMS::CP::Manifest->new( file => 't/data/10_parse/imsmanifest.xml' );
isa_ok($manifest,'IMS::CP::Manifest');

# Verify that xmlns prefixes are present
is($manifest->xpc->lookupNs('cp'), 'http://www.imsglobal.org/xsd/imscp_v1p1', "IMS CP namespace mismatch");
is($manifest->xpc->lookupNs('lom'), 'http://www.imsglobal.org/xsd/imsmd_v1p2', "IMS LOM namespace mismatch");

isa_ok($manifest->title, 'IMS::LOM::LangString');
my $title_dump = <<'XML';
<imsmd:title>
  <imsmd:langstring xml:lang="no">Oppsummering</imsmd:langstring>
</imsmd:title>
XML
chomp($title_dump);
#diag($manifest->title->dump);
is($manifest->title->dump_xml, $title_dump, "title XML dump mismatch");
is($manifest->title->language, 'no', "manifest title language mismatch");
is($manifest->title->text, 'Oppsummering', "manifest title text mismatch");

isa_ok($manifest->organizations,'ARRAY');
my $org = $manifest->organizations->[0];
isa_ok($org, 'IMS::CP::Organization');

is($org->title, 'Oppsummering','organization title mismatch');

isa_ok($org->items, 'ARRAY');
ok( @{ $org->items } == 5, 'organization item count is not 5');

my $item0 = $org->items->[0];
isa_ok( $item0, 'IMS::CP::Organization::Item' );
is( $item0->id, '722716', "item0 id mismatch");
is( $item0->title->language, 'no', "item0 title language mismatch");
is( $item0->title->text, '8.1-XTRA Virkemiddel: Musikk, tempo og rytme', "item0 title text mismatch");

my $item4 = $org->items->[4];
isa_ok( $item4, 'IMS::CP::Organization::Item' );
is( $item4->id, '722762', "item4 id mismatch");
is( $item4->title->language, 'no', "item4 title language mismatch");
is( $item4->title->text, '8.5-XTRA Fra deler til helhet', "item4 title text mismatch");

my $res0 = $item0->resource;
isa_ok($res0, 'IMS::CP::Resource');
is( $res0->id, 'content_item_657075_722716', 'res0 id mismatch');
is( $res0->href, '8.1-XTRA Virkemiddel: Musikk, tempo og rytme/8.1 Virkemiddel: Musikk, tempo og rytme.html', "res0 href mismatch");
is( $res0->title->language, 'no', "res0 title language mismatch");
is( $res0->title->text, '8.1 Virkemiddel: Musikk, tempo og rytme', "res0 title text mismatch");
ok( @{ $res0->files } == 1, 'res0 file count is not 1');

my $res4 = $item4->resource;
isa_ok($res4, 'IMS::CP::Resource');
is( $res4->id, 'content_item_657075_722762', 'res4 id mismatch');
is( $res4->href, '8.5-XTRA Fra deler til helhet/8.5 Fra deler til helhet.html', "res4 href mismatch");
is( $res4->title->language, 'no', "res4 title language mismatch");
is( $res4->title->text, '8.5 Fra deler til helhet', "res4 title text mismatch");
ok( @{ $res4->files } == 1, 'res4 file count is not 1');

my $file0 = $res0->files->[0];
isa_ok( $file0, 'IMS::CP::Resource::File');
is( $file0->id, 'Stromgren-Gorri_Gorr', "file0 id mismatch");
is( $file0->href, 'resources/Gorri Gorri med Jo Stroemgren Co..flv', "file0 href mismatch");
is( $file0->title->language, 'no', "file0 title language mismatch");
is( $file0->title->text, 'Gorri Gorri med Jo Strømgren Co.', "file0 title text mismatch");

my $file4 = $res4->files->[0];
isa_ok( $file4, 'IMS::CP::Resource::File');
is( $file4->id, 'Stromgren-Tok_Pisin', "file4 id mismatch");
is( $file4->href, 'resources/Tok Pisin med Jo Stroemgren Co..flv', "file4 href mismatch");
is( $file4->title->language, 'no', "file4 title language mismatch");
is( $file4->title->text, 'Tok Pisin med Jo Strømgren Co.', "file4 title text mismatch");
my $file4_title_dump = <<'XML';
<imsmd:title>
  <imsmd:langstring xml:lang="no">Tok Pisin med Jo Strømgren Co.</imsmd:langstring>
</imsmd:title>
XML
chomp($file4_title_dump);
#diag($file4->title->dump);
is($file4->title->dump_xml, $file4_title_dump, "file4 title XML dump mismatch");

exit;

1;
