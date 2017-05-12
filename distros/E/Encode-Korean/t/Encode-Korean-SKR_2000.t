# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Encode-Korean.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 4;
BEGIN { use_ok('Encode::Korean::SKR_2000') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

ok defined &encode, "import Encode's encode() function";
ok defined &decode, "import Encode's decode() function";

# ccs = complex_consonants_group
# "잇어 이서 있어 잇서 이써 있서 잇써 있써"
# "나가 낙아 낚아 낙가 나까 낚가 낙까 낚까"
# "보다 볻아 볻다 보따 볻따"
# "맞아 마자 맞자 마짜 맞짜"
# "앉아 안자 앉자 안짜 앉짜"

my $enc = 'skr-2000';
my $str_ccs = "\x{C787}\x{C5B4} \x{C774}\x{C11C} " .                  # iseo
			  "\x{C788}\x{C5B4} \x{C787}\x{C11C} \x{C774}\x{C368} " . # isseo
			  "\x{C788}\x{C11C} \x{C787}\x{C368} " .                  # issseo
			  "\x{C788}\x{C368} " .                                   # isssseo
			  "\x{B098}\x{AC00} \x{B099}\x{C544} " .                  # naka
			  "\x{B09A}\x{C544} \x{B099}\x{AC00} \x{B098}\x{AE4C} " . # nakka
			  "\x{B09A}\x{AC00} \x{B099}\x{AE4C} " .                  # nakkka
			  "\x{B09A}\x{AE4C} " .                                   # nakkkka
			  "\x{BCf4}\x{B2E4} \x{BCfB}\x{C544} " .                  # pota
			  "\x{BCfB}\x{B2E4} \x{BCf4}\x{B530} " .                  # potta
			  "\x{BCfB}\x{B530} " .                                   # pottta
			  "\x{B9DE}\x{C544} \x{B9C8}\x{C790} " .                  # maca
			  "\x{B9DE}\x{C790} \x{B9C8}\x{C9DC} " .                  # macca
			  "\x{B9DE}\x{C9DC} " .                                   # maccca
			  "\x{C549}\x{C544} \x{C548}\x{C790} " .                  # anca
			  "\x{C549}\x{C790} \x{C548}\x{C9DC} " .                  # ancca
			  "\x{C549}\x{C9DC}";                                     # anccca


# implicit test: Can it decode a text encoded by itself?
# This test doesn't care whether the rule is correctly set. 
is $str_ccs, (decode $enc, encode $enc, $str_ccs), 'encode <-> decode reversible';

__END__
# explicit test: Can it decode a user transliteration?
# Checks whether the rule is correclty defined.
my $hsr_ccs = "is.eo i.seo " .
			  "iss.eo is.seo i.sseo " .
			  "iss.seo is.sseo " .
			  "iss.sseo " .
			  "na.ga nag.a " .
			  "nagg.a nag.ga na.gga " .
			  "nagg.ga nag.gga " .
			  "nagg.gga " . 
			  "bo.da bod.a " .
			  "bod.da bo.dda " .
			  "bod.dda " .
			  "maj.a ma.ja " .
			  "maj.ja ma.jja " .
			  "maj.jja " .
			  "anj.a an.ja " .
			  "anj.ja an.jja " .
			  "anj.jja" ;

my $hsr_ccs_smart_sep = "is.eo iseo " .
			  "iss.eo is.seo isseo " .
			  "iss.seo issseo " .
			  "isssseo " .
			  "na.ga nag.a " .
			  "nagg.a nag.ga nagga " .
			  "nagg.ga naggga " .
			  "nagggga " . 
			  "boda bod.a " .
			  "bod.da bodda " .
			  "boddda " .
			  "maj.a maja " .
			  "maj.ja majja " .
			  "majjja " .
			  "anj.a anja " .
			  "anj.ja anjja " .
			  "anjjja" ;
	
my $encoded_ccs = encode $enc, $str_ccs;
my $decoded_ccs = decode $enc, $hsr_ccs;
my $decoded_ccs_smart_sep = decode $enc, $hsr_ccs_smart_sep;

is $encoded_ccs, $hsr_ccs, 'encoded complex consonants group';
is $decoded_ccs, $str_ccs, 'decoded complex consonants group';
is $decoded_ccs_smart_sep, $str_ccs, 'decoded complex consonants group with smart sep';

is $encoded_ccs, (encode $enc, $decoded_ccs), 'encode ($enc, $decoded)';
is $decoded_ccs, (decode $enc, $encoded_ccs), 'decode ($enc, $encoded)';


