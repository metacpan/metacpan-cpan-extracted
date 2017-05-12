# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

use Mail::Postfix::Attr;

use Test::More tests => 3 ;
use Data::Dumper ;
use IO::Socket::UNIX ;

my @attrs = (

	'number'	=> '4711',
	'long_number'	=> '1234',
	'string'	=> 'whoopee',
	'foo-name'	=> 'foo-value',
	'bar-name'	=> 'bar-value',
	'number'	=> '4711',
	'long_number'	=> '1234',
	'string'	=> 'whoopee',
) ;

my $golden = Dumper \@attrs ;
#print $golden ;

my $sock_path = 'postfix_sock' ;


foreach my $type ( qw( 0 64 plain ) ) {

	fork_server() ;
	sleep 1 ;

	my $pf = Mail::Postfix::Attr->new( 'path' => $sock_path,
					   'codec' => $type ) ;

	my @attrs_back = $pf->send( @attrs ) ;

#print "RECV ", Dumper \@back_attrs ;

	my $back_text = Dumper \@attrs_back ;

#print "BACK $back_text\n" ;

	is( $back_text, $golden, "format $type" ) ;
}

unlink $sock_path ;

exit ;


sub fork_server {

	return if fork() ;

	unlink $sock_path ;

	my $listen_sock = IO::Socket::UNIX->new(
				Listen => 5,
				Local => $sock_path
	) ;

	$listen_sock or die "can't listen on '$sock_path' $!" ;

#print "$$ listen ok\n" ;

	my $sock = $listen_sock->accept() ;

	my $buf ;

	sysread( $sock, $buf, 1000 ) ;

#print "READ [$buf]\n" ;

	syswrite( $sock, $buf ) ;

#print "exiting\n" ;
	exit() ;
}
