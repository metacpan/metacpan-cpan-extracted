#!/usr/bin/perl -w

use strict;
use Jcode::CP932;
use Test;
BEGIN { plan tests => 4 }

my $seq = 0;
sub myok{ # overloads Test::ok;
    my ($a, $b, $comment) = @_;
    print "not " if $a ne $b;
    ++$seq;
    print "ok $seq # $comment\n";
}

my $file;

my $hiragana; $file = "t/cp932-hiragana.euc"; open F, $file or die "$file:$!";
read F, $hiragana, -s $file;

my $zenkaku; $file = "t/zenkaku.euc"; open F, $file or die "$file:$!";
read F, $zenkaku, -s $file;

my %code2str = 
    (
     'hira2kata' =>  $zenkaku,
     'kata2hira' =>  $hiragana,
     );

# by Value

for my $icode (keys %code2str){
    for my $ocode (keys %code2str){
	my $ok;
	my $str = $code2str{$icode};
	my $out = jcode(\$str)->$ocode()->euc;
	myok($out, $code2str{$ocode}, 
	     "H2Z: $icode -> $ocode");
    }
}
__END__




