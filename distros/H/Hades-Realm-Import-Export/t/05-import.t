use Test::More;

BEGIN {
	use Hades;
	Hades->run({
		eval => q|KatoImport use KatoTest [qw/curae nosoi geras/]  {
			one :test(['is', '$obj->one', 5]) { curae; }
			two :test(['is', '$obj->two', 3]) { nosoi; }
			three $value :test(['is', '$obj->three("okay")', q{'okay'}]) { geras($value) } 
		}|,
		lib => 't/lib',
		tlib => 't/lib',
	});
	use lib 't/lib';
}

my $lame = 't/lib/KatoImport.t';
open my $fh, '<', $lame;
my $content  = do { local $/; <$fh> };
close $fh;
eval $content;
print $@;
