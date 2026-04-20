use strict;
use warnings FATAL => 'all';

use Capture::Tiny qw(capture);
use Config ();
use Cwd qw(abs_path getcwd);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir tempfile);
use IO::Socket::INET;
use LWP::UserAgent;
use POSIX qw(WNOHANG);
use Test::More;
use Time::HiRes qw(sleep);

my $repo_root      = abs_path('.');
my $repo_lib       = File::Spec->catdir( $repo_root, 'lib' );
my $dashboard_bin  = File::Spec->catfile( $repo_root, 'bin', 'dashboard' );
my $host_home_root = $ENV{HOME} || '';

_prepare_optional_rdbms_env();

my $node_bin     = _find_command('node');
my $npx_bin      = _find_command('npx');
my $git_bin      = _find_command('git');
my $docker_bin   = _find_command('docker');
my $chromium_bin = _find_command( qw(google-chrome-stable google-chrome chromium-browser chromium) );

plan skip_all => 'RDBMS SQL Playwright browser test requires node, npx, git, docker, and Chromium on PATH'
  if !$node_bin || !$npx_bin || !$git_bin || !$docker_bin || !$chromium_bin;

plan skip_all => 'RDBMS SQL Playwright browser test requires DBI in the current Perl environment'
  if !_module_available('DBI');

my $playwright_dir = eval { _playwright_dir( $npx_bin, $host_home_root ) };
plan skip_all => "Playwright module cache is unavailable: $@"
  if !$playwright_dir;

plan skip_all => 'Docker daemon is not reachable for SQL dashboard RDBMS browser coverage'
  if !_docker_available($docker_bin);

subtest 'MySQL browser workflow' => sub {
    _run_rdbms_matrix(
        label            => 'MySQL',
        driver_module    => 'DBD::mysql',
        driver_name      => 'DBD::mysql',
        image            => 'mysql:5.7',
        container_port   => 3306,
        database         => 'dashboard_test',
        username         => 'dashboard',
        password         => 'dashboardpass',
        expected_row     => 'Alice',
        expected_tables  => [ 'users', 'orders' ],
        template_dsn     => 'dbi:mysql:database=app;host=127.0.0.1;port=3306',
        guide_fragment   => 'dbi:mysql:database=app;host=127.0.0.1;port=3306',
        docker_args      => [
            '-e', 'MYSQL_ROOT_PASSWORD=rootpass',
            '-e', 'MYSQL_DATABASE=dashboard_test',
            '-e', 'MYSQL_USER=dashboard',
            '-e', 'MYSQL_PASSWORD=dashboardpass',
        ],
        dsn_builder      => sub {
            my ($port) = @_;
            return "dbi:mysql:database=dashboard_test;host=127.0.0.1;port=$port";
        },
        wait_for_ready   => sub {
            my (%args) = @_;
            my $last_error     = '';
            for ( 1 .. 120 ) {
                my $dbh = eval {
                    require DBI;
                    DBI->connect(
                        $args{dsn},
                        $args{user},
                        $args{password},
                        {
                            RaiseError => 1,
                            PrintError => 0,
                            AutoCommit => 1,
                        }
                    );
                };
                return $dbh if $dbh;
                $last_error = DBI->errstr // $@ // '';
                sleep 1;
            }
            die "Timed out waiting for MySQL to accept connections on $args{dsn}: $last_error\n";
        },
        seed_database    => sub {
            my (%args) = @_;
            my $dbh = $args{dbh};
            $dbh->do('create table users (id integer primary key, name varchar(128), status varchar(32), note text)');
            $dbh->do('create table orders (id integer primary key, user_id integer, total decimal(10,2), status varchar(32))');
            $dbh->do(q{insert into users (id, name, status, note) values (1, 'Alice', 'active', 'alpha')});
            $dbh->do(q{insert into users (id, name, status, note) values (2, 'Bob', 'review', 'beta')});
            $dbh->do(q{insert into orders (id, user_id, total, status) values (1, 1, 10.50, 'new')});
            $dbh->do(q{insert into orders (id, user_id, total, status) values (2, 2, 25.00, 'pending')});
            return 1;
        },
    );
};

subtest 'PostgreSQL browser workflow' => sub {
    _run_rdbms_matrix(
        label            => 'PostgreSQL',
        driver_module    => 'DBD::Pg',
        driver_name      => 'DBD::Pg',
        image            => 'postgres:16',
        container_port   => 5432,
        database         => 'dashboard_test',
        username         => 'dashboard',
        password         => 'dashboardpass',
        expected_row     => 'Alice',
        expected_tables  => [ 'users', 'orders' ],
        template_dsn     => 'dbi:Pg:dbname=app;host=127.0.0.1;port=5432',
        guide_fragment   => 'dbi:Pg:dbname=app;host=127.0.0.1;port=5432',
        docker_args      => [
            '-e', 'POSTGRES_DB=dashboard_test',
            '-e', 'POSTGRES_USER=dashboard',
            '-e', 'POSTGRES_PASSWORD=dashboardpass',
        ],
        dsn_builder      => sub {
            my ($port) = @_;
            return "dbi:Pg:dbname=dashboard_test;host=127.0.0.1;port=$port";
        },
        wait_for_ready   => sub {
            my (%args) = @_;
            my $last_error = '';
            require DBI;
            my $dsn = $args{dsn};
            for ( 1 .. 120 ) {
                my $dbh = eval {
                    DBI->connect(
                        $dsn,
                        $args{user},
                        $args{password},
                        {
                            RaiseError => 1,
                            PrintError => 0,
                            AutoCommit => 1,
                        }
                    );
                };
                return $dbh if $dbh;
                $last_error = DBI->errstr // $@ // '';
                sleep 1;
            }
            die "Timed out waiting for PostgreSQL to accept connections on $dsn: $last_error\n";
        },
        seed_database    => sub {
            my (%args) = @_;
            my $dbh = $args{dbh};
            $dbh->do('create table users (id integer primary key, name text, status text, note text)');
            $dbh->do('create table orders (id integer primary key, user_id integer, total numeric, status text)');
            $dbh->do(q{insert into users (id, name, status, note) values (1, 'Alice', 'active', 'alpha')});
            $dbh->do(q{insert into users (id, name, status, note) values (2, 'Bob', 'review', 'beta')});
            $dbh->do(q{insert into orders (id, user_id, total, status) values (1, 1, 10.5, 'new')});
            $dbh->do(q{insert into orders (id, user_id, total, status) values (2, 2, 25.0, 'pending')});
            return 1;
        },
    );
};

