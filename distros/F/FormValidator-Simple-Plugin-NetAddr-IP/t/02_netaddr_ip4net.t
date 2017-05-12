use strict;
use Test::More tests => 26;
use CGI;

use FormValidator::Simple;
FormValidator::Simple->import('NetAddr::IP');

use NetAddr::IP;

my $q = CGI->new;

# Lines of good data
my $line = 12;
for (1..$line) {
	my $num = <DATA>;
	chomp $num;
	$q->param( ip => $num );
	my $r = FormValidator::Simple->check( $q => [
						     ip => [qw/NETADDR_IP4NET/],
						     ] );
	unless ( ok(!$r->invalid('ip'),'ok '.$num) )
	{
		my $addr = NetAddr::IP->new($num);
		diag( "$num becomes ".$addr );
	}
}

# The rest is bad
while (<DATA>) {
	chomp;
	$q->param( ip => $_ );
	my $r = FormValidator::Simple->check( $q => [
						     ip => [qw/NETADDR_IP4NET/],
						     ] );
	unless( ok($r->invalid('ip'), 'invalid '.$_ ) )
	{
		my $addr = NetAddr::IP->new($_);
		diag( "$_ becomes ".$addr );
	}
}









__DATA__
127.0.0.1
10.0.0.1
192.168.0.1
172.16.0.1
1.1.1.1
255.255.255.255
224.0.0.1
64.111.122.213
64.111.122.213/32
64.111.122.213/31
64.111.122.213/30
64.111.122.213/24
10
10.10
10.10.10
300.0.0.1
127.300.0.1
127.0.1000.1
127.0.0.1000
127..0.1
"127,0,0,1"
example.com
64.111.122.213\32
64 111.122.213
64/111.122.213
64-111-122-213