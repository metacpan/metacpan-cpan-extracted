use Test::More tests => 8;

use lib '../lib', 'lib';

chdir 't';

use IPC::Open3::Utils qw(:all);

my $output = '';    # my $output; ;

my $rc = IPC::Open3::Utils::put_cmd_in( q{perl -e 'my $line=<STDIN>;print $line;'}, \$output, { 'pre_read_print_to_stdin' => "Hello World\n" } );
ok( $output eq "Hello World\n", "pre_read_print_to_stdin as string properly handled" );

$output = '';
$rc = IPC::Open3::Utils::put_cmd_in( q{perl -e 'for (1..2) { my $line=readline(STDIN);print $line }'}, \$output, { 'pre_read_print_to_stdin' => [ "Hello World\n", "test\n" ] } );
ok( $output eq "Hello World\ntest\n", "pre_read_print_to_stdin as array ref of strings properly handled" );

$output = '';
$rc     = IPC::Open3::Utils::put_cmd_in(
    q{perl -e 'for (1..2) { my $line=readline(STDIN);print $line }'},
    \$output,
    {
        'pre_read_print_to_stdin' => sub { return "Hello World\n", "test\n" }
    }
);
ok( $output eq "Hello World\ntest\n", "pre_read_print_to_stdin as code ref that returns  array of strings properly handled" );

diag("Testing for exit-before-write-to-stdin race condition");
$output = '';
$rc = IPC::Open3::Utils::put_cmd_in( q{perl -e 'exit;my $line=<STDIN>;print $line;'}, \$output, { 'pre_read_print_to_stdin' => "Hello World\n", '_pre_run_sleep' => 1 } );
ok( $output eq '', "pre_read_print_to_stdin properly handles command that immediately exits (i.e. before the print)" );

$output = '';
$rc = IPC::Open3::Utils::put_cmd_in( q{perl -e 'exit;my $line=<STDIN>;print $line;'}, \$output, { 'close_stdin' => 1, 'pre_read_print_to_stdin' => "Hello World\n", '_pre_run_sleep' => 1 } );
ok( $output eq '', "pre_read_print_to_stdin properly handles command that immediately exits (i.e. before the print) close_stdin true" );

$output = '';
$rc = IPC::Open3::Utils::put_cmd_in( q{perl -e 'my $line=<STDIN>;print $line;print STDERR "oops\n";exit;'}, \$output, { 'pre_read_print_to_stdin' => "Hello World\n", '_pre_run_sleep' => 2 } );
ok( $output eq "Hello World\noops\n" || $output eq "oops\nHello World\n", "pre_read_print_to_stdin properly handles command that exits before read is done(i.e. before the print)" );

$output = '';
$rc = IPC::Open3::Utils::put_cmd_in( q{perl -e 'my $line=<STDIN>;print $line;print STDERR "oops\n";exit;'}, \$output, { 'close_stdin' => 1, 'pre_read_print_to_stdin' => "Hello World\n", '_pre_run_sleep' => 2 } );
ok( $output eq "Hello World\noops\n" || $output eq "oops\nHello World\n", "pre_read_print_to_stdin properly handles command that exits before read is done (i.e. before the print) close_stdin true" );

$output = '';
$rc = IPC::Open3::Utils::put_cmd_in( q{perl -e 'print STDOUT "Hello World\n";print $line;print STDERR "oops\n";exit;'}, \$output, { '_pre_run_sleep' => 2 } );
ok( $output eq "Hello World\noops\n" || $output eq "oops\nHello World\n", "start read after proc exit" );
