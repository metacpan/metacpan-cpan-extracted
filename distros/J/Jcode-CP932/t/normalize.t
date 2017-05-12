#!/usr/bin/perl

use strict;
use Jcode::CP932;
use Test;
BEGIN { plan tests => 25 }

my $seq = 0;
sub myok{ # overloads Test::ok;
    my ($a, $b, $comment) = @_;
    print "not " if $a ne $b;
    ++$seq;
    print "ok $seq # $comment\n";
}

my %code2str;
for my $enc (qw/euc sjis jis utf8 ucs2/){
    my $file = "t/table.$enc";
    open F, $file or die "$file:$!";
    binmode F;
    read F, $code2str{$enc}, -s $file;
    close F;
}

use Encode::EUCJPMS;
my %cp932_enc = (
	utf8 => 'utf8',
	sjis => 'cp932',
	euc  => 'cp51932',
	jis  => 'cp50221',
	ucs2 => 'ucs2',
);
my %code2str_cp932;
for my $enc (qw/utf8 sjis euc jis ucs2/){
    my $file = "t/cp932-table.$enc";
    open F, $file or die "$file:$!";
    binmode F;
    read F, $code2str_cp932{ $cp932_enc{$enc} }, -s $file;
    close F;
}

my @code2str = keys %code2str;
check("cp932-table");

sub check {
    my $table = shift;
    Jcode::CP932->set_jname2e(
	       sjis        => 'shiftjis',
	       euc         => 'euc-jp',
	       jis         => '7bit-jis',
	       iso_2022_jp => 'iso-2022-jp',
	       ucs2        => 'UTF-16BE',
    );
    $Jcode::CP932::NORMALIZE = \&Jcode::CP932::normalize_jis;
    
    for my $icode (keys %code2str_cp932) {
	for my $ocode (@code2str){
	    my $str = $code2str_cp932{$icode};
	    my $obj = Jcode::CP932->new($str, $icode);
	    my $evo = eval qq{\$obj->$ocode}; # for perl 5.00x
	    myok($evo, $code2str{$ocode},
		 "$table:Jcode::CP932->new(\$str, '$icode')->$ocode");
	}
    }
}

__END__
