package Declare::CLI::Test;
use strict;
use warnings;
use Fennec;

use Scalar::Util qw/blessed/;

my $CLASS;
BEGIN {
    $CLASS = 'Declare::CLI';
    use_ok $CLASS;
}

sub opts { shift->{opts} };
sub set_opts {
    my $self = shift;
    ($self->{opts}) = @_;
}

before_all load => sub {
    my $self = shift;
    can_ok(
        $self,
        qw{
            CLI_META opt arg process_cli usage describe_opt describe_arg
            preparse_cli parse_cli run_cli handle_cli
        }
    );
    isa_ok( CLI_META(), $CLASS );
    is( CLI_META->class, blessed($self), "correct class" );
    is_deeply( CLI_META->opts, {}, "no opts yet" );
    is_deeply( CLI_META->args, {}, "no args yet" );
};

tests simple => sub {
    my $self = shift;

    my $saw = {};
    arg '-tub' => sub {
        is( $_[0], $self, "got self" );
        is( $_[1], '-tub', "got this arg" );
        is( ref( $_[2] ), 'HASH', "got opts hash" );
        $saw->{tub} = 1;
    };

    opt 'foo';
    opt 'bar';
    opt 'baz';

    my ( $opts, $args ) = $self->parse_cli(
        '--foo=zoot',
        '-bar' => 'a',
        '--baz' => 'b',
        '--',
        '-tub',
        'blug'
    );
    $self->run_cli( $opts, $args );

    is_deeply( $saw, { tub => 1 }, "Args handled properly" );
    is_deeply( $opts, { foo => 'zoot', bar => 'a', baz => 'b' }, "got opts" );

    arg xxxa => sub { 1 };
    arg xxxb => sub { 1 };

    ok( !eval { $self->handle_cli( 'xxx' ); 1 }, "Ambiguity" );
    like( $@, qr/partial argument 'xxx' is ambiguous, could be: xxxa, xxxb/, "Ambiguity Message" );

    ok( !eval { $self->handle_cli( '-b' => 'xxx' ); 1 }, "Ambiguity" );
    like( $@, qr/partial option 'b' is ambiguous, could be: bar, baz/, "Ambiguity Message" );

    ok( !eval { $self->handle_cli( '-x' => 'xxx' ); 1 }, "Invalid" );
    like( $@, qr/unknown option 'x'/, "Invalid Message" );
};

tests usage => sub {
    my $self = shift;

    opt 'nodesc';
    opt foo => ( description => "this is foo" );
    opt bool => ( bool => 1, description => 'this is bool' );
    opt list => ( list => 1, description => 'this is list' );
    opt longer => ( description => 'this is longer' );

    arg one => sub { 1 };
    arg two => sub { 2 };
    arg three => ( handler => sub { 3 }, description => 'is three' );

    is( $self->usage, <<"    EOT", "Get usage" );
Options:
    -bool              this is bool
    -foo    XXX        this is foo
    -list   XXX,...    this is list
    -longer XXX        this is longer
    -nodesc XXX        No Description.

Arguments:
    one      No Description.
    three    is three
    two      No Description.

    EOT

    describe_opt nodesc => "nodesc is now described";
    describe_arg one => "Just a one";

    is( $self->usage, <<"    EOT", "Get usage" );
Options:
    -bool              this is bool
    -foo    XXX        this is foo
    -list   XXX,...    this is list
    -longer XXX        this is longer
    -nodesc XXX        nodesc is now described

Arguments:
    one      Just a one
    three    is three
    two      No Description.

    EOT
};

