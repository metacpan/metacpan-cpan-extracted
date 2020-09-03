use Test::More;
BEGIN {
	use Hades;
	Hades->run({
		realm => 'Import::Export',
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
				[penthos curae] :t(Int) :d(2) :p :pr :c :r :i 
				geras $nosoi :t(Int) :d(5) :i { if (£penthos == $nosoi) { return £curae; } } 
				eros $eros :t(Str) :d(t/test.txt) :i {
					€s2ar('$eros');
					€ar2s('$eros');
					€wf('$eros', q|'this is a test'|);
					return $eros;
				}
				psyche $psyche :t(Str) :d(t/test.txt) :i {
					€rf('$psyche');
					return $content;
				}
			}
		`,
		lib => 't/lib'
	});
	use lib 't/lib';
}

use KosmosMacro qw/penthos has_curae geras eros psyche/;
eval { penthos };
like( $@, qr/^cannot call private/);
is(has_curae, 1);
is(geras(2), 2);
is(eros(), 't/test.txt');
is(psyche(), 'this is a test');

done_testing;
