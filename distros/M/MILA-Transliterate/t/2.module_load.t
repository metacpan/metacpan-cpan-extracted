use Test::More 'tests' => 1;
BEGIN {
	# Tests - Ensure that the module can be loaded
	#	 and export the functions

    use_ok( 'MILA::Transliterate', qw/hebrew2treebank treebank2hebrew hebrew2erel erel2hebrew hebrew2fsma fsma2hebrew/ );
}

