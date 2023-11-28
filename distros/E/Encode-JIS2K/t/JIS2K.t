BEGIN {
    if ($ENV{'PERL_CORE'}){
        chdir 't';
        unshift @INC, '../lib';
    }
    require Config; Config->import();
    if ($Config{'extensions'} !~ /\bEncode\b/) {
      print "1..0 # Skip: Encode was not built\n";
      exit 0;
    }
    if (ord("A") == 193) {
	print "1..0 # Skip: EBCDIC\n";
	exit 0;
    }
    $| = 1;
}

use strict;
# Adjust the number here!
use Test::More tests => 19;
#use Test::More qw(no_plan);

use Encode;
use_ok('Encode::JIS2K');

use File::Basename;
use File::Spec;
use File::Compare qw(compare_text);
our $DEBUG = shift || 0;

my %Charset =
    (
     'x0213-1'     => [qw(euc-jisx0213 shiftjisx0213 iso-2022-jp-3)],
     'x0213-2'     => [qw(euc-jisx0213 shiftjisx0213 iso-2022-jp-3)],
    );

my $dir = dirname(__FILE__);
my $seq = 1;

for my $charset (sort keys %Charset){
    my ($src, $uni, $dst, $txt);

    my $transcoder = find_encoding($Charset{$charset}[0]) or die;

    my $src_enc = File::Spec->catfile($dir,"$charset.enc");
    my $src_utf = File::Spec->catfile($dir,"$charset.utf");
    my $dst_enc = File::Spec->catfile($dir,"$$.enc");
    my $dst_utf = File::Spec->catfile($dir,"$$.utf");


    open $src, "<$src_enc" or die "$src_enc : $!";
    # binmode($src); # not needed! 

    $txt = join('',<$src>);
    close($src);
    
    eval{ $uni = $transcoder->decode($txt, 1) }; 
    $@ and print $@;
    ok(defined($uni),  "decode $charset"); $seq++;
    unless(is(length($txt),0, "decode $charset completely")){
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

    eval{ $txt = $transcoder->encode($uni,1) };    
    $@ and print $@;
    ok(defined($txt),   "encode $charset"); $seq++;
    unless(is(length($uni), 0, "encode $charset completely")){
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
	is($uni, decode($canon, encode($canon, $uni)), 
	   "RT/$charset/$canon");
	$seq++;
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
