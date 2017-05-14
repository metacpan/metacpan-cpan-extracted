# Very simple: just get the TouchSensor event and give
# a random color to the other box.

$PORT=9000;

use IO::Socket;

$server = IO::Socket::INET->new(Proto => 'tcp',
	LocalPort => $PORT,
	Listen => SOMAXCONN,
	Reuse => 1) or die("Can't set up server");

system("perl ./freewrl eai/t1.wrl eai=localhost:$PORT &");

$sock = $server->accept();
$sock->autoflush(1);

print "EAI CLIENT STARITNG!!!!!\n";

sub getlines {
	my @arr;
	for(1..$_[0]) {
		print "EXPECTING ROW $_\n";
		my $str = <$sock>;
		chomp $str;
		print "GOT '$str'\n";
		push @arr, $str;
	}
	return @arr;
}

# Test the sample EAI protocol.

$a = <$sock>;
print "GOT HANDSHAKE '$a'\n";
$sock->print("TJL EAI CLIENT 0.00\n");

$sock->print("1\nGN TS\n2\nGN MAT\n");

my @l = getlines(4);

$sock->print("3\nRL $l[1] touchTime XX\n");

my @l2 = getlines(1);

# XXX This is fragile - it breaks if user clicks quickly and two events
# come before our response gets to them
while(@x = getlines(2)) {
	if($x[0] ne "XX") {die("Invalid ev '$x[0]'")}
	$sock->print("15\nSE $l[3] diffuseColor\n".(join ' ',map {rand} 0..2)
		."\n");
	@y = getlines(1);
}
