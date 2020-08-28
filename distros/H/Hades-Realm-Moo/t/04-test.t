use Test::More;

BEGIN {
	use Hades;
	Hades->run({
		realm => 'Moo',
		eval => q|KatoTest { 
			curae :r :default(5)
			penthos :t(Str) 
			phobos :t(ArrayRef[HashRef, 1, 100]) 
			aporia :t(HashRef[Int])	
			thanatos :t(Map[Str, Int])
			gaudia :t(Tuple[Str, Int])
			nosoi :default(3) :t(Int) :clearer
			hypnos :pr :r :default(this is just a test) :type(Str) :c
			geras :t(Str) :r
			limos 
				$test :t(Str)
				:test(
					['ok', '$obj->penthos(2) && $obj->nosoi(2) && $obj->curae(5)'],
					['is', '$obj->limos("yay")', 5 ],
					['ok', '$obj->penthos(5)' ],
					['is', '$obj->limos("yay")', q{''}]
				) 
				{ if ($_[0]->penthos == $_[0]->nosoi) { return $_[0]->curae; } } 
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
