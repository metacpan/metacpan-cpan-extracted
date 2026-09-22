use strict;
use warnings;
use utf8;
use warnings FATAL => 'utf8';
use open ':std', ':encoding(UTF-8)';
use Test2::V0;
use Test2::Bundle::More;
use Test2::Tools::Exception qw/dies lives/;
use Path::Tiny;
use Finance::Tiller2QIF;
use Finance::Tiller2QIF::Util;
use feature qw/signatures postderef/;

no warnings 'experimental::try';
use feature 'try';

require './t/TestHelper.pm';

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

subtest api_ingest => sub {
  my $db_path = uniqfile( 'ingest', 'sqlite3' );
  my $csvfile = uniqfile( 'ingest', 'csv' );
  my $DB  = freshdb($db_path);
  freshcsv( $csvfile,
    '04/25/2026,1,Checking,100.00,Deposit,Paycheck,Income',
    '04/25/2026,2,Checking,-50.00,Coffee,Cafe,Food',
  );
  ok( lives { Finance::Tiller2QIF::_ingest( input => $csvfile, db_path => $db_path ) },
    '_ingest() lives' );
  is( $DB->select( 'transactions', ['id'] )->arrays->@*, 2,
    '_ingest() loaded two rows' );
  $DB->disconnect;
};

subtest api_apply_map => sub {
  my $db_path = uniqfile( 'map', 'sqlite3' );
  my $csvfile = uniqfile( 'map', 'csv' );
  my $mapfile = uniqfile( 'map', 'map' );
  my $DB  = freshdb($db_path);
  freshcsv( $csvfile, '04/25/2026,1,Checking,100.00,Deposit,Paycheck,Income' );
  freshmap( $mapfile,
    'category | Income | Income:Salary',
    'default | source',
  );
  Finance::Tiller2QIF::_ingest( input => $csvfile, db_path => $db_path );
  ok( lives { Finance::Tiller2QIF::_apply_map( db_path => $db_path, mapfile => $mapfile ) },
    '_apply_map() lives' );
  is( $DB->select( 'transactions', ['mapped_category'], { id => 1 } )->hash->{mapped_category},
    'Income:Salary', '_apply_map() wrote mapped_category' );
  $DB->disconnect;
};

subtest api_emit => sub {
  my $db_path = uniqfile( 'emit', 'sqlite3' );
  my $csvfile = uniqfile( 'emit', 'csv' );
  my $qiffile = uniqfile( 'emit', 'qif' );
  my $DB  = freshdb($db_path);
  freshcsv( $csvfile, '04/25/2026,1,Checking,100.00,Deposit,Paycheck,Income' );
  Finance::Tiller2QIF::_ingest( input => $csvfile, db_path => $db_path );
  ok( lives { Finance::Tiller2QIF::_emit( db_path => $db_path, output => $qiffile, qifdate => 'ymd' ) },
    '_emit() lives' );
  ok( -e $qiffile, '_emit() created QIF file' );
  like( path($qiffile)->slurp_utf8, qr/PDeposit/, 'emitted QIF contains payee' );
  $DB->disconnect;
};

subtest api_run => sub {
  my $db_path = uniqfile( 'run', 'sqlite3' );
  my $csvfile = uniqfile( 'run', 'csv' );
  my $mapfile = uniqfile( 'run', 'map' );
  my $qiffile = uniqfile( 'run', 'qif' );
  freshdb($db_path)->disconnect;
  freshcsv( $csvfile, '04/25/2026,1,Checking,50.00,Deposit,Paycheck,Income' );
  freshmap( $mapfile,
    'category | Income | Income:Salary',
    'default | blank',
  );
  ok( lives {
    Finance::Tiller2QIF::_run(
      input   => $csvfile,
      db_path => $db_path,
      mapfile => $mapfile,
      output  => $qiffile,
      qifdate => 'ymd',
    )
  }, '_run() lives' );
  like( path($qiffile)->slurp_utf8, qr/LIncome:Salary/, '_run() QIF has mapped category' );
};

# ---------------------------------------------------------------------------
# run_cli dispatch — local @ARGV overrides argument list for each call
# ---------------------------------------------------------------------------

