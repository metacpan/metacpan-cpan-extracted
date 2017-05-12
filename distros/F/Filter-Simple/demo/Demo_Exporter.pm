package Demo_Exporter;
$VERSION = '0.01';

use Filter::Simple;
use base Exporter;

@EXPORT = qw(foo);            # symbols to export by default
@EXPORT_OK = qw(bar);         # symbols to export on request

sub foo { print "foo\n" }
sub bar { print "bar\n" }

FILTER {
	s/dye/die/g;
}
