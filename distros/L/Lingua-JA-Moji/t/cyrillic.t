use FindBin '$Bin';
use lib "$Bin";
use LJMT;

my %examples = (
    'シンブン',  'симбун',      
    'サンカ',   'санка',        
    'カンイ',   'канъи',       
    'ホンヤ',   'хонъя',       
);

for my $kana (keys %examples) {
#    print "$kana\n";
    my $expect = $examples{$kana};
    my $cyrillic = kana2cyrillic ($kana);
#    print "$cyrillic $expect\n";
    ok ($cyrillic eq $expect);
    my $roundtrip = cyrillic2katakana ($cyrillic);
#    print "$roundtrip\n";
    ok ($roundtrip eq $kana);
}

# These tests are taken from Wikipedia and are meant to be tests using
# capital versions of the cyrillic letters. The "shindo" is missing a
# final "う".
my $c1 = 'Ябу но нака но куронэко';
my $c2 = 'Канэто Синдо';
my $k1 = cyrillic2katakana ($c1);
my $k2 = cyrillic2katakana ($c2);
#print "$k1 $k2\n";
ok ($k1 eq 'ヤブ ノ ナカ ノ クロネコ');
ok ($k2 eq 'カネト シンド');

done_testing ();
