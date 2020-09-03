use Test::More;
BEGIN {
	use Hades;
	Hades->run({
		eval => q`
			macro {
				Dolos
			}
			KosmosDolos { 
				eros $eros :t(HashRef) $psyche :t(HashRef) {
					€merge_hash_refs(q|$eros|, q|$psyche|);
					return $eros;
				}
				psyche $dolos :t(Int) $eros :t(HashRef) $psyche :t(HashRef) {
					€if(
						q|$dolos|,
						q|€if(
							q{$dolos > 10},
							q{return $eros;}
						);|,
						q|€elsif(
							q{$dolos > 5},
							q{€merge_hash_refs(q/$eros/, q/$psyche/);}
						);|,
						q|€else(
							q{return $psyche;}
						);|
					);
					return undef;
				}
			}
		`,
		lib => 't/lib'
	});
	use lib 't/lib';
}
use KosmosDolos;
my $okay = KosmosDolos->new();
is_deeply($okay->eros({ a => 1 }, { b => 2 }), { a => 1, b => 2 });
done_testing;
