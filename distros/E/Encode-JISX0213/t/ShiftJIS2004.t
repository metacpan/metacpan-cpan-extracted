#-*- perl -*-
#-*- coding: us-ascii -*-

use strict;
use warnings;
use File::Basename;
use File::Spec;
use File::Compare qw(compare_text);
use Test::More tests => 3;

BEGIN { use_ok('Encode::ShiftJIS2004') };

my $charset = 'shift jis 2004';

my $dir = dirname(__FILE__);
my $src_enc = File::Spec->catfile($dir,"shiftjis2004.enc");
my $src_utf = File::Spec->catfile($dir,"shiftjis2004.utf");
my $dst_enc = File::Spec->catfile($dir,"$$.enc");
my $dst_utf = File::Spec->catfile($dir,"$$.utf");

{
open my $src, '<', $src_enc or die "$src_enc: $!";
my $txt = join '', <$src>;
close $src;
my $uni;
eval { $uni = Encode::encode_utf8(Encode::decode($charset, $txt, 1)) };
$@ and print $@;
open my $dst, '>', $dst_utf;
print $dst $uni;
close $dst;
is(compare_text($src_utf, $dst_utf), 0, "decode")
    and unlink $dst_utf;
}

{
open my $src, '<', $src_utf or die "$src_utf: $!";
my $uni = join '', <$src>;
close $src;
my $txt;
eval { $txt = Encode::encode($charset, Encode::decode_utf8($uni), 1) };
$@ and print $@;
open my $dst, '>', $dst_enc;
print $dst $txt;
close $dst;
is(compare_text($src_enc, $dst_enc), 0, "encode")
    and unlink $dst_enc;
}