subtest cli_unknown_command => sub {
  local @ARGV = ('notacommand');
  ok( dies { Finance::Tiller2QIF::run_cli() }, 'Unknown command dies' );
};

subtest cli_missing_command => sub {
  local @ARGV = ();
  like(
    dies { Finance::Tiller2QIF::run_cli() },
    qr/Command Missing!/,
    'Missing command shows clear error message'
  );
};

subtest cli_missing_db => sub {
  local @ARGV = ( 'ingest', '--input', 'x.csv' );
  ok( dies { Finance::Tiller2QIF::run_cli() }, 'Missing --db dies' );
};

subtest cli_missing_input => sub {
  local @ARGV = ( 'ingest', '--db', 'x.sqlite3' );
  ok( dies { Finance::Tiller2QIF::run_cli() }, 'Missing --input for ingest dies' );
};

subtest cli_missing_output => sub {
  local @ARGV = ( 'emit', '--db', 'x.sqlite3' );
  ok( dies { Finance::Tiller2QIF::run_cli() }, 'Missing --output for emit dies' );
};

subtest cli_newdb_missing_db => sub {
  local @ARGV = ('newdb');
  ok( dies { Finance::Tiller2QIF::run_cli() }, 'newdb without --db dies' );
};

subtest cli_newconfig_missing_config => sub {
  local @ARGV = ('newconfig');
  ok( dies { Finance::Tiller2QIF::run_cli() }, 'newconfig without --config dies' );
};

subtest cli_newdb => sub {
  my $db_path = uniqfile( 'cli_newdb', 'sqlite3' );
  local @ARGV = ( 'newdb', '--db', $db_path );
  ok( lives { Finance::Tiller2QIF::run_cli() }, 'newdb with --db returns normally' );
  ok( -s $db_path, 'newdb created the database file' );
};

subtest cli_run => sub {
  my $db_path = uniqfile( 'cli_run', 'sqlite3' );
  my $csvfile = uniqfile( 'cli_run', 'csv' );
  my $qiffile = uniqfile( 'cli_run', 'qif' );
  freshdb($db_path)->disconnect;
  freshcsv( $csvfile, '04/25/2026,1,Checking,75.00,Deposit,Salary,Income' );
  local @ARGV = ( 'run', '--input', $csvfile, '--db', $db_path, '--output', $qiffile );
  ok( lives { Finance::Tiller2QIF::run_cli() }, 'cli run returns normally' );
  ok( -e $qiffile, 'cli run produced QIF file' );
};

subtest cli_command_after_options => sub {
  my $db_path = uniqfile( 'cli_cmdafter', 'sqlite3' );
  my $csvfile = uniqfile( 'cli_cmdafter', 'csv' );
  my $qiffile = uniqfile( 'cli_cmdafter', 'qif' );
  freshdb($db_path)->disconnect;
  freshcsv( $csvfile, '04/25/2026,1,Checking,75.00,Deposit,Salary,Income' );
  local @ARGV = ( '--input', $csvfile, '--db', $db_path, '--output', $qiffile, 'run' );
  ok( lives { Finance::Tiller2QIF::run_cli() }, 'cli run with command after options returns normally' );
  ok( -e $qiffile, 'cli run with command after options produced QIF file' );
};

subtest cli_command_last_newdb => sub {
  my $db_path = uniqfile( 'cli_newdbafter', 'sqlite3' );
  local @ARGV = ( '--db', $db_path, 'newdb' );
  ok( lives { Finance::Tiller2QIF::run_cli() }, 'newdb with command after --db returns normally' );
  ok( -s $db_path, 'newdb with command last created the database file' );
};

subtest cli_unknown_command_after_options => sub {
  local @ARGV = ( '--db', 'x.sqlite3', 'notacommand' );
  like(
    dies { Finance::Tiller2QIF::run_cli() },
    qr/Unknown command/,
    'unknown command after options dies'
  );
};

subtest cli_extra_stray_argument => sub {
  local @ARGV = ( 'run', 'stray', '--db', 'x.sqlite3' );
  like(
    dies { Finance::Tiller2QIF::run_cli() },
    qr/unexpected argument/,
    'stray argument after command and options dies'
  );
};

