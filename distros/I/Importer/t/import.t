use strict;
use warnings;
use Test::More;

BEGIN {
    $INC{'My/Exporter.pm'} = 1;

    use Importer Importer => qw/import/;

    our @EXPORT = qw/foo/;

    sub foo { 'foo' }
}

use My::Exporter;

can_ok(__PACKAGE__, qw/foo/);

is(foo(), 'foo', "foo() imported");

done_testing;
