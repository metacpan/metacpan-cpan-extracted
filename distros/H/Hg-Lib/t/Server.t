#!perl

use strict;
use warnings;

use t::common;

use Test::More;
use Test::Exception;

use Hg::Lib::Server;

sub new { Hg::Lib::Server->new( hg => fake_hg, @_ ) }

lives_ok { new( args => [ qw( hello ) ] ) } 'hello, no args';

throws_ok { new( args => [ qw( bad_hello_chan ) ] ) }
	  	 qr/incomplete hello message/, 'bad hello channel';

throws_ok { new( args => [ qw( bad_hello_len ) ] ) }
	  	 qr/incomplete hello message/, 'bad hello length';

throws_ok { new( args => [ qw( bad_hello_no_capabilities ) ] ) }
	  	 qr/did not provide capabilities/, 'missing capabilities';

throws_ok { new( args => [ qw( bad_hello_no_runcommand ) ] ) }
	  	 qr/missing runcommand capability/, 'missing runcommand capability';

throws_ok { new( args => [ qw( bad_hello_no_encoding ) ] ) }
	  	 qr/did not provide encoding/, 'missing encoding';


done_testing;


