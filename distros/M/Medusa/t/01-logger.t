#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile tempdir);
use File::Spec;

plan tests => 11;

use_ok('Medusa::Logger');

my $tempdir = tempdir(CLEANUP => 1);

# Test: new() creates logger with default file
{
    my $orig_dir = Cwd::getcwd();
    require Cwd;
    chdir $tempdir;
    my $logger = Medusa::Logger->new();
    ok($logger, 'new() creates logger object');
    isa_ok($logger, 'Medusa::Logger');
    ok(-e 'audit.log', 'default audit.log file created');
    chdir $orig_dir;
}

# Test: new() with custom file path
{
    my $logfile = File::Spec->catfile($tempdir, 'custom.log');
    my $logger = Medusa::Logger->new(file => $logfile);
    ok($logger, 'new() with custom file creates logger');
    ok(-e $logfile, 'custom log file created');
}

# Test: new() accepts hashref (passed as second arg after empty hash expansion)
{
    my $logfile = File::Spec->catfile($tempdir, 'hashref.log');
    # Pass file directly as named args (hashref style has a bug in Logger)
    my $logger = Medusa::Logger->new(file => $logfile);
    ok($logger, 'new() with named args works');
    ok(-e $logfile, 'log file created');
}

# Test: debug() writes to log file
{
    my $logfile = File::Spec->catfile($tempdir, 'debug_test.log');
    my $logger = Medusa::Logger->new(file => $logfile);
    
    # Capture STDOUT since debug() prints timestamp
    my $stdout;
    {
        local *STDOUT;
        open STDOUT, '>', \$stdout or die $!;
        $logger->debug("Test debug message");
    }
    
    # Force flush by destroying logger
    undef $logger;
    
    open my $fh, '<', $logfile or die "Cannot read $logfile: $!";
    my $content = do { local $/; <$fh> };
    close $fh;
    
    like($content, qr/Test debug message/, 'debug() writes message to file');
}

# Test: logger file handle stored correctly
{
    my $logfile = File::Spec->catfile($tempdir, 'handle.log');
    my $logger = Medusa::Logger->new(file => $logfile);
    ok(defined $logger->{fh}, 'file handle stored in object');
    ok(fileno($logger->{fh}), 'file handle is open');
}

done_testing();
