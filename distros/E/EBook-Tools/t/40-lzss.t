use strict; use warnings; use utf8;
use Cwd qw(chdir getcwd);
use Digest::MD5 qw(md5);
use File::Basename qw(basename);
use File::Path;    # Exports 'mkpath' and 'rmtree'
use Test::More tests => 6;
BEGIN { use_ok('EBook::Tools::LZSS',':all') };

my $cwd;
my $lzss;
my $md5 = Digest::MD5->new();

my $fh_rebtest;
my $fh_usconst;
my $compressed;
my $textref;

my %md5sums = (
    'rebtest' => 'DhHZauG6nwpwgNnlxiWlOQ',
    'usconst' => 'wZUe6q66PWlwu3tx6n/NEg',
    );

########## TESTS BEGIN ##########

ok( (basename(getcwd()) eq 't') || chdir('t/'), "Working in 't/" ) or die;
$cwd = getcwd();

ok($lzss = EBook::Tools::LZSS->new(lengthbits => 3,
                                   offsetbits => 14,
                                   windowstart => 1,
                                   verbose => 0),
   'LZSS->new(3,14,1) returns successfully');

open($fh_rebtest,'<:raw','imp/REBtestdoc-ETI.RES/DATA.FRK')
    or die(@!);
sysread($fh_rebtest,$compressed,-s 'imp/REBtestdoc-ETI.RES/DATA.FRK');
close($fh_rebtest);

$textref = $lzss->uncompress(\$compressed);
$md5->reset();
$md5->add($$textref);
ok($md5->b64digest eq $md5sums{'rebtest'},
   'REBTestdoc DATA.FRK uncompresses correctly');

#open($fh_rebtest,'>:raw','REBTest.txt')
#    or die(@!);
#print {*$fh_rebtest} $$textref;
#close($fh_rebtest);


open($fh_usconst,'<:raw','us-constitution.lzss')
    or die(@!);
sysread($fh_usconst,$compressed,-s 'us-constitution.lzss');
close($fh_usconst);

ok($lzss = EBook::Tools::LZSS->new(screwybits => 1,
                                   verbose => 0),
   'LZSS->new(screwybits => 1) returns successfully');

$textref = $lzss->uncompress(\$compressed);
$md5->reset();
$md5->add($$textref);
ok($md5->b64digest eq $md5sums{'usconst'},
   'US Constitution uncompresses correctly');

#open($fh_usconst,'>:raw','us-const.txt')
#    or die(@!);
#print {*$fh_usconst} $$textref;
#close($fh_usconst);
