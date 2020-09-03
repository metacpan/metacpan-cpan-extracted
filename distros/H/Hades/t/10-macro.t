use Test::More;
BEGIN {
	use Hades;
	Hades->run({
		eval => q`
			macro {
				FH [ alias => { read_file => [qw/rf/], write_file => [qw/wf/] } ]
				str2ArrayRef :a(s2ar) {
					return qq|$params[0] = [ $params[0] ];|;
				}
				ArrayRef2Str :a(ar2s) {
					return qq|$params[0] = $params[0]\->[0];|;
				}
			}
			KosmosMacro { 
				[penthos curae] :t(Int) :d(2) :p :pr :c :r 
				geras $nosoi :t(Int) :d(5) { if (£penthos == $nosoi) { return £curae; } } 
				eros $eros :t(Str) :d(t/test.txt) {
					€s2ar('$eros');
					€ar2s('$eros');
					€wf('$eros', q|'this is a test'|);
					return $eros;
				}
				psyche $psyche :t(Str) :d(t/test.txt) {
					€rf('$psyche');
					return $content;
				}
			}
		`,
		lib => 't/lib'
	});
	use lib 't/lib';
}
use KosmosMacro;
my $okay = KosmosMacro->new({
	curae => 5
});
eval { $okay->penthos };
like( $@, qr/^cannot call private method penthos/);
is($okay->has_curae, 1);
is($okay->geras(2), 5);
is($okay->eros(), 't/test.txt');
is($okay->psyche(), 'this is a test');

done_testing;
