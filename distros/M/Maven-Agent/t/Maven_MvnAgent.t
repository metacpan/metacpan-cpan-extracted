use strict;
use warnings;

use Test::More;

BEGIN { use_ok('Maven::MvnAgent') }

use Carp;
use Digest::MD5;
use File::Basename;
use File::Spec;
use File::Temp;
use Log::Any;
use Log::Any::Adapter ( 'Stdout', log_level => 'debug' );

my $logger = Log::Any->get_logger();
$logger->info('logging for Maven_MvnAgent.t');

my $test_dir = dirname( File::Spec->rel2abs($0) );

my $pastdev_url       = 'http://pastdev.com/nexus/groups/pastdev';
my $maven_central_url = 'http://repo.maven.apache.org/maven2';

sub escape_and_quote {
    my ($value) = @_;
    $value =~ s/\\/\\\\/g;
    $value =~ s/"/\\"/g;
    return "\"$value\"";
}

sub hash_file {
    my ($file) = @_;
    open( my $handle, '<', $file ) || croak("cant open $file: $!");
    binmode($handle);
    my $hash = Digest::MD5->new();
    $hash->addfile($handle);
    close($handle);
    return $hash->hexdigest();
}

sub os_path {
    my ($path) = @_;
    my $os_path =
        $^O eq 'cygwin'
        ? Cygwin::posix_to_win_path($path)
        : $path;
}

