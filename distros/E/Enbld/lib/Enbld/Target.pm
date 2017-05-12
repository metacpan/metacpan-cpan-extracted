package Enbld::Target;

use strict;
use warnings;

use Carp;

use version;

use File::Spec;
use File::Path qw/make_path remove_tree/;
use File::Find;
use File::Copy::Recursive qw/rcopy/;
use autodie;
use List::Util qw/first/;

require Enbld::Definition;
require Enbld::Feature;
require Enbld::Condition;
require Enbld::Message;
require Enbld::Home;
require Enbld::HTTP;
require Enbld::Target::Symlink;
require Enbld::Error;
require Enbld::Deployed;

sub new {
    my ( $class, $name, $config ) = @_;

    my $self = {
        name       =>  $name,
        config     =>  $config,
        attributes =>  undef,
        build      =>  undef,
        install    =>  undef,
        PATH       =>  undef,
        conditions =>  undef,
    };

    bless $self, $class;

    $self->_set_config;
    $self->_set_attributes;
    $self->_set_PATH;

    return $self;
}

sub install {
    my $self = shift;
    my $version = shift;
    
    if ( ! $self->_is_install_ok ) {
        Enbld::Error->throw( "'$self->{name}' is already installed." );
    }

    my $condition = $version ? Enbld::Condition->new( version => $version ) :
        Enbld::Condition->new;

    $self->{attributes}->add( 'VersionCondition', $condition->version );

    $self->_build( $condition );

    return $self->{config};
}

sub _is_install_ok {
    my $self = shift;

    return 1 if Enbld::Feature->is_force_install;
    return if $self->is_installed;
    return 1;
}

sub deploy {
    my $self = shift;

    my $condition = Enbld::Condition->new;

    $self->{attributes}->add( 'VersionCondition', $condition->version );

    $self->_build_to_deploy( $condition );

    return $self->{config};
}

sub install_declared {
    my ( $self, $declared_conditions ) = @_;

    $self->{attributes}->add(
            'VersionCondition',
            $declared_conditions->{$self->{name}}{version}
            );

    return unless $self->_is_install_declared_ok(
            $declared_conditions->{$self->{name}}
            );

    $self->{conditions} = $declared_conditions;

    $self->_build( $declared_conditions->{$self->{name}} );

    return $self->{config};
}

sub deploy_declared {
    my ( $self, $declared_conditions ) = @_;

    $self->{attributes}->add(
            'VersionCondition',
            $declared_conditions->{$self->{name}}{version}
            );

    $self->{conditions} = $declared_conditions;

    $self->_build_to_deploy( $declared_conditions->{$self->{name}} );

    return $self->{config};
}

sub _is_install_declared_ok {
    my ( $self, $condition ) = @_;

    return 1 if Enbld::Feature->is_force_install;
    return 1 unless $self->{config}->enabled;
    return 1 unless $condition->is_equal_to( $self->{config}->condition );
    return if $self->{config}->enabled eq $self->{attributes}->Version;

    return 1;
}

sub upgrade {
    my $self = shift;

    if ( ! $self->is_installed ) {
        Enbld::Error->throw( "'$self->{name}' is not installed yet." );
    }

    $self->{attributes}->add(
            'VersionCondition',
            $self->{config}->condition->version
            );

    my $current = $self->{attributes}->Version;
    my $enabled = $self->{config}->enabled;

    my $VersionList = $self->{attributes}->SortedVersionList;

    my $index_current =
        first { ${ $VersionList }[$_] eq $current } 0..$#{ $VersionList };

    my $index_enabled =
        first { ${ $VersionList }[$_] eq $enabled } 0..$#{ $VersionList };

    if ( $index_current <= $index_enabled ) {
        Enbld::Error->throw( "'$self->{name}' is up to date." );
    }

    $self->_build( $self->{config}->condition );

    return $self->{config};
}

