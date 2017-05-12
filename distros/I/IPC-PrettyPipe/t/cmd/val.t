#! perl

use strict;
use warnings;

use IPC::PrettyPipe::Cmd;

use Test::More;
use Test::Exception;

sub new { IPC::PrettyPipe::Cmd->new( cmd => shift(), ( @_ ? (args => \@_) : () )); }

lives_and {
    is(
        new( 'ls', [ '-a', '%OUTPUT%' ] )->valmatch( qr/%OUTPUT%/ ),
       1 );
}
'match';

lives_and {
    is(
        new( 'ls', [ '-a', '%OUTPUT%' ], [ '-b', '%OUTPUT%' ] )->valmatch( qr/%OUTPUT%/ ),
       2 );
}
'match 2';

lives_and {
    is(
        new( 'ls', [ '-a', '%INPUT%' ] )->valmatch( qr/%OUTPUT%/ ),
       0 );
}
'valmatch: value, not matched';

lives_and {
    is(
        new( 'ls', '-l' )->valmatch( qr/%INPUT%/ ),
       0 );
}
'valmatch: no value';


lives_and {

	my $cmd = new( 'ls', [ '-a', '%OUTPUT%' ] );
	$cmd->valsubst( qr/%OUTPUT%/, 'foo',);

	is( $cmd->args->elements->[0]->value, 'foo' );
}
'valsubst: match';

lives_and {

	my $cmd = new( 'ls', [ '-a', '%OUTPUT%' ], [ '-b', '%OUTPUT%' ] );
	$cmd->valsubst( qr/%OUTPUT%/, 'foo',
	              lastvalue => 'last'
	            );

	is( $cmd->args->elements->[0]->value, 'foo' );
	is( $cmd->args->elements->[1]->value, 'last' );
}
'valsubst: match, lastvalue, nmatch = 2';

lives_and {

	my $cmd = new( 'ls', [ '-a', '%OUTPUT%' ],
		             [ '-b', '%OUTPUT%' ],
		             [ '-c', '%OUTPUT%' ],
		     );
	$cmd->valsubst( qr/%OUTPUT%/, 'middle',
			firstvalue => 'first',
			lastvalue => 'last',
	            );

	is( $cmd->args->elements->[0]->value, 'first' );
	is( $cmd->args->elements->[1]->value, 'middle' );
	is( $cmd->args->elements->[2]->value, 'last' );
}
'valsubst: match, firstvalue + lastvalue, nmatch = 3';

lives_and {

	my $cmd = new( 'ls', [ '-a', '%OUTPUT%' ], [ '-b', '%INPUT%' ] );
	$cmd->valsubst( qr/%OUTPUT%/, 'foo',
	              lastvalue => 'last'
	            );

	is( $cmd->args->elements->[0]->value, 'last' );
	is( $cmd->args->elements->[1]->value, '%INPUT%' );
}
'valsubst: match, lastvalue, nmatch = 1';

lives_and {

	my $cmd = new( 'ls', [ '-a', '%OUTPUT%' ], [ '-b', '%INPUT%' ] );
	is ( $cmd->valsubst( qr/%OUTPUT%/, 'foo',
	                     firstvalue => 'first',
	                 ),
	     1);

	is( $cmd->args->elements->[0]->value, 'first' );
	is( $cmd->args->elements->[1]->value, '%INPUT%' );

}
'valsubst: match, firstvalue, nmatch = 1';

lives_and {

	my $cmd = new( 'ls', [ '-a', '%OUTPUT%' ], [ '-b', '%OUTPUT%' ] );
	is ( $cmd->valsubst( qr/%OUTPUT%/, 'foo',
	                     firstvalue => 'first',
	                 ),
	     2);
	is( $cmd->args->elements->[0]->value, 'first' );
	is( $cmd->args->elements->[1]->value, 'foo' );

}
'valsubst: match, firstvalue';


lives_and {

	my $cmd = new( 'ls', [ '-a', '%OUTPUT%' ], [ '-b', '%OUTPUT%' ] );
	$cmd->valsubst( qr/%OUTPUT%/,'foo',
	                firstvalue => 'first',
	                lastvalue => 'last'
	              );
	is( $cmd->args->elements->[0]->value, 'first' );
	is( $cmd->args->elements->[1]->value, 'last' );

}
'valsubst: match, firstvalue, lastvalue';


lives_and {

	my $cmd = new( 'ls', [ '-a', '%OUTPUT%' ] );

	$cmd->valsubst( qr/%OUTPUT%/, 'foo', { lastvalue => 'bar' } );

	is( $cmd->args->elements->[0]->value, 'bar' );
}
'valsubst: match, hash attr';

lives_and {

	my $cmd = new( 'ls', [ '-a', '%INPUT%' ] );

	is( $cmd->valsubst( qr/%OUTPUT%/, 'foo' ),
	    0 );

	is( $cmd->args->elements->[0]->value, '%INPUT%' );
}
'valsubst: no match';


done_testing;