subtest cli_options_only_missing_command => sub {
  local @ARGV = ( '--db', 'x.sqlite3' );
  like(
    dies { Finance::Tiller2QIF::run_cli() },
    qr/Command Missing!/,
    'options with no command still dies with Command Missing!'
  );
};

subtest cli_help_extra => sub {
  local @ARGV = ( '--help', 'extra' );
  my $out = '';
  ok( lives { open( local *STDOUT, '>', \$out ); Finance::Tiller2QIF::run_cli() },
    '--help with trailing extra argument still returns normally' );
  like( $out, qr/tiller2qif/, '--help with trailing extra argument prints usage' );
};

subtest cli_run_beforeafter => sub {
  my $db_path = uniqfile( 'cli_bfaf', 'sqlite3' );
  my $csvfile = uniqfile( 'cli_bfaf', 'csv' );
  my $mapfile = uniqfile( 'cli_bfaf', 'map' );
  my $qiffile = uniqfile( 'cli_bfaf', 'qif' );
  freshdb($db_path)->disconnect;
  freshcsv( $csvfile, '04/25/2026,1,Checking,10.00,Coffee,Cafe,Food' );
  freshmap( $mapfile,
    '[Checking-VIP] category | Food | Expenses:Dining',
    'default | source',
  );
  local @ARGV = (
    'run',
    '--input',     $csvfile,
    '--db',        $db_path,
    '--output',    $qiffile,
    '--mapfile',   $mapfile,
    '--beforemap', 't/testcase/beforemap.sql',
    '--aftermap',  't/testcase/aftermap.sql',
  );
  ok( lives { Finance::Tiller2QIF::run_cli() }, 'cli run with beforemap and aftermap lives' );
  my $DB = dbi_connect($db_path);
  my $tx = $DB->select( 'transactions', [qw(mapped_category check_number)], { id => 1 } )->hash;
  is( $tx->{mapped_category}, 'Expenses:Dining', 'beforemap+map fired via account rename' );
  is( $tx->{check_number},    'after_ran',       'aftermap ran after map via CLI' );
  $DB->disconnect;
};

subtest cli_ingest_then_emit => sub {
  my $db_path = uniqfile( 'cli_ie', 'sqlite3' );
  my $csvfile = uniqfile( 'cli_ie', 'csv' );
  my $qiffile = uniqfile( 'cli_ie', 'qif' );
  freshdb($db_path)->disconnect;
  freshcsv( $csvfile, '04/25/2026,1,Checking,30.00,Coffee,Cafe,Food' );

  { local @ARGV = ( 'ingest', '--input', $csvfile, '--db', $db_path );
    ok( lives { Finance::Tiller2QIF::run_cli() }, 'cli ingest returns normally' ); }

  { local @ARGV = ( 'emit', '--db', $db_path, '--output', $qiffile );
    ok( lives { Finance::Tiller2QIF::run_cli() }, 'cli emit returns normally' ); }

  like( path($qiffile)->slurp_utf8, qr/PCoffee/, 'two-phase cli produced QIF' );
};

subtest cli_run_verbose => sub {
  my $db_path = uniqfile( 'cli_runv', 'sqlite3' );
  my $qiffile = uniqfile( 'cli_runv', 'qif' );
  freshdb($db_path)->disconnect;
  local @ARGV = (
    'run',
    '--input',   't/testcase/mapping1.csv',
    '--db',      $db_path,
    '--output',  $qiffile,
    '--mapfile', 't/testcase/mapping1.map',
    '--verbose',
  );
  my $out = '';
  ok( lives { open( local *STDOUT, '>', \$out ); Finance::Tiller2QIF::run_cli() },
    'cli run --verbose returns normally' );
  ok( -e $qiffile, 'cli run --verbose produced QIF file' );
  like( $out, qr/Tiller2QIF VERSION:/, 'verbose output includes the version' );
  like( $out, qr/Ingesting CSV/,    'verbose output mentions ingesting' );
  like( $out, qr/Applying mapping/, 'verbose output mentions mapping' );
  like( $out, qr/Writing QIF/,      'verbose output mentions writing' );
};