tests complex => sub {
    my $self = shift;

    my $saw = {};
    arg 'zubba' => (
        alias => '-tubb',
        handler => sub {
            is( $_[0], $self, "got self" );
            is( $_[1], 'zubba', "got this arg" );
            is( ref( $_[2] ), 'HASH', "got opts hash" );
            is( $_[3], 'blug', "got next args" );
            is( $_[4], 'foo', "got next args" );
            $saw->{tub} = 1;
        }
    );
    arg 'blug' => sub { $saw->{blug} = 1 };

    opt foo => ( bool => 1 );
    opt bar => ( list => 1 );
    opt baz => ( alias => 'zag' );
    opt buz => ( bool => 1, default => 1 );
    opt tin => ( default => 'fred', alias => ['tinn', 'tinnn'] );

    ok( !eval { opt boot => ( bool => 1, list => 1 ); 1 }, "invalid props" );
    like( $@, qr/opt properties 'list' and 'bool' are mutually exclusive/, "invalid prop message" );

    my ( $opts, $args ) = $self->parse_cli(
        '-f',
        '--bar' => 'a,b,c, d , e',
        '-bar=1, 2 ,3',
        '-zag=b',
        '--',
        '-tub',
        'blug',
        'foo',
    );
    $self->run_cli( $opts, $args );

    is_deeply( $saw, { tub => 1 }, "Args handled properly" );
    is_deeply(
        $opts,
        {
            foo => 1,
            bar => [qw/a b c d e 1 2 3/],
            baz => 'b',
            buz => 1,
            tin => 'fred'
        },
        "got opts"
    );

    ( $opts, $args ) = $self->parse_cli(
        '-f=0',
        '-buz',
        '--tinnn',
        "din dan"
    );

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
    my $self = shift;

    opt code   => ( check => sub { $_[0] eq 'food' });
    opt number => ( check => 'number', list => 1    );
    opt dir    => ( check => 'dir',    list => 1    );
    opt regex  => ( check => qr/^AAA/               );
    opt file   => ( check => 'file'                 );

    ok( !eval { opt bad1 => ( check => "foo" ); 1 }, "invalid check (string)" );
    like( $@, qr/'foo' is not a valid value for 'check'/, "invalid check message" );

    ok( !eval { opt bad2 => ( check => []    ); 1 }, "invalid check (ref)" );
    like( $@, qr/'ARRAY\(0x[\da-fA-F]*\)' is not a valid value for 'check'/, "invalid check message" );

    lives_ok { $self->parse_cli(
        '-code=food',
        '--regex' => 'AAA Whatever',
        '-number' => '100, 22, 3435',
        '-file'   => __FILE__,
        '-dir'    => '., ..',
    ) } "Valid opts";

    ok( !eval { $self->handle_cli( '--code=tub' ); 1 }, "fail check (code)" );
    like( $@, qr/Validation Failed for 'code=CODE': tub/, "fail check message (code)" );

    ok( !eval { $self->handle_cli( '-regex' => 'Whatever' ); 1 }, "fail check (regex)" );
    like( $@, qr/Validation Failed for 'regex=Regexp': Whatever/, "fail check message (regex)" );

    ok( !eval { $self->handle_cli( '--number' => 'a,b,1,2'); 1 }, "fail check (number)" );
    like( $@, qr/Validation Failed for 'number=number': a, b/, "fail check message (number)" );

    ok( !eval { $self->handle_cli( '-file' => '/Some/Fake/File' ); 1 }, "fail check (file)" );
    like( $@, qr{Validation Failed for 'file=file': /Some/Fake/File}, "fail check message (file)" );

    ok( !eval { $self->handle_cli( '-dir' => '/Some/Fake/Dir,/Another/Fake/Dir,.,..' ); 1 }, "fail check (dir)" );
    like( $@, qr{Validation Failed for 'dir=dir': /Some/Fake/Dir, /Another/Fake/Dir}, "fail check message (dir)" );
};

tests transform_and_trigger => sub {
    my $self = shift;

    my %triggered;

    opt add5 => (
        transform => sub { $_[1] + 5 },
        check => 'number',
        trigger => sub {
            is( $_[0], $self, "got self" );
            is( $_[1], 'add5', "got opt name" );
            is( $_[2], '10', "got value" );
            $triggered{$_[1]}++;
        },
    );
    opt add6 => (
        transform => sub { $_[1] + 6 },
        check => 'number',
        list => 1,
        trigger => sub {
            is( $_[0], $self, "got self" );
            is( $_[1], 'add6', "got opt name" );
            is_deeply( $_[2], [ 7, 8, 9 ], "got value" );
            $triggered{$_[1]}++;
        },
    );

    my ( $opts, $args ) = $self->parse_cli(
        '-add5' => '5',
        '-add6' => '1,2,3',
    );

    is_deeply( \%triggered, { add5 => 1, add6 => 1 }, "triggers fired" );

    is_deeply(
        $opts,
        {
            add5 => 10,
            add6 => [ 7, 8 ,9 ],
        },
        "got opts"
    );
};

