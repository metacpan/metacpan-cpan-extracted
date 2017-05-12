use Test::More 'tests' => 1;
BEGIN {
	# Test 1 - Ensure that the Lingua::HE::Sentence module can be loaded
	#	and export the get_sentences function
    use_ok( 'Lingua::HE::Sentence', qw/get_sentences/ );
}

