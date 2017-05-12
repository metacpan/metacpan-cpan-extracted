use strict;
use warnings;
use utf8;
use Test::More;

{
    package Thing;
    use Exporter::Auto;
    use File::Spec::Functions qw(catfile);
    BEGIN {
        $INC{'Thing.pm'}++;
    }

    sub foo {
        'ok'
    }
    sub _private {
    }
}

use Thing;

ok(__PACKAGE__->can('foo'));
ok(!__PACKAGE__->can('_private'));
ok(!__PACKAGE__->can('catfile'));

done_testing;