sub off {
    my $self = shift;

    if ( ! $self->is_installed ) {
        Enbld::Error->throw( "'$self->{name}' is not installed yet." );
    }

    $self->_drop;

    $self->{config}->drop_enabled;

    return $self->{config};
}

sub rehash {
    my $self = shift;

    if ( ! $self->is_installed ) {
        Enbld::Error->throw( "'$self->{name}' isn't installed yet." );
    }

    $self->_switch( $self->{config}->enabled );

    return $self->{config};
}

sub use {
    my ( $self, $version ) = @_;

    if ( ! $self->{config}->installed ) {
        Enbld::Error->throw( "'$self->{name}' isn't installed yet." );
    }

    my $form = $self->{attributes}->VersionForm;
    if ( $version !~ /^$form$/ ) {
        Enbld::Error->throw( "'$version' is not valid version form." );
    }

    if ( $self->{config}->enabled && $self->{config}->enabled eq $version ) {
        Enbld::Error->throw( "'$version' is current enabled version." );
    }

    if ( ! $self->{config}->is_installed_version( $version ) ) {
        Enbld::Error->throw( "'$version' isn't installed yet" );
    }

    $self->_switch( $version );

    return $self->{config};
}

sub is_installed {
    my $self = shift;

    return $self->{config}->enabled;
}

sub is_outdated {
    my $self = shift;

    return unless ( $self->{config}->enabled );

    $self->{attributes}->add(
            'VersionCondition', $self->{config}->condition->version
            );

    my $current = $self->{attributes}->Version;
    my $enabled = $self->{config}->enabled;

    my $VersionList = $self->{attributes}->SortedVersionList;

    my $index_current =
        first { ${ $VersionList }[$_] eq $current } 0..$#{ $VersionList };

    my $index_enabled =
        first { ${ $VersionList }[$_] eq $enabled } 0..$#{ $VersionList };

    if ( $index_current > $index_enabled ) {
        return $current;
    }

    return;
}

sub _set_config {
    my $self = shift;

    if ( ! $self->{config} ) {
        require Enbld::Config;
        $self->{config} = Enbld::Config->new( name => $self->{name} );
    }
}

sub _set_attributes {
    my $self = shift;

    $self->{attributes} = Enbld::Definition->new( $self->{name} )->parse;
}

sub _set_PATH {
    my $self = shift;

    my $path = File::Spec->catdir( Enbld::Home->install_path, 'bin' );

    $self->{PATH} = $path . ':' . $ENV{PATH};
}

sub _switch {
    my ( $self, $version ) = @_;

    my $path = File::Spec->catdir(
            Enbld::Home->depository,
            $self->{attributes}->DistName
            );

    my $new = File::Spec->catdir( $path, $version );

    Enbld::Target::Symlink->delete_symlink( $path );
    Enbld::Target::Symlink->create_symlink( $new );

    $self->{config}->set_enabled(
            $version,
            $self->{config}->condition( $version ),
            );
}

sub _drop {
    my $self = shift;

    my $path = File::Spec->catdir(
            Enbld::Home->depository,
            $self->{attributes}->DistName,
            );

    Enbld::Target::Symlink->delete_symlink( $path );

    $self->{config}->drop_enabled;
}

sub _build {
    my ( $self, $condition ) = @_;

    Enbld::Message->notify( "=====> Start building target '$self->{name}'." );

    local $ENV{PATH} = $self->{PATH};

    $self->_solve_dependencies;

    $self->_setup_install_directory;
    $self->_exec_build_command( $condition );

    if ( $condition->module_file ) {
        $self->_install_module( $condition );
    }

    $self->_postbuild;

    my $finish_msg = "=====> Finish building target '$self->{name}'.";
    Enbld::Message->notify( $finish_msg );

    $self->{config}->set_enabled( $self->{attributes}->Version, $condition );
}

