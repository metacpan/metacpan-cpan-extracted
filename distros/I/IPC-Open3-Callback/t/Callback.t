use strict;
use warnings;

eval {
    require Log::Log4perl;
    Log::Log4perl->easy_init($Log::Log4perl::ERROR);
    $Log::Log4perl::ERROR if (0);    # prevent used only once warning
};
if ($@) {
    require IPC::Open3::Callback::Logger;
    IPC::Open3::Callback::Logger->set_level('off');
}

use Test::More tests => 22;

BEGIN { use_ok('IPC::Open3::Callback') }

use Data::Dumper;
use File::Basename;
use File::Spec;
use File::Temp;
use IPC::Open3::Callback qw(safe_open3);

my @methods = (
    'new',               'get_err_callback',   'set_err_callback', 'get_last_command',
    '_set_last_command', 'get_out_callback',   'set_out_callback', 'get_buffer_size',
    'set_buffer_size',   'get_pid',            '_set_pid',         'get_input_buffer',
    'run_command',       'get_last_exit_code', '_set_last_exit_code',
);

my $test_dir          = dirname( File::Spec->rel2abs($0) );
my $echo              = 'Hello World';
my $echo_result_regex = qr/^$echo[\r\n]?[\r\n]?$/;
my $buffer            = '';
my $err_buffer        = '';
my $runner;
my $command;
my $expected;
my $temp_file;
my $file_handle;

ok( $runner = IPC::Open3::Callback->new(
        {   out_callback => sub {
                $buffer .= shift;
            },
            err_callback => sub {
                $err_buffer .= shift;
            }
        }
    ),
    'can get an instance'
);

isa_ok( $runner, 'IPC::Open3::Callback' );
can_ok( $runner, @methods );
isa_ok( $runner->get_out_callback(), 'CODE' );
isa_ok( $runner->get_err_callback(), 'CODE' );
is( $runner->get_buffer_size(), 1024, 'get_buffer_size returns the default value' );
is( $runner->run_command("echo $echo"),
    0, 'run_command() method child process returns zero (success)' );
$runner->set_buffer_size(512);
is( $runner->get_buffer_size(),  512,          'get_buffer_size returns the new value' );
is( $runner->get_last_command(), "echo $echo", 'get_last_command returns the correct value' );
is( $err_buffer,                 '',           "err_buffer has the correct value" );
like( $buffer, $echo_result_regex, "outbuffer has the correct value" );

my ( $pid, $in, $out, $err );
$runner->run_command(
    'echo', 'hello', 'world',
    {   out_callback => sub {
            $pid = $runner->get_pid();
        }
    }
);
like( $pid, qr/^\d+$/, 'get_pid returns something like a PID' );

$buffer = '';
$runner = IPC::Open3::Callback->new();
$runner->run_command(
    "echo", "Hello", "World",
    {   out_callback => sub {
            $buffer .= shift;
        }
    }
);
like( $buffer, $echo_result_regex, "out_callback as command option" );

( $pid, $in, $out, $err ) = safe_open3("echo $echo");
$buffer = '';
my $select = IO::Select->new();
$select->add($out);
while ( my @ready = $select->can_read(5) ) {
    foreach my $fh (@ready) {
        my $line;
        my $bytes_read = sysread( $fh, $line, 1024 );
        if ( !defined($bytes_read) && !$!{ECONNRESET} ) {
            die("error in running ('echo $echo'): $!");
        }
        elsif ( !defined($bytes_read) || $bytes_read == 0 ) {
            $select->remove($fh);
            next;
        }
        else {
            if ( $fh == $out ) {
                $buffer .= $line;
            }
            else {
                die("impossible... somehow got a filehandle i dont know about!");
            }
        }
    }
}
like( $buffer, $echo_result_regex, "safe_open3 read out" );
waitpid( $pid, 0 );
my $exit_code = $? >> 8;
ok( !$exit_code, "safe_open3 exited $exit_code" );

my $three_line_file_path = File::Spec->catfile( $test_dir, 'three_line_file.txt' );
$command = ( ( $^O =~ /MSWin32/ ) ? 'type ' : 'cat ' ) . $three_line_file_path;
$runner = IPC::Open3::Callback->new();
my @lines = ();
$runner->run_command(
    $command,
    {   buffer_output => 1,
        out_callback  => sub {
            push( @lines, shift );
        }
    }
);
is( scalar(@lines), 3, 'buffer_output number of calls' );
is_deeply( \@lines, [ 'three', 'line', 'file' ], 'buffer_output match' );

$temp_file = File::Temp->new();
open( $file_handle, '>', $temp_file );
$runner = IPC::Open3::Callback->new();
$command = ( ( $^O =~ /MSWin32/ ) ? 'type ' : 'cat ' ) . $three_line_file_path;
$runner->run_command( $command, { out_handle => $file_handle } );
close($file_handle);
is( do { local ( @ARGV, $/ ) = $temp_file;            <> },
    do { local ( @ARGV, $/ ) = $three_line_file_path; <> },
    'piped out handle'
);

open( my $three_line_file, '<', $three_line_file_path );
if ( $^O =~ /MSWin32/ ) {
    $command  = 'more';
    $expected = "three\r\nline\r\nfile\r\n";
}
else {
    $command  = 'cat';
    $expected = "three\nline\nfile\n";
}
$runner = IPC::Open3::Callback->new();
$buffer = '';
$runner->run_command(
    $command,
    {   in_handle    => $three_line_file,
        out_callback => sub {
            $buffer .= shift;
        }
    }
);
is( $buffer, $expected, 'piped in handle' );
close($three_line_file);

$runner = IPC::Open3::Callback->new();
my $killed;
$buffer    = '';
$exit_code = $runner->run_command(
    "cat $three_line_file_path",
    {   buffer_output => 1,
        out_callback  => sub {
            my ( $data, $pid ) = @_;
            if ( $data =~ /line/ ) {
                if ( $pid =~ /^\d+$/ ) {
                    $killed = 1;
                    kill( 9, $pid );
                }
            }
            return if ($killed);
            $buffer .= $data;
        }
    }
);
ok( $killed, 'got pid to kill' );
is( $buffer, 'three', 'short circuit' );

