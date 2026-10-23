use strict;
use warnings;
use Test::More;

{
	package T::None;
	use Math::Basic::XS;
}
ok(!T::None->can('sum'), 'nothing by default');

{
	package T::Names;
	use Math::Basic::XS qw/sum mean/;
}
ok(T::Names->can('sum') && T::Names->can('mean'), 'by name');
ok(!T::Names->can('mode'), 'only the names asked for');

{
	package T::Bare;
	use Math::Basic::XS qw/all/;
}
ok(T::Bare->can($_), "bare tag brings $_") for qw/sum min max mean median mode/;

{
	package T::Colon;
	use Math::Basic::XS qw/:all !mode/;
}
ok(T::Colon->can('median') && !T::Colon->can('mode'), 'colon tag with negation');

is(prototype('T::Bare::sum'), '&@', 'the block prototype survives the import');

ok(!eval "package T::Bad; use Math::Basic::XS qw/nope/; 1", 'unknown name dies');
like($@, qr/"nope" is not exported by the Math::Basic::XS module/, 'unknown name message');

done_testing();
