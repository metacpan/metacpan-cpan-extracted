use IPC::Cmd qw(run);
use Data::Dumper;
my $cmd = $ARGV[0];

print Dumper  run( command => $cmd, verbose => 0 );

    my( $success, $error_message, $full_buf, $stdout_buf, $stderr_buf ) =
            run( command => $cmd, verbose => 0 );

print "Success=$success;exit=$?\n";
