use Test::More;
use Test::Output;
use File::Path;
use File::Temp;
use JSON;

BEGIN {
    use_ok 'Lemonldap::NG::Common::Conf';
}

SKIP: {
    eval {
        require Lemonldap::NG::Common::Cli;
        require Lemonldap::NG::Manager::Cli;
        require Lemonldap::NG::Manager::Conf::Zero;
    };
    skip "Manager not available", 1 if $@;

    my $conf;
    my $dir = File::Temp::tempdir( CLEANUP => 1 );
    ok( $conf = &Lemonldap::NG::Manager::Conf::Zero::zeroConf(),
        'Build new conf' );
    $conf->{cfgNum} = 1;
    my $confAcc = new Lemonldap::NG::Common::Conf( {
            type    => 'File',
            dirName => $dir,
        }
    );
    ok( $confAcc->store($conf) == 1, "Conf is stored" );

    open my $f, '>', "$dir/lemonldap-ng.ini" or die $!;
    my $ini = <<"EOF";
[ all ]
logLevel = debug

[ configuration ]
type = File
dirName = $dir

[ manager ]
enabledModules = conf
templateDir = $dir
EOF
    print $f $ini;
    close $f;

    sub runTest {
        my $type = shift;
        my $name = shift;
        my $test = shift;
        my @ARGS = @_;

        #Lemonldap::NG::Manager::Cli->new(
        #{ iniFile => "$dir/lemonldap-ng.ini" } )->run(@ARGS);
        my ($str) = Test::Output::output_from(
            sub {
                $type eq 'manager'
                  ? Lemonldap::NG::Manager::Cli->new(
                    { iniFile => "$dir/lemonldap-ng.ini" } )->run(@ARGS)
                  : Lemonldap::NG::Common::Cli->new(
                    { iniFile => "$dir/lemonldap-ng.ini" } )->run(@ARGS);
            }
        );
        chomp $str;
        my $json;
        ok( $json = eval { JSON::from_json("[$str]")->[0] }, 'Valid JSON response' )
          or diag($@);
        $test->($json);
        ok( $test->($json), "$name result matches" ) or diag "$str";
    }

    subtest 'Conf: simple string', sub {
        runTest( 'manager', 'portal',
            sub { $_[0] eq 'http://auth.example.com/' },
            'get', 'portal', '-json', );
    };
    subtest 'Conf: hash ref', sub {
        runTest(
            'manager',
            'globalStorageOptions',
            sub { $_[0]->{Directory} eq '/var/lib/lemonldap-ng/sessions' },
            '--json',
            'get',
            'globalStorageOptions'
        );
    };
    subtest 'Conf: metadata', sub {
        runTest(
            'common', 'info',
            sub {
                $_[0]->{author} eq 'The LemonLDAP::NG team';
            },    #qr#"author"\s*:\s*"The LemonLDAP::NG team"#,
            'info',
            '-json'
        );
    };
}

done_testing();