sub write_global_settings {
    my ( $path, $proxy ) = @_;

    open( my $settings, '>', $path ) || croak("cant open $path: $!");
    print( $settings "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n" );
    print( $settings "<settings xmlns=\"http://maven.apache.org/SETTINGS/1.0.0\"\n" );
    print( $settings "  xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"\n" );
    print( $settings
            "  xsi:schemaLocation=\"http://maven.apache.org/SETTINGS/1.0.0 http://maven.apache.org/xsd/settings-1.0.0.xsd\">\n"
    );
    my $proxies = Maven::MvnAgent->new()->get_maven()->get_settings()->get_proxies();
    if ($proxies) {
        print( $settings "  <proxies>\n" );
        foreach my $proxy (@$proxies) {
            next unless ( $proxy->get_active() && $proxy->get_active() =~ /^true$/i );
            my $id              = $proxy->get_id();
            my $protocol        = $proxy->get_protocol();
            my $host            = $proxy->get_host();
            my $port            = $proxy->get_port();
            my $non_proxy_hosts = $proxy->get_nonProxyHosts();
            my $username        = $proxy->get_username();
            my $password        = $proxy->get_password();

            print( $settings "    <proxy>\n" );
            print( $settings "      <id>$id</id>\n" ) if ($id);
            print( $settings "      <active>true</active>\n" );
            print( $settings "      <protocol>$protocol</protocol>\n" ) if ($protocol);
            print( $settings "      <host>$host</host>\n" )             if ($host);
            print( $settings "      <port>$port</port>\n" )             if ($port);
            print( $settings "      <nonProxyHosts>$non_proxy_hosts</nonProxyHosts>\n" )
                if ($non_proxy_hosts);
            print( $settings "      <username>$username</username>\n" ) if ($username);
            print( $settings "      <password>$port</password>\n" )     if ($password);
            print( $settings "    </proxy>\n" );
        }
        print( $settings "  </proxies>\n" );
    }
    print( $settings "  <profiles>\n" );
    print( $settings "    <profile>\n" );
    print( $settings "      <id>global</id>\n" );
    print( $settings "      <activation><activeByDefault>true</activeByDefault></activation>\n" );
    print( $settings "      <repositories>\n" );
    print( $settings "        <repository>\n" );
    print( $settings "          <id>central</id>\n" );
    print( $settings "          <url>http://repo.maven.apache.org/maven2</url>\n" );
    print( $settings "        </repository>\n" );
    print( $settings "      </repositories>\n" );
    print( $settings "    </profile>\n" );
    print( $settings "  </profiles>\n" );
    print( $settings "</settings>\n" );
    close($settings);
}

my $get_goal = 'org.apache.maven.plugins:maven-dependency-plugin:2.10:get';

{
    $logger->info("test instance mvn_options");

    my $user_home          = File::Spec->catdir( $test_dir, 'HOME' );
    my $temp_dir           = File::Temp->newdir();
    my $mvn_test_user_home = File::Spec->catdir( $temp_dir, 'HOME' );
    `cp -r $user_home $temp_dir`;
    my $mvn_test_user_settings =
        File::Spec->catfile( $mvn_test_user_home, '.m2', 'settings.xml' );
    my $mvn_test_m2_home = File::Spec->catdir( $temp_dir, 'M2_HOME' );
    mkdir($mvn_test_m2_home);
    mkdir( File::Spec->catdir( $mvn_test_m2_home, 'conf' ) );
    my $mvn_test_global_settings =
        File::Spec->catfile( $mvn_test_m2_home, 'conf', 'settings.xml' );
    `mv $mvn_test_user_home/.m2/empty_settings.xml $mvn_test_user_settings`;
    write_global_settings( $mvn_test_global_settings, {} );

    my $command;
    my $agent = Maven::MvnAgent->new(
        M2_HOME        => $mvn_test_m2_home,
        'user.home'    => $mvn_test_user_home,
        command_runner => sub { ($command) = @_ },
        mvn_options => { '-Dfoo' => 'bar' }
    );
    is( $agent->get_command('com.pastdev:foo:pom:1.0.1'),
        "mvn --global-settings "
            . escape_and_quote( os_path($mvn_test_global_settings) )
            . " --settings "
            . escape_and_quote( os_path($mvn_test_user_settings) )
            . " -Dfoo=\"bar\" -Duser.home="
            . escape_and_quote( os_path($mvn_test_user_home) )
            . " $get_goal -DartifactId=\"foo\" -DgroupId=\"com.pastdev\""
            . " -Dpackaging=\"pom\" -DremoteRepositories=\"$maven_central_url\" -Dversion=\"1.0.1\"",
        'instance mvn_options foo'
    );
}

{
    $logger->info("test custom command_runner");

    my $user_home          = File::Spec->catdir( $test_dir, 'HOME' );
    my $temp_dir           = File::Temp->newdir();
    my $mvn_test_user_home = File::Spec->catdir( $temp_dir, 'HOME' );
    `cp -r $user_home $temp_dir`;
    my $mvn_test_user_settings =
        File::Spec->catfile( $mvn_test_user_home, '.m2', 'settings.xml' );
    my $mvn_test_m2_home = File::Spec->catdir( $temp_dir, 'M2_HOME' );
    mkdir($mvn_test_m2_home);
    mkdir( File::Spec->catdir( $mvn_test_m2_home, 'conf' ) );
    my $mvn_test_global_settings =
        File::Spec->catfile( $mvn_test_m2_home, 'conf', 'settings.xml' );
    `mv $mvn_test_user_home/.m2/empty_settings.xml $mvn_test_user_settings`;
    write_global_settings( $mvn_test_global_settings, {} );

    my $command;
    my $agent = Maven::MvnAgent->new(
        M2_HOME        => $mvn_test_m2_home,
        'user.home'    => $mvn_test_user_home,
        command_runner => sub { ($command) = @_ }
    );
    $agent->get('com.pastdev:foo:pom:1.0.1');
    is( $command,
        "mvn --global-settings "
            . escape_and_quote( os_path($mvn_test_global_settings) )
            . " --settings "
            . escape_and_quote( os_path($mvn_test_user_settings) )
            . " -Duser.home="
            . escape_and_quote( os_path($mvn_test_user_home) )
            . " $get_goal -DartifactId=\"foo\" -DgroupId=\"com.pastdev\""
            . " -Dpackaging=\"pom\" -DremoteRepositories=\"$maven_central_url\" -Dversion=\"1.0.1\"",
        'command_runner get foo'
    );
}

SKIP: {
    skip( "not cygwin", 4 ) if ( $^O ne 'cygwin' );

    my $user_home          = File::Spec->catdir( $test_dir, 'HOME' );
    my $temp_dir           = File::Temp->newdir();
    my $mvn_test_user_home = File::Spec->catdir( $temp_dir, 'HOME' );
    `cp -r $user_home $temp_dir`;
    my $mvn_test_user_settings =
        File::Spec->catfile( $mvn_test_user_home, '.m2', 'settings.xml' );
    `mv $mvn_test_user_home/.m2/empty_settings.xml $mvn_test_user_settings`;
    ok( ( -f $mvn_test_user_settings ), "cygwin temp .m2/settings.xml exists" );

    my $m2_home     = $ENV{M2_HOME};
    my $userprofile = $ENV{USERPROFILE};
    eval {
        $ENV{M2_HOME} = os_path( File::Spec->catdir( $test_dir, 'M2_HOME' ) );
        $ENV{USERPROFILE} = os_path($mvn_test_user_home);
        my $mvn_test_global_settings =
            File::Spec->catfile( $ENV{M2_HOME}, 'conf', 'settings.xml' );
        my $agent = Maven::MvnAgent->new();
        is( $agent->get_maven()->dot_m2('settings.xml'),
            $mvn_test_user_settings, 'cygwin agent user settings' );

        my $mvn_test_user_home_link = File::Spec->catdir( $temp_dir, 'LINK_HOME' );
        `ln -s $mvn_test_user_home $mvn_test_user_home_link`;
        $agent = Maven::MvnAgent->new( 'user.home' => $mvn_test_user_home_link );
        is( $agent->get_maven()->dot_m2('settings.xml'),
            File::Spec->catfile( $mvn_test_user_home_link, '.m2', 'settings.xml' ),
            'cygwin link agent user settings'
        );
        is( $agent->get_command('javax.servlet:servlet-api:2.5'),
            "mvn --global-settings "
                . escape_and_quote( os_path($mvn_test_global_settings) )
                . " --settings "
                . escape_and_quote( os_path($mvn_test_user_settings) )
                . " -Duser.home="
                . escape_and_quote( os_path($mvn_test_user_home) )
                . " $get_goal -DartifactId=\"servlet-api\" -DgroupId=\"javax.servlet\""
                . " -Dpackaging=\"jar\" -DremoteRepositories=\"$maven_central_url\" -Dversion=\"2.5\"",
            'cygwin get servlet-api command'
        );
    };
    my $error = $@;
    $ENV{M2_HOME}     = $m2_home;
    $ENV{USERPROFILE} = $userprofile;
    die($@) if ($@);
}

SKIP: {
    eval { require LWP::UserAgent };

    #skip("disabled mvn tests", 9) if 1;
    skip( "LWP::UserAgent not installed", 9 ) if $@;

    my $user_home          = File::Spec->catdir( $test_dir, 'HOME' );
    my $temp_dir           = File::Temp->newdir();
    my $mvn_test_user_home = File::Spec->catdir( $temp_dir, 'HOME' );
    `cp -r $user_home $temp_dir`;
    my $mvn_test_user_settings =
        File::Spec->catfile( $mvn_test_user_home, '.m2', 'settings.xml' );
    my $mvn_test_m2_home = File::Spec->catdir( $temp_dir, 'M2_HOME' );
    mkdir($mvn_test_m2_home);
    mkdir( File::Spec->catdir( $mvn_test_m2_home, 'conf' ) );
    my $mvn_test_global_settings =
        File::Spec->catfile( $mvn_test_m2_home, 'conf', 'settings.xml' );
    `mv $mvn_test_user_home/.m2/empty_settings.xml $mvn_test_user_settings`;
    write_global_settings( $mvn_test_global_settings, {} );
    ok( ( -f $mvn_test_user_settings ), "mvn test $mvn_test_user_home/.m2/settings.xml exists" );

    my $agent = Maven::MvnAgent->new(
        M2_HOME     => $mvn_test_m2_home,
        'user.home' => $mvn_test_user_home
    );
    is( $agent->get_maven()->dot_m2('settings.xml'), $mvn_test_user_settings, 'user settings' );
    is( $agent->get_maven()->m2_home( 'conf', 'settings.xml' ),
        $mvn_test_global_settings, 'global settings' );
    is( $agent->get_command('javax.servlet:servlet-api:2.5'),
        "mvn --global-settings "
            . escape_and_quote( os_path($mvn_test_global_settings) )
            . " --settings "
            . escape_and_quote( os_path($mvn_test_user_settings) )
            . " -Duser.home="
            . escape_and_quote( os_path($mvn_test_user_home) )
            . " $get_goal -DartifactId=\"servlet-api\" -DgroupId=\"javax.servlet\""
            . " -Dpackaging=\"jar\" -DremoteRepositories=\"$maven_central_url\" -Dversion=\"2.5\"",
        'get servlet-api command'
    );

    if ( $agent->get_maven()->_default_agent( timeout => 1 )->head($maven_central_url)
        ->is_success() )
    {
        my $jta_jar = $agent->resolve('javax.transaction:jta:1.1');
        ok( $jta_jar, 'resolve jta jar' );

    SKIP: {
            skip "mvn not installed", 5 if ( system('which mvn > /dev/null 2>&1') >> 8 );
            $logger->warn("first mvn call, be patient, lots of downloads");

            my $jta_jar_file;
            eval { $jta_jar_file = $agent->download($jta_jar); };
            skip( "mvn failed: $@", 5 ) if ($@);

            ok( $jta_jar_file,    'got jta jar file' );
            ok( -s $jta_jar_file, 'jta jar file is not empty' );

            my $jta_jar_file_to = $agent->download( $jta_jar, to => File::Temp->new() );
            ok( $jta_jar_file_to,    'got jta jar to file to' );
            ok( -s $jta_jar_file_to, 'jta jar file to is not empty' );

            is( hash_file($jta_jar_file), hash_file($jta_jar_file_to), 'jta hashes match' );
        }
    }
}

done_testing();
