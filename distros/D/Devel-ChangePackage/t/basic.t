use strict;
use warnings;
use Test::More 0.89;

use Devel::ChangePackage;

BEGIN {
    my $old_pkg = change_package 'Foo::Bar';
    is $old_pkg, 'main', 'previous package returned';
}

::is __PACKAGE__, 'Foo::Bar', 'package was changed';

::done_testing;
