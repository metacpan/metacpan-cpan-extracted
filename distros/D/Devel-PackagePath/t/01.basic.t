use strict;
use Test::More tests => 10;

use Devel::PackagePath;

ok(
    my $path = Devel::PackagePath->new( package => 'Foo::Bar::Baz' ),
    'Create a path object'
);

use File::Spec;
my $foobar = File::Spec->catdir(qw(Foo Bar));

is( $path->path, $foobar, 'got the right path' );
ok( $path->create, "create $foobar" );
ok( -e 'Foo',      'Foo exists' );
ok( -e 'Foo/Bar',  "$foobar exists" );

# XXX: We should figure out a safe way to do a remove inside
#      the package
ok( $path->directory->rmtree, 'able to rmtree' );
ok( $path->directory->parent->remove, 'able to remote the parent' );
ok( !-e $foobar, "$foobar is gone" );
ok( !-e 'Foo',     'Foo is gone' );

is( $path->file_name, 'Baz.pm', 'got the right file name' );
