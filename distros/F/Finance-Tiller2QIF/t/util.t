use 5.034;
use strict;
use warnings;
use Test2::V0;
use Test2::Bundle::More;
use Mojo::SQLite;
use Finance::Tiller2QIF::Util qw( vPrint );
use Path::Tiny;
use Capture::Tiny qw( capture_stdout );
# use Carp::Always;

require './t/TestHelper.pm';

my $tmpdir = "t/tmp";
mkdir $tmpdir unless -d $tmpdir;

my $test_db = "$tmpdir/utiltest.sqlite3";

unlink $test_db if -e $test_db;
Finance::Tiller2QIF::Util::InitDB($test_db);

ok( -s $test_db, "Database ${test_db} created and has non-zero size" );

my $db = Mojo::SQLite->new($test_db)->options( { sqlite_unicode => 1 } )->db;
my $tables =
  $db->query("SELECT name FROM sqlite_master WHERE type='table'")->arrays;
my @table_names = map { $_->[0] } @$tables;
ok( grep { $_ eq 'transactions' } @table_names, 'transactions table exists' );

# Check columns
my $cols      = $db->query("PRAGMA table_info(transactions)")->arrays;
my @col_names = sort { $a cmp $b } map { $_->[1] } @$cols;
my @expected  = sort { $a cmp $b } qw(id account date amount payee memo category mapped_category check_number skipped exported);

is( "@col_names", "@expected", 'transactions table has expected columns' );
$db->disconnect;

subtest 'bad db, bad conf' => sub {
  local $SIG{__WARN__} = sub {};
  my $bad_db = '/0Glunwitajwek/foo/deeply/unreachable/fake.sqlite3';
  ok( dies { Finance::Tiller2QIF::Util::InitDB($bad_db) },
    'InitDB dies on unwritable path' );

  my $bad_config = '/8Glunwitajwek/foo/deeply/unreachable/fake.conf';
  ok( dies { Finance::Tiller2QIF::Util::InitConfig($bad_config) },
    'InitConfig dies on unwritable path' );
};

subtest 'CheckConfig output' => sub {
    my $out = capture_stdout { Finance::Tiller2QIF::Util::CheckConfig( foo => 'bar' ) };
    like( $out, qr/foo\s*:\s*bar/, 'CheckConfig prints provided options' );
};

subtest 'CheckConfig bad db' => sub {
    my $out = capture_stdout {
        Finance::Tiller2QIF::Util::CheckConfig( db_path => '/no/such/file.sqlite3' );
    };
    like( $out, qr/Problem.*db/, 'CheckConfig reports unreadable db_path' );
};

subtest 'CheckConfig bad input' => sub {
    my $out = capture_stdout {
        Finance::Tiller2QIF::Util::CheckConfig( input => '/no/such/file.csv' );
    };
    like( $out, qr/Problem.*input/, 'CheckConfig reports unreadable input' );
};

subtest 'CheckConfig bad mapfile' => sub {
    my $out = capture_stdout {
        Finance::Tiller2QIF::Util::CheckConfig( mapfile => '/no/such/file.map' );
    };
    like( $out, qr/Problem.*mapfile/, 'CheckConfig reports unreadable mapfile' );
};

subtest 'CheckConfig output file does not exist' => sub {
    my $out = capture_stdout {
        Finance::Tiller2QIF::Util::CheckConfig( output => "$tmpdir/newfile.qif" );
    };
    unlike( $out, qr/Alert/, 'no alert when output does not yet exist' );
    unlike( $out, qr/Problem/, 'no problem when parent dir is writable' );
};

subtest 'CheckConfig output file already exists' => sub {
    my $existing = "$tmpdir/existing.qif";
    path($existing)->spew_utf8("data");
    my $out = capture_stdout {
        Finance::Tiller2QIF::Util::CheckConfig( output => $existing );
    };
    like( $out, qr/Alert/, 'alert when output already exists' );
};

subtest 'CheckConfig output parent dir not writable' => sub {
    my $locked_dir = "$tmpdir/locked";
    mkdir $locked_dir unless -d $locked_dir;
    chmod 0555, $locked_dir;
    my $out = capture_stdout {
        Finance::Tiller2QIF::Util::CheckConfig( output => "$locked_dir/out.qif" );
    };
    like( $out, qr/Problem/, 'problem reported when parent dir not writable' );
    chmod 0755, $locked_dir;
};

subtest 'CheckConfig output file exists but not writable' => sub {
    my $readonly_file = "$tmpdir/readonly.qif";
    path($readonly_file)->spew_utf8("data");
    chmod 0444, $readonly_file;
    my $out = capture_stdout {
        Finance::Tiller2QIF::Util::CheckConfig( output => $readonly_file );
    };
    like( $out, qr/Alert/, 'alert when file exists' );
    like( $out, qr/Problem.*not writable/, 'problem reported when existing file not writable' );
    chmod 0644, $readonly_file;
};

subtest 'vPrint verbose true' => sub {
    my $out = capture_stdout { vPrint( 1, 'hello', 'world' ) };
    like( $out, qr/hello/, 'vPrint prints first message when verbose' );
    like( $out, qr/world/, 'vPrint prints second message when verbose' );
};

subtest 'vPrint verbose false' => sub {
    my $out = capture_stdout { vPrint( 0, 'hello', 'world' ) };
    is( $out, '', 'vPrint prints nothing when verbose is false' );
};

done_testing();
unlink glob "t/tmp/*" if test_pass();