subtest cli_newdb_verbose => sub {
  my $db_path = uniqfile( 'cli_newdbv', 'sqlite3' );
  local @ARGV = ( 'newdb', '--db', $db_path, '--verbose' );
  my $out = '';
  ok( lives { open( local *STDOUT, '>', \$out ); Finance::Tiller2QIF::run_cli() },
    'newdb --verbose returns normally' );
  like( $out, qr/Creating database/, 'verbose newdb output mentions creating' );
};

subtest cli_newconfig_verbose => sub {
  my $cfgfile = uniqfile( 'cli_newcfgv', 'json' );
  local @ARGV = ( 'newconfig', '--config', $cfgfile, '--verbose' );
  my $out = '';
  ok( lives { open( local *STDOUT, '>', \$out ); Finance::Tiller2QIF::run_cli() },
    'newconfig --verbose returns normally' );
  like( $out, qr/Creating config/, 'verbose newconfig output mentions creating' );
};

subtest cli_checkconfig => sub {
  my $db_path = uniqfile( 'cli_chkcfg', 'sqlite3' );
  my $csvfile = uniqfile( 'cli_chkcfg', 'csv' );
  my $qiffile = uniqfile( 'cli_chkcfg', 'qif' );
  freshdb($db_path)->disconnect;
  freshcsv( $csvfile, '04/25/2026,1,Checking,10.00,Test,Test,Food' );

  # checkconfig command reaches line 162 via $cmd =~ /^checkconfig/
  local @ARGV = (
    'checkconfig',
    '--db',     $db_path,
    '--input',  $csvfile,
    '--output', $qiffile,
  );
  my $out = '';
  ok( lives { open( local *STDOUT, '>', \$out ); Finance::Tiller2QIF::run_cli() },
    'checkconfig returns normally' );
  like( $out, qr/db_path\s*:/, 'checkconfig output lists db_path option' );
};

subtest cli_emit_verbose_checkconfig => sub {
  my $db_path = uniqfile( 'cli_emitv', 'sqlite3' );
  my $csvfile = uniqfile( 'cli_emitv', 'csv' );
  my $qiffile = uniqfile( 'cli_emitv', 'qif' );
  freshdb($db_path)->disconnect;
  freshcsv( $csvfile, '04/25/2026,1,Checking,20.00,Test,Test,Food' );
  Finance::Tiller2QIF::_ingest( input => $csvfile, db_path => $db_path );

  # --verbose on emit reaches line 162 via $opt->verbose (non-run command)
  local @ARGV = ( 'emit', '--db', $db_path, '--output', $qiffile, '--verbose' );
  my $out = '';
  ok( lives { open( local *STDOUT, '>', \$out ); Finance::Tiller2QIF::run_cli() },
    'emit --verbose returns normally' );
  like( $out, qr/db_path\s*:/, 'emit --verbose output lists db_path option via CheckConfig' );
};

subtest cli_run_checkpoints => sub {
  my $db_path = uniqfile( 'cli_ckpt_run', 'sqlite3' );
  my $csvfile = uniqfile( 'cli_ckpt_run', 'csv' );
  my $qiffile = uniqfile( 'cli_ckpt_run', 'qif' );
  freshdb($db_path)->disconnect;
  freshcsv( $csvfile, '04/25/2026,1,Checking,10.00,Test,Test,Food' );
  local @ARGV = ( 'run', '--input', $csvfile, '--db', $db_path, '--output', $qiffile );
  ok( lives { Finance::Tiller2QIF::run_cli() }, 'run returns normally' );
  my @copies = glob( $db_path . '*' );
  ok( @copies > 1, 'run created a checkpoint copy of the database' );
};

