use Test::More;

BEGIN {
	use Hades;
	Hades->run({
		realm => 'Exporter',
		eval => q|KatoTest { 
			curae :r :default(5)
			penthos :t(Str) 
			phobos :t(ArrayRef[HashRef, 1, 100]) 
			aporia :t(HashRef[Int])	
			thanatos :t(Map[Str, Int])
			gaudia :t(Tuple[Str, Int])
			nosoi :default(3) :t(Int) :clearer
			hypnos :pr :default(this is just a test) :type(Str) :c
			geras :t(Str)
			limos 
				$test :t(Str)
				:test(
					['ok', 'KatoTest::penthos(2) && KatoTest::nosoi(2) && KatoTest::curae(5)'],
					['is', 'KatoTest::limos("yay")', 5 ],
					['ok', 'KatoTest::penthos(5)' ],
					['is', 'KatoTest::limos("yay")', q{''}]
				) 
				{ if (£penthos == £nosoi) { return £curae; } } 
		}|,
		lib => 't/lib',
		tlib => 't/lib',
	});
	use lib 't/lib';
}

my $lame = 't/lib/KatoTest.t';
open my $fh, '<', $lame;
my $content  = do { local $/; <$fh> };
close $fh;
eval $content;
print $@;
