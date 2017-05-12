#! perl

use strict;
use warnings;

use IPC::PrettyPipe::Arg;

use Test::More;
use Test::Exception;

sub new { IPC::PrettyPipe::Arg->new( @_ ); }


lives_and {
    is(
        new(
            name   => 'a',
            value => '%OUTPUT%',
          )->valmatch( qr/%OUTPUT%/ ),
       1 );
}
'match';

lives_and {
    is(
        new(
            name   => 'a',
            value => '%OUTPUT%',
          )->valmatch( qr/%INPUT%/ ),
       '' );
}
'valmatch: value, not matched';

lives_and {
    is(
        new(
            name   => 'a',
          )->valmatch( qr/%INPUT%/ ),
       '' );
}
'valmatch: no value';

lives_and {

	my $arg = new(
	              name   => 'a',
	              value => '%OUTPUT%bar',
	             );

	$arg->valsubst( qr/%OUTPUT%/, 'foo' );

	is( $arg->value, 'foobar' );

}
'valsubst: value match';

lives_and {

	my $arg = new(
	              name   => 'a',
	             );

	is( $arg->valsubst( qr/%OUTPUT%/, 'foo' ), 0 );

}
'valsubst: no value';

lives_and {

	my $arg = new(
	              name   => 'a',
	              value => '%OUTPUT%bar',
	             );

	$arg->valsubst( qr/%INPUT%/, 'foo' );

	is( $arg->value, '%OUTPUT%bar' );

}
'valsubst not match';


done_testing;