subtest cli_checkpoint_flag => sub {
  my $db_path = uniqfile( 'cli_ckpt_flag', 'sqlite3' );
  my $csvfile = uniqfile( 'cli_ckpt_flag', 'csv' );
  freshdb($db_path)->disconnect;
  freshcsv( $csvfile, '04/25/2026,1,Checking,10.00,Test,Test,Food' );
  local @ARGV = ( 'ingest', '--input', $csvfile, '--db', $db_path, '--checkpoint' );
  ok( lives { Finance::Tiller2QIF::run_cli() }, 'ingest --checkpoint returns normally' );
  my @copies = glob( $db_path . '*' );
  ok( @copies > 1, '--checkpoint created a checkpoint copy of the database' );
};

subtest cli_clean_missing_db => sub {
  local @ARGV = ('clean');
  ok( dies { Finance::Tiller2QIF::run_cli() }, 'clean without --db dies' );
};

subtest cli_clean => sub {
  my $db_path = uniqfile( 'cli_clean', 'sqlite3' );
  freshdb($db_path)->disconnect;

  # Create two checkpoint copies directly, with distinct names
  Finance::Tiller2QIF::_checkpoint( $db_path );
  sleep 1;
  Finance::Tiller2QIF::_checkpoint( $db_path );

  my @before = grep { /\.\d{4}-\d{2}-\d{2}_\d{2}_\d{2}_\d{2}$/ } glob( $db_path . '.*' );
  ok( @before == 2, 'two checkpoint copies exist before clean' );

  local @ARGV = ( 'clean', '--db', $db_path );
  ok( lives { Finance::Tiller2QIF::run_cli() }, 'clean returns normally' );

  my @after = grep { /\.\d{4}-\d{2}-\d{2}_\d{2}_\d{2}_\d{2}$/ } glob( $db_path . '.*' );
  ok( @after == 0, 'clean removed all checkpoint copies' );
  ok( -e $db_path,  'clean left the original database intact' );
};

subtest cli_version => sub {
  local @ARGV = ('version');
  my $out = '';
  ok( lives { open( local *STDOUT, '>', \$out ); Finance::Tiller2QIF::run_cli() },
    'version command returns normally' );
  like( $out, qr/VERSION/, 'version command prints VERSION' );
};

subtest cli_version_option => sub {
  local @ARGV = ('--version');
  my $out = '';
  ok( lives { open( local *STDOUT, '>', \$out ); Finance::Tiller2QIF::run_cli() },
    '--version returns normally' );
  like( $out, qr/Tiller2QIF VERSION:/, '--version prints the installed version' );
};

subtest cli_help => sub {
  local @ARGV = ('--help');
  my $out = '';
  ok( lives { open( local *STDOUT, '>', \$out ); Finance::Tiller2QIF::run_cli() },
    '--help returns normally' );
  like( $out, qr/tiller2qif/, '--help prints usage' );
};

subtest cli_config => sub {
  my $db_path = uniqfile( 'cli_cfg', 'sqlite3' );
  my $csvfile = uniqfile( 'cli_cfg', 'csv' );
  my $qiffile = uniqfile( 'cli_cfg', 'qif' );
  my $cfgfile = uniqfile( 'cli_cfg', 'json' );
  freshdb($db_path)->disconnect;
  freshcsv( $csvfile, '04/25/2026,1,Checking,10.00,Test,Test,Food' );
  Finance::Tiller2QIF::run_cli() if 0; # load module
  path($cfgfile)->spew_utf8( qq|{ "db": "$db_path", "input": "$csvfile", "output": "$qiffile" }| );
  local @ARGV = ( 'ingest', '--config', $cfgfile );
  ok( lives { Finance::Tiller2QIF::run_cli() }, '--config loads options from file' );
  my $db = dbi_connect($db_path);
  is( $db->select('transactions', ['id'])->arrays->@*, 1, '--config ingest loaded a row' );
  $db->disconnect;
};

subtest cli_preview => sub {
  my $db_path = uniqfile( 'cli_preview', 'sqlite3' );
  my $csvfile = uniqfile( 'cli_preview', 'csv' );
  freshdb($db_path)->disconnect;
  freshcsv( $csvfile, '04/25/2026,1,Checking,10.00,Test,Test,Food' );
  Finance::Tiller2QIF::_ingest( input => $csvfile, db_path => $db_path );
  local @ARGV = ( 'preview', '--db', $db_path );
  my $out = '';
  ok( lives { open( local *STDOUT, '>', \$out ); Finance::Tiller2QIF::run_cli() },
    'preview command returns normally' );
  like( $out, qr/pending export/, 'preview output mentions pending export' );
};

