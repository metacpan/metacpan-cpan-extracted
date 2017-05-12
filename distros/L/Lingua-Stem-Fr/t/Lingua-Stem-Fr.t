# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..16\n"; }
END {print "not ok 1\n" unless $loaded;}
use Lingua::Stem::Fr;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

sub test_stem {
	my ($t, $expected, @words) = @_;
	my @errors = ();
	my $stemmed_words = Lingua::Stem::Fr::stem( { -words => \@words } );
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
	my $stem = Lingua::Stem::Fr::stem_word( $word );
	$stem ne $expected and print "not ";
	print "ok $t\n";
	if($stem ne $expected) {
		print "\t# expected '$expected', got '$stem'\n";
	}
}

test_stem(2, 'fortun', qw( fortune fortunées fortuné fortune ));
test_stem(3, 'fouill', qw( fouillait fouilleront fouillent fouillez ));
test_stem(4, 'froid', qw( froidement froide froides froids ));

test_stem_word( 5, 'aim', 'aimer');
test_stem_word( 6, 'fortun', 'fortunées');
test_stem_word( 7, 'fortun', 'fortuné');
test_stem_word( 8, 'fortun', 'fortune');

test_stem_word( 9, 'fouill', 'fouillait');
test_stem_word(10, 'fouill', 'fouilleront');
test_stem_word(11, 'fouill', 'fouillent');
test_stem_word(12, 'fouill', 'fouillez');

test_stem_word(13, 'froid', 'froidement');
test_stem_word(14, 'froid', 'froide');
test_stem_word(15, 'froid', 'froides');
test_stem_word(16, 'froid', 'froids');
