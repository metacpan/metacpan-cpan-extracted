use strict;
use warnings;

use Test::More;

BEGIN { use_ok('Maven::Xml::Pom') }

use Data::Dumper;
use File::Basename;
use File::Spec;

my $test_dir = dirname( File::Spec->rel2abs($0) );
my $pom;

$pom = Maven::Xml::Pom->new( file => File::Spec->catfile( $test_dir, 'pom_for_parser.xml' ) );
my $pom_for_parser_expected = {
    modelVersion => '4.0.0',
    parent       => {
        groupId      => 'com.pastdev',
        artifactId   => 'parent',
        version      => '1.0.0',
        relativePath => '../parent-parent'
    },
    groupId      => 'com.pastdev',
    artifactId   => 'my-project',
    version      => '1.0.0',
    packaging    => 'jar',
    dependencies => {
        'com.pastdev:dependency:jar:assembly' => {
            groupId    => 'com.pastdev',
            artifactId => 'dependency',
            version    => '1.0.0',
            classifier => 'assembly',
            type       => 'jar',
            scope      => 'compile',
            systemPath => '${java.home}/lib',
            optional   => 'true',
            exclusions => [
                {   groupId    => 'com.pastdev',
                    artifactId => 'exclude-me'
                }
            ]
        }
    },
    modules    => [ 'module-one' ],
    properties => { key => 'value' },
    build      => {
        defaultGoal => 'install',
        directory   => '${basedir}/target',
        finalName   => '${artifactId}-${version}',
        filters     => [ 'filters/filter1.properties' ],
        resources   => [
            {   targetPath => 'META-INF/main',
                filtering  => 'false',
                directory  => '${basedir}/src/main/main',
                includes   => [ 'configuration.xml' ],
                excludes   => [ '**/*.properties' ]
            }
        ],
        testResources => [
            {   targetPath => 'META-INF/test',
                filtering  => 'false',
                directory  => '${basedir}/src/test/test',
                includes   => [ 'test_configuration.xml' ],
                excludes   => [ '**/*test.properties' ]
            }
        ],
        plugins => {
            'com.pastdev.plugins:build-plugin' => {
                groupId       => 'com.pastdev.plugins',
                artifactId    => 'build-plugin',
                version       => '2.0',
                extensions    => 'false',
                inherited     => 'true',
                configuration => { classifier => 'test' },
                dependencies  => {
                    'com.pastdev:plugin-dep:jar:' => {
                        groupId    => 'com.pastdev',
                        artifactId => 'plugin-dep',
                        version    => '1.0.0'
                    }
                },
                executions => [
                    {   id            => 'foo',
                        goals         => [ 'run' ],
                        phase         => 'verify',
                        inherited     => 'false',
                        configuration => { tasks => { echo => 'Foo you' } }
                    }
                ]
            }
        },
        pluginManagement => {
            plugins => {
                'com.pastdev.plugins:build-plugin' => {
                    groupId    => 'com.pastdev.plugins',
                    artifactId => 'build-plugin',
                    version    => '2.1'
                }
            }
        },
        sourceDirectory       => '${basedir}/src/main/java',
        scriptSourceDirectory => '${basedir}/src/main/scripts',
        testSourceDirectory   => '${basedir}/src/test/java',
        outputDirectory       => '${basedir}/target/classes',
        testOutputDirectory   => '${basedir}/target/test-classes',
        extensions            => [
            {   groupId    => 'com.pastdev',
                artifactId => 'build-extension',
                version    => '1.0.0'
            }
        ]
    },
    reporting => {
        outputDirectory => '${basedir}/target/site',
        plugins         => [
            {   artifactId => 'reporting-plugin',
                version    => '2.0.0',
                reportSets => [
                    {   id        => 'reportSet1',
                        reports   => [ 'javadoc' ],
                        inherited => 'true',
                        configuration =>
                            { links => { 'link' => 'http://java.sun.com/j2se/1.5.0/docs/api/' } }
                    }
                ]
            }
        ]
    },
    name          => 'project name',
    description   => 'project description',
    url           => 'project url',
    inceptionYear => '2014',
    licenses      => [
        {   name         => 'Artistic License 2.0',
            url          => 'http://www.perlfoundation.org/artistic_license_2_0',
            distribution => 'repo',
            comments     => 'Basic perl license',
        }
    ],
    organization => {
        name => 'Pastdev',
        url  => 'http://pastdev.com'
    },
    developers => [
        {   id              => 'lucastheisen',
            name            => 'Lucas',
            email           => 'dontuse@lucastheisen.com',
            url             => 'https://github.com/lucastheisen',
            organization    => 'Pastdev',
            organizationUrl => 'http://pastdev.com',
            roles           => [ 'architect', 'developer' ],
            timezone        => '-6',
            properties      => {
                picUrl => 'http://www.gravatar.com/avatar/c292b959ecf29c86e4c0d093a6f24e19.png'
            }
        }
    ],
    contributors => [
        {   name            => 'Contributor',
            email           => 'dontuse@contributor.com',
            url             => 'http://contributor.com',
            organization    => 'Contributor Organization',
            organizationUrl => 'http://contributor.org',
            roles           => [ 'tester' ],
            timezone        => 'America/Vancouver',
            properties      => { gtalk => 'contributor@gmail.com' }
        }
    ],
    issueManagement => {
        system => 'Github',
        url    => 'https://github.com/dashboard/issues'
    },
    ciManagement => {
        system    => 'jenkins',
        url       => 'http://127.0.0.1:8080/jenkins',
        notifiers => [
            {   type          => 'mail',
                sendOnError   => 'true',
                sendOnFailure => 'true',
                sendOnSuccess => 'false',
                sendOnWarning => 'false',
                configuration => { address => 'jenkins@127.0.0.1' }
            }
        ]
    },
    mailingLists => [
        {   name          => 'User List',
            subscribe     => 'user-subscribe@127.0.0.1',
            unsubscribe   => 'user-unsubscribe@127.0.0.1',
            post          => 'user@127.0.0.1',
            archive       => 'http://127.0.0.1/user/',
            otherArchives => [ 'http://base.google.com/base/1/127.0.0.1' ]
        }
    ],
    scm => {
        connection          => 'scm:git:https://github.com/lucastheisen/perl-maven.git',
        developerConnection => 'scm:git:git@github.com:lucastheisen/perl-maven.git',
        tag                 => 'HEAD',
        url                 => 'http://127.0.0.1/websvn/my-project',
    },
    prerequisites => { maven => '2.0.6' },
    repositories  => [
        {   releases => {
                enabled        => 'false',
                updatePolicy   => 'always',
                checksumPolicy => 'warn'
            },
            snapshots => {
                enabled        => 'true',
                updatePolicy   => 'never',
                checksumPolicy => 'fail'
            },
            id     => 'pastdev',
            name   => 'Pastdev',
            url    => 'http://pastdev.com/maven2',
            layout => 'default'
        }
    ],
    pluginRepositories => [
        {   releases => {
                enabled        => 'false',
                updatePolicy   => 'always',
                checksumPolicy => 'warn'
            },
            snapshots => {
                enabled        => 'true',
                updatePolicy   => 'never',
                checksumPolicy => 'fail'
            },
            id     => 'pastdev-plugins',
            name   => 'Pastdev Plugins',
            url    => 'http://pastdev.com/plugins/maven2',
            layout => 'default'
        }
    ],
    distributionManagement => {
        repository => {
            uniqueVersion => 'false',
            id            => 'pastdev',
            name          => 'Pastdev Repository',
            url           => 'scp://repo/maven2',
            layout        => 'default'
        },
        snapshotRepository => {
            uniqueVersion => 'true',
            id            => 'pastdev',
            name          => 'Pastdev Snapshots',
            url           => 'sftp://pastdev.com/maven',
            layout        => 'legacy'
        },
        site => {
            id   => 'website',
            name => 'Website',
            url  => 'http://pastdev.com/public_html/'
        },
        relocation => {
            groupId    => 'com.pastdev',
            artifactId => 'my-new-project',
            version    => '1.0',
            message    => 'We have moved the project',
        },
        downloadUrl => 'http://pastdev.com/my-project',
        status      => 'deployed',
    },
    profiles => [
        {   id                     => 'test',
            activation             => undef,
            build                  => undef,
            reporting              => undef,
            dependencyManagement   => undef,
            distributionManagement => undef
        }
    ]
};

is_deeply( $pom, $pom_for_parser_expected, 'pom_for_parser' );

done_testing();