subtest cli_viewer => sub {
  my $db_path = uniqfile( 'cli_pvviewer', 'sqlite3' );
  my $csvfile = uniqfile( 'cli_pvviewer', 'csv' );
  my $marker  = uniqfile( 'cli_pvviewer_marker', 'txt' );
  my $script  = uniqfile( 'cli_pvviewer_stub',   'pl' );
  freshdb($db_path)->disconnect;
  freshcsv( $csvfile, '04/25/2026,1,Checking,10.00,Test,Test,Food' );
  Finance::Tiller2QIF::_ingest( input => $csvfile, db_path => $db_path );
  path($script)->spew_utf8( <<"STUB" );
use v5.36;
open my \$in,  '<:encoding(UTF-8)', \$ARGV[0] or die "stub viewer: \$!";
open my \$out, '>:encoding(UTF-8)', '$marker' or die "stub viewer: \$!";
print {\$out} "\$ARGV[0]\\n", <\$in>;
STUB

  local @ARGV = ( 'preview', '--db', $db_path, '--viewer', "$^X $script" );
  my $out = '';
  ok( lives { open( local *STDOUT, '>', \$out ); Finance::Tiller2QIF::run_cli() },
    '--viewer returns normally' );
  like( $out, qr/Preview written to \S+\.t2qpv/, 'reports the preview file path' );
  like( $out, qr/pending export/, 'still reports the pending count' );
  unlike( $out, qr/Checking/, 'preview table went to the viewer, not STDOUT' );
  ok( -e $marker, 'viewer was launched with the preview file' );
  like( path($marker)->slurp_utf8, qr/Checking/, 'viewer received the preview table' );
  unlink $1 if $out =~ /Preview written to (\S+)/;
};

subtest cli_viewer_errors => sub {
  my $db_path = uniqfile( 'cli_pvbad', 'sqlite3' );
  my $csvfile = uniqfile( 'cli_pvbad', 'csv' );
  freshdb($db_path)->disconnect;
  freshcsv( $csvfile, '04/25/2026,1,Checking,10.00,Test,Test,Food' );
  Finance::Tiller2QIF::_ingest( input => $csvfile, db_path => $db_path );

  my $out = '';
  {
    local @ARGV = ( 'preview', '--db', $db_path, '--viewer', 'nosuchprog-xyz' );
    like(
      dies { open( local *STDOUT, '>', \$out ); Finance::Tiller2QIF::run_cli() },
      qr/'nosuchprog-xyz' was not found in PATH/,
      'unknown --viewer is fatal' );
  }
  {
    local @ARGV = ( 'preview', '--db', $db_path, '--viewer', '' );
    like(
      dies { open( local *STDOUT, '>', \$out ); Finance::Tiller2QIF::run_cli() },
      qr/must name a program or 'console'/,
      'empty --viewer is fatal' );
  }

  my $cfgfile = uniqfile( 'cli_pvbad', 'json' );
  path($cfgfile)->spew_utf8(
    qq|{ "db": "$db_path", "viewer": "" }| );
  {
    local @ARGV = ( 'preview', '--config', $cfgfile );
    like(
      dies { open( local *STDOUT, '>', \$out ); Finance::Tiller2QIF::run_cli() },
      qr/must name a program or 'console'/,
      'empty viewer in a config file is fatal' );
  }
};

