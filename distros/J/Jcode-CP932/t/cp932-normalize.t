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
    my $file = "t/cp932-table.$enc";
    open F, $file or die "$file:$!";
    binmode F;
    read F, $code2str{$enc}, -s $file;
    close F;
}

my %jis_enc = (
    utf8 => 'utf8',
    sjis => 'shift_jis',
    euc  => 'euc-jp',
    jis  => '7bit-jis',
    ucs2 => 'ucs2',
);
my %code2str_jis;
for my $enc (qw/euc sjis jis utf8 ucs2/){
    my $file = "t/table.$enc";
    open F, $file or die "$file:$!";
    binmode F;
    read F, $code2str_jis{ $jis_enc{$enc} }, -s $file;
    close F;
}

my @code2str = keys %code2str;
check("cp932-table");

sub check {
    my $table = shift;
    for my $icode (keys %code2str_jis) {
	for my $ocode (@code2str){
	    my $str = $code2str_jis{$icode};
	    my $obj = Jcode::CP932->new($str, $icode);
	    my $evo = eval qq{\$obj->$ocode}; # for perl 5.00x
	    myok($evo, $code2str{$ocode},
		 "$table:Jcode::CP932->new(\$str, $icode)->$ocode");
	}
    }
}

__END__
