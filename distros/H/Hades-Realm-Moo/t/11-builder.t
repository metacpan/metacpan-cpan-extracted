use Test::More;

BEGIN {
	use Hades;
	Hades->run({
		realm => 'Moo',
		eval => 'KatoBuilder { 
			penthos :t(HashRef) :builder
			_build_penthos $value {
				return {
					a => "b",
					c => "d"
				};
			} 
		}
		KatoBuilder::Kosmos parent KatoBuilder { 
			_build_penthos $value {
				return {
					b => "a",
					d => "c"
				};
			}
		}',
		lib => 't/lib'
	});
	use lib 't/lib';
}

use KatoBuilder;
use KatoBuilder::Kosmos;
my $obj = KatoBuilder->new;

is_deeply($obj->penthos, { a => "b", c => "d" });

$obj = KatoBuilder::Kosmos->new;

is_deeply($obj->penthos, { b => "a", d => "c" });

ok(1);

done_testing;