sub _build_to_deploy {
    my ( $self, $condition ) = @_;

    Enbld::Message->notify( "=====> Start building target '$self->{name}'." );

    local $ENV{PATH} = $self->{PATH};

    $self->_solve_dependencies_to_deploy;

    $self->{install} = Enbld::Home->deploy_path;

    $self->_exec_build_command( $condition );

    if ( $condition->module_file ) {
        $self->_install_module( $condition );
    }

    my $finish_msg = "=====> Finish building target '$self->{name}'.";
    Enbld::Message->notify( $finish_msg );

    $self->{config}->set_enabled( $self->{attributes}->Version, $condition );
}

sub _exec_build_command {
    my $self = shift;
    my $condition = shift;

    $self->_setup_build_directory;
    chdir $self->{build};

    $self->_prebuild;

    $self->_configure( $condition ) if $self->{attributes}->CommandConfigure;
    $self->_make                    if $self->{attributes}->CommandMake;

    if ( $condition->make_test or Enbld::Feature->is_make_test_all ) {
        $self->_test;
    }

    $self->_install                 if $self->{attributes}->CommandInstall;
}

sub _solve_dependencies {
    my $self = shift;

    return if ( ! @{ $self->{attributes}->Dependencies } );

    Enbld::Message->notify( "=====> Found dependencies." );

    require Enbld::App::Configuration;

    foreach my $dependency ( @{ $self->{attributes}->Dependencies } ) {

        Enbld::Message->notify( "--> Dependency '$dependency'." );

        my $config = Enbld::App::Configuration->search_config( $dependency );
        my $target = Enbld::Target->new( $dependency, $config );

        if ( $target->is_installed ) {
            my $installed_msg = "--> $dependency is already installed.";
            Enbld::Message->notify( $installed_msg );
            next;
        }

        Enbld::Message->notify( "--> $dependency is not installed yet." );

        my $condition = $self->{conditions}{$dependency} ?
            $self->{conditions}{$dependency} : undef;

        my $installed;
        if ( $condition ) {
            $installed = $target->install_declared( $self->{conditions} );
        } else {
            $installed = $target->install;
        }
        
        Enbld::App::Configuration->set_config( $installed );
    }
}

sub _solve_dependencies_to_deploy {
    my $self = shift;

    return if ( ! @{ $self->{attributes}->Dependencies } );

    Enbld::Message->notify( "=====> Found dependencies." );

    foreach my $dependency ( @{ $self->{attributes}->Dependencies } ) {

        next if ( Enbld::Deployed->is_deployed( $dependency ));

        Enbld::Message->notify( "--> Dependency '$dependency'." );
        Enbld::Message->notify( "--> $dependency is not installed yet." );
 
        my $target = Enbld::Target->new( $dependency );

        my $condition = $self->{conditions}{$dependency} ?
            $self->{conditions}{$dependency} : undef;

        my $installed;
        if ( $condition ) {
            $installed = $target->deploy_declared( $self->{conditions} );
        } else {
            $installed = $target->deploy;
        }

        Enbld::Deployed->add( $installed );
    }
}

sub _prebuild {
    my $self = shift;

    $self->_apply_patchfiles if $self->{attributes}->PatchFiles;
}

sub _configure {
    my $self      = shift;
    my $condition = shift;

    return $self unless $self->{attributes}->CommandConfigure;

    my $configure;

    $configure = $self->{attributes}->CommandConfigure . ' ';
    $configure .= $self->{attributes}->Prefix . $self->{install};

    if( $self->{attributes}->AdditionalArgument ) {
        $configure .= ' ' . $self->{attributes}->AdditionalArgument;
    }

    if ( $condition->arguments ) {
        $configure .= ' ' . $condition->arguments;
    }

    $self->_exec( $configure );
}