subtest 'MSSQL browser workflow' => sub {
    _run_rdbms_matrix(
        label            => 'MSSQL',
        driver_module    => 'DBD::ODBC',
        driver_name      => 'DBD::ODBC',
        image            => 'mcr.microsoft.com/mssql/server:2022-latest',
        container_port   => 1433,
        database         => 'tempdb',
        username         => 'sa',
        password         => 'DashboardPassw0rd!',
        expected_row     => 'Alice',
        expected_tables  => [ 'orders', 'users' ],
        template_dsn     => 'dbi:ODBC:Driver=FreeTDS;Server=127.0.0.1;Port=1433;TDS_Version=7.4;Database=master;Encrypt=optional;TrustServerCertificate=yes',
        guide_fragment   => 'Driver=FreeTDS',
        docker_args      => [
            '-e', 'ACCEPT_EULA=Y',
            '-e', 'MSSQL_PID=Developer',
            '-e', 'MSSQL_SA_PASSWORD=DashboardPassw0rd!',
        ],
        dsn_builder      => sub {
            my ($port) = @_;
            return "dbi:ODBC:Driver=/home/mv/opt/freetds/lib/libtdsodbc.so;Server=127.0.0.1;Port=$port;TDS_Version=7.4;Database=tempdb;Encrypt=optional;TrustServerCertificate=yes";
        },
        wait_for_ready   => sub {
            my (%args) = @_;
            my $last_error = '';
            require DBI;
            for ( 1 .. 180 ) {
                my $dbh = eval {
                    DBI->connect(
                        $args{dsn},
                        $args{user},
                        $args{password},
                        {
                            RaiseError => 1,
                            PrintError => 0,
                            AutoCommit => 1,
                        }
                    );
                };
                return $dbh if $dbh;
                $last_error = $DBI::errstr // $@ // '';
                sleep 1;
            }
            die "Timed out waiting for MSSQL to accept connections on $args{dsn}: $last_error\n";
        },
        seed_database    => sub {
            my (%args) = @_;
            my $dbh = $args{dbh};
            $dbh->do(q{if object_id('orders', 'U') is not null drop table orders});
            $dbh->do(q{if object_id('users', 'U') is not null drop table users});
            $dbh->do('create table users (id int primary key, name nvarchar(128), status nvarchar(32), note nvarchar(max))');
            $dbh->do('create table orders (id int primary key, user_id int, total decimal(10,2), status nvarchar(32))');
            $dbh->do(q{insert into users (id, name, status, note) values (1, 'Alice', 'active', 'alpha')});
            $dbh->do(q{insert into users (id, name, status, note) values (2, 'Bob', 'review', 'beta')});
            $dbh->do(q{insert into orders (id, user_id, total, status) values (1, 1, 10.50, 'new')});
            $dbh->do(q{insert into orders (id, user_id, total, status) values (2, 2, 25.00, 'pending')});
            return 1;
        },
    );
};

subtest 'Oracle browser workflow' => sub {
    _run_rdbms_matrix(
        label            => 'Oracle',
        driver_module    => 'DBD::Oracle',
        driver_name      => 'DBD::Oracle',
        image            => 'gvenzl/oracle-xe:21-slim-faststart',
        container_port   => 1521,
        database         => 'XEPDB1',
        username         => 'dashboard',
        password         => 'dashboardpass',
        expected_row     => 'Alice',
        expected_tables  => [ 'ORDERS', 'USERS' ],
        template_dsn     => 'dbi:Oracle:host=127.0.0.1;port=1521;service_name=XEPDB1',
        guide_fragment   => 'service_name=XEPDB1',
        docker_args      => [
            '-e', 'ORACLE_PASSWORD=DashboardPassw0rd!',
            '-e', 'APP_USER=dashboard',
            '-e', 'APP_USER_PASSWORD=dashboardpass',
        ],
        dsn_builder      => sub {
            my ($port) = @_;
            return "dbi:Oracle:host=127.0.0.1;port=$port;service_name=XEPDB1";
        },
        wait_for_ready   => sub {
            my (%args) = @_;
            my $last_error = '';
            require DBI;
            for ( 1 .. 180 ) {
                my $dbh = eval {
                    DBI->connect(
                        $args{dsn},
                        $args{user},
                        $args{password},
                        {
                            RaiseError => 1,
                            PrintError => 0,
                            AutoCommit => 1,
                        }
                    );
                };
                return $dbh if $dbh;
                $last_error = $DBI::errstr // $@ // '';
                sleep 1;
            }
            die "Timed out waiting for Oracle to accept connections on $args{dsn}: $last_error\n";
        },
        seed_database    => sub {
            my (%args) = @_;
            my $dbh = $args{dbh};
            $dbh->do(q{
                begin
                    execute immediate 'drop table orders';
                exception
                    when others then
                        if sqlcode != -942 then raise; end if;
                end;
            });
            $dbh->do(q{
                begin
                    execute immediate 'drop table users';
                exception
                    when others then
                        if sqlcode != -942 then raise; end if;
                end;
            });
            $dbh->do('create table users (id number primary key, name varchar2(128), status varchar2(32), note varchar2(4000))');
            $dbh->do('create table orders (id number primary key, user_id number, total number(10,2), status varchar2(32))');
            $dbh->do(q{insert into users (id, name, status, note) values (1, 'Alice', 'active', 'alpha')});
            $dbh->do(q{insert into users (id, name, status, note) values (2, 'Bob', 'review', 'beta')});
            $dbh->do(q{insert into orders (id, user_id, total, status) values (1, 1, 10.5, 'new')});
            $dbh->do(q{insert into orders (id, user_id, total, status) values (2, 2, 25.0, 'pending')});
            return 1;
        },
    );
};

done_testing;

# _prepare_optional_rdbms_env()
# Purpose: expose user-space Perl DB drivers and native client libraries before optional live RDBMS tests probe them.
# Input: none.
# Output: true after @INC and process environment are updated best-effort.
sub _prepare_optional_rdbms_env {
    my $home = $ENV{HOME} || '';
    return 1 if $home eq '';

    my @inc_candidates = grep { -d $_ }
      File::Spec->catdir( $home, 'perl5', 'lib', 'perl5' ),
      File::Spec->catdir( $home, 'perl5', 'lib', 'perl5', $Config::Config{archname} );
    if (@inc_candidates) {
        my %seen = map { $_ => 1 } @INC;
        unshift @INC, grep { !$seen{$_}++ } reverse @inc_candidates;
        my %env_seen;
        $ENV{PERL5LIB} = join(
            ':',
            grep { defined $_ && $_ ne '' && !$env_seen{$_}++ }
              @inc_candidates,
              split( /:/, ( $ENV{PERL5LIB} || '' ) ),
        );
    }

    my @path_entries = grep { -d $_ }
      File::Spec->catdir( $home, 'perl5', 'bin' ),
      File::Spec->catdir( $home, 'opt', 'unixodbc', 'bin' );
    if (@path_entries) {
        my %seen;
        $ENV{PATH} = join(
            ':',
            grep { defined $_ && $_ ne '' && !$seen{$_}++ }
              @path_entries,
              split( /:/, ( $ENV{PATH} || '' ) ),
        );
    }

    my $oracle_home = '';
    for my $candidate (
        File::Spec->catdir( $home, 'opt', 'oracle-client', 'product', '21c', 'dbhomeXE' ),
        '/tmp/oracle-image-opt/product/21c/dbhomeXE'
      )
    {
        next if !-d $candidate;
        $oracle_home = $candidate;
        last;
    }
    $ENV{ORACLE_HOME} = $oracle_home if $oracle_home ne '';

    my @ld_entries = grep { -d $_ }
      File::Spec->catdir( $home, 'opt', 'unixodbc', 'lib' ),
      File::Spec->catdir( $home, 'opt', 'freetds', 'lib' ),
      File::Spec->catdir( $home, 'opt', 'libaio', 'lib' ),
      ( $oracle_home ne '' ? File::Spec->catdir( $oracle_home, 'lib' ) : () );
    if (@ld_entries) {
        my %seen;
        $ENV{LD_LIBRARY_PATH} = join(
            ':',
            grep { defined $_ && $_ ne '' && !$seen{$_}++ }
              @ld_entries,
              split( /:/, ( $ENV{LD_LIBRARY_PATH} || '' ) ),
        );
    }

    return 1;
}

# _run_rdbms_matrix(%args)
# Purpose: run one full docker-backed sql-dashboard Playwright flow for one server-backed DB driver.
# Input: hash with label, driver names, docker image settings, DSN builder, readiness callback, and seed callback.
# Output: true after the subtest assertions complete or skip_all if prerequisites are missing.
sub _run_rdbms_matrix {
    my (%args) = @_;

    plan skip_all => "$args{label} browser workflow requires $args{driver_module} in the current Perl environment"
      if !_module_available( $args{driver_module} );

    my $home_root         = tempdir( 'dd-sql-rdbms-home-XXXXXX', CLEANUP => 1, TMPDIR => 1 );
    my $project_root      = tempdir( 'dd-sql-rdbms-project-XXXXXX', CLEANUP => 1, TMPDIR => 1 );
    my $runtime_root      = File::Spec->catdir( $project_root, '.developer-dashboard' );
    my $sql_config_root   = File::Spec->catdir( $runtime_root, 'config', 'sql-dashboard' );
    my $collection_root   = File::Spec->catdir( $sql_config_root, 'collections' );
    my $dashboard_port    = _reserve_port();
    my $database_port     = _reserve_port();
    my $dashboard_pid;
    my $dashboard_log     = File::Spec->catfile( $project_root, 'dashboard-serve.log' );
    my $container_name    = sprintf( 'dd-sql-%s-%d-%d', lc( $args{label} ), $$, time() );
    my $saved_collection  = File::Spec->catfile( $collection_root, "$args{label} Reporting.json" );
    my $dsn               = $args{dsn_builder}->($database_port);

    eval {
        _run_command(
            command => [ $git_bin, 'init', '-q', $project_root ],
            label   => "$args{label} git init for Playwright fixture",
        );
        make_path($runtime_root);

        _run_command(
            command => [ $^X, "-I$repo_lib", $dashboard_bin, 'init' ],
            cwd     => $project_root,
            env     => { HOME => $home_root },
            label   => "$args{label} dashboard init for Playwright fixture",
        );

        _run_command(
            command => [
                $docker_bin, 'run', '-d', '--rm',
                '--name', $container_name,
                @{$args{docker_args}},
                '-p', "127.0.0.1:$database_port:$args{container_port}",
                $args{image},
            ],
            label => "$args{label} docker run",
        );

        my $dbh = $args{wait_for_ready}->(
            docker_bin     => $docker_bin,
            container_name => $container_name,
            dsn      => $dsn,
            user     => $args{username},
            password => $args{password},
        );
        $args{seed_database}->( dbh => $dbh );
        $dbh->disconnect or die "Unable to disconnect seeded $args{label} fixture\n";

        $dashboard_pid = _start_dashboard_server(
            cwd           => $project_root,
            home          => $home_root,
            port          => $dashboard_port,
            repo_lib      => $repo_lib,
            dashboard_bin => $dashboard_bin,
            log_file      => $dashboard_log,
        );
        _wait_for_http("http://127.0.0.1:$dashboard_port/app/sql-dashboard");

        my ( $script_fh, $script_path ) = tempfile( 'sql-dashboard-rdbms-playwright-XXXXXX', SUFFIX => '.js', TMPDIR => 1 );
        print {$script_fh} _playwright_script();
        close $script_fh or die "Unable to close Playwright script $script_path: $!";

        my $playwright_result = _run_command(
            command => [ $node_bin, $script_path ],
            env     => {
                PLAYWRIGHT_DIR    => $playwright_dir,
                CHROMIUM_BIN      => $chromium_bin,
                DASHBOARD_URL     => "http://127.0.0.1:$dashboard_port/app/sql-dashboard",
                DB_DRIVER         => $args{driver_name},
                DB_DSN            => $dsn,
                DB_PROFILE        => "$args{label} Profile",
                DB_COLLECTION     => "$args{label} Reporting",
                DB_USER           => $args{username},
                DB_PASSWORD       => $args{password},
                DB_EXPECTED_ROW   => $args{expected_row},
                DB_EXPECT_TABLE_A => $args{expected_tables}[0],
                DB_EXPECT_TABLE_B => $args{expected_tables}[1],
                DB_TEMPLATE_DSN   => $args{template_dsn} || '',
                DB_GUIDE_FRAGMENT => $args{guide_fragment} || '',
            },
            label => "$args{label} Playwright sql-dashboard matrix",
        );

        is( $playwright_result->{stderr}, '', "$args{label} sql-dashboard Playwright matrix keeps stderr clean" );
        my $payload = $playwright_result->{stdout} ne ''
          ? _json_decode( $playwright_result->{stdout} )
          : {
            ok              => 0,
            cases           => [],
            consoleMessages => [],
            pageErrors      => [],
          };
        ok( $payload->{ok}, "$args{label} sql-dashboard Playwright matrix reports success" )
          or diag _diagnostic_text($payload);
        is( scalar @{ $payload->{cases} || [] }, 22, "$args{label} sql-dashboard Playwright matrix records 22 browser cases" );
        for my $case ( @{ $payload->{cases} || [] } ) {
            ok( $case->{ok}, "$args{label}: $case->{name}" ) or diag _case_diagnostic($case);
        }

        ok( -f $saved_collection, "$args{label} Playwright matrix keeps the saved SQL collection on disk" );
        like( _read_text($saved_collection), qr/"name"\s*:\s*"\Q$args{label} Reporting\E"/, "$args{label} Playwright matrix persists the browser-created collection name" );
        is( _mode_octal($sql_config_root), '0700', "$args{label} Playwright matrix keeps the sql-dashboard config root owner-only" );
        is( _mode_octal($collection_root), '0700', "$args{label} Playwright matrix keeps the sql-dashboard collection root owner-only" );
        is( _mode_octal($saved_collection), '0600', "$args{label} Playwright matrix keeps the saved SQL collection file owner-only" );

        1;
    } or do {
        my $error = $@ || "$args{label} sql-dashboard Playwright matrix failed";
        diag $error;
        diag _read_text($dashboard_log) if -f $dashboard_log;
        my $docker_logs = _docker_logs( $docker_bin, $container_name );
        diag $docker_logs if $docker_logs ne '';
        _stop_dashboard_server(
            cwd           => $project_root,
            home          => $home_root,
            repo_lib      => $repo_lib,
            dashboard_bin => $dashboard_bin,
            pid           => $dashboard_pid,
        ) if $dashboard_pid;
        _docker_rm_force( $docker_bin, $container_name );
        fail("$args{label} sql-dashboard Playwright matrix setup or execution failed");
        return 0;
    };

    _stop_dashboard_server(
        cwd           => $project_root,
        home          => $home_root,
        repo_lib      => $repo_lib,
        dashboard_bin => $dashboard_bin,
        pid           => $dashboard_pid,
    ) if $dashboard_pid;
    _docker_rm_force( $docker_bin, $container_name );

    return 1;
}

# _playwright_script()
# Purpose: build the generic Chromium Playwright regression script for one server-backed SQL dashboard driver.
# Input: no arguments.
# Output: JavaScript source string that writes JSON case results to stdout.
sub _playwright_script {
    return <<'JS';
const path = require('path');
const { chromium } = require(path.join(process.env.PLAYWRIGHT_DIR, 'index.js'));

async function main() {
  const browser = await chromium.launch({
    executablePath: process.env.CHROMIUM_BIN,
    headless: true
  });
  const page = await browser.newPage();
  const consoleMessages = [];
  const pageErrors = [];
  const cases = [];

  function record(name, ok, detail) {
    cases.push({ name, ok: !!ok, detail: detail || '' });
  }

  async function check(name, fn) {
    try {
      await fn();
      record(name, true, '');
    } catch (error) {
      record(name, false, String(error && error.stack || error));
    }
  }

  function ensure(condition, detail) {
    if (!condition) throw new Error(detail);
  }

  async function waitForBootstrapReady() {
    await page.waitForFunction(() => {
      const select = document.getElementById('sql-profile-driver');
      return !!(select && select.options && select.options.length > 1);
    });
  }

  page.on('console', (message) => {
    consoleMessages.push(message.type() + ': ' + message.text());
  });
  page.on('pageerror', (error) => {
    pageErrors.push(String(error && error.stack || error));
  });

  await page.goto(process.env.DASHBOARD_URL, { waitUntil: 'domcontentloaded' });
  await page.waitForSelector('#sql-profile-driver');
  await waitForBootstrapReady();

  await check('main tabs visible', async () => {
    const tabs = await page.locator('[data-sql-main-tab]').allTextContents();
    ensure(tabs.includes('Connection Profiles') && tabs.includes('SQL Workspace') && tabs.includes('Schema Explorer'),
      'expected top-level SQL tabs were not all visible: ' + JSON.stringify(tabs));
  });

  await check('driver dropdown exposes requested driver', async () => {
    const options = await page.locator('#sql-profile-driver option').allTextContents();
    ensure(options.some((value) => String(value || '').includes(process.env.DB_DRIVER)),
      'driver dropdown did not expose requested driver: ' + JSON.stringify({ driver: process.env.DB_DRIVER, options }));
  });

  await check('driver guidance shows the expected DSN example', async () => {
    await page.locator('#sql-profile-dsn').fill('');
    await page.locator('#sql-profile-driver').selectOption(process.env.DB_DRIVER);
    const dsn = await page.locator('#sql-profile-dsn').inputValue();
    ensure(dsn === process.env.DB_TEMPLATE_DSN,
      'blank driver selection should seed the driver-specific DSN example: ' + JSON.stringify({ driver: process.env.DB_DRIVER, dsn, expected: process.env.DB_TEMPLATE_DSN }));
    const help = await page.locator('#sql-profile-driver-help').textContent();
    ensure(String(help || '').includes(process.env.DB_GUIDE_FRAGMENT || process.env.DB_TEMPLATE_DSN),
      'driver guidance should mention the driver-specific DSN details: ' + JSON.stringify({ driver: process.env.DB_DRIVER, help, expected: process.env.DB_GUIDE_FRAGMENT || process.env.DB_TEMPLATE_DSN }));
  });

  await page.locator('#sql-profile-name').fill(process.env.DB_PROFILE);
  await page.locator('#sql-profile-dsn').fill(process.env.DB_DSN);
  await page.locator('#sql-profile-driver').selectOption(process.env.DB_DRIVER);
  await page.locator('#sql-profile-user').fill(process.env.DB_USER);
  await page.locator('#sql-profile-password').fill(process.env.DB_PASSWORD);
  await page.locator('#sql-profile-attrs').fill('{"RaiseError":1,"PrintError":0,"AutoCommit":1}');
  await page.locator('#sql-profile-save-password').check();

  let savedRouteUrl = '';

  await check('profile save succeeds', async () => {
    const response = await Promise.all([
      page.waitForResponse((value) => value.request().method() === 'POST' && value.url().includes('/ajax/sql-dashboard-profiles-save') && value.status() === 200),
      page.locator('#sql-profile-save').click()
    ]).then((values) => values[0]);
    const payload = await response.json();
    ensure(payload && payload.ok, 'profile save failed: ' + JSON.stringify(payload || {}));
  });

  await check('profile save banner confirms active profile', async () => {
    await page.waitForFunction(() => {
      const banner = document.getElementById('sql-banner');
      return banner && !banner.hidden;
    });
    const banner = await page.locator('#sql-banner').textContent();
    ensure(String(banner || '').includes('Profile saved: ' + process.env.DB_PROFILE),
      'profile banner mismatch: ' + JSON.stringify({ banner }));
  });

  await check('saved profile tab appears', async () => {
    await page.waitForFunction((profile) => !!document.querySelector('[data-sql-profile-tab="' + profile + '"]'), process.env.DB_PROFILE);
    const tabText = await page.locator('[data-sql-profile-tab="' + process.env.DB_PROFILE + '"]').textContent();
    ensure(String(tabText || '').includes(process.env.DB_PROFILE), 'saved profile tab did not appear');
  });

  await page.locator('[data-sql-main-tab="workspace"]').click();
  await page.locator('#sql-editor').fill('select id, name from users order by id');

  await check('workspace subtabs default to Run SQL', async () => {
    const layout = await page.evaluate(() => {
      const tabs = Array.from(document.querySelectorAll('[data-sql-workspace-tab]')).map((node) => node.textContent || '');
      const active = document.querySelector('[data-sql-workspace-tab].is-active');
      return {
        tabs,
        active: active ? active.textContent : ''
      };
    });
    ensure(layout.tabs.includes('Collection') && layout.tabs.includes('Run SQL') && String(layout.active || '').includes('Run SQL'),
      'workspace should expose Collection and Run SQL subtabs with Run SQL active by default: ' + JSON.stringify(layout));
  });

  await check('workspace route includes portable connection id', async () => {
    const url = page.url();
    ensure(url.includes('connection='), 'workspace URL should include a connection parameter: ' + url);
    ensure(url.includes(encodeURIComponent(process.env.DB_DSN + '|' + process.env.DB_USER)),
      'workspace URL should carry the saved connection id: ' + url);
  });

  await check('workspace route omits password', async () => {
    const url = page.url();
    ensure(!url.includes('password'), 'workspace URL should not leak passwords: ' + url);
  });

  await page.locator('[data-sql-workspace-tab="collections"]').click();
  await page.locator('#sql-collection-name').fill(process.env.DB_COLLECTION);
  const collectionCreateResponse = await Promise.all([
    page.waitForResponse((value) => value.request().method() === 'POST' && value.url().includes('/ajax/sql-dashboard-collections-save') && value.status() === 200),
    page.locator('#sql-collection-save').click()
  ]).then((values) => values[0]);
  const collectionCreatePayload = await collectionCreateResponse.json();
  ensure(collectionCreatePayload && collectionCreatePayload.ok, 'collection create failed: ' + JSON.stringify(collectionCreatePayload || {}));

  await page.locator('[data-sql-workspace-tab="run"]').click();
  await page.locator('#sql-collection-item-name').fill('Users Query');
  await check('collection save succeeds', async () => {
    const response = await Promise.all([
      page.waitForResponse((value) => value.request().method() === 'POST' && value.url().includes('/ajax/sql-dashboard-collections-save') && value.status() === 200),
      page.locator('#sql-collection-item-save').click()
    ]).then((values) => values[0]);
    const payload = await response.json();
    ensure(payload && payload.ok, 'collection save failed: ' + JSON.stringify(payload || {}));
  });

  savedRouteUrl = page.url();

  await check('saved collection tab appears', async () => {
    await page.waitForFunction((collection) => !!document.querySelector('[data-sql-collection-tab="' + collection + '"]'), process.env.DB_COLLECTION);
    const tabText = await page.locator('[data-sql-collection-tab="' + process.env.DB_COLLECTION + '"]').textContent();
    ensure(String(tabText || '').includes(process.env.DB_COLLECTION), 'saved collection tab did not appear');
  });

  await check('saved SQL item appears', async () => {
    await page.waitForFunction(() => !!document.querySelector('[data-sql-collection-item-link="users-query"]'));
    const text = await page.locator('[data-sql-collection-item-link="users-query"]').textContent();
    ensure(String(text || '').includes('Users Query'), 'saved SQL item did not appear');
  });

  await check('select query executes successfully', async () => {
    const response = await Promise.all([
      page.waitForResponse((value) => value.request().method() === 'POST' && value.url().includes('/ajax/sql-dashboard-execute') && value.status() === 200),
      page.locator('#sql-run').click()
    ]).then((values) => values[0]);
    const payload = await response.json();
    ensure(payload && payload.ok, 'sql execute failed: ' + JSON.stringify(payload || {}));
  });

  await page.waitForTimeout(400);
  await check('result DOM includes seeded row content', async () => {
    const text = await page.locator('#sql-result-html').innerText();
    ensure(String(text || '').includes(process.env.DB_EXPECTED_ROW),
      'result html should include the seeded row content: ' + JSON.stringify({ text }));
  });

  await check('result info reports the active driver', async () => {
    const info = await page.locator('#sql-result-info').textContent();
    ensure(String(info || '').includes(process.env.DB_DRIVER),
      'result info should include the driver: ' + JSON.stringify({ info }));
  });

  const schemaResponse = await Promise.all([
    page.waitForResponse((value) => value.request().method() === 'POST' && value.url().includes('/ajax/sql-dashboard-schema-browse') && value.status() === 200),
    page.locator('[data-sql-main-tab="schema"]').click()
  ]).then((values) => values[0]);
  const schemaPayload = await schemaResponse.json();
  ensure(schemaPayload && schemaPayload.ok, 'schema browse failed: ' + JSON.stringify(schemaPayload || {}));
  await page.waitForTimeout(400);

  await check('schema browse loads first table', async () => {
    const tabs = await page.locator('[data-sql-table-name]').allTextContents();
    ensure(tabs.includes(process.env.DB_EXPECT_TABLE_A),
      'schema tabs should include the first expected table: ' + JSON.stringify(tabs));
  });

  await check('schema browse loads second table', async () => {
    const tabs = await page.locator('[data-sql-table-name]').allTextContents();
    ensure(tabs.includes(process.env.DB_EXPECT_TABLE_B),
      'schema tabs should include the second expected table: ' + JSON.stringify(tabs));
  });

  await check('schema table filter narrows the table list live', async () => {
    await page.locator('#sql-table-filter').fill(process.env.DB_EXPECT_TABLE_B.slice(0, 3));
    await page.waitForTimeout(200);
    const tabs = await page.locator('[data-sql-table-name]').allTextContents();
    ensure(tabs.some((value) => String(value || '') === process.env.DB_EXPECT_TABLE_B),
      'schema filter should keep the matching table visible: ' + JSON.stringify(tabs));
    await page.locator('#sql-table-filter').fill('');
  });

  await page.locator('[data-sql-main-tab="profiles"]').click();
  const deleteResponse = await Promise.all([
    page.waitForResponse((value) => value.request().method() === 'POST' && value.url().includes('/ajax/sql-dashboard-profiles-delete') && value.status() === 200),
    page.locator('#sql-profile-delete').click()
  ]).then((values) => values[0]);
  const deletePayload = await deleteResponse.json();
  ensure(deletePayload && deletePayload.ok, 'profile delete failed: ' + JSON.stringify(deletePayload || {}));

  await page.goto(savedRouteUrl, { waitUntil: 'domcontentloaded' });
  await page.waitForSelector('#sql-profile-driver');
  await waitForBootstrapReady();
  await page.waitForTimeout(400);

  await check('shared URL reload restores draft dsn and user', async () => {
    const values = await page.evaluate(() => {
      return {
        dsn: document.getElementById('sql-profile-dsn').value,
        user: document.getElementById('sql-profile-user').value,
        password: document.getElementById('sql-profile-password').value
      };
    });
    ensure(values.dsn === process.env.DB_DSN, 'shared reload should restore the DSN: ' + JSON.stringify(values));
    ensure(values.user === process.env.DB_USER, 'shared reload should restore the DB user: ' + JSON.stringify(values));
    ensure(values.password === '', 'shared reload should not restore a local password: ' + JSON.stringify(values));
  });

  await check('shared URL reload asks for local credentials', async () => {
    const banner = await page.locator('#sql-banner').textContent();
    ensure(String(banner || '').match(/local credentials|required local credentials|password/i),
      'shared reload should ask for local credentials when the profile password is gone: ' + JSON.stringify({ banner }));
  });

  await check('collection list still shows the active collection after reload', async () => {
    const title = await page.locator('#sql-collection-item-list-title').textContent();
    ensure(String(title || '').includes(process.env.DB_COLLECTION),
      'collection title should still identify the active collection: ' + JSON.stringify({ title }));
  });

  await check('saved SQL label stays visible after reload', async () => {
    const label = await page.locator('#sql-active-sql-name').textContent();
    ensure(String(label || '').includes('Users Query'),
      'active saved SQL label should stay visible after reload: ' + JSON.stringify({ label }));
  });

  const ok = cases.every((item) => item.ok) && pageErrors.length === 0;
  process.stdout.write(JSON.stringify({ ok, cases, consoleMessages, pageErrors }));
  await browser.close();
}

main().catch((error) => {
  process.stderr.write(String(error && error.stack || error) + '\n');
  process.exit(1);
});
JS
}

# _module_available($module_name)
# Purpose: report whether one optional Perl module can be loaded in the current test Perl.
# Input: module name string.
# Output: true when the module loads successfully, otherwise false.
sub _module_available {
    my ($module_name) = @_;
    return eval "require $module_name; 1" ? 1 : 0;
}

# _diagnostic_text($payload)
# Purpose: format a compact diagnostic string from one Playwright JSON payload.
# Input: decoded payload hash reference.
# Output: printable diagnostic string for Test::More::diag.
sub _diagnostic_text {
    my ($payload) = @_;
    return '' if ref($payload) ne 'HASH';
    return join(
        "\n",
        map { ref($_) ? join( ', ', @{$_} ) : $_ }
          grep { defined $_ && $_ ne '' }
          (
            $payload->{pageErrors} && @{ $payload->{pageErrors} } ? 'pageErrors=' . join( ' | ', @{ $payload->{pageErrors} } ) : '',
            $payload->{consoleMessages} && @{ $payload->{consoleMessages} } ? 'console=' . join( ' | ', @{ $payload->{consoleMessages} } ) : '',
          )
    );
}

# _case_diagnostic($case)
# Purpose: format one failed RDBMS browser case for Test::More diagnostics.
# Input: hash reference with name and detail keys from the Playwright payload.
# Output: printable one-line diagnostic string.
sub _case_diagnostic {
    my ($case) = @_;
    return '' if ref($case) ne 'HASH';
    return ($case->{name} || 'unnamed case') . ': ' . ( $case->{detail} || 'unknown failure' );
}

# _find_command(@candidates)
# Purpose: resolve the first executable command path from a candidate list.
# Input: list of command names to search on PATH.
# Output: absolute executable path string or undef when no candidate exists.
sub _find_command {
    my @candidates = @_;
    for my $candidate (@candidates) {
        next if !defined $candidate || $candidate eq '';
        for my $dir ( File::Spec->path() ) {
            my $path = File::Spec->catfile( $dir, $candidate );
            next if !-f $path || !-x $path;
            next if $path eq '/snap/bin/chromium';
            return $path;
        }
    }
    return undef;
}

# _playwright_dir($npx_bin, $home_root)
# Purpose: locate the cached Playwright module directory that npx will use.
# Input: resolved npx path and the host HOME directory.
# Output: absolute directory path containing the Playwright package.
sub _playwright_dir {
    my ( $npx_bin, $home_root ) = @_;
    my ( $stdout, $stderr, $exit ) = capture {
        system( $npx_bin, 'playwright', '--version' );
        return $? >> 8;
    };
    die "Unable to resolve Playwright with npx: $stderr$stdout"
      if $exit != 0;
    my @matches = sort glob( File::Spec->catfile( $home_root, '.npm', '_npx', '*', 'node_modules', 'playwright' ) );
    die "Unable to find cached Playwright module directory under $home_root/.npm/_npx\n"
      if !@matches;
    return $matches[-1];
}

# _docker_available($docker_bin)
# Purpose: verify that the local docker daemon can accept commands before live RDBMS browser coverage starts.
# Input: resolved docker executable path.
# Output: true when docker info exits successfully, otherwise false.
sub _docker_available {
    my ($docker_bin) = @_;
    my ( undef, undef, $exit ) = capture {
        system( $docker_bin, 'info' );
        return $? >> 8;
    };
    return $exit == 0 ? 1 : 0;
}

# _reserve_port()
# Purpose: reserve a free loopback TCP port for an isolated database or dashboard server.
# Input: no arguments.
# Output: integer TCP port number.
sub _reserve_port {
    my $socket = IO::Socket::INET->new(
        LocalAddr => '127.0.0.1',
        LocalPort => 0,
        Proto     => 'tcp',
        Listen    => 1,
        ReuseAddr => 1,
    ) or die "Unable to reserve a local TCP port: $!";
    my $port = $socket->sockport();
    close $socket or die "Unable to close reserved TCP port socket for $port: $!";
    return $port;
}

# _run_command(%args)
# Purpose: execute one command with optional cwd/env overrides and return captured output.
# Input: hash containing command array reference plus optional cwd, env, and label keys.
# Output: hash reference with stdout, stderr, and exit keys.
sub _run_command {
    my (%args) = @_;
    my $command = $args{command} || [];
    die "run_command requires a command array reference\n" if ref($command) ne 'ARRAY' || !@{$command};

    my $cwd = getcwd();
    my ( $stdout, $stderr, $exit ) = capture {
        local %ENV = ( %ENV, %{ $args{env} || {} } );
        if ( defined $args{cwd} && $args{cwd} ne '' ) {
            chdir $args{cwd} or die "Unable to chdir to $args{cwd}: $!";
        }
        system( @{$command} );
        my $status = $? >> 8;
        chdir $cwd or die "Unable to restore cwd to $cwd: $!";
        return $status;
    };

    is( $exit, 0, ( $args{label} || 'command' ) . ' exits successfully' ) or diag $stderr . $stdout;
    return {
        stdout => $stdout,
        stderr => $stderr,
        exit   => $exit,
    };
}

# _start_dashboard_server(%args)
# Purpose: fork and exec one foreground dashboard server for browser coverage.
# Input: hash containing cwd, home, port, repo_lib, dashboard_bin, and log_file.
# Output: child pid integer for the running dashboard server.
sub _start_dashboard_server {
    my (%args) = @_;
    my $pid = fork();
    die "Unable to fork dashboard server: $!" if !defined $pid;
    if ( $pid == 0 ) {
        local %ENV = %ENV;
        $ENV{HOME} = $args{home};
        chdir $args{cwd} or die "Unable to chdir to $args{cwd}: $!";
        open STDOUT, '>', $args{log_file} or die "Unable to write $args{log_file}: $!";
        open STDERR, '>&STDOUT' or die "Unable to dup dashboard log: $!";
        exec $^X, "-I$args{repo_lib}", $args{dashboard_bin}, 'serve', '--foreground', '--host', '127.0.0.1', '--port', $args{port}, '--workers', '1'
          or die "Unable to exec dashboard server: $!";
    }
    return $pid;
}

