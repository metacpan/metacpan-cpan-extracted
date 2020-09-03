use Test::More;

BEGIN {
	use Hades;
	Hades->run({
		eval => q|KatoPOD {
			synopsis {
A quick summary of what KatoPOD does.

	my $obj = KatoPod->new(
		indentation => 'ahhh'
	);

Some more text some more text.		
			}
			abstract { this is the abstract }
			curae :r :default(5) :pod($name $name $name. Expects no params.) :example($kato->$name();) 
			nosoi :default(3) :t(Int) :clearer
			penthos :t(Str) 
			geras :t(Str) :r
			limos
				$test :t(Str)
				:pod($name $name $name method.)
				:example(
	$kato->$name();

or

	$kato->$name({
		abc => 123,
		def => [
			qw/d e f/
		]
	});
				)
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

my $lame = 't/lib/KatoPOD.t';
open my $fh, '<', $lame;
my $content  = do { local $/; <$fh> };
close $fh;
eval $content;
print $@;