subtest cli_multipreview => sub {
  my $db_path = uniqfile( 'cli_multi', 'sqlite3' );
  my $csvfile = uniqfile( 'cli_multi', 'csv' );
  my $mapfile = uniqfile( 'cli_multi', 'map' );
  my $marker  = uniqfile( 'cli_multi_marker', 'txt' );
  my $script  = uniqfile( 'cli_multi_stub',   'pl' );
  freshdb($db_path)->disconnect;
  freshcsv( $csvfile, '04/25/2026,1,Checking,10.00,Test,Test,Food' );
  freshmap( $mapfile, 'category | Food | Expenses:Food' );
  Finance::Tiller2QIF::_ingest( input => $csvfile, db_path => $db_path );
  # stub viewer: records every file it was handed
  path($script)->spew_utf8( <<"STUB" );
use v5.36;
open my \$out, '>:encoding(UTF-8)', '$marker' or die "stub viewer: \$!";
print {\$out} join( "\\n", \@ARGV ), "\\n";
STUB

  my $out = '';
  {
    local @ARGV = ( 'preview', '--db', $db_path, '--mapfile', $mapfile,
      '--viewer', "$^X $script", '--multipreview' );
    ok( lives { open( local *STDOUT, '>', \$out ); Finance::Tiller2QIF::run_cli() },
      '--multipreview returns normally' );
  }
  like( $out, qr/\QAlso opening: $mapfile\E/, 'reports the mapping file it opened' );
  my @opened = path($marker)->lines_utf8( { chomp => 1 } );
  is( scalar @opened, 2, 'viewer was handed two files in one invocation' );
  like( $opened[0], qr/\.t2qpv$/, 'preview file first' );
  is( $opened[1], $mapfile, 'mapping file second' );
  unlink $opened[0];

  {
    local @ARGV = ( 'preview', '--db', $db_path, '--mapfile', $mapfile, '--multipreview' );
    like(
      dies { open( local *STDOUT, '>', \$out ); Finance::Tiller2QIF::run_cli() },
      qr/--multipreview requires --viewer/,
      '--multipreview without a viewer is fatal' );
  }
  {
    local @ARGV = ( 'preview', '--db', $db_path,
      '--viewer', "$^X $script", '--multipreview' );
    like(
      dies { open( local *STDOUT, '>', \$out ); Finance::Tiller2QIF::run_cli() },
      qr/--multipreview requires --mapfile/,
      '--multipreview without a mapfile is fatal' );
  }
  {
    local @ARGV = ( 'preview', '--db', $db_path, '--mapfile', 'no/such.map',
      '--viewer', "$^X $script", '--multipreview' );
    like(
      dies { open( local *STDOUT, '>', \$out ); Finance::Tiller2QIF::run_cli() },
      qr/preview cannot open 'no\/such\.map'/,
      '--multipreview with an unreadable mapfile is fatal' );
    unlink $1 if $out =~ /Preview written to (\S+)/;
  }
};

subtest cli_viewer_config => sub {
  my $db_path = uniqfile( 'cli_pvcfg', 'sqlite3' );
  my $csvfile = uniqfile( 'cli_pvcfg', 'csv' );
  my $cfgfile = uniqfile( 'cli_pvcfg', 'json' );
  my $marker  = uniqfile( 'cli_pvcfg_marker', 'txt' );
  my $script  = uniqfile( 'cli_pvcfg_stub',   'pl' );
  freshdb($db_path)->disconnect;
  freshcsv( $csvfile, '04/25/2026,1,Checking,10.00,Test,Test,Food' );
  Finance::Tiller2QIF::_ingest( input => $csvfile, db_path => $db_path );
  path($script)->spew_utf8( <<"STUB" );
use v5.36;
open my \$out, '>:encoding(UTF-8)', '$marker' or die "stub viewer: \$!";
print {\$out} "\$ARGV[0]\\n";
STUB
  path($cfgfile)->spew_utf8(
    qq|{ "db": "$db_path", "viewer": "$^X $script" }| );

  my $out = '';
  {
    local @ARGV = ( 'preview', '--config', $cfgfile );
    ok( lives { open( local *STDOUT, '>', \$out ); Finance::Tiller2QIF::run_cli() },
      'viewer from config file runs' );
  }
  like( $out, qr/Preview written to /, 'config file viewer was used' );
  ok( -e $marker, 'config file viewer was launched' );
  unlink $1 if $out =~ /Preview written to (\S+)/;

  # command line beats the config file
  $out = '';
  {
    local @ARGV = ( 'preview', '--config', $cfgfile, '--viewer', 'console' );
    ok( lives { open( local *STDOUT, '>', \$out ); Finance::Tiller2QIF::run_cli() },
      '--viewer console overrides the config file' );
  }
  unlike( $out, qr/Preview written to /, 'console on the command line wins' );
  like( $out, qr/Checking/, 'preview printed to STDOUT' );
};

