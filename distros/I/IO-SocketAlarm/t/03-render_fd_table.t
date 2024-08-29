use Test2::V0;
use Socket ':all';
use File::Temp;
use IO::SocketAlarm 'get_fd_table_str';

my $have_proc_fd= -d '/proc/self/fd';

my $f= File::Temp->new;
socket my $s, AF_INET, SOCK_STREAM, 0;
my $file_fd= fileno($f);
my $sock_fd= fileno($s);

ok( my $table= get_fd_table_str, 'get_fd_table_str' );
note $table;
like( $table, qr/^ *$file_fd: $f$/m,    'includes known file' )
   if $have_proc_fd;
like( $table, qr/^ *$sock_fd: inet \[0\.0\.0\.0\]:0$/m, 'includes known socket' );
like( $table, qr/\}\n\Z/, 'ends with }\\n' );

done_testing;