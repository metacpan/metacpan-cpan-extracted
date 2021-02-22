use FindBin '$Bin';
use lib "$Bin";
use LJMT;
eval {
    kana_consonant ('');
};
ok ($@ && $@ =~ /empty/i, "dies with empty input");
eval {
    kana_consonant ('猿');
};
ok ($@ && $@ =~ /not kana/i, "dies with non-kana input");
is (kana_consonant ('さる'), 's', "saru gets s"); 
is (kana_consonant ('ざる'), 's', "zaru gets s"); 
is (kana_consonant ('ある'), '', "aru gets empty string"); 
done_testing ();
