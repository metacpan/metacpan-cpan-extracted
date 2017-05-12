#!perl

use strict;
use warnings;

use t::common;

use Test::More;
use Test::Exception;

use Hg::Lib::Server::Pipe;

sub fnew { Hg::Lib::Server::Pipe->new( hg => fake_hg, @_ ) }

lives_ok { fnew( args => [ qw( wait ) ] ) } 'fake, no args';

throws_ok {

    my $pipe = fnew( args => [ qw( fail )  ] );

    # we have to wait a bit to make sure that the process actually
    # dies.
    for ( 0..10 ) {
	sleep 1;
	Hg::Lib::Server::Pipe::_check_on_child( $pipe->_pid,
						status => 'alive' );
    }


}  qr/unexpected exit of child/, 'fake, fail';


subtest 'badlen' => sub {

    my $hg;
    lives_ok { $hg = fnew( args => [ qw(  badlen ) ] ) } 'open hg';


    throws_ok { $hg->get_chunk( my $buf ) } qr/end-of-file reading/, 'short data';

};


done_testing;


