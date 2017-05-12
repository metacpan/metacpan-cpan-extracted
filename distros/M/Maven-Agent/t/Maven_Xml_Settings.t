use strict;
use warnings;

use Test::More;

BEGIN { use_ok('Maven::Xml::Settings') }

use Data::Dumper;
use File::Basename;
use File::Spec;

my $test_dir = dirname( File::Spec->rel2abs($0) );
my $settings;

$settings =
    Maven::Xml::Settings->new(
    file => File::Spec->catfile( $test_dir, 'settings_for_parser.xml' ) );
my $settings_for_parser_expected = {
    localRepository   => '${user.home}/.m2/repository',
    interactiveMode   => 'true',
    usePluginRegistry => 'false',
    offline           => 'false',
    proxies           => [
        {   active        => 'true',
            protocol      => 'http',
            username      => 'proxy_user',
            password      => 'proxy_pass',
            port          => '8080',
            host          => 'proxy_host',
            nonProxyHosts => 'non_proxy_1|non_proxy_2',
            id            => 'default_proxy'
        }
    ],
    servers => [
        {   username             => 'server_user',
            password             => 'server_pass',
            privateKey           => 'server_priv_key',
            passphrase           => 'server_priv_key_passphrase',
            filePermissions      => '0660',
            directoryPermissions => '0770',
            configuration        => {
                a => 'b',
                c => {
                    d => 'e',
                    f => 'g'
                }
            },
            id => 'default_server'
        }
    ],
    mirrors => [
        {   mirrorOf        => 'central',
            name            => 'central_mirror',
            url             => 'http://central.maven.org/maven2',
            layout          => 'default',
            mirrorOfLayouts => 'default',
            id              => 'default_mirror',
        }
    ],
    profiles => [
        {   activation => {
                activeByDefault => 'false',
                jdk             => '1.7',
                os              => {
                    name    => 'os_name',
                    family  => 'os_family',
                    arch    => 'os_arch',
                    version => 'os_version',
                },
                property => {
                    name  => 'property_name',
                    value => 'property_value'
                },
                file => {
                    missing  => 'missing_file',
                    'exists' => 'exists_file'
                }
            },
            properties   => { key => 'value' },
            repositories => [
                {   releases => {
                        enabled        => 'true',
                        updatePolicy   => 'always',
                        checksumPolicy => 'fail'
                    },
                    snapshots => {
                        enabled        => 'true',
                        updatePolicy   => 'daily',
                        checksumPolicy => 'warn'
                    },
                    id     => 'repository_id',
                    name   => 'repository_name',
                    url    => 'repository_url',
                    layout => 'default'
                }
            ],
            pluginRepositories => [
                {   releases => {
                        enabled        => 'true',
                        updatePolicy   => 'always',
                        checksumPolicy => 'fail'
                    },
                    snapshots => {
                        enabled        => 'true',
                        updatePolicy   => 'daily',
                        checksumPolicy => 'warn'
                    },
                    id     => 'repository_id',
                    name   => 'repository_name',
                    url    => 'repository_url',
                    layout => 'default'
                }
            ],
            id => 'profile_id'
        }
    ],
    activeProfiles => [ 'profile_id' ],
    pluginGroups   => [ 'com.pastdev.plugins' ]
};

is_deeply( $settings, $settings_for_parser_expected, 'settings_for_parser' );

done_testing();
