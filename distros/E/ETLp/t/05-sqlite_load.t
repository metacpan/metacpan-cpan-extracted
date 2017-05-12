#!perl
use ETLp;
use FindBin qw($Bin);
use lib "$Bin/lib";
use ETLp::Test::Load;

my $data_dir = "$Bin/../t/data";

unless (-d $data_dir) {
    mkdir $data_dir;
}

my $db_file = "$data_dir/test.sqlite";
$ENV{DSN}  = 'DBI:SQLite:'.$db_file;

ETLp::Test::Load->runtests;

unlink $db_file;
rmdir $data_dir;
