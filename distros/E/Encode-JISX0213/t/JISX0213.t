#-*- perl -*-
#-*- coding: us-ascii -*-

use strict;
use Test::More tests => 45;

use Encode;
use_ok('Encode::JISX0213');
use_ok('Encode::ShiftJIS2004');

use File::Basename;
use File::Spec;
use File::Compare qw(compare_text);
our $DEBUG = shift || 0;

my %Charset =
    (
	'x0213-1-ascii' => [qw(euc-jis-2004 iso-2022-jp-2004)],
	'x0213-1-compatible' => [qw(iso-2022-jp-2004-compatible)],
	'x0213-1-strict' => [qw(iso-2022-jp-2004-strict)],
	'x0213-2' => [
	    qw(euc-jis-2004 shift_jis-2004 iso-2022-jp-2004
	    iso-2022-jp-2004-compatible iso-2022-jp-2004-strict
	    euc-jisx0213 iso-2022-jp-3)
	],
	'x0213-2000-1-ascii' => [qw(euc-jisx0213 iso-2022-jp-3)],
    );

my $dir = dirname(__FILE__);
my $seq = 1;

for my $charset (sort keys %Charset){
    my ($src, $uni, $dst, $txt);

    my $transcoder = Encode::find_encoding($Charset{$charset}[0]) or die;

    my $src_enc = File::Spec->catfile($dir, "$charset.enc");
    $src_enc =~ s/-(?:ascii|jis)(.*?)$/$1/;
    my $src_utf = File::Spec->catfile($dir, "$charset.utf");
    $src_utf =~ s/-(?:compatible|strict)(.*?)$/-ascii$1/;
    my $dst_enc = File::Spec->catfile($dir, "$$.enc");
    my $dst_utf = File::Spec->catfile($dir, "$$.utf");

    open $src, "<$src_enc" or die "$src_enc : $!";
    # binmode($src); # not needed! 

    $txt = join('',<$src>);
    close($src);
    
    eval{ $uni = $transcoder->decode($txt, 1) }; 
    $@ and print $@;
    ok(defined($uni), sprintf('decode %s by %s', $charset, $transcoder->name));
    $seq++;
    unless(is(length($txt), 0,
	sprintf('decode %s by %s completely', $charset, $transcoder->name))){
	$seq++;
	$DEBUG and dump_txt($txt, "t/$$.$seq");
    }else{
	$seq++
    }
    
    open $dst, ">$dst_utf" or die "$dst_utf : $!";
    if (PerlIO::Layer->find('perlio')){
	binmode($dst, ":utf8");
	print $dst $uni;
    }else{ # ugh!
	binmode($dst);
	my $raw = $uni; Encode::_utf8_off($raw);
	print $dst $raw;
    }

    close($dst); 
    is(compare_text($dst_utf, $src_utf), 0, "$dst_utf eq $src_utf")
	or ($DEBUG and rename $dst_utf, "$dst_utf.$seq");
    $seq++;
    
    open $src, "<$src_utf" or die "$src_utf : $!";
    if (PerlIO::Layer->find('perlio')){
	binmode($src, ":utf8");
	$uni = join('', <$src>);
    }else{ # ugh!
	binmode($src);
	$uni = join('', <$src>);
	Encode::_utf8_on($uni);
    }
    close $src;
    my $uni_orig = $uni;

    eval{ $txt = $transcoder->encode($uni,1) };    
    $@ and print $@;
    ok(defined($txt), sprintf('encode %s by %s', $charset, $transcoder->name));
    $seq++;
    unless(is(length($uni), 0,
	sprintf('encode %s by %s completely', $charset, $transcoder->name))){
	$seq++;
	$DEBUG and dump_txt($uni, "t/$$.$seq");
    }else{
	$seq++;
    }
    open $dst,">$dst_enc" or die "$dst_enc : $!";
    binmode($dst);
    print $dst $txt;
    close($dst); 
    is(compare_text($src_enc, $dst_enc), 0 => "$dst_enc eq $src_enc")
	or ($DEBUG and rename $dst_enc, "$dst_enc.$seq");
    $seq++;
    
    for my $canon (@{$Charset{$charset}}){
	$uni = $uni_orig;
	my $uni_dec = decode($canon, encode($canon, $uni));
	$uni = $uni_orig;
	unless (ok($uni eq $uni_dec, "RT/$charset/$canon")) {
	    $seq++;
	    $DEBUG and dump_txt(Encode::encode_utf8($uni_dec), "t/$$.$seq");
	} else {
	    $seq++;
	}
     }
    unlink($dst_utf, $dst_enc);
}

sub dump_txt{
    my ($txt, $file) = @_;
    open my $dst,">$file" or die "$file : $!";
    binmode($dst);
    print $dst $txt;
    close($dst);
}
