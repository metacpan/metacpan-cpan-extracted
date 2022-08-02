use strict; use warnings;

use Test::More tests => 1;
use FlatFile;

my @TO_REMOVE = my $FILE = "/tmp/FlatFile.$$";
END { unlink @TO_REMOVE }

{ open my $fh, '>', $FILE or die "Couldn't write $FILE: $!\n"; print $fh <<'' }
95709010,2
28176010,2
96087810,foo
62912R10,2
89840410,2

ok eval {
	my $MaxList = FlatFile->new(
		FILE   => $FILE,
		FIELDS => [qw(cusip value)],
		MODE     => "+<",  # "<" for read-write access
		RECSEP   => "\n",
		FIELDSEP => ","
	);

	foreach my $cusip ('95709010', '96087810', '62912R10', '89840410') {
		my ($max) = $MaxList->lookup(cusip => "$cusip");
		if ($max->cusip eq '96087810') {
			$max->set_value("foo");
		}
	}

	1;
} or diag "$@";
