use Test::More;
use LogFilter;
use File::ShareDir 'module_dir';

my ($vol, $dir, $file) = File::Spec->splitpath(__FILE__);
my $test_data_dir = File::Spec->catdir($dir, '..', 'share');

my $keywords_file = File::Spec->catfile($test_data_dir, 'test_keywords.txt');
my $exclude_file = File::Spec->catfile($test_data_dir, 'test_exclude.txt');
my $log_file = File::Spec->catfile($test_data_dir, 'test_log.txt');

my $filter = LogFilter->new($keywords_file, $exclude_file, $log_file);
ok($filter, 'New instance');

# Start a child process to update the test log periodically
my $pid = fork();
if ($pid == 0) {
    # Child process
    while (1) {
        open my $log, '>>', $log_file or die "Cannot open log file: $!";
        print $log "This is an error line\n";
        print $log "This is a warning line\n";
        print $log "This is an ignore_this_error line\n";
        print $log "This is a normal line\n";
        close $log;
        sleep 1;
    }
    exit;
}

# Run filter method with a timeout
my $output;
eval {
    local $SIG{ALRM} = sub { die "timeout\n" };
    alarm 5; # Set timeout
    {
        local *STDOUT;
        open(STDOUT, '>', \$output) or die "Can't open STDOUT: $!";
        $filter->filter();
        close(STDOUT);
    }
    alarm 0;
};

kill 'TERM', $pid; # Terminate child process

# Check if the lines containing keywords (and not excluded) are in the output
like($output, qr/This is an error line/, 'Error line is included');
like($output, qr/This is a warning line/, 'Warning line is included');
unlike($output, qr/This is an ignore_this_error line/, 'Excluded line is not included');
unlike($output, qr/This is a normal line/, 'Normal line is not included');

done_testing();