describe legacy => sub {
    tests simple => sub {
        my $self = shift;

        my $saw = {};
        arg '-tub' => sub {
            is( $_[0], $self, "got self" );
            is( $_[1], '-tub', "got this arg" );
            is( ref( $_[2] ), 'HASH', "got opts hash" );
            $saw->{tub} = 1;
        };

        opt 'foo';
        opt 'bar';
        opt 'baz';

        $self->process_cli(
            '--foo=zoot',
            '-bar' => 'a',
            '--baz' => 'b',
            '--',
            '-tub',
            'blug'
        );

        is_deeply( $saw, { tub => 1 }, "Args handled properly" );
        is_deeply( $self->opts, { foo => 'zoot', bar => 'a', baz => 'b' }, "got opts" );

        arg xxxa => sub { 1 };
        arg xxxb => sub { 1 };

        ok( !eval { $self->process_cli( 'xxx' ); 1 }, "Ambiguity" );
        like( $@, qr/partial argument 'xxx' is ambiguous, could be: xxxa, xxxb/, "Ambiguity Message" );

        ok( !eval { $self->process_cli( '-b' => 'xxx' ); 1 }, "Ambiguity" );
        like( $@, qr/partial option 'b' is ambiguous, could be: bar, baz/, "Ambiguity Message" );

        ok( !eval { $self->process_cli( '-x' => 'xxx' ); 1 }, "Invalid" );
        like( $@, qr/unknown option 'x'/, "Invalid Message" );
    };

    tests complex => sub {
        my $self = shift;

        my $saw = {};
        arg 'zubba' => (
            alias => '-tubb',
            handler => sub {
                is( $_[0], $self, "got self" );
                is( $_[1], 'zubba', "got this arg" );
                is( ref( $_[2] ), 'HASH', "got opts hash" );
                is( $_[3], 'blug', "got next args" );
                is( $_[4], 'foo', "got next args" );
                $saw->{tub} = 1;
            }
        );
        arg 'blug' => sub { $saw->{blug} = 1 };

        opt foo => ( bool => 1 );
        opt bar => ( list => 1 );
        opt baz => ( alias => 'zag' );
        opt buz => ( bool => 1, default => 1 );
        opt tin => ( default => 'fred', alias => ['tinn', 'tinnn'] );

        ok( !eval { opt boot => ( bool => 1, list => 1 ); 1 }, "invalid props" );
        like( $@, qr/opt properties 'list' and 'bool' are mutually exclusive/, "invalid prop message" );

        $self->process_cli(
            '-f',
            '--bar' => 'a,b,c, d , e',
            '-bar=1, 2 ,3',
            '-zag=b',
            '--',
            '-tub',
            'blug',
            'foo',
        );

        is_deeply( $saw, { tub => 1 }, "Args handled properly" );
        is_deeply(
            $self->opts,
            {
                foo => 1,
                bar => [qw/a b c d e 1 2 3/],
                baz => 'b',
                buz => 1,
                tin => 'fred'
            },
            "got opts"
        );

        $self->process_cli(
            '-f=0',
            '-buz',
            '--tinnn',
            "din dan"
        );

        is_deeply(
            $self->opts,
            {
                foo => 0,
                buz => 0,
                tin => 'din dan'
            },
            "change default"
        );
    };

    tests validation => sub {
        my $self = shift;

        opt code   => ( check => sub { $_[0] eq 'food' });
        opt number => ( check => 'number', list => 1    );
        opt dir    => ( check => 'dir',    list => 1    );
        opt regex  => ( check => qr/^AAA/               );
        opt file   => ( check => 'file'                 );

        ok( !eval { opt bad1 => ( check => "foo" ); 1 }, "invalid check (string)" );
        like( $@, qr/'foo' is not a valid value for 'check'/, "invalid check message" );

        ok( !eval { opt bad2 => ( check => []    ); 1 }, "invalid check (ref)" );
        like( $@, qr/'ARRAY\(0x[\da-fA-F]*\)' is not a valid value for 'check'/, "invalid check message" );

        lives_ok { $self->process_cli(
            '-code=food',
            '--regex' => 'AAA Whatever',
            '-number' => '100, 22, 3435',
            '-file'   => __FILE__,
            '-dir'    => '., ..',
        ) } "Valid opts";

        ok( !eval { $self->process_cli( '--code=tub' ); 1 }, "fail check (code)" );
        like( $@, qr/Validation Failed for 'code=CODE': tub/, "fail check message (code)" );

        ok( !eval { $self->process_cli( '-regex' => 'Whatever' ); 1 }, "fail check (regex)" );
        like( $@, qr/Validation Failed for 'regex=Regexp': Whatever/, "fail check message (regex)" );

        ok( !eval { $self->process_cli( '--number' => 'a,b,1,2'); 1 }, "fail check (number)" );
        like( $@, qr/Validation Failed for 'number=number': a, b/, "fail check message (number)" );

        ok( !eval { $self->process_cli( '-file' => '/Some/Fake/File' ); 1 }, "fail check (file)" );
        like( $@, qr{Validation Failed for 'file=file': /Some/Fake/File}, "fail check message (file)" );

        ok( !eval { $self->process_cli( '-dir' => '/Some/Fake/Dir,/Another/Fake/Dir,.,..' ); 1 }, "fail check (dir)" );
        like( $@, qr{Validation Failed for 'dir=dir': /Some/Fake/Dir, /Another/Fake/Dir}, "fail check message (dir)" );
    };

    tests transform_and_trigger => sub {
        my $self = shift;

        my %triggered;

        opt add5 => (
            transform => sub { $_[1] + 5 },
            check => 'number',
            trigger => sub {
                is( $_[0], $self, "got self" );
                is( $_[1], 'add5', "got opt name" );
                is( $_[2], '10', "got value" );
                $triggered{$_[1]}++;
            },
        );
        opt add6 => (
            transform => sub { $_[1] + 6 },
            check => 'number',
            list => 1,
            trigger => sub {
                is( $_[0], $self, "got self" );
                is( $_[1], 'add6', "got opt name" );
                is_deeply( $_[2], [ 7, 8, 9 ], "got value" );
                $triggered{$_[1]}++;
            },
        );

        $self->process_cli(
            '-add5' => '5',
            '-add6' => '1,2,3',
        );

        is_deeply( \%triggered, { add5 => 1, add6 => 1 }, "triggers fired" );

        is_deeply(
            $self->opts,
            {
                add5 => 10,
                add6 => [ 7, 8 ,9 ],
            },
            "got opts"
        );
    };
};

done_testing;

