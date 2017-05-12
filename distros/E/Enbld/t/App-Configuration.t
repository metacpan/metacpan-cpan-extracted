#!perl

use strict;
use warnings;

use File::Temp;
use File::Spec;
use Test::More;

require_ok( 'Enbld::App::Configuration' );

require Enbld::Feature;
require Enbld::Home;
require Enbld::Config;

subtest 'envname' => sub {
    Enbld::App::Configuration->set_envname( 'myenv' );
    my $envname = Enbld::App::Configuration->envname;
    is( $envname, 'myenv', 'env name' );

    Enbld::App::Configuration->destroy;
};

subtest 'no write configuration file' => sub {
    local $ENV{HOME} = File::Temp->newdir;

    Enbld::Home->initialize;

    my $conf = File::Spec->catfile( Enbld::Home->conf, 'Enbld.conf' );

    Enbld::App::Configuration->write_file;

    ok( ! -e $conf, 'not write configuration file - not dirty' );

    Enbld::Feature->initialize( deploy => File::Temp->newdir );

    my $config = Enbld::Config->new( name => 'app' );
    Enbld::App::Configuration->set_config( $config );

    Enbld::App::Configuration->write_file;

    ok( ! -e $conf, 'not write configuration file - deploy mode' );
};

subtest 'write and read config to configuration file' => sub {
    local $ENV{HOME} = File::Temp->newdir;

    Enbld::Home->initialize;
    Enbld::Feature->initialize;

    is( Enbld::App::Configuration->read_file, undef, 'no read' );

    require Enbld::Condition;
    my $condition = Enbld::Condition->new( name => 'app', version => '1.0' );
    my $config = Enbld::Config->new( name =>  'app' );
    $config->set_enabled( '1.0', $condition );

    Enbld::App::Configuration->set_config( $config );

    Enbld::App::Configuration->write_file;

    my $conf = File::Spec->catfile( Enbld::Home->conf, 'enbld.conf' );
    ok( -e $conf, 'write configuration file' );
    my $dummy = Enbld::Config->new( name =>  'app', enabled  =>  '1.1' );
    Enbld::App::Configuration->set_config( $dummy );

    Enbld::App::Configuration->destroy;

    Enbld::App::Configuration->read_file;
    my $read_config = Enbld::App::Configuration->search_config( 'app' );

    is( $read_config->name, 'app', 'read configure - name' );
    is( $read_config->enabled, '1.0', 'read configure - enabled' );

    Enbld::App::Configuration->destroy;
};

subtest 'collection for config' => sub {
    subtest 'method success' => sub {
        require Enbld::Condition;
        my $condition = Enbld::Condition->new( name => 'app' );
        my $config = Enbld::Config->new( name => 'app' );
        $config->set_enabled( '1.0', $condition );
        Enbld::App::Configuration->set_config( $config );

        my $searched = Enbld::App::Configuration->search_config( 'app' );
        
        is( $searched->name, 'app', 'got name' );
        is( $searched->enabled, '1.0', 'got enabled' );

        my $ref = Enbld::App::Configuration->config;
        ok( exists $ref->{app}, 'config method' );

        Enbld::App::Configuration->destroy;
    };

    subtest 'no config' => sub {
        my $config = Enbld::App::Configuration->search_config( 'dummy' );
        is( $config, undef, 'no config' );

        Enbld::App::Configuration->destroy;
    };
};


require Enbld::RcFile;

subtest 'write and read rcfile to configuration file' => sub {
    local $ENV{HOME} = File::Temp->newdir;

    require Enbld::Home;
    Enbld::Home->initialize;

    is( Enbld::App::Configuration->read_file, undef, 'no read' );

    my $rcfile = Enbld::RcFile->new(
            filepath    => '.Enbldrc',
            contents    => 'content',
            command     => 'set',
            );

    $rcfile->do;

    Enbld::App::Configuration->set_rcfile( $rcfile );
    Enbld::App::Configuration->write_file;

    Enbld::App::Configuration->destroy;

    Enbld::App::Configuration->read_file;
    my $read = Enbld::App::Configuration->search_rcfile( '.Enbldrc' );

    is( $read->filename, '.Enbldrc', 'read rcfile - filename' );

    Enbld::App::Configuration->destroy;
};

subtest 'collection for rcfile method' => sub {
    subtest 'method success' => sub {

        my $rcfile = Enbld::RcFile->new(
                filepath    => '.Enbldrc',
                contents    => 'content',
                command     => 'set',
                );

        $rcfile->do;

        Enbld::App::Configuration->set_rcfile( $rcfile );

        my $searched = Enbld::App::Configuration->search_rcfile(
                '.Enbldrc'
                );
        
        is( $searched->filename, '.Enbldrc', 'got filename' );

        my $ref = Enbld::App::Configuration->rcfile;
        ok( exists $ref->{'.Enbldrc'}, 'rcfile method' );

        Enbld::App::Configuration->destroy;
    };

    subtest 'no config' => sub {
        my $rcfile = Enbld::App::Configuration->search_rcfile( 'dummy' );
        is( $rcfile, undef, 'no rcfile' );

        Enbld::App::Configuration->destroy;
    };
};

done_testing();
