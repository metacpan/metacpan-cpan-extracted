use strict; use warnings;

########## SETUP ##########

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 39;
use Cwd qw(chdir getcwd);
use File::Basename qw(basename);
use File::Copy;
BEGIN { use_ok('EBook::Tools',qw(:all)) };

# Set this to 1 or 2 to stress the debugging code, but expect lots of
# output.
$EBook::Tools::debug = 0;

my ($ebook1,$ebook2,$ebook3);
my ($meta1,$meta2,$dcmeta1,$dcmeta2);
my @elementnames;
my @elements;
my @strings;
my $exitval;
my $temp;

my @dcexpected1 = (
    "dc:Identifier",
    "dc:Identifier",
    "dc:Identifier",
    "dc:Title",
    "dc:Creator",
    "dc:Creator",
    "dc:Publisher",
    "dc:Date",
    "dc:Date",
    "dc:Date",
    "dc:Date",
    "dc:Type",
    "dc:Format",
    "dc:Language",
    "dc:Language",
    "dc:Rights"
    );

my @metastruct_expected1 = (
    "dc-metadata",
    "dc:Identifier",
    "dc:title",
    "dc:creator",
    "dc:Creator",
    "dc:creator",
    "dc:publisher",
    "dc:date",
    "dc:Date",
    "dc:date",
    "dc:Date",
    "dc:Type",
    "dc:format",
    "dc:identifier",
    "dc:identifier",
    "dc:identifier",
    "dc:identifier",
    "dc:language",
    "dc:Language",
    "dc:rights",
    "dc:subject",
    "dc:Subject",
    "dc:identifier",
    "x-metadata",
    );

my @metastruct_expected2 = (
    "dc-metadata",
    "dc:Identifier",
    "dc:Title",
    "dc:Creator",
    "dc:Creator",
    "dc:Creator",
    "dc:Publisher",
    "dc:Date",
    "dc:Date",
    "dc:Date",
    "dc:Date",
    "dc:Type",
    "dc:Format",
    "dc:Identifier",
    "dc:Identifier",
    "dc:Identifier",
    "dc:Identifier",
    "dc:Language",
    "dc:Language",
    "dc:Rights",
    "dc:Subject",
    "dc:Subject",
    "dc:Identifier",
    "x-metadata",
    );

my @metastruct_expected_opf20 = (
    "dc:identifier",
    "dc:identifier",
    "dc:identifier",
    "dc:title",
    "dc:creator",
    "dc:creator",
    "dc:publisher",
    "dc:date",
    "dc:date",
    "dc:date",
    "dc:date",
    "dc:type",
    "dc:format",
    "dc:language",
    "dc:language",
    "dc:rights",
    );

########## TESTS ##########

ok( (basename(getcwd()) eq 't') || chdir('t/'), "Working in 't/" ) or die;

copy('testopf-emptyuid.xml','emptyuid.opf') or die("Could not copy: $!");
copy('testopf-missingfwid.xml','missingfwid.opf') or die("Could not copy: $!");

$ebook1 = EBook::Tools->new('missingfwid.opf') or die;
is($ebook1->twigroot->att('unique-identifier'),undef,
   'missingfwid.opf really missing unique-identifier') or die;
$ebook2 = EBook::Tools->new('emptyuid.opf') or die;
is($ebook2->twigroot->att('unique-identifier'),'emptyUID',
   'new(): emptyuid.opf found') or die;

# fix_oeb12()
ok($ebook1->fix_oeb12,'fix_oeb12(): successful call');
ok($meta1 = $ebook1->twigroot->first_child('metadata'),'fix_oeb12(): metadata found');
ok($dcmeta1 = $meta1->first_child('dc-metadata'),'fix_oeb12(): dc-metadata found');
ok(@elements = $dcmeta1->children,'fix_oeb12(): DC elements found');
undef @elementnames;
foreach my $el (@elements) { push(@elementnames,$el->gi); }
is_deeply(\@elementnames,\@dcexpected1,
          'fix_oeb12(): DC elements found in expected order');


ok($ebook2->fix_metastructure_oeb12,
   'fix_metastructure_oeb12(): successful call');
