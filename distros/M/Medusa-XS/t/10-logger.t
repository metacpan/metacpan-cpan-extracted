#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile tempdir);
use File::Spec;
use Cwd;

plan tests => 11;

use_ok('Medusa::XS::Logger');

my $tempdir = tempdir(CLEANUP => 1);

# Test: new() creates logger with default file
{
    my $orig_dir = Cwd::getcwd();
    chdir $tempdir;
    my $logger = Medusa::XS::Logger->new();
    ok($logger, 'new() creates logger object');
    isa_ok($logger, 'Medusa::XS::Logger');
    ok(-e 'audit.log', 'default audit.log file created');
    chdir $orig_dir;
}

# Test: new() with custom file path
{
    my $logfile = File::Spec->catfile($tempdir, 'custom.log');
    my $logger = Medusa::XS::Logger->new(file => $logfile);
    ok($logger, 'new() with custom file creates logger');
    ok(-e $logfile, 'custom log file created');
}

# Test: new() accepts hashref (passed as second arg after empty hash expansion)
{
    my $logfile = File::Spec->catfile($tempdir, 'hashref.log');
    my $logger = Medusa::XS::Logger->new(file => $logfile);
    ok($logger, 'new() with named args works');
    ok(-e $logfile, 'log file created');
}

# Test: debug() writes to log file
{
    my $logfile = File::Spec->catfile($tempdir, 'debug_test.log');
    my $logger = Medusa::XS::Logger->new(file => $logfile);
    
    $logger->debug("Test debug message");
    
    # Force flush by destroying logger
    undef $logger;
    
    open my $fh, '<', $logfile or die "Cannot read $logfile: $!";
    my $content = do { local $/; <$fh> };
    close $fh;
    
    like($content, qr/Test debug message/, 'debug() writes message to file');
}

# Test: logger object is valid and writable
{
    my $logfile = File::Spec->catfile($tempdir, 'handle.log');
    my $logger = Medusa::XS::Logger->new(file => $logfile);
    ok(ref $logger, 'logger is a blessed reference');
    $logger->info("handle test");
    undef $logger;
    ok(-s $logfile, 'log file has content after write');
}

done_testing();