sub _make {
    my $self = shift;

    if ( $self->{attributes}->CommandConfigure ) {
        $self->_exec( $self->{attributes}->CommandMake );
        return $self;
    }

    # this code for tree command...tree don't has configure
    my $args = $self->{attributes}->Prefix . $self->{install};

    if ( $self->{attributes}->AdditionalArgument ) {
        $args .= ' ' . $self->{attributes}->AdditionalArgument;
    }

    $self->_exec( $self->{attributes}->CommandMake . ' ' . $args );

    return $self;
}

sub _test {
    my $self = shift;

    return $self unless $self->{attributes}->CommandTest;

    $self->_exec( $self->{attributes}->CommandTest );
}

sub _install {
    my $self = shift;

    if ( $self->{attributes}->CommandConfigure ) {
        $self->_exec( $self->{attributes}->CommandInstall );
        return $self;
    }

    my $args = $self->{attributes}->Prefix . $self->{install};

    if ( $self->{attributes}->AdditionalArgument ) {
        $args .= ' ' . $self->{attributes}->AdditionalArgument;
    }

    $self->_exec( $self->{attributes}->CommandInstall . ' ' . $args );

    return $self;
}

sub _install_module {
    my ( $self, $condition ) = @_;

    require Enbld::Module;
    my $module = Enbld::Module->new(
            name        => $self->{name},
            path        => $self->{install},
            module_file => $condition->module_file,
            );

    $module->install;
}

sub _postbuild {
    my $self = shift;

    $self->_copy_files;

    my $path = File::Spec->catdir(
            Enbld::Home->depository,
            $self->{attributes}->DistName,
            );

    Enbld::Target::Symlink->delete_symlink( $path );
    Enbld::Target::Symlink->create_symlink( $self->{install} );
}

sub _copy_files {
    my $self = shift;

    return $self unless ( my $dirs = $self->{attributes}->CopyFiles );

    for my $dir ( @{ $dirs } ) {
        rcopy(
                File::Spec->catdir( $self->{build},   $dir ),
                File::Spec->catdir( $self->{install}, $dir )
                );
    }

}

sub _exec {
    my ( $self, $cmd ) = @_;

    require Enbld::Logger;
    my $logfile = Enbld::Logger->logfile;

    Enbld::Message->notify( "--> $cmd" );

    system( "LANG=C;$cmd >> $logfile 2>&1" );

    return $self unless $?;

    if ( $? == -1 ) {
        Enbld::Error->throw( "Failed to execute:$cmd" );
    } elsif ( $? & 127 ) {
        Enbld::Error->new( "Child died with signal:$cmd" );
    } else {
        Enbld::Error->throw(
                "Build fail.Command:$cmd return code:" . ( $? >> 8 )
                );
    }
}

sub _apply_patchfiles {
    my $self = shift;

    my $patchfiles = $self->{attributes}->PatchFiles;

    require Enbld::HTTP;
    require Enbld::Message;
    require Enbld::Logger;
    my $logfile = Enbld::Logger->logfile;
    foreach my $patchfile ( @{ $patchfiles } ) {
        my @parse = split( /\//, $patchfile );
        my $path = File::Spec->catfile( $self->{build}, $parse[-1] );

        Enbld::HTTP->download( $patchfile, $path );
        Enbld::Message->notify( "--> Apply patch $parse[-1]." );

        system( "patch -p0 < $path >> $logfile 2>&1" );
    }
}

sub _setup_build_directory {
    my $self = shift;
    
    my $path = File::Spec->catfile(
            Enbld::Home->dists,
            $self->{attributes}->Filename
            );

    my $archivefile =
        Enbld::HTTP->download_archivefile( $self->{attributes}->URL, $path );

    my $build = $archivefile->extract( Enbld::Home->build );

    return ( $self->{build} = $build );
}

sub _setup_install_directory {
    my $self = shift;
  
    my $depository = File::Spec->catdir(
            Enbld::Home->depository,
            $self->{attributes}->DistName,
            $self->{attributes}->Version,
            );

    remove_tree( $depository ) if ( -d $depository );

    return ( $self->{install} = $depository );
}

1;
