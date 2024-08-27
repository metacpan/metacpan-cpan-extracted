use Test2::V0;
use Socket ':all';
use File::Temp;
use IO::SocketAlarm 'is_socket';

my $f= File::Temp->new;
socket my $s, AF_INET, SOCK_STREAM, 0;

ok( !is_socket(undef),    'undef' );
ok( !is_socket(-1),       '-1' );
ok( !is_socket($f),       'File::Temp' );
ok( is_socket($s),        'socket' );
ok( is_socket(fileno $s), 'fileno(socket)' );
done_testing;