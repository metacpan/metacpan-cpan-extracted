use Test::More 'tests' => 1;
BEGIN {
	# Test 1 - Ensure that the Lingua::HE::Sentence module can be loaded
	#	and export the 
	#		get_sentences, get_EOS, set_EOS 
	#	functions
    use_ok( 'Lingua::HE::Sentence', qw/get_sentences get_EOS set_EOS/ );
}