subtest cli_confirm_yes => sub {
  my $db_path = uniqfile( 'cli_confirm_y', 'sqlite3' );
  my $csvfile = uniqfile( 'cli_confirm_y', 'csv' );
  my $qiffile = uniqfile( 'cli_confirm_y', 'qif' );
  freshdb($db_path)->disconnect;
  freshcsv( $csvfile, '04/25/2026,1,Checking,10.00,Test,Test,Food' );
  Finance::Tiller2QIF::_ingest( input => $csvfile, db_path => $db_path );

  local @ARGV = ( 'emit', '--db', $db_path, '--output', $qiffile, '--confirm' );
  my $stdin = "y\n";
  open( my $fh, '<', \$stdin ) or die $!;
  local *STDIN = $fh;
  my $out = '';
  ok( lives { open( local *STDOUT, '>', \$out ); Finance::Tiller2QIF::run_cli() },
    '--confirm with "y" proceeds to emit' );
  ok( -e $qiffile, '--confirm "y" produced QIF file' );
};

subtest cli_confirm_no => sub {
  my $db_path = uniqfile( 'cli_confirm_n', 'sqlite3' );
  my $csvfile = uniqfile( 'cli_confirm_n', 'csv' );
  my $qiffile = uniqfile( 'cli_confirm_n', 'qif' );
  freshdb($db_path)->disconnect;
  freshcsv( $csvfile, '04/25/2026,1,Checking,10.00,Test,Test,Food' );
  Finance::Tiller2QIF::_ingest( input => $csvfile, db_path => $db_path );

  local @ARGV = ( 'emit', '--db', $db_path, '--output', $qiffile, '--confirm' );
  my $stdin = "n\n";
  open( my $fh, '<', \$stdin ) or die $!;
  local *STDIN = $fh;
  my $out = '';
  ok( lives { open( local *STDOUT, '>', \$out ); Finance::Tiller2QIF::run_cli() },
    '--confirm with "n" returns without error' );
  ok( !-e $qiffile, '--confirm "n" did not produce QIF file' );
};

subtest cli_confirm_revert_to_checkpoint => sub {
  my $db_path = uniqfile( 'cli_confirm_r', 'sqlite3' );
  my $csvfile = uniqfile( 'cli_confirm_r', 'csv' );
  my $qiffile = uniqfile( 'cli_confirm_r', 'qif' );
  freshdb($db_path)->disconnect;
  freshcsv( $csvfile, '04/25/2026,1,Checking,10.00,Test,Test,Food' );
  Finance::Tiller2QIF::_ingest( input => $csvfile, db_path => $db_path );

  my $checkpoint = Finance::Tiller2QIF::_checkpoint( $db_path );
  my $checkpoint_content = path($checkpoint)->slurp_raw;

  # Add another transaction after checkpoint
  freshcsv( $csvfile, '04/25/2026,1,Checking,10.00,Test,Test,Food' );
  Finance::Tiller2QIF::_ingest( input => $csvfile, db_path => $db_path );

  local @ARGV = ( 'emit', '--db', $db_path, '--output', $qiffile, '--confirm', '--checkpoint' );
  my $stdin = "r\n";
  open( my $fh, '<', \$stdin ) or die $!;
  local *STDIN = $fh;
  my $out = '';
  ok( lives { open( local *STDOUT, '>', \$out ); Finance::Tiller2QIF::run_cli() },
    '--confirm with "r" returns without error' );
  ok( !-e $qiffile, '--confirm "r" did not produce QIF file' );

  my $db_after_revert = dbi_connect($db_path);
  my $count_after = $db_after_revert->select('transactions', ['id'])->arrays->@*;
  $db_after_revert->disconnect;
  is( $count_after, 1, 'revert to checkpoint restored original state (1 transaction)' );
};

done_testing();

unlink glob "t/tmp/t2q_*" if test_pass();
