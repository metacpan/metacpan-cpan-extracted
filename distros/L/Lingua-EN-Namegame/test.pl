# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'
#
# Tim Maher, yumpy@cpan.org

#########################

BEGIN {
	%verses = (
		Yumpy => 
			qr|
			^Yumpy\ Yumpy
			\s+bo\ Bumpy,
			\s+Banana\ Fanna\ Fo\ Fumpy,
			\s+Fee\ Fi\ Mo\ Mumpy
			\s+YUMPY!\s*$
			|ix
			,
		Marsha => 
			qr|
			^Marsha\ Marsha
			\s+bo\ Barsha,
			\s+Banana\ Fanna\ Fo\ Farsha,
			\s+Fee\ Fi\ Mo-arsha
			\s+MARSHA!\s*$
			|ix
			,
		Fitzwilly => 
			qr|
			^Fitzwilly\ Fitzwilly
			\s+bo\ Bitzwilly,
			\s+Banana\ Fanna\ Fo-itzwilly,
			\s+Fee\ Fi\ Mo\ Mitzwilly
			\s+FITZWILLY!\s*$
			|ix
			,
		Bilbo => 
			qr|
			^Bilbo\ Bilbo
			\s+Bo-ilbo,
			\s+Banana\ Fanna\ Fo\ Filbo,
			\s+Fee\ Fi\ Mo\ Milbo
		\s+BILBO!\s*$
		|ix
	);

	# I don't want to require this Module as a dependency, but
	# if it's present, I'll run the tests in the script that uses it

	eval {
		require Regexp::Common
	};
	if ( $@ ne "") {
		$extra_tests = 0;
	}	
	else {
		$extra_tests = 2;
	}
	$num_tests = ( (keys %verses) * 2 + 1 + $extra_tests );
}

# +1 is for the "use Namegame" 'test' itself


use Test::More tests => $num_tests;

use Lingua::EN::Namegame;

ok(1, 'MODULE LOADED SUCCESSFULLY'); # So far, so good!

# I'm using regexes instead of string equality tests because I might change the
# white-space or character-case details in a future version, and don't want to rewrite
# all the tests then

# First, test the function
foreach $name (sort keys %verses) {
	ok ( name2verse("$name") =~ /$verses{$name}/, "$name via function") ;
}


# Next, test the simplest script
# must set PERL5LIB or else, pre-install, module not found

$ENV{PERL5LIB}='blib/lib:blib/arch';
foreach $name (sort keys %verses) {
	ok ( `./name2verse.pl '$name'` =~ /$verses{$name}/, "$name via script") ;
}

if (! $extra_tests) {
	warn  "\nSkipping tests of 'name2verse_nonprofane.pl',\n";
	warn  "but after you install Regexp::Common, you can use it.\n";
	exit;
}

# Finally, try the profanity filtering script, first with clean name, then dirty name
$name='Marsha';
ok (  `./name2verse_nonprofane.pl '$name'` =~ /$verses{$name}/, "$name via Profanity-filtering script") ;

$name='Chuck';	 # profanity-ogenic name
ok (  `./name2verse_nonprofane.pl '$name'` =~ /profane/, "$name via Profanity-filtering script") ;

