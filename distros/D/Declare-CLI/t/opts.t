package Declare::Opts::Test;
use strict;
use warnings;
use Fennec;

my $CLASS;
BEGIN {
    $CLASS = 'Declare::Opts';
    use_ok $CLASS;
}

tests load => sub {
    can_ok( __PACKAGE__, qw/ OPTS_META opt parse_opts/ );
    isa_ok( OPTS_META(), $CLASS );

    is( OPTS_META->class, __PACKAGE__, "correct class" );
    is_deeply( OPTS_META->opts, {}, "no opts yet" );
};

tests simple => sub {
    opt 'foo';
    opt 'bar';
    opt 'baz';

    my ( $args, $opts ) = parse_opts(
        '--foo=zoot',
        '-bar' => 'a',
        '--baz' => 'b',
        '--',
        '-tub',
        'blug'
    );

    is_deeply( $args, ['-tub', 'blug'], "Got params" );
    is_deeply( $opts, { foo => 'zoot', bar => 'a', baz => 'b' }, "got flags" );

    ok( !eval { parse_opts( '-b' => 'xxx' ); 1 }, "Ambiguity" );
    like( $@, qr/option 'b' is ambiguous, could be: (bar|baz), (bar|baz)/, "Ambiguity Message" );

    ok( !eval { parse_opts( '-x' => 'xxx' ); 1 }, "Invalid" );
    like( $@, qr/unknown option 'x'/, "Invalid Message" );
};

tests description => sub {
    opt 'foo';
    opt bar => ( description => 'a bar' );

    my $info = opt_info();

    is_deeply(
        opt_info(),
        {
            bar => 'a bar',
            foo => 'No Description',
        },
        "Got Info"
    );
};

tests complex => sub {
    opt foo => ( bool => 1 );
    opt bar => ( list => 1 );
    opt baz => ( alias => 'zag' );
    opt buz => ( bool => 1, default => 1 );
    opt tin => ( default => 'fred', alias => ['tinn', 'tinnn'] );

    ok( !eval { opt boot => ( bool => 1, list => 1 ); 1 }, "invalid props" );
    like( $@, qr/opt properties 'list' and 'bool' are mutually exclusive/, "invalid prop message" );

    my ( $args, $opts ) = parse_opts(
        '-f',
        '--bar' => 'a,b,c, d , e',
        '-bar=1, 2 ,3',
        '-zag=b',
        '--',
        '-tub',
        'blug'
    );

    is_deeply( $args, ['-tub', 'blug'], "Got params" );
    is_deeply(
        $opts,
        {
            foo => 1,
            bar => [qw/a b c d e 1 2 3/],
            baz => 'b',
            buz => 1,
            tin => 'fred'
        },
        "got flags"
    );

    ( $args, $opts ) = parse_opts(
        '-f=0',
        '-buz',
        '--tinnn',
        "din dan"
    );

    is_deeply( $args, [], "Got params" );
    is_deeply(
        $opts,
        {
            foo => 0,
            buz => 0,
            tin => 'din dan'
        },
        "change default"
    );
};

tests validation => sub {
    opt code   => ( check => sub { $_[0] eq 'food' });
    opt number => ( check => 'number', list => 1    );
    opt dir    => ( check => 'dir',    list => 1    );
    opt regex  => ( check => qr/^AAA/               );
    opt file   => ( check => 'file'                 );

    ok( !eval { opt bad1 => ( check => "foo" ); 1 }, "invalid check (string)" );
    like( $@, qr/'foo' is not a valid value for 'check'/, "invalid check message" );

    ok( !eval { opt bad2 => ( check => []    ); 1 }, "invalid check (ref)" );
    like( $@, qr/'ARRAY\(0x[\da-fA-F]*\)' is not a valid value for 'check'/, "invalid check message" );

    lives_ok { parse_opts(
        '-code=food',
        '--regex' => 'AAA Whatever',
        '-number' => '100, 22, 3435',
        '-file'   => __FILE__,
        '-dir'    => '., ..',
    ) } "Valid opts";

    ok( !eval { parse_opts( '--code=tub' ); 1 }, "fail check (code)" );
    like( $@, qr/Validation Failed for 'code=CODE': tub/, "fail check message (code)" );

    ok( !eval { parse_opts( '-regex' => 'Whatever' ); 1 }, "fail check (regex)" );
    like( $@, qr/Validation Failed for 'regex=Regexp': Whatever/, "fail check message (regex)" );

    ok( !eval { parse_opts( '--number' => 'a,b,1,2'); 1 }, "fail check (number)" );
    like( $@, qr/Validation Failed for 'number=number': a, b/, "fail check message (number)" );

    ok( !eval { parse_opts( '-file' => '/Some/Fake/File' ); 1 }, "fail check (file)" );
    like( $@, qr{Validation Failed for 'file=file': /Some/Fake/File}, "fail check message (file)" );

    ok( !eval { parse_opts( '-dir' => '/Some/Fake/Dir,/Another/Fake/Dir,.,..' ); 1 }, "fail check (dir)" );
    like( $@, qr{Validation Failed for 'dir=dir': /Some/Fake/Dir, /Another/Fake/Dir}, "fail check message (dir)" );
};

tests transform => sub {
    opt add5 => ( transform => sub { $_[0] + 5 }, check => 'number' );
    opt add6 => ( transform => sub { $_[0] + 6 }, check => 'number', list => 1 );

    my ( $args, $opts ) = parse_opts(
        '-add5' => '5',
        '-add6' => '1,2,3',
        '--',
        '-tub',
        'blug'
    );

    is_deeply( $args, ['-tub', 'blug'], "Got params" );
    is_deeply(
        $opts,
        {
            add5 => 10,
            add6 => [ 7, 8 ,9 ],
        },
        "got flags"
    );
};

done_testing;
