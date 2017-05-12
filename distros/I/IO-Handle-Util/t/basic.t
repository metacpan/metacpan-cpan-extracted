#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use ok 'IO::Handle::Util' => qw(:all);

use Scalar::Util qw(blessed);

ok( IO::Handle->can("print"), "IO::Handle loaded" );
ok( FileHandle->can("tell"), "FileHandle loaded" );

ok( !blessed(*STDIN), "STDIN not blessed" );
eval { STDIN->tell };
is( $@, '', "but responds to methods" );

sub new_fh {
    my ( $mode, $string ) = @_;
    open my $fh, $mode, \$string;
    return wantarray ? ( $fh, \$string ) : $fh;
}

{
    my ( $fh, $buf ) = new_fh ">", "";

    my $sub = io_to_write_cb($fh);

    is( ref $sub, 'CODE', "io_to_write_cb makes a code ref" );

    $sub->("foo\n");

    is( $$buf, "foo\n", "first invocation" );

    $sub->("blah\n");

    is( $$buf, "foo\nblah\n", "second invocation" );
}

{
    my $str = '';
    my $sub = io_to_write_cb(\$str);

    $sub->("foo");

    is($str, "foo", "coerced from scalar ref");

    local $\ = "\n";
    local $, = ", ";

    $sub->(qw(foo bar));

    is( $str, "foofoobar", "immune to ORS and OFS" );
}

{
    my $fh = new_fh "<", "foo\nbar\n";

    is( ref($fh), 'GLOB', "PerlIO handle is a glob" );

    is( io_to_glob($fh), $fh, 'io_to_glob isa passthrough' );
}

{
    my $fh = io_from_array [qw(foo bar)];

    isnt( ref($fh), 'GLOB' );

    my $glob = io_to_glob($fh);

    is( ref($glob), "GLOB", "io_to_glob" );

    isa_ok( tied(*$glob), "IO::Handle::Util::Tie", "tied" );

    is_deeply(
        [ <$glob> ],
        [qw(foo bar)],
        "readline builtin",
    );
}

{
    my $fh = io_from_array [qw(foo bar)];

    isnt( ref($fh), 'GLOB' );

    is_deeply(
        [ <$fh> ],
        [qw(foo bar)],
        "readline builtin through overloading",
    );
}

{
    my $fh = new_fh "<", "foo\nbar\n";

    my $sub = io_to_read_cb($fh);

    is( ref $sub, 'CODE', "io_to_read_cb makes a code ref" );

    is( $sub->(), "foo\n", "like getline" );
    is( $sub->(), "bar\n", "like getline" );
    is( $sub->(), undef, "like getline" );
}

{
    my $fh = new_fh "<", "foo\nbar\nbaz\ngorch";

    local $/ = "a";
    is( $fh->getline, "foo\nba", "getline with IRS" );

    is( io_to_string($fh), "r\nbaz\ngorch", "slurp with io_to_string" );

    is( io_to_string($fh), "", "IO depleted" );

    is( io_to_string("foo"), "foo", "strings pass through" );
}

{
    my $fh = new_fh "<", "foo\nbar\nbaz\ngorch";

    is_deeply(
        io_to_array($fh),
        [
            "foo\n",
            "bar\n",
            "baz\n",
            "gorch",
        ],
        "io_to_array",
    );

    is_deeply(
        [ io_to_list(new_fh "<", "foo\nbar\nbaz\n") ],
        [ "foo\n", "bar\n", "baz\n" ],
        "io_to_list",
    );

    is_deeply(
        io_to_array([qw(foo bar)]),
        [qw(foo bar)],
        "passthrough",
    );

    is_deeply(
        [io_to_list([qw(foo bar)])],
        [qw(foo bar)],
        "passthrough list context",
    );
}

sub io_ok ($;$) {
    my ( $fh, $desc ) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    ok($fh, $desc || "got IO" );

    if ( blessed($fh) ) {
        can_ok( $fh, "getline", "print" );
    } else {
        ok( ref($fh) eq 'GLOB' && *{$fh}{IO}, "unblessed GLOB with IO" );
    }

    return $fh;
}

