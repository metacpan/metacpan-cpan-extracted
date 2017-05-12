use Test::More tests => 5;

BEGIN { use_ok('IO::Socket::ByteCounter') };

my $path   = 'socket.rocket';
unlink $path;

use IO::Socket::UNIX;

ok(IO::Socket::ByteCounter->record_bytes('IO::Socket') eq '1', 'record_bytes');
my $listen = IO::Socket::UNIX->new('Local' => $path, 'Listen' => 0) || die "$!";

if(my $pid = fork()) {

    my $sock = $listen->accept();

    if (defined $sock) {
        my $buf;
    	$sock->recv($buf, 12);      
        $sock->send("Hello Yourself, Lovely weather today", 0, 'mypeer');
        
        ok($sock->get_bytes_out() eq '36', 'bytes out');
        ok($sock->get_bytes_in()  eq '12', 'bytes in');
        ok($sock->get_bytes_total() eq '48', 'bytes total');
        
    	$sock->close;

    	waitpid $pid, 0;
    	unlink $path or warn "Can't unlink $path: $!";
    } 
    else {
    	die "# accept() failed: $!";
    }
} 
elsif(defined $pid) {
    my $sock = IO::Socket::UNIX->new('Peer' => $path) or die "$!";
    
    $sock->send("Hello World\n", 0, 'mypeer');
    my $buf;
    $sock->recv($buf, 36); 
    
    $sock->close;
    exit;
} 
else {
    die;
}