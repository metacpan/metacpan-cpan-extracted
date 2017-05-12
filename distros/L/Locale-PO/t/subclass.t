use strict;
use warnings;

use Test::More 'no_plan';
use File::Slurp;

my $pos = Locale::PO::Subclass->load_file_asarray("t/test.pot");
ok $pos, "loaded test.pot file";

my $out = $pos->[0]->dump;
ok $out, "dumped po object";

is($pos->[1]->loaded_line_number, 16, "got line number of 2nd po entry");

ok Locale::PO::Subclass->save_file_fromarray( "t/test.pot.out", $pos ), "save to file";
ok -e "t/test.pot.out", "the file now exists";

SKIP: {
	if ($^O eq 'msys') {
		skip(1, "Comparing POs after roundtrip fails on msys platform");
	}
	is(
		read_file("t/test.pot"),
		read_file("t/test.pot.out"),
		"found no matches - good"
	  )
	  && unlink("t/test.pot.out");
}

package Locale::PO::Subclass;
use strict;
use warnings;
use base qw( Locale::PO );

sub custom_format
{
	my $self = shift;
	return $self->_tri_value_flag('custom-format', @_);
}

1;
