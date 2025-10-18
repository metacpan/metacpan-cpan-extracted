use warnings;
use strict;
use Test::More tests => 17;
use Data::Dumper;

BEGIN { use_ok('Lemonldap::NG::Common::Conf') }

use File::Temp;
my $dir = File::Temp::tempdir( CLEANUP => 1 );
my $h;

ok(
    $h = new Lemonldap::NG::Common::Conf( {
            type    => 'File',
            dirName => $dir,
        }
    ),
    'type => file',
);
my $conf = {
    cfgNum              => 1,
    test                => '%SERVERENV:A%',
    test2               => '%SERVERENV:B% %SERVERENV:C%',
    '%SERVERENV:MYKEY%' => {
        test  => 'Test: %SERVERENV:A%',
        array => [ 'a', '%SERVERENV:B% %SERVERENV:C%', ],
    },
};

$ENV{A}     = 'Aa';
$ENV{B}     = 'Bb';
$ENV{C}     = 'Cc';
$ENV{MYKEY} = 'MyKey';

ok( $h->store($conf) == 1, "Conf is stored" )
  or print STDERR "$Lemonldap::NG::Common::Conf::msg $!";
my $cfg;
ok( $cfg = $h->getConf( { cfgNum => 1 } ), "Conf can be read" )
  or print STDERR $Lemonldap::NG::Common::Conf::msg;
ok( $cfg->{test} eq '%SERVERENV:A%',
    '%SERVERENV:A% is not substitued into Aa without useServerEnv' )
  or print STDERR "Expect $cfg->{test} eq %SERVERENV:A%\n";

ok(
    $h = new Lemonldap::NG::Common::Conf( {
            type         => 'File',
            dirName      => "t/",
            useServerEnv => 1,
        }
    ),
    'type => file',
);
ok( $h->store($conf) == 1, "Conf is stored" )
  or print STDERR "$Lemonldap::NG::Common::Conf::msg $!";

ok( $cfg = $h->getConf( { cfgNum => 1 } ), "Conf can be read" )
  or print STDERR $Lemonldap::NG::Common::Conf::msg;
ok( $cfg->{test} eq 'Aa', '%SERVERENV:A% is substitued into Aa' )
  or print STDERR "Expect $cfg->{test} eq Aa\n";
ok( $cfg->{test2} eq 'Bb Cc',
    '%SERVERENV:B% %SERVERENV:C% is substitued into Bb Cc' )
  or print STDERR "Expect $cfg->{test} eq Aa\n";

ok( ( !$cfg->{'%SERVERENV:MYKEY%'} and $cfg->{MyKey} ),
    'Keyname is transformed' );
ok( (
              $cfg->{MyKey}->{array}->[0] eq 'a'
          and $cfg->{MyKey}->{array}->[1] eq 'Bb Cc'
    ),
    'Values are substitued into arrays'
);

ok( $cfg = $h->getConf( { cfgNum => 1, raw => 1 } ), 'Get raw conf' );
ok( $cfg->{test} eq '%SERVERENV:A%',
    '%SERVERENV:A% is not substitued into Aa in raw mode' )
  or print STDERR "Expect $cfg->{test} eq %SERVERENV:A%\n";

subtest "Check useServerEnv in config file in localConf" => sub {

    my ( $fh, $filename ) =
      File::Temp::tempfile( "lemonldap-ng.ini.XXXXXX", DIR => $dir );
    print $fh <<\EOF;
[all]
useSafeJail = 1
logLevel     = notice
checkTime = 1
myA = %SERVERENV:A%

[configuration]
useServerEnv=1
type=t::TestConfBackend
accessoption=%SERVERENV:MYKEY%

EOF
    close($fh);

    my $h = Lemonldap::NG::Common::Conf->new( {
            confFile => $filename,
        }
    );
    is( $h->{accessoption}, "MyKey",
        'configuration access option correctly replaced' );
    my $localConf = $h->getLocalConf();
    {
        is( $localConf->{myA}, "Aa", 'configuration variable replaced' );
    }
};

subtest "Check useServerEnv in build option in localConf" => sub {

    my ( $fh, $filename ) =
      File::Temp::tempfile( "lemonldap-ng.ini.XXXXXX", DIR => $dir );
    print $fh <<\EOF;
[all]
useSafeJail = 1
logLevel     = notice
checkTime = 1
myA = %SERVERENV:A%

[configuration]
type=t::TestConfBackend
accessoption=%SERVERENV:MYKEY%

EOF
    close($fh);

    my $h = Lemonldap::NG::Common::Conf->new( {
            confFile     => $filename,
            useServerEnv => 1,
        }
    );
    is( $h->{accessoption}, "MyKey",
        'configuration access option correctly replaced' );
    my $localConf = $h->getLocalConf();
    {
        is( $localConf->{myA}, "Aa", 'configuration variable replaced' );
    }
};

subtest "No useServerEnv in localConf" => sub {

    my ( $fh, $filename ) =
      File::Temp::tempfile( "lemonldap-ng.ini.XXXXXX", DIR => $dir );
    print $fh <<\EOF;
[all]
useSafeJail = 1
logLevel     = notice
checkTime = 1
myA = %SERVERENV:A%

[configuration]
type=t::TestConfBackend
accessoption=%SERVERENV:MYKEY%

EOF
    close($fh);

    my $h = Lemonldap::NG::Common::Conf->new( {
            confFile => $filename,
        }
    );
    is( $h->{accessoption}, "%SERVERENV:MYKEY%",
        'configuration access option not replaced' );
    my $localConf = $h->getLocalConf();
    {
        is( $localConf->{myA}, "%SERVERENV:A%",
            'configuration variable not replaced' );
    }
};

unlink 't/lmConf-1.json';
