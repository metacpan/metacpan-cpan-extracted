#! perl

use Test2::V0;

use IPC::PrettyPipe::Cmd;

sub new {
    IPC::PrettyPipe::Cmd->new( cmd => shift(), ( @_ ? ( args => \@_ ) : () ) );
}

subtest 'match' => sub {
    my $cmd;
    ok( lives { $cmd = new( 'ls', [ '-a', '%OUTPUT%' ] ) } );
    is( $cmd->valmatch( qr/%OUTPUT%/ ), 1, );
};

subtest 'match 2' => sub {
    my $cmd;
    ok(
        lives {
            $cmd = new( 'ls', [ '-a', '%OUTPUT%' ], [ '-b', '%OUTPUT%' ] );
        } );
    is( $cmd->valmatch( qr/%OUTPUT%/ ), 2, );
};

subtest 'valmatch: value, not matched' => sub {
    my $cmd;
    ok( lives { $cmd = new( 'ls', [ '-a', '%INPUT%' ] ) } );
    is( $cmd->valmatch( qr/%OUTPUT%/ ), 0, );
};

subtest 'valmatch: no value' => sub {
    my $cmd;
    ok( lives { $cmd = new( 'ls', '-l' ) } );
    is( $cmd->valmatch( qr/%INPUT%/ ), 0 );
};


subtest 'valsubst: match' => sub {
    my $cmd;
    ok(
        lives {
            $cmd = new( 'ls', [ '-a', '%OUTPUT%' ] );
            $cmd->valsubst( qr/%OUTPUT%/, 'foo', );
        } );
    is( $cmd->args->elements->[0]->value, 'foo' );
};

subtest 'valsubst: match, lastvalue, nmatch = 2' => sub {
    my $cmd;
    ok(
        lives {
            $cmd = new( 'ls', [ '-a', '%OUTPUT%' ], [ '-b', '%OUTPUT%' ] );
            $cmd->valsubst( qr/%OUTPUT%/, 'foo', lastvalue => 'last' );
        } );

    is( $cmd->args->elements->[0]->value, 'foo' );
    is( $cmd->args->elements->[1]->value, 'last' );
};

subtest 'valsubst: match, firstvalue + lastvalue, nmatch = 3' => sub {
    my $cmd;
    ok(
        lives {
            $cmd = new(
                'ls',
                [ '-a', '%OUTPUT%' ],
                [ '-b', '%OUTPUT%' ],
                [ '-c', '%OUTPUT%' ],
            );
            $cmd->valsubst(
                qr/%OUTPUT%/, 'middle',
                firstvalue => 'first',
                lastvalue  => 'last',
            );
        } );
    is( $cmd->args->elements->[0]->value, 'first' );
    is( $cmd->args->elements->[1]->value, 'middle' );
    is( $cmd->args->elements->[2]->value, 'last' );
};

subtest 'valsubst: match, lastvalue, nmatch = 1' => sub {
    my $cmd;
    ok(
        lives {
            $cmd = new( 'ls', [ '-a', '%OUTPUT%' ], [ '-b', '%INPUT%' ] );
            $cmd->valsubst( qr/%OUTPUT%/, 'foo', lastvalue => 'last' );
        } );

    is( $cmd->args->elements->[0]->value, 'last' );
    is( $cmd->args->elements->[1]->value, '%INPUT%' );
};

subtest 'valsubst: match, firstvalue, nmatch = 1' => sub {
    my $cmd;
    ok(
        lives {
            $cmd = new( 'ls', [ '-a', '%OUTPUT%' ], [ '-b', '%INPUT%' ] );
        } );
    is( $cmd->valsubst( qr/%OUTPUT%/, 'foo', firstvalue => 'first', ), 1 );

    is( $cmd->args->elements->[0]->value, 'first' );
    is( $cmd->args->elements->[1]->value, '%INPUT%' );

};

subtest 'valsubst: match, firstvalue' => sub {

    my $cmd;
    ok(
        lives { $cmd = new( 'ls', [ '-a', '%OUTPUT%' ], [ '-b', '%OUTPUT%' ] ) }
    );
    is( $cmd->valsubst( qr/%OUTPUT%/, 'foo', firstvalue => 'first', ), 2 );
    is( $cmd->args->elements->[0]->value, 'first' );
    is( $cmd->args->elements->[1]->value, 'foo' );

};


subtest 'valsubst: match, firstvalue, lastvalue' => sub {

    my $cmd;
    ok(
        lives {
            $cmd
              = new( 'ls', [ '-a', '%OUTPUT%' ], [ '-b', '%OUTPUT%' ] );
            $cmd->valsubst(
                qr/%OUTPUT%/, 'foo',
                firstvalue => 'first',
                lastvalue  => 'last'
            );
        } );
    is( $cmd->args->elements->[0]->value, 'first' );
    is( $cmd->args->elements->[1]->value, 'last' );
};


subtest 'valsubst: match, hash attr' => sub {

    my $cmd;

    ok(
        lives {
            $cmd = new( 'ls', [ '-a', '%OUTPUT%' ] );
            $cmd->valsubst( qr/%OUTPUT%/, 'foo', { lastvalue => 'bar' } );
        } );

    is( $cmd->args->elements->[0]->value, 'bar' );
};

subtest 'valsubst: no match' => sub {

    my $cmd;
    ok( lives { $cmd = new( 'ls', [ '-a', '%INPUT%' ] ) } );

    is( $cmd->valsubst( qr/%OUTPUT%/, 'foo' ), 0 );
    is( $cmd->args->elements->[0]->value, '%INPUT%' );
};


done_testing;
