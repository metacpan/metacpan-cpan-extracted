use strict;
use warnings;

use Test::More;

use Data::Dumper;
use File::Basename;
use File::Spec;
use Maven::Maven;
use Maven::SettingsLoader qw(load_settings);

#use Log::Any::Adapter;
#use Log::Log4perl qw(:easy);
#Log::Log4perl->easy_init( $TRACE );
#Log::Any::Adapter->set('Log4perl');

my $test_dir = dirname( File::Spec->rel2abs($0) );
my $settings;

$settings = load_settings(
    [   File::Spec->catfile( $test_dir, 'M2_HOME', 'conf', 'settings.xml' ),
        File::Spec->catfile( $test_dir, 'HOME',    '.m2',  'settings.xml' ),
    ],
    { 'user.home' => File::Spec->catfile( $test_dir, 'HOME' ) }
);

is( $settings->get_localRepository(),
    File::Spec->catfile( $test_dir, 'HOME', '.m2', 'repository' ),
    'localRepository'
);

done_testing();
