use warnings;
use strict;
use Test::More tests => 2;
use utf8;
use Lingua::JA::Moji qw/new2old_kanji old2new_kanji/;
binmode Test::More->builder->output, ":utf8";
binmode Test::More->builder->failure_output, ":utf8";

binmode STDOUT, ':utf8';
my $old1 = '櫻井';
my $new1 = old2new_kanji ($old1);
#print "$new1\n";
ok ($new1 eq '桜井', 'Convert 櫻井 to 桜井');
my $new2 = '三国 連太郎';
my $old2 = new2old_kanji ($new2);
#print "$old2\n";
ok ($old2 eq '三國 連太郎', 'Convert 三國');

