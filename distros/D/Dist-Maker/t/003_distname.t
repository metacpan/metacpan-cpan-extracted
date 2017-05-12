#!perl -w
use strict;
use Test::More;

use Dist::Maker::Name;

foreach my $name(qw(Foo-Bar-Baz Foo::Bar::Baz)) {
    note $name;
    my $dist = Dist::Maker::Name->new($name);

    is $dist,         'Foo-Bar-Baz';
    is $dist->name,   'Foo-Bar-Baz';
    is $dist->path,   'Foo/Bar/Baz';
    is $dist->module, 'Foo::Bar::Baz';
}
done_testing;
