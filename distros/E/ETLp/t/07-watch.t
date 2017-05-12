#!perl -w
use strict;
use Test::More;
use FindBin qw($Bin);

if (!eval "require  Parallel::SubFork") {
    plan skip_all => 'require Parallel::SubFork';
} else {
    plan tests => 6;
}

use ETLp::File::Watch;
use Log::Log4perl;
use ETLp::Config;
use lib "$Bin/lib";

Parallel::SubFork->import;

my $directory    = "$Bin/tests/csv";
my $file         = "fw_ep.csv";
my $file_pattern = "fw*.csv";

my $log_conf = qq(
    log4perl.rootLogger=DEBUG,NULL
    log4perl.appender.NULL=ETLp::Test::Log::Log4perl::Appender::Null
    log4perl.appender.NULL.layout   = Log::Log4perl::Layout::PatternLayout
);

Log::Log4perl::init(\$log_conf);
my $logger = Log::Log4perl::get_logger("DW");
my $config = ETLp::Config->new(logger => $logger,);


sub remove_file {
    my $file = shift;
    if (-f $file) {
        unlink $file || die "Unable to unlink $file\n";
    }
}

sub gen_file {
    my $delay = shift;
    sleep $delay;
    open(my $fh, '>', "$directory/$file");
    close $fh;
}

remove_file("$directory/$file");

my $fw = ETLp::File::Watch->new(
    directory           => $directory,
    file_pattern        => $file_pattern,
    duration            => '5s',
    call                => 'dummy_config dummy_section',
);

my $manager = Parallel::SubFork->new();
$manager->start(\&gen_file, 3);
is ($fw->watch, 1, 'Watcher detected file pattern');

$fw = ETLp::File::Watch->new(
    directory           => $directory,
    file_pattern        => $file,
    duration            => '5s',
    call                => 'dummy_config dummy_section',
);

$manager = Parallel::SubFork->new();
$manager->start(\&gen_file, 3);
is ($fw->watch, 1, 'Watcher detected exact file');
remove_file("$directory/$file");

$fw = ETLp::File::Watch->new(
    directory           => $directory,
    file_pattern        => $file,
    duration            => '5s',
    call                => 'dummy_config dummy_section',
);

is ($fw->watch, 0, 'Watcher could not find exact file');
remove_file("$directory/$file");

$fw = ETLp::File::Watch->new(
    directory           => $directory,
    file_pattern        => $file_pattern,
    duration            => '5s',
    call                => 'dummy_config dummy_section',
);
$manager->start(\&gen_file, 8);
is ($fw->watch, 0, 'No file found within duration');
sleep 6;
remove_file("$directory/$file");

$fw = ETLp::File::Watch->new(
    directory           => $directory,
    file_pattern        => $file_pattern,
    duration            => '3s',
    call                => 'dummy_config dummy_section',
    raise_no_file_error => 1
);
$manager->start(\&gen_file, 5);
eval {$fw->watch};

if (my $e = Exception::Class->caught()) {
    is($e->error, 'No file found','No file found - error caught');
}

$manager->wait_for_all();
remove_file("$directory/$file");

$fw = ETLp::File::Watch->new(
    directory           => $directory,
    file_pattern        => $file_pattern,
    duration            => '15s',
    call                => 'dummy_config dummy_section',
    exit_on_detection => 1
);

my $dt = DateTime->now;

$manager->start(\&gen_file, 2);
eval {$fw->watch};

my $dur = DateTime->now - $dt;
ok ($dur->seconds >= 2 && $dur->seconds <= 4, 'Exit on detection');

$manager->wait_for_all();
remove_file("$directory/$file");