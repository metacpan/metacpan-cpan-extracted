# This is a test for module Gzip::Faster.

use warnings;
use strict;
use FindBin '$Bin';
use Test::More;
use Gzip::Faster ':all';

my $tests = 'test this';
my $zipped = gzip ($tests);
my $unzipped = gunzip ($zipped);
is ($unzipped, $tests, "round trip with gzip and gunzip");
my $deflated = deflate ($tests);
my $inflated = inflate ($deflated);
is ($inflated, $tests, "round trip with deflate and inflate");
is ($unzipped, $tests, "round trip with gzip and gunzip");
my $raw_deflated = deflate_raw ($tests);
my $raw_inflated = inflate_raw ($raw_deflated);
is ($raw_inflated, $tests, "round trip with deflate_raw and inflate_raw");
# Test for ungzipped input in gunzip.
eval {
    gunzip ('ragamuffin');
};
ok ($@, "error with ungzipped input");
like ($@, qr/Data input to inflate is not in libz format/,
      "got correct error message");

use utf8;
my $kujira = '鯨';
if (! utf8::is_utf8 ($kujira)) {
    die "Sanity check failed";
}

my $gf1 = Gzip::Faster->new ();
# round trips involving object and non-object
my $rt;
my $input = '';
for (0..10000) {
    $input .= (0..9)[int (rand () * 10)];
}
#print "$input\n";
eval {
    $rt = gunzip ($gf1->zip ($input));
};
ok (! $@, "zip method doesn't crash");
if ($@) {
    note ("'$@'");
}
ok ($rt, "Got round trip value");
is ($rt, $input, "Round trip is OK");
eval {
    $rt = $gf1->unzip (gzip ($input));
};
ok (! $@, "unzip method doesn't crash");
if ($@) {
    note ($@);
}
ok ($rt, "Got round trip value");
is ($rt, $input, "Round trip is OK");


my $gfraw = Gzip::Faster->new ();
$gfraw->raw (1);
eval {
    $rt = inflate_raw ($gfraw->zip ($input));
};
ok (! $@, "zip method doesn't crash");
if ($@) {
    note ("'$@'");
}
ok ($rt, "Got round trip value");
is ($rt, $input, "Round trip is OK");
eval {
    $rt = $gfraw->unzip (deflate_raw ($input));
};
ok (! $@, "unzip method doesn't crash");
if ($@) {
    note ($@);
}
ok ($rt, "Got round trip value");
is ($rt, $input, "Round trip is OK");

my $gf = Gzip::Faster->new ();
$gf->copy_perl_flags (1);
ok (utf8::is_utf8 ($gf->unzip ($gf->zip ($kujira))), "UTF-8 round trip");

# This tests the converse of the above.

no utf8;
my $iruka = '海豚';
if (utf8::is_utf8 ($iruka)) {
    die "Sanity check failed";
}
ok (! utf8::is_utf8 ($gf->unzip ($gf->zip ($iruka))), "no UTF-8 round trip");

my $f = "$FindBin::Bin/gzip-faster.t";
my $fgz = "$f.gz";
my $zippedf = gzip_file ($f);
ok ($zippedf, "Got gzipped file from $f");
open my $out, ">:raw", $fgz or die $!;
print $out $zippedf;
close $out or die $!;
my $plain = gunzip_file ($fgz);
ok ($plain, "Got back contents from $fgz");
if (-f $fgz) {
    unlink ($fgz);
}

# This tests that Z_BUF_ERROR is ignored. The file "index.html.gz" is
# deliberately chosen to be a file which trips a Z_BUF_ERROR.

gunzip_file ("$FindBin::Bin/index.html.gz");

for my $test (0, 10101) {
    my $binary = pack "N", $test;
    my $gzipped_binary = gzip ($binary);
    my $ungzipped_binary = gunzip ($gzipped_binary);
    is ($ungzipped_binary, $binary, "Round trip with $test as packed");
    my $unpacked_ungzipped_binary = unpack "N", $ungzipped_binary;
    cmp_ok ($unpacked_ungzipped_binary, '==', $test,
	    "Round trip with $test ungzipped and unpacked");
}

