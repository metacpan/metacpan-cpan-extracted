use strict;
use warnings;

use Importer 'Test::More';

BEGIN {
    $INC{'Export/Tester.pm'} = 1;
    package Export::Tester;

    our @EXPORT = qw/foo bar bad/;

    sub foo { 'foo' }
    sub bar { 'bar' }
}

use Importer 'Export::Tester';

can_ok(__PACKAGE__, qw/foo bar/);

pass("Legacy, Exporter.pm allows you to list subs for export that are missing");

done_testing;
