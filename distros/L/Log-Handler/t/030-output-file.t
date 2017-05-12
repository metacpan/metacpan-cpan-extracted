use strict;
use warnings;
use Test::More tests => 6;
use File::Spec;
use Log::Handler::Output::File;

my $rand_num = int(rand(999999));
my $logfile  = File::Spec->catfile('t', "Log-Handler-$rand_num.log");
my $log      = Log::Handler::Output::File->new(
    filename     => [ 't', "Log-Handler-$rand_num.log" ],
    permissions  => '0664',
    mode         => 'append',
    autoflush    => 0,
    fileopen     => 0,
    filelock     => 0,
    reopen       => 0,
);

# write a string to the file
$log->log(message => "test\n") or die $!;
ok(1, "checking log()");

# checking if the file is readable
open(my $fh, '<', $logfile) or do {
   ok(0, "open logfile ($logfile)");
   exit(1);
};

ok(1, "open logfile ($logfile)");

my $line = <$fh>;
chomp($line);
close $fh;

ok($line =~ /^test\z/, "checking logfile ($line)");

if ( unlink($logfile) ) {
    ok(1, "unlink logfile ($logfile)");
} else {
    ok(0, "unlink logfile ($logfile)");
}

$log->reload(
    {
        filename  => [ 't', "Log-Handler-$rand_num.log" ],
        autoflush => 1,
        fileopen  => 0,
        reopen    => 0,
    }
);

ok($log->{autoflush} == 1, "checking reload ($log->{autoflush})");
ok($log->{filename}  =~ /$rand_num/, "checking reload ($log->{filename})");