#  ____       _      __ _ _                                        
# / ___|  ___| |_   / _(_) | ___   _ __   __ _ _ __ ___   ___  ___ 
# \___ \ / _ \ __| | |_| | |/ _ \ | '_ \ / _` | '_ ` _ \ / _ \/ __|
#  ___) |  __/ |_  |  _| | |  __/ | | | | (_| | | | | | |  __/\__ \
# |____/ \___|\__| |_| |_|_|\___| |_| |_|\__,_|_| |_| |_|\___||___/
                                                                 
# Test adding names with the object.

my $fname = 'Philip Marlowe';
my $text = 'Moose Malloy';
my $gfnamein = Gzip::Faster->new ();
my $gfnameout = Gzip::Faster->new ();
$gfnamein->file_name ($fname);
my $zippedwithname = $gfnamein->zip ($text);
my $outwithname = $gfnameout->unzip ($zippedwithname);
is ($outwithname, $text, "Output text with name is OK");
my $name_out = $gfnameout->file_name ();
is ($name_out, $fname, "Got file name back");

# Test setting file names in gzip_to_file and gunzip_file and gzip_file.

my $filewname = 'file-name-file';
my $filename = "has-name.gz";
gzip_to_file ($input, $filename, file_name => $filewname);
my $outname;
gunzip_file ($filename, file_name => \$outname);
is ($outname, $filewname, "Retrieved file name from file");

# $filename is unlinked below, underneath the check for warnings on
# not using a scalar reference.

my $named = gzip_file ($0, file_name => $filewname);
my $gfnametest = Gzip::Faster->new ();
$gfnametest->unzip ($named);
is ($gfnametest->file_name (), $filewname,
    "Retrieved file name with gzip_file");

#  __  __           _   _   _                
# |  \/  | ___   __| | | |_(_)_ __ ___   ___ 
# | |\/| |/ _ \ / _` | | __| | '_ ` _ \ / _ \
# | |  | | (_) | (_| | | |_| | | | | | |  __/
# |_|  |_|\___/ \__,_|  \__|_|_| |_| |_|\___|
#                                           

gunzip_file ("$Bin/index.html.gz", mod_time => \my $mod_time);
ok ($mod_time != 0, "Got modification time");
ok ($mod_time == 1396598505, "Got correct modification time");

# __        __               _                 
# \ \      / /_ _ _ __ _ __ (_)_ __   __ _ ___ 
#  \ \ /\ / / _` | '__| '_ \| | '_ \ / _` / __|
#   \ V  V / (_| | |  | | | | | | | | (_| \__ \
#    \_/\_/ \__,_|_|  |_| |_|_|_| |_|\__, |___/
#                                    |___/     


my $warning;
$SIG{__WARN__} = sub {
    $warning = $_[0];
};
$warning = undef;
my $gflevel = Gzip::Faster->new ();
$gflevel->level (-1);
my $out0 = $gflevel->zip ($input);
ok ($warning, "got warning");
like ($warning, qr/level/, "warning looks OK");
$warning = undef;
$gflevel->level (100);
ok ($warning, "got warning");
like ($warning, qr/level/, "warning looks OK");
my $out9 = $gflevel->zip ($input);
cmp_ok (length ($out0) , ">", length ($out9),
	"level 9 compression works better"); 
$warning = undef;
$gflevel->level ('monkey business');
ok ($warning, "got warning");
like ($warning, qr/numeric/, "warning looks OK");

$warning = undef;
my $undefout = gunzip (undef);
ok ($warning, "got warning");
like ($warning, qr/empty input/i, "Warning on empty input");

$warning = undef;
gunzip_file ($filename, file_name => 'monkeyshines');
ok ($warning, "got warning");
like ($warning, qr/scalar reference/, "Warning on non-reference");

$warning = undef;
gunzip_file ($filename, mod_time => 'monkeyshines');
ok ($warning, "got warning");
like ($warning, qr/scalar reference/, "Warning on non-reference");

my @subs = (\& inflate, \& inflate_raw, \& gunzip,
	    \& gzip, \& deflate, \& deflate_raw);

for my $sub (@subs) {
    $warning = undef;
    my $emptyout = &{$sub} ('');
    is ($emptyout, undef, "got undefined value (un)compressing empty string"); 
    ok ($warning, "got warning");
    like ($warning, qr/empty string/);
}

# Delete  the file now we have used it.

unlink ($filename);


done_testing ();
exit;
