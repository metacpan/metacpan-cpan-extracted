use Test::More;

BEGIN {
	use Hades;
	Hades->run({
		eval => 'Limos { 
			phobos :p :pr :co(coerce_array_to_string) :d([1]) :tr(dump_test)
			geras { return $self->phobos; } 
			penthos $string :d(def) :t(Str) { return $string; }
			nosoi $string :t(Str) :co(coerce_array_to_string) { return $string; } 
			curae $int :t(Int) $string :t(Str) { return $int . $string; }
			coerce_array_to_string $array { return ref($array) || "" eq "ARRAY" ? $array->[0] : $array; }
			dump_test $int { $int; }
		}
		Kato::Limos parent Limos { 
			algea { return 1; }
			geras :around {
				my @res = $self->$orig(@params);
			}
		}',
		lib => 't/lib'
	});
	use lib 't/lib';
}

use Limos;
my $okay = Limos->new({});

is($okay->geras, 1);
is($okay->penthos, 'def');
is($okay->penthos('abc'), 'abc');
is($okay->nosoi('abc'), 'abc');
is($okay->nosoi(['abc']), 'abc');
is($okay->curae(1, 'abc'), '1abc');

use Kato::Limos;
$okay = Kato::Limos->new({});

is($okay->geras, 1);
is($okay->algea, 1);

done_testing;