ok($meta2 = $ebook2->twigroot->first_child('metadata'),
   'fix_metastructure_oeb12(): metadata found');
ok(@elements = $meta2->children,
   'fix_metastructure_oeb12(): metadata subelements found');
undef @elementnames;
foreach my $el (@elements) { push(@elementnames,$el->gi); }
is_deeply(\@elementnames,\@metastruct_expected1,
          'fix_metastructure_oeb12(): subelements found in expected order');

ok($ebook2->fix_oeb12_dcmetatags,'fix_oeb12_dcmetatags(): successful call');
ok(@elements = $meta2->children,'fix_oeb12_dcmetatags(): DC elements found');
undef @elementnames;
foreach my $el (@elements) { push(@elementnames,$el->gi); }
is_deeply(\@elementnames,\@metastruct_expected2,
          'fix_oeb12_dcmetatags(): DC elements found in expected order');

# fix_opf20()
ok($ebook1->fix_opf20,'fix_opf20(): successful call');
is($ebook1->twigroot->att('xmlns'),'http://www.idpf.org/2007/opf',
   'fix_opf20(): package xmlns set correctly');
is($ebook1->twigroot->att('version'),'2.0',
   'fix_opf20(): package version set correctly');
is($ebook1->twigroot->att('unique-identifier'),'FWID',
   'fix_opf20(): unique-identifier set to FWID');
ok($meta1 = $ebook1->twigroot->first_child('metadata'),
   'fix_opf20(): metadata found');
is($dcmeta1 = $meta1->first_child('dc-metadata'),undef,
   'fix_opf20(): dc-metadata removed');
ok(@elements = $meta1->children,'fix_opf20(): metadata children found');
undef @elementnames;
foreach my $el (@elements) { push(@elementnames,$el->gi); }
is_deeply(\@elementnames,\@metastruct_expected_opf20,
          'fix_opf20(): metadata elements found in expected order');

# fix_packageid()
# We want to test this independently of the fix_packageid calls in
# fix_oeb12 and fix_opf20 above, so initialize new books.
$ebook3 = EBook::Tools->new('missingfwid.opf') or die;
is($ebook3->twigroot->att('unique-identifier'),undef,
   'missingfwid.opf still really missing unique-identifier') or die;
ok($ebook3->fix_packageid,'fix_packageid[missing]: successful call');
is($ebook3->twigroot->att('unique-identifier'),'FWID',
   'fix_packageid[missing]: FWID found');
$ebook3 = EBook::Tools->new('emptyuid.opf') or die;
is($ebook3->twigroot->att('unique-identifier'),'emptyUID',
   'new(): emptyuid.opf still found intact') or die;
ok($ebook3->fix_packageid,'fix_packageid[blank]: successful call');
is($ebook3->twigroot->att('unique-identifier'),'UID',
   'fix_packageid[blank]: UID found');
is($ebook3->twigroot->att('xmlns'),'http://www.idpf.org/2007/opf',
   'fix_opf20(): package xmlns still set correctly');
is($ebook3->twigroot->att('version'),'2.0',
   'fix_opf20(): package version still set correctly');


# fix_dates() -- Not a comprehensive date test.  See 10-fix_datestring.t
ok($ebook1->fix_dates,'fix_dates(): successful call');
is($ebook1->twigroot
   ->first_descendant('dc:date[@opf:event="creation"]')->text,'2008-01-01',
   'fixdate(): YYYY-01-01 not clobbered');
is($ebook1->twigroot
   ->first_descendant('dc:date[@opf:event="publication"]')->text,'2008-03',
   'fixdate(): MM/01/YYYY properly handled');
is($ebook1->twigroot
   ->first_descendant('dc:date[@opf:event="badfebday"]')->text,'2/31/2004',
   'fixdate(): invalid day not touched');
is($ebook1->twigroot
   ->first_descendant('dc:date[@opf:event="YYYY-xx-DD"]')->text,'2009-xx-01',
   'fixdate(): invalid datestring not touched');

ok($ebook1->save,'save() of missingfwid.opf returned successfully');
ok($ebook2->save,'save() of emptyuid.opf returned successfully');

########## CLEANUP ##########

unlink('emptyuid.opf');
unlink('missingfwid.opf');