{
    my $str = "foo\nbar\n";

    foreach my $arg ( $str, \$str ) {
        io_ok( my $fh = io_from_any($arg), "IO from " . lc(ref(\$arg)) );

        ok( !$fh->eof, "not eof" );
        is( $fh->getline, "foo\n", "getline" );
        ok( !$fh->eof, "not eof" );
        is( $fh->getline, "bar\n", "getline" );
        ok( $fh->eof, "eof" );
        is( $fh->getline, undef, "getline" );
        ok( $fh->eof, "eof" );
    }
}

{
    io_ok( my $fh = io_from_any([qw(foo bar gorch)]), "from array");

    isa_ok( $fh, "IO::Handle::Iterator" );

    is( $fh->getline, "foo", "fake getline" );

    is_deeply(
        [ $fh->getlines ],
        [ qw(bar gorch) ],
        "fake lines preserved",
    );
}

{
    io_ok( my $fh = io_from_any([qw(foo bar gorch)]), "from array");

    isa_ok( $fh, "IO::Handle::Iterator" );

    is( $fh->getline, "foo", "fake getline" );

    is_deeply(
        [ <$fh> ],
        [ qw(bar gorch) ],
        "getlines via readline operator",
    );
}

{
    my $str_fh = IO::String->new("foo");

    can_ok( $str_fh, qw(getline print) );

    io_ok( my $fh = io_from_any($str_fh), "from IO::String" );

    is( $fh, $str_fh, "passthrough" );
}

{
    my $perlio_string = new_fh "<", "foo";

    ok( !blessed($perlio_string), "PerlIO string handle not blessed" );

    io_ok( my $fh = io_from_any($perlio_string), "from PerlIO string" );

    is( $fh, $perlio_string, "passthrough" );
}

{
    my $fh = io_from_thunk sub {
        return "foo\nbar\n";
    };

    io_ok( $fh, "from thunk" );

    ok( !$fh->eof, "not eof" );
    is( $fh->getline, "foo\nbar\n", "getline" );
    is( $fh->getline, undef, "getline" );
    ok( $fh->eof, "eof" );
}

{
    my $fh = io_from_thunk sub {
        return qw(
            foo
            bar
        );
    };

    io_ok( $fh, "from list thunk" );

    ok( !$fh->eof, "not eof" );
    is( $fh->getline, "foo", "getline" );
    is( $fh->getline, "bar", "getline" );
    is( $fh->getline, undef, "getline" );
    ok( $fh->eof, "eof" );
}

{
    my @array = qw(foo bar);

    my $fh = io_from_getline sub {
        if ( @array ) {
            return shift @array;
        } else {
            return;
        }
    };

    io_ok( $fh, "from getline callback" );

    ok( !$fh->eof, "not eof" );
    is( $fh->getline, "foo", "getline" );
    is( $fh->getline, "bar", "getline" );
    is( $fh->getline, undef, "getline" );
    ok( $fh->eof, "eof" );
}

{
    my $buf = '';

    my $fh = io_from_write_cb sub {
        $buf .= $_[0];
    };

    io_ok( $fh, "write cb" );

    $fh->print("foo");
    is( $buf, "foo", "print" );

    $buf = '';
    local $\ = "bar";
    $fh->print("baz");
    is( $buf, 'bazbar', "respects ORS" );

    $buf = '';
    $fh->say("baz");
    is( $buf, "baz\n", "say localizes ORS" );

    $buf = '';
    local $, = ", ";
    $\ = "\n";
    $fh->print(qw(foo bar gorch));
    is( $buf, "foo, bar, gorch\n", "respects OFS" );

    $buf = '';
    $fh->write("foobar", 4, 2);
    is( $buf, 'obar', "handles offset/length in write" );
}

foreach my $fake (
    IO::String->new("blah"),
    IO::String->new(do { my $x = "blah"; \$x }),
    scalar(new_fh("<", "hello")),
    scalar(new_fh(">", "hello")),
) {
    ok( !is_real_fh($fake), "not a real handle ($fake)" );
}

{
    open my $fh, "<", __FILE__ or die $!;
    ok( is_real_fh($fh), "real fh" );
}

done_testing;

# ex: set sw=4 et:

