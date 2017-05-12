#!/usr/bin/perl -w
use strict;

use Labyrinth::Test::Harness;
use Labyrinth::Plugin::CPAN;
use Labyrinth::Variables;
use Test::Database;
use Test::More tests => 91;

my @plugins = qw(
    Labyrinth::Plugin::CPAN
);

my $exceptions = 'Test.php|Net-ITE.pm|CGI.pm';
my $symlinks = {
          'Net-ITE.pm' => 'Net-ITE',
          'Math-Gsl' => 'Math-GSL',
          'CGI.pm' => 'CGI'
        };
my $merged = {
          'Math-GSL' => [
                          'Math-Gsl',
                          'Math-GSL'
                        ],
          'CGI' => [
                     'CGI.pm',
                     'CGI'
                   ],
          'Net-ITE' => [
                         'Net-ITE.pm',
                         'Net-ITE'
                       ]
        };
my $ignore = {
          'new.spirit' => 1,
          'perl5n.os' => 1,
          'FLAT.FA' => 1
        };
my $osnames = {
          'aix' => 'AIX',
          'freebsd' => 'FreeBSD',
          'hpux' => 'HP-UX',
          'minix' => 'MINIX',
          'bitrig' => 'BITRIG',
          'bsdos' => 'BSD/OS',
          'dragonfly' => 'Dragonfly BSD',
          'haiku' => 'Haiku',
          'gnu' => 'GNU Hurd',
          'linux' => 'GNU/Linux',
          'nto' => 'QNX Neutrino',
          'cygwin' => 'Windows (Cygwin)',
          'os2' => 'OS/2',
          'mswin32' => 'Windows (Win32)',
          'dec_osf' => 'Tru64',
          'sco' => 'SCO',
          'vms' => 'VMS',
          'openbsd' => 'OpenBSD',
          'midnightbsd' => 'MidnightBSD',
          'beos' => 'BeOS',
          'irix' => 'IRIX',
          'gnukfreebsd' => 'Debian GNU/kFreeBSD',
          'os390' => 'OS390/zOS',
          'interix' => 'Interix',
          'solaris' => 'SunOS/Solaris',
          'netbsd' => 'NetBSD',
          'macos' => 'Mac OS classic',
          'mirbsd' => 'MirOS BSD',
          'darwin' => 'Mac OS X'
        };
my $perls = [
          '5.7.3',
          '5.7.2',
          '5.7.1',
          '5.6.1',
          '5.6.0',
          '5.5.670',
          '5.5.660',
          '5.5.650',
          '5.5.640',
          '5.5.3',
          '5.5.2',
          '5.5.1',
          '5.4.4',
          '5.4.3',
          '5.4.0',
          '5.3.97',
          '5.3.0'
        ];

my $dists = [
    ['Acme-CPANAuthors-BackPAN-OneHundred']
];

my $profile1 = {
          'guid' => 'guid-test-4',
          'id' => '4',
          'addressid' => '4',
          'testerid' => '1',
          'name' => 'Barbie',
          'pause' => 'BARBIE',
          'contact' => 'barbie@cpan.org',
          'address' => 'Barbie <barbie@missbarbell.co.uk>',
          'email' => 'barbie@missbarbell.co.uk',
          'display' => 'Barbie (BARBIE)',
          'fulldate' => '201411010004'
        };
my $profile2 = {
          'testerid' => '1',
          'addressid' => '4',
          'name' => 'Barbie',
          'pause' => 'BARBIE',
          'contact' => 'barbie@cpan.org',
          'address' => 'Barbie <barbie@missbarbell.co.uk>',
          'email' => 'barbie@missbarbell.co.uk',
          'display' => 'Barbie (BARBIE)'
        };
my $profile3 = {
          'addressid' => '1',
          'testerid' => '0',
          'name' => undef,
          'pause' => undef,
          'contact' => undef,
          'address' => 'neil@bowers.com',
          'email' => 'neil@bowers.com',
          'display' => 'neil@bowers.com'
        };
my $profile4 = {
          'addressid' => '2',
          'testerid' => '2',
          'name' => 'Barbie',
          'pause' => undef,
          'contact' => 'barbie@cpantesters.org',
          'address' => 'barbie@cpantesters.org',
          'email' => 'barbie@cpantesters.org',
          'display' => 'Barbie'
        };

# -----------------------------------------------------------------------------
# Set up

my $loader = Labyrinth::Test::Harness->new( keep => 0 );
my $dir = $loader->directory;

my $cpanstats = create_database();

my $res = $loader->prep(
    sql     => [ "t/data/test-base.sql" ],
    files   => { 
        't/data/phrasebook.ini' => 'cgi-bin/config/phrasebook.ini',
        't/data/cpan-config.ini' => 'cgi-bin/config/cpan-config.ini',
        't/data/cpan-config-empty.ini' => 'cgi-bin/config/cpan-config-empty.ini'
    },
    config  => {
        'INTERNAL'  => { logclear => 0, cpan_config => $dir . '/cgi-bin/config/cpan-config.ini' },
        'CPANSTATS' => $cpanstats
    }
);
diag($loader->error)    unless($res);

SKIP: {
    skip "Unable to prep the test environment", 91  unless($res && $cpanstats);

    $res = is($loader->labyrinth(@plugins),1);
    diag($loader->error)    unless($res);

    # -------------------------------------------------------------------------
    # Public methods

    my $cpan = Labyrinth::Plugin::CPAN->new();
    isa_ok($cpan,'Labyrinth::Plugin::CPAN');

    my $dbx = $cpan->DBX('cpanstats');
    isa_ok($dbx,'Labyrinth::DBUtils');
    $dbx = $cpan->DBX();
    is($dbx,undef);
    $dbx = $cpan->DBX('unknown');
    is($dbx,undef);
    $dbx = $cpan->DBX('cpanstats');
    isa_ok($dbx,'Labyrinth::DBUtils');  # cached version
    $dbx = $cpan->DBX('cpanstats',1);
    isa_ok($dbx,'Labyrinth::DBUtils');  # fresh version
    my @rows = $dbx->GetQuery('array','GetAuthorDists','BARBIE');
    is_deeply(\@rows,$dists,'.. got matching author dists');

    $settings{cpan_config} = $dir . '/cgi-bin/config/cpan-config-empty.ini';
    $cpan->Configure();
    is_deeply($cpan->exceptions,    undef,  '.. matches exceptions');
    is_deeply($cpan->symlinks,      undef,  '.. matches symlinks');
    is_deeply($cpan->merged,        undef,  '.. matches merged');
    is_deeply($cpan->ignore,        undef,  '.. matches ignore');

    $settings{cpan_config} = '';
    $cpan->Configure();
    is_deeply($cpan->exceptions,    undef,  '.. matches exceptions');
    is_deeply($cpan->symlinks,      undef,  '.. matches symlinks');
    is_deeply($cpan->merged,        undef,  '.. matches merged');
    is_deeply($cpan->ignore,        undef,  '.. matches ignore');

    $settings{cpan_config} = $dir . '/cgi-bin/config/cpan-config.ini';
    $cpan->Configure();
    is_deeply($cpan->exceptions,    $exceptions,    '.. matches exceptions');
    is_deeply($cpan->symlinks,      $symlinks,      '.. matches symlinks');
    is_deeply($cpan->merged,        $merged,        '.. matches merged');
    is_deeply($cpan->ignore,        $ignore,        '.. matches ignore');
    is_deeply($cpan->osnames,       $osnames,       '.. matches osnames');

    is_deeply($cpan->mklist_perls,  $perls,         '.. matches perls');
    is_deeply($cpan->mklist_perls,  $perls,         '.. matches perls'); # cached version

    my @tests = (
        [ 'GNUKFREEBSD', 'Debian GNU/kFreeBSD', 'gnukfreebsd' ],
        [ 'BLAH', 'BLAH', 'blah' ],
        [ undef, undef, undef ]
    );

    for my $test (@tests) {
        my ($osname,$oscode) = $cpan->OSName($test->[0]);
        is($osname,$test->[1],'.. returns correct OS name ($test->[0])');
        is($oscode,$test->[2],'.. returns correct OS code ($test->[0])');
    }

    is( $cpan->DistIndex('Acme-CPANAuthors-BackPAN-OneHundred','1.02'), 3, '.. not on CPAN');
    is( $cpan->DistIndex('Acme-CPANAuthors-BackPAN-OneHundred','1.03'), 4, '.. on CPAN');
    is( $cpan->DistIndex('Acme-CPANAuthors-BackPAN-OneHundred','1.10'), 0, '.. not known');
    is( $cpan->DistIndex('Acme-CPANAuthors-BackPAN-OneHundred'), 0, '.. not known');

    is( $cpan->OnCPAN('Acme-CPANAuthors-BackPAN-OneHundred','1.02'), 0, '.. not on CPAN');
    is( $cpan->OnCPAN('Acme-CPANAuthors-BackPAN-OneHundred','1.03'), 1, '.. on CPAN');
    is( $cpan->OnCPAN('Acme-CPANAuthors-BackPAN-OneHundred','1.10'), 1, '.. not known, but assume its been uploaded to CPAN');
    is( $cpan->OnCPAN('Acme-CPANAuthors-BackPAN-OneHundred'), undef, '.. unknown, need a version');

    is( $cpan->check_oncpan('Acme-CPANAuthors-BackPAN-OneHundred','1.02'), 0, '.. not on CPAN');
    is( $cpan->check_oncpan('Acme-CPANAuthors-BackPAN-OneHundred','1.03'), 1, '.. on CPAN');
    is( $cpan->check_oncpan('Acme-CPANAuthors-BackPAN-OneHundred','1.10'), 1, '.. not known, but assume its been uploaded to CPAN');

    @tests = (
        [ 'Barbie <barbie@missbarbell.co.uk>', 'barbie@missbarbell.co.uk', 'Barbie', 2, 3 ],
        [ 'Example <barbie@example.com>', 'barbie@example.com', 'CPAN Tester', -1, 0 ],
        [ 'Barbie', 'admin@cpantesters.org', 'CPAN Testers Admin', -1, 0 ],
        [ undef, 'admin@cpantesters.org', 'CPAN Testers Admin', -1, 0 ],
        [ 'Barbie <barbie@missbarbell.co.uk>', 'barbie@missbarbell.co.uk', 'Barbie', 2, 3 ],    # cached version
    );

    for my $test (@tests) {
        my ($email,$name,$userid,$addressid) = $cpan->FindTester($test->[0]);
        is($email,      $test->[1], ".. email matches for FindTester (".($test->[0]||'').")");
        is($name,       $test->[2], '.. name matches for FindTester');
        is($userid,     $test->[3], '.. userid matches for FindTester');
        is($addressid,  $test->[4], '.. addressid matches for FindTester');
    }

    my $profile = $cpan->GetTesterProfile('guid-test-4');
    is_deeply($profile,$profile1);
    $profile = $cpan->GetTesterProfile('guid-test-4');
    is_deeply($profile,$profile1);  # second call should use cache
    $profile = $cpan->GetTesterProfile('guid-test-5','Barbie <barbie@missbarbell.co.uk>');
    is_deeply($profile,$profile2);  # guid not found, using tester address
    $profile = $cpan->GetTesterProfile('guid-test-6');
    is_deeply($profile,undef);      # no tester address
    $profile = $cpan->GetTesterProfile();
    is_deeply($profile,undef);      # no guid or address
    $profile = $cpan->GetTesterProfile('guid-test-7','neil@bowers.com');
    is_deeply($profile,$profile3);  # no profile
    $profile = $cpan->GetTesterProfile('guid-test-8','barbie@cpantesters.org');
    is_deeply($profile,$profile4);  # no PAUSE account

    @tests = (
        [ 'pause:BARBIE', 'BARBIE', undef, 'BARBIE' ],
        [ 'imposter:Barbie', 'BARBIE', undef, 'BARBIE' ],
        [ 'imposter:2', undef, 2, 'Barbie' ],
        [ 'imposter:Example', 'EXAMPLE', undef, 'EXAMPLE' ],
        [ 'imposter:', undef, undef, undef ],
        [ 'pause:', undef, undef, undef ]
    );

    for my $test (@tests) {
        $loader->refresh( \@plugins, { user => { name => $test->[0], author => undef, fakename => undef, test => undef } } );
        $cpan->Rename();
        is($tvars{user}{name},      $test->[0],".. Rename name '$test->[0]'");
        is($tvars{user}{author},    $test->[1],".. Rename author '$test->[0]'");
        is($tvars{user}{tester},    $test->[2],".. Rename tester '$test->[0]'");
        is($tvars{user}{fakename},  $test->[3],".. Rename fakename '$test->[0]'");
    }
}

sub create_database {
    my $td1 = Test::Database->handle( 'mysql' );
    unless($td1) {
        diag "Unable to load a test database instance.";
        return;
    }

    $loader->create_mysql_databases($td1,['t/data/test-cpanstats.sql']);

    my %opts;
    ($opts{dsn}, $opts{dbuser}, $opts{dbpass}) =  $td1->connection_info();
    ($opts{driver})    = $opts{dsn} =~ /dbi:([^;:]+)/;
    ($opts{database})  = $opts{dsn} =~ /database=([^;]+)/;
    ($opts{database})  = $opts{dsn} =~ /dbname=([^;]+)/     unless($opts{database});
    ($opts{dbhost})    = $opts{dsn} =~ /host=([^;]+)/;
    ($opts{dbport})    = $opts{dsn} =~ /port=([^;]+)/;
    my %db_config = map {my $v = $opts{$_}; defined($v) ? ("cpanstats_$_" => $v) : () }
                        qw(driver database dbfile dbhost dbport dbuser dbpass);

    $db_config{cpanstats_dictionary} = 'CPANSTATS';
    return \%db_config;
}
