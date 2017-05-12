#!perl
use strict;
use warnings;
my $count;
BEGIN { $count = 40 };
use Test::More tests => $count * 2;
use Filesys::Virtual::Plain;
use Filesys::Virtual::SSH;
use File::Slurp::Tree;
use Cwd;
use Sys::Hostname;

if (eval { require Test::Differences; 1 }) {
    no warnings 'redefine';
    *is_deeply = \&Test::Differences::eq_or_diff;
}

# A comparitive test against Filesys::Virtual::Plain, more so I
# understand the api as Filesys::Virtual is low on docs

my $tree = {
    foo => "I r foo\n",
    bar => {
        baz => "I r not foo\n",
    },
};

SKIP:
for my $class (map { "Filesys::Virtual::$_" } qw( Plain SSH )) {
    if ($class =~ /::SSH$/ && hostname ne 'brains') {
        skip( "Not on brains, not doing SSH testing", $count );
    }
    my $root = cwd().'/t/test_root';
    # ick
    `rm -rf $root`;
    spew_tree( $root => $tree );
    isa_ok( my $vfs = $class->new({
        host      => 'localhost',
        cwd       => '/',
        root_path => $root,
        home_path => '/home',
    }), $class );

    is( $vfs->cwd, "/", "cwd" );
    is_deeply( [ $vfs->list( "/" ) ],
               [ sort qw( . .. ), keys %$tree ],
               "list /" );

    is_deeply( [ $vfs->list( "" ) ],
               [ sort qw( . .. ), keys %$tree ],
               "list ''" );

    is_deeply( [ $vfs->list( "foo" ) ],
               [ "foo" ],
               "list foo" );

    is_deeply( [ $vfs->list( "i_do_not_exist" ) ],
               [ ],
               "list i_do_not_exist" );

    is_deeply( [ $vfs->list( "/bar" ) ],
               [ sort qw( . .. ), keys %{ $tree->{bar} } ],
               "list /bar" );

    is_deeply( [ $vfs->list( "/bar" ) ],
               [ sort qw( . .. ), keys %{ $tree->{bar} } ],
               "list bar" );

    is( $vfs->chdir( 'bar' ), "/bar", "chdir bar" );
    is( $vfs->cwd, "/bar", "cwd is /bar" );

    is_deeply( [ $vfs->list( "" ) ],
               [ sort qw( . .. ), keys %{ $tree->{bar} } ],
               "list ''" );

    is_deeply( [ $vfs->list( "/" ) ],
               [ sort qw( . .. ), keys %$tree ],
               "list /" );

    my @ls_al = $vfs->list_details("");
    is( scalar @ls_al, 3, "list_details pulled back 3 things");
    diag( $ls_al[2] );
    like( $ls_al[2], qr/\sbaz$/, "seemed to get bar" );

    # ::Plain just doesn't bother - that's easy enough
    is_deeply( [ $vfs->modtime( "/foo" ) ], [ 0, "" ], "modtime /foo" );

    is( $vfs->size( "/foo" ), length $tree->{foo}, "size /foo" );

    is( ( $vfs->stat("/foo") )[7], length $tree->{foo}, "stat /foo" );

    ok( $vfs->test( "e", "/foo" ), "test -e /foo" );
    ok( !$vfs->test( "e", "/does_not_exist" ), "!test -e /does_not_exist" );

    ok( $vfs->delete( "/foo" ), "delete /foo" );
    ok( !-e "$root/foo", "it really went" );

    ok( !$vfs->delete( "/does_not_exist" ), "failed to delete /does_not_exist" );
    ok( !$vfs->delete( "/bar" ), "failed to delete /bar" );

    ok( $vfs->chmod( 0600, "/bar/baz" ), "chmod /bar/baz" );
    is( (stat "$root/bar/baz" )[2] & 07777, 0600, "chmod took" );

    ok( $vfs->mkdir( "/ninja" ), "mkdir /ninja" );
    ok( -d "$root/ninja", "it was really made" );

    ok( $vfs->rmdir( "/ninja" ), "rmdir /ninja" );
    ok( !-e "$root/ninja", "it went" );

    ok( !$vfs->rmdir( "/does_not_exist" ), "failed to rmdir /does_not_exist" );
    ok( !$vfs->rmdir( "/bar" ), "failed to rmdir /bar" );

    ok( my $ifh = $vfs->open_read( "/bar/baz" ), "open_read /bar/baz" );
    is( <$ifh>, $tree->{bar}{baz}, "get contents of /bar/baz" );
    ok( $vfs->close_read( $ifh ), "closed" );

    ok( my $ofh = $vfs->open_write( "/foo" ), "open_write /foo" );
    print $ofh $tree->{foo};
    ok( $vfs->close_write( $ofh ) , "closed" );
    is( slurp_tree( $root )->{foo}, $tree->{foo}, "wrote ok" );

    ok( my $afh = $vfs->open_write( "/foo", 1 ), "open_write /foo append" );
    print $afh $tree->{foo};
    ok( $vfs->close_write( $afh ) , "closed" );
    is( slurp_tree( $root )->{foo}, $tree->{foo}.$tree->{foo}, "wrote ok" );
}
