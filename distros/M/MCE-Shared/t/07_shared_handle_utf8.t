#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Test::More;
use MCE::Signal qw( $tmp_dir );

BEGIN {
   use_ok 'MCE::Shared';
   use_ok 'MCE::Shared::Handle';
}

# https://sacred-texts.com/cla/usappho/sph02.htm (VII)

my $sappho_text =
   "ἔλθε μοι καὶ νῦν, χαλεπᾶν δὲ λῦσον\n".
   "ἐκ μερίμναν ὄσσα δέ μοι τέλεσσαι\n".
   "θῦμοσ ἰμμέρρει τέλεσον, σὐ δ᾽ αὔτα\n".
   "σύμμαχοσ ἔσσο.\n";

my $translation =
   "Come then, I pray, grant me surcease from sorrow,\n".
   "Drive away care, I beseech thee, O goddess\n".
   "Fulfil for me what I yearn to accomplish,\n".
   "Be thou my ally.\n";

## --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

# https://perldoc.perl.org/PerlIO.html

my ($buf, $fno, $ret1, $ret2, $ret3, $ret4, $ret5, $ret6, $ret7, $size) = ('');
my $tmp_file = "$tmp_dir/test.txt";
my $fh;

mce_open $fh, ">:raw:utf8", $tmp_file or die "open error: $!";

$fno = fileno $fh;
print $fh $sappho_text;

close $fh;

## --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

mce_open $fh, "<:raw:utf8", $tmp_file or die "open error: $!";

$ret1 = eof $fh;
$buf .= $_ while <$fh>;
$ret2 = eof $fh;
$ret3 = tell $fh;

seek $fh, 34, 0;
$ret4 = readline $fh; chomp $ret4;
$size = read $fh, $ret5, 8;
$ret6 = $ret5;

read $fh, $ret6, 3, 3;
$ret7 = getc $fh;  # " "
$ret7 = getc $fh;  # "ὄ"

close $fh;

like( $fno, qr/\A\d+\z/, "shared utf8 file, OPEN, FILENO, CLOSE" );
is( $buf, $sappho_text,  "shared utf8 file, PRINT, PRINTF, READLINE, WRITE" );

is( $ret1, "",                 "shared utf8 file, EOF (test 1)" );
is( $ret2, "1",                "shared utf8 file, EOF (test 2)" );
is( $ret3, "232",              "shared utf8 file, TELL" );
is( $ret4, "χαλεπᾶν δὲ λῦσον", "shared utf8 file, SEEK, READLINE" );
is( $ret5, "ἐκ μερίμ",         "shared utf8 file, READ" );
is( $ret6, "ἐκ ναν",           "shared utf8 file, READ offset" );
is( $ret7, "ὄ",                "shared utf8 file, GETC" );

## --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

mce_open $fh, ">:raw:utf8", $tmp_file or die "open error: $!";

print  $fh $ret4, "\n";
printf $fh "%s\n", $ret5;
print  $fh "$ret6\n";

close $fh;

mce_open $fh, "<:raw:utf8", $tmp_file or die "open error: $!";

$ret1 = readline($fh); chomp $ret1;
$ret2 = readline($fh); chomp $ret2;
$ret3 = readline($fh); chomp $ret3;

is( $ret1, $ret4, "shared utf8 file, READLINE 1" ); 
is( $ret2, $ret5, "shared utf8 file, READLINE 1" ); 
is( $ret3, $ret6, "shared utf8 file, READLINE 1" ); 

close $fh;

unlink $tmp_file if -f $tmp_file;

done_testing;