# _stop_dashboard_server(%args)
# Purpose: stop one foreground dashboard server started by _start_dashboard_server().
# Input: hash containing cwd, home, repo_lib, dashboard_bin, and pid.
# Output: hash reference with the stop command stdout, stderr, and exit code.
sub _stop_dashboard_server {
    my (%args) = @_;
    return if !$args{pid};
    local %ENV = %ENV;
    $ENV{HOME} = $args{home};
    my ( $stdout, $stderr, $exit ) = capture {
        chdir $args{cwd} or die "Unable to chdir to $args{cwd}: $!";
        system( $^X, "-I$args{repo_lib}", $args{dashboard_bin}, 'stop' );
        return $? >> 8;
    };
    my $waited = waitpid( $args{pid}, WNOHANG );
    if ( $waited == 0 && kill 0, $args{pid} ) {
        kill 'TERM', $args{pid};
        for ( 1 .. 20 ) {
            my $done = waitpid( $args{pid}, WNOHANG );
            last if $done == $args{pid};
            sleep 0.1;
        }
    }
    if ( kill 0, $args{pid} ) {
        kill 'KILL', $args{pid};
    }
    waitpid( $args{pid}, 0 );
    return {
        stdout => $stdout,
        stderr => $stderr,
        exit   => $exit,
    };
}

# _wait_for_http($url)
# Purpose: wait until one dashboard HTTP endpoint is reachable.
# Input: absolute HTTP URL string.
# Output: true when the endpoint responds successfully, otherwise dies on timeout.
sub _wait_for_http {
    my ($url) = @_;
    my $ua = LWP::UserAgent->new(
        timeout      => 2,
        max_redirect => 0,
    );
    for ( 1 .. 60 ) {
        my $response = $ua->get($url);
        return 1 if $response->is_success;
        sleep 0.25;
    }
    die "Timed out waiting for HTTP endpoint $url\n";
}

# _read_text($path)
# Purpose: read one text file into memory for diagnostics.
# Input: absolute file path.
# Output: full file contents string.
sub _read_text {
    my ($path) = @_;
    open my $fh, '<', $path or die "Unable to read $path: $!";
    local $/;
    my $text = <$fh>;
    close $fh or die "Unable to close $path: $!";
    return $text;
}

# _json_decode($text)
# Purpose: decode one JSON string through the project's JSON helper.
# Input: JSON text string.
# Output: decoded Perl data structure.
sub _json_decode {
    my ($text) = @_;
    require Developer::Dashboard::JSON;
    return Developer::Dashboard::JSON::json_decode($text);
}

# _mode_octal($path)
# Purpose: convert one filesystem object's mode to a comparable octal string.
# Input: absolute filesystem path.
# Output: four-digit octal mode string or undef if the path does not exist.
sub _mode_octal {
    my ($path) = @_;
    my @stat = stat($path);
    return undef if !@stat;
    return sprintf( '%04o', $stat[2] & 07777 );
}

# _docker_logs($docker_bin, $container_name)
# Purpose: capture recent logs from one managed SQL test container for diagnostics.
# Input: resolved docker binary path and container name string.
# Output: docker logs text, or an empty string when logs are unavailable.
sub _docker_logs {
    my ( $docker_bin, $container_name ) = @_;
    return '' if !$container_name;
    my ( $stdout, $stderr, undef ) = capture {
        system( $docker_bin, 'logs', '--tail', '200', $container_name );
        return $? >> 8;
    };
    return $stdout ne '' ? $stdout : $stderr;
}

# _docker_rm_force($docker_bin, $container_name)
# Purpose: stop and remove one managed SQL test container without touching unrelated docker resources.
# Input: resolved docker binary path and container name string.
# Output: true after the best-effort cleanup command completes.
sub _docker_rm_force {
    my ( $docker_bin, $container_name ) = @_;
    return 1 if !$container_name;
    capture {
        system( $docker_bin, 'rm', '-f', $container_name );
        return $? >> 8;
    };
    return 1;
}

__END__

=head1 NAME

32-sql-dashboard-rdbms-playwright.t - docker-backed MySQL, PostgreSQL, MSSQL, and Oracle browser coverage for the sql-dashboard bookmark

=for comment FULL-POD-DOC START

=head1 PURPOSE

This test is the executable regression contract for the sql-dashboard runtime and browser workflow. Read it when you need to understand the real fixture setup, assertions, and failure modes for this slice of the repository instead of guessing from the module names alone.

=head1 WHY IT EXISTS

It exists because the sql-dashboard runtime and browser workflow has enough moving parts that a code-only review can miss real regressions. Keeping those expectations in a dedicated test file makes the TDD loop, coverage loop, and release gate concrete.

=head1 WHEN TO USE

Use it when the Docker-backed MySQL, PostgreSQL, MSSQL, or Oracle browser paths change, especially profile setup, schema explorer behavior, or SQL execution UX.

=head1 HOW TO USE

Run it directly with C<prove -lv t/32-sql-dashboard-rdbms-playwright.t> while iterating, then keep it green under C<prove -lr t> and the coverage runs before release. For browser-backed tests, make sure the external browser tooling they name is actually present instead of assuming the suite will fabricate it. Because this matrix reaches real containers and drivers, treat skips as environment signals and real failures as product regressions. Make sure node, npx, git, docker, Chromium, DBI, and the relevant DBD drivers are available. The test skips when that external matrix is not ready rather than pretending the cross-database path is covered.

=head1 WHAT USES IT

Developers during TDD, the full C<prove -lr t> suite, the coverage gates, and the release verification loop all rely on this file to keep this behavior from drifting.

=head1 EXAMPLES

Example 1:

  prove -lv t/32-sql-dashboard-rdbms-playwright.t

Run the focused regression test by itself while you are changing the behavior it owns.

Example 2:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lv t/32-sql-dashboard-rdbms-playwright.t

Exercise the same focused test while collecting coverage for the library code it reaches.

Example 3:

  prove -lr t

Put the focused fix back through the whole repository suite before calling the work finished.

=for comment FULL-POD-DOC END

=cut
