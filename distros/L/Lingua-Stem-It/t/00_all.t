# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

# count the lines in __DATA__
my $start = tell(DATA);
my $n = 0;
$n++ while <DATA>;
seek(DATA, $start, 0);

$| = 1; 

print "1..", 18+$n, "\n"; 

# test module usage

eval "use Lingua::Stem::It";
if ($@) {
	print "not ok 1\n";
	exit;
} else {
	print "ok 1\n";
}

# fixed tests

test_stem(2, 'gatt', qw( gatto gatta gatti gatte ));	
test_stem(3, 'programm', qw( programma programmi programmare programmazione ));

test_stem_word( 4, 'gatt', 'gatto');
test_stem_word( 5, 'gatt', 'gatta');
test_stem_word( 6, 'gatt', 'gatti');
test_stem_word( 7, 'gatt', 'gatte');

test_stem_word( 8, 'programm', 'programma');
test_stem_word( 9, 'programm', 'programmi');
test_stem_word(10, 'programm', 'programmare');
test_stem_word(11, 'programm', 'programmazione');

test_stem_word(12, 'abbandon', 'abbandonare');
test_stem_word(13, 'abbandon', 'abbandonato');
test_stem_word(14, 'abbandon', 'abbandonavamo');
test_stem_word(15, 'abbandona', 'abbandonai'); # not really sure about this one

# corner cases

test_stem_word(16, '', '');
test_stem_word(17, '12345678', '12345678');
test_stem_word(18, '   gat-t', '   GAT-to');


# test the stuff in <DATA>

my $i = 19;
while(<DATA>) {
	chomp;
	my($word, $result) = split /\s+/;
	test_stem_word($i++, $result, $word);
}

# subroutines

sub test_stem {
	my ($t, $expected, @words) = @_;
	my @errors = ();
	my $stemmed_words = Lingua::Stem::It::stem( { -words => \@words } );
	foreach my $stem (@$stemmed_words) {
		if($stem ne $expected) {
			push @errors, "\t# expected '$expected', got '$stem'\n";
		}
	}
	print "not " if @errors;
	print "ok $t\n";
	print @errors;
}

sub test_stem_word {
	my($t, $expected, $word) = @_;
	my $stem = Lingua::Stem::It::stem_word( $word );
	$stem ne $expected and print "not ";
	print "ok $t\n";
	if($stem ne $expected) {
		print "\t# expected '$expected', got '$stem'\n";
	}
}	

# the following taken from:
# http://snowball.tartarus.org/algorithms/italian/stemmer.html

__DATA__
abbandonata		abbandon
abbandonate		abbandon
abbandonati		abbandon
abbandonato		abbandon
abbandonava		abbandon
abbandonerà		abbandon
abbandoneranno		abbandon
abbandonerò		abbandon
abbandono		abband
abbandonò		abbandon
abbaruffato		abbaruff
abbassamento		abbass
abbassando		abbass
abbassandola		abbass
abbassandole		abbass
abbassar		abbass
abbassare		abbass
abbassarono		abbass
abbassarsi		abbass
abbassassero		abbass
abbassato		abbass
abbassava		abbass
abbassi			abbass
abbassò			abbass
abbastanza		abbast
abbatté			abbatt
abbattendo		abbatt
abbattere		abbatt
abbattersi		abbatt
abbattesse		abbattess
abbatteva		abbatt
abbattevamo		abbatt
abbattevano		abbatt
abbattimento		abbatt
abbattuta		abbatt
abbattuti		abbatt
abbattuto		abbatt
abbellita		abbell
abbenché		abbenc
abbi			abbi
pronto			pront
pronuncerà		pronunc
pronuncia		pronunc
pronunciamento		pronunc
pronunciare		pronunc
pronunciarsi		pronunc
pronunciata		pronunc
pronunciate		pronunc
pronunciato		pronunc
pronunzia		pronunz
pronunziano		pronunz
pronunziare		pronunz
pronunziarle		pronunz
pronunziato		pronunz
pronunzio		pronunz
pronunziò		pronunz
propaga			propag
propagamento		propag
propaganda		propagand
propagare		propag
propagarla		propag
propagarsi		propag
propagasse		propag
propagata		propag
propagazione		propag
propaghino		propaghin
propalate		propal
propende		prop
propensi		propens
propensione		propension
propini			propin
propio			prop
propizio		propiz
propone			propon
proponendo		propon
proponendosi		propon
proponenti		proponent
proponeva		propon
proponevano		propon
proponga		propong