use strict; use warnings; use utf8;
use Cwd qw(chdir getcwd);
use Digest::MD5 qw(md5_base64);
use EBook::Tools;
use EBook::Tools::BISG;
use File::Basename qw(basename);
use File::Copy;
use File::Path;    # Exports 'mkpath' and 'rmtree'
use Test::More;
BEGIN
{
    if($ENV{'AUTOMATED_TESTING'})
    {
        plan skip_all => "Accurate unpacker tests rely on the BISG downloads that some automated testers can't handle.";
    }
    else
    {
        plan tests => 49;
        use_ok('EBook::Tools::Unpack');
        use_ok('EBook::Tools::BISG');
        use_ok('EBook::Tools::EReader',qw(:all));
        use_ok('EBook::Tools::Mobipocket',qw(:all));
        use_ok('EBook::Tools::MSReader',qw(:all));
        use_ok('EBook::Tools::PalmDoc',qw(:all));
    }
};

# Set this to 1 or 2 to stress the debugging code, but expect lots of
# output.
$EBook::Tools::debug = 0;


my $cwd;
my $ebook = EBook::Tools->new();
my $unpacker;
my @list;

my $md5 = Digest::MD5->new();
my %md5sums = (
    'resonance.png' => 'N0aTiJPQrsyTNRD8Iy0PQA',
    );

my $mobitest_description =
    '<P>Description line 1 — <EM>emphasized</EM> </P> <P>Description line 2 — <STRONG>a bold move </STRONG></P>';


########## TESTS BEGIN ##########

ok( (basename(getcwd()) eq 't') || chdir('t/'), "Working in 't/" ) or die;
$cwd = getcwd();


##### MOBIPOCKET #####
ok($unpacker = EBook::Tools::Unpack->new(
       'file' => 'mobi/mobitest.prc'),
   'new(file => mobi/mobitest.prc) returns successfully');
ok($unpacker->unpack,'unpack(mobi) returns successfully');
chdir($cwd);
ok(-d 'mobitest','unpack() created mobitest/');
ok(-f 'mobitest/content.opf','unpack() created mobitest/content.opf');
ok(-f 'mobitest/A Noncompliant OPF Test Sample.html',
   'unpack() created mobitest/A Noncompliant OPF Test Sample.html');

ok($ebook->init('mobitest/content.opf'),'content.opf parses');
is($ebook->title,'A Noncompliant OPF Test Sample',
   'content.opf title is correct');
is($ebook->primary_author,'Zed 1 Pobre',
   'content.opf author is correct');
@list = $ebook->contributor_list;
is_deeply(\@list, ['Me Myself'],
          'content.opf has correct contributors');
@list = $ebook->isbn_list;
is_deeply(\@list, ['0-9999-XXXX-1'],
          'content.opf has correct ISBNs');
@list = $ebook->subject_list;
is_deeply(\@list, ['Computing, Internet','Secondary subject','Education',
                   'COMPUTERS / General','EDUCATION / General','Computers'],
          'content.opf has correct subjects');
is($ebook->description,$mobitest_description,
   'content.opf has correct description');
@list = $ebook->publishers;
is_deeply(\@list, ['CPAN'],
          'content.opf has correct publishers');
is($ebook->date_list(event => 'publication'),'2008-10',
   'content.opf has correct publication date');
is($ebook->languages,'en',
   'content.opf has correct language');
is($ebook->element_list(cond => 'DictionaryInLanguage'),'de-at',
   'content.opf has correct DictionaryInLanguage');
is($ebook->element_list(cond => 'DictionaryOutLanguage'),'es-ar',
   'content.opf has correct DictionaryOutLanguage');
is($ebook->adult,'yes',
   'content.opf is flagged adult');
@list = $ebook->retailprice;
is_deeply(\@list, ['1.23','USD'],
          'content.opf has correct SRP');
@list = $ebook->manifest_hrefs;
is_deeply(\@list, ['A Noncompliant OPF Test Sample.html'],
          'content.opf has correct manifest');
@list = $ebook->spine_idrefs;
is_deeply(\@list, ['text-main'],
          'content.opf has correct spine');


##### MOBIPOCKET HUFF/CDIC #####
chdir($cwd);
ok($unpacker = EBook::Tools::Unpack->new(
    'file' => 'mobi/hufftest.mobi'),
   'new(file => mobi/hufftest.mobi) returns successfully');
ok($unpacker->unpack,'unpack(mobi/hufftest) returns successfully');
chdir($cwd);
ok(-d 'hufftest','unpack(mobi/hufftest.mobi) created hufftest/');
ok(-f 'hufftest/content.opf',
   'unpack(mobi/hufftest.mobi) created hufftest/content.opf');
ok(-f 'hufftest/Space Encyclopedia HUFFCDIC test.html',
   'unpack(mobi/hufftest.mobi) created hufftest/Space Encyclopedia HUFFCDIC test.html');
ok(-f 'hufftest/Space_Encycl-_HUFFCDIC_test-0001.jpg',
   'unpack(mobi/hufftest.mobi) created image');
ok($ebook->init('hufftest/content.opf'),'content.opf parses');
is($ebook->title,'Space Encyclopedia (HUFF/CDIC test)',
   'content.opf title is correct');
is($ebook->primary_author,'Mobipocket',
   'content.opf author is correct');

##### EREADER #####
chdir($cwd);
ok($unpacker = EBook::Tools::Unpack->new(
       'file' => 'ereader/ertest.pdb'),
   'new(file => ereader/ertest.pdb) returns successfully');
ok($unpacker->unpack,'unpack(ereader) returns successfully');
ok(-d 'ertest','unpack() created ertest/');
ok(-f 'ertest/content.opf','created ertest/content.opf');
ok(-f 'ertest/ertest.pml','created ertest/ertest.pml');
ok(-d 'ertest/ertest_img','unpack() created ertest/ertest_img');
open(my $fh_md5,'<:raw','ertest/ertest_img/resonance.png')
    or die("Unable to open 'ertest/ertest_img/resonance.png': @!");
$md5->addfile($fh_md5);
close($fh_md5);
is($md5->b64digest,$md5sums{'resonance.png'},
   'unpack() created ertest/ertest_img/resonance.png with correct checksum');
ok($ebook->init('ertest/content.opf'),'content.opf parses');
is($ebook->title,'eReader Test',
   'content.opf title is correct');
is($ebook->primary_author,'Zed Pobre',
   'content.opf author is correct');
@list = $ebook->publishers;
is_deeply(\@list, ['CPAN'],
          'content.opf has correct publishers');
is($ebook->rights,"Copyright \x{a9} 2008 Zed Pobre",
   'content.opf has correct rights (in UTF-8)');

########## CLEANUP ##########

chdir($cwd);
rmtree('ertest');
rmtree('hufftest');
rmtree('mobitest');
