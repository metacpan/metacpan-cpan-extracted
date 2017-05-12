use strict;
use warnings;

use Test::More;

BEGIN { use_ok('Maven::Command') }

use Maven::Artifact;

is( Maven::Command::mvn_command('commit'), 'mvn commit', 'commit' );

is( Maven::Command::mvn_command(
        'dependency:get',
        {   groupId    => 'javax.servlet',
            artifactId => 'servlet-api',
            version    => '2.5'
        }
    ),
    'mvn dependency:get -DartifactId="servlet-api" -DgroupId="javax.servlet" -Dversion="2.5"',
    'dependency:get'
);

is( Maven::Command::mvn_command( { '-X' => undef }, 'test' ), 'mvn -X test', 'debug test' );

is( Maven::Command::mvn_command(
        {   '-X'         => undef,
            '--settings' => '/home/me/test/.m2/settings.xml'
        },
        'dependency:get',
        {   groupId    => 'javax.servlet',
            artifactId => 'servlet-api',
            version    => '2.5'
        }
    ),
    'mvn --settings "/home/me/test/.m2/settings.xml" -X dependency:get -DartifactId="servlet-api" -DgroupId="javax.servlet" -Dversion="2.5"',
    'debug test settings dependency get'
);

is( Maven::Command::mvn_command(
        {   '-X'         => undef,
            '--settings' => '/home/me/test/.m2/settings.xml'
        },
        'dependency:get',
        {   Maven::Command::mvn_artifact_params(
                Maven::Artifact->new('javax.servlet:servlet-api:2.5')
            )
        }
    ),
    'mvn --settings "/home/me/test/.m2/settings.xml" -X dependency:get -DartifactId="servlet-api" -DgroupId="javax.servlet" -Dpackaging="jar" -Dversion="2.5"',
    'debug test settings dependency get artifact'
);

done_testing();
