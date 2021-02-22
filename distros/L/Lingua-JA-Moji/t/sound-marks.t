use FindBin '$Bin';
use lib "$Bin";
use LJMT;

is (join_sound_marks ('か゛は゜つ゛'), 'がぱづ');
is (split_sound_marks ('がぱづ'), 'か゛は゜つ゛');
is (join_sound_marks ('カ゛ハ゜ツ゛'), 'ガパヅ');
is (split_sound_marks ('ガパヅ'), 'カ゛ハ゜ツ゛');
is (strip_sound_marks ('がぱづ'), 'かはつ');
is (strip_sound_marks ('ガパヅ'), 'カハツ');

done_testing ();
