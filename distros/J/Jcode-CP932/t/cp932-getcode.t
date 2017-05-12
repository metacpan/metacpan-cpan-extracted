#!/usr/bin/perl

use strict;
use Jcode::CP932;
use Test;
BEGIN { plan tests => 5 }

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
my @code2str = keys %code2str;
check("ascii|x0208");

SKIP_x0212: {
last;
%code2str = ();
for my $enc (qw/euc jis utf8 ucs2/){
    my $file = "t/x0212.$enc";
    open F, $file or die "$file:$!";
    binmode F;
    read F, $code2str{$enc}, -s $file;
    close F;
}
@code2str = keys %code2str;
check("x0212");
}

sub check{
    my $table = shift;
    for my $icode (@code2str){
	my $str = $code2str{$icode};
	my $code = getcode(\$str);
	myok($icode, $code,
		 "$table:getcode(\$str, $icode) -> $code");
    }
}

__END__
