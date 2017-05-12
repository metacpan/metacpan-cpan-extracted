#!/perl

use 5.10.1;

use Test::More;
use Test::Exception;
use IO::Pipe;
use Carp;

# map from signal name to signal; just in case some systems differ
use Config;
my %Signal;
{
    my @sig = split( ' ', $Config{sig_name} );
    @Signal{@sig} = ( 0..@sig-1 );
}

use Hg::Lib::Server::Pipe;


*_check_on_child = \&Hg::Lib::Server::Pipe::_check_on_child;


# see
# http://blogs.perl.org/users/aristotle/2012/10/concise-fork-idiom.html

use constant {
  FORK_ERROR  => undef,
  FORK_CHILD  => 0,
  FORK_PARENT => sub { $_[0] > 0 },
};

subtest fork_alive => sub {

    my $pipe = IO::Pipe->new;

    for (fork) {

	when (FORK_ERROR) {
	    confess "Error forking";
	}
	when (FORK_PARENT) {

	    throws_ok {_check_on_child( $_, status => 'exit' ) }
		qr/still alive/, 'alive, expect exit';

	    lives_ok {
		_check_on_child( $_, status => 'alive' );
	    } 'alive, expect alive';

	    $pipe->writer->close;

	    lives_ok {
		_check_on_child( $_, status => 'exit', wait => 1 );
	    } 'exit, expect exit';

	}
	when (FORK_CHILD) {

	    my $fh = $pipe->reader;

	    $fh->getline;
	    exit(0);
	}
    }

};


subtest fork_exit => sub {

    my $pipe = IO::Pipe->new;

    for (fork) {

	when (FORK_ERROR) {
	    confess "Error forking";
	}
	when (FORK_PARENT) {

	    throws_ok {_check_on_child( $_, status => 'exit' ) }
		qr/still alive/, 'alive, expect exit';

	    lives_ok {
		_check_on_child( $_, status => 'alive' );
	    } 'alive, expect alive';


	    kill $Signal{'TERM'}, $_
		or die( "unable to send SIGTERM to child\n" );

	    throws_ok {
		_check_on_child( $_, status => 'exit', wait => 1 );
	    } qr/signal $Signal{'TERM'}/, 'exit with signal';

	    # handle case when child has been reaped
	    lives_ok {
		_check_on_child( $_, status => 'exit', wait => 1 );
	    } 'exit: reaped child';

	    throws_ok {
		_check_on_child( $_, status => 'alive', wait => 1 );
	    } qr/unexpected exit/, 'alive: reaped child';

	}
	when (FORK_CHILD) {

	    my $fh = $pipe->reader;

	    $fh->getline;

	    exit(0);

	}
    }

};


done_testing;
