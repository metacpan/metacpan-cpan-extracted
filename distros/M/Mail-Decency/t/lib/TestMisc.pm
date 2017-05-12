package TestMisc;

use strict;
use Scalar::Util qw/ blessed /;
use Test::More;
use feature qw/ switch /;
use base qw/ Exporter /;
use FindBin qw/ $Bin /;
use File::Path qw/ remove_tree /;
use TestDatabase;
use Mail::Decency::Helper::Logger;

our @EXPORT = qw/ ok_for_dunno ok_for_ok ok_for_reject ok_for_prepend empty_logger /;


sub ok_for_reject {
    my ( $policy, $err, $msg ) = @_;
    my $ok = 0;
    given( $err ) {
        when( blessed($_) && $_->isa( 'Mail::Decency::Core::Exception::Reject' ) && $policy->session_data->response =~ /^(REJECT|[45]\d\d)/ ) {
            $ok++;
        }
        default {
            diag( "Wrong state: ". $policy->session_data->response. ", expected REJECT or [45]\\d\\d" )
                if $policy->session_data->response !~ /^(REJECT|[45]\d\d)/;
            diag( "Wrong Exception: ". ref( $_ ) )
                if blessed($_) && ! $_->isa( 'Mail::Decency::Core::Exception::Reject' );
            diag( "Unexpected error $_" )
                if ! blessed($_) && $_;
        }
    }
    ok( $ok, $msg );
}


sub ok_for_ok {
    my ( $policy, $err, $msg ) = @_;
    my $ok = 0;
    given( $err ) {
        when( blessed($_) && $_->isa( 'Mail::Decency::Core::Exception::Accept' ) && $policy->session_data->response =~ /^OK/ ) {
            $ok++;
        }
        default {
            diag( "Wrong state: ". $policy->session_data->response. ", expected OK" )
                if $policy->session_data->response !~ /^OK/;
            diag( "Wrong Exception: ". ref( $_ ) )
                if blessed($_) && ! $_->isa( 'Mail::Decency::Core::Exception::OK' );
            diag( "Unexpected error $_" )
                if ! blessed($_) && $_;
        }
    }
    ok( $ok, $msg );
}


sub ok_for_prepend {
    my ( $policy, $err, $msg ) = @_;
    my $ok = 0;
    given( $err ) {
        when( blessed($_) && $_->isa( 'Mail::Decency::Core::Exception::Prepend' ) && $policy->session_data->response =~ /^PREPEND/ ) {
            $ok++;
        }
        default {
            diag( "Wrong state: ". $policy->session_data->response. ", expected PREPEND" )
                if $policy->session_data->response !~ /^PREPEND/;
            diag( "Wrong Exception: ". ref( $_ ) )
            if blessed($_) && ! $_->isa( 'Mail::Decency::Core::Exception::Prepend' );
            diag( "Unexpected error $_" )
                if ! blessed($_) && $_;
        }
    }
    ok( $ok, $msg );
}


sub ok_for_dunno {
    my ( $policy, $err, $msg ) = @_;
    my $ok = 0;
    given( $err ) {
        when( ! $_ && $policy->session_data->response =~ /^DUNNO/ ) {
            $ok++;
        }
        default {
            diag( "Wrong state: ". $policy->session_data->response. ", expected DUNNO" )
                if $policy->session_data->response !~ /^DUNNO/;
            diag( "Wrong Exception: ". ref( $_ ) )
                if blessed($_);
            diag( "Unexpected error: $_" )
                if ! blessed($_) && $_;
        }
    }
    ok( $ok, $msg );
}


sub create_server {
    my ( $class, $file, $config_modi_ref ) = @_;
    
    my $config_ref = YAML::LoadFile( "$Bin/conf/$file.yml" );
    
    # bind database
    if ( $ENV{ USE_MONGODB } && $ENV{ USE_MONGODB } == 1 ) {
        $config_ref->{ database } = {
            type     => "MongoDB",
            database => $ENV{ MONGODB_DATABASE } || "test_decency",
            server   => $ENV{ MONGODB_HOST } || "127.0.0.1",
            port     => $ENV{ MONGODB_PORT } || 27017,
        };
    }
    else {
        $config_ref->{ database } = {
            type  => "DBD",
            args  => [ "dbi:SQLite:dbname=". TestDatabase::sqlite_file() ]
        };
    }
    
    # bind cache
    $config_ref->{ cache } = {
        class      => "Memory",
        #cache_root => "$Bin/data/cache"
    };
    $config_ref->{ config_dir } = "$Bin/conf";
    
    if ( $config_modi_ref ) {
        $config_ref->{ $_ } = $config_modi_ref->{ $_ }
            for keys %$config_modi_ref;
    }
    
    my $server = $class->new( config => $config_ref, config_dir => "$Bin/conf" );
    
    return $server;
}


sub cleanup {
    my ( $server ) = @_;
    remove_tree( "$Bin/data/cache" );
    
    my $sqlite = TestDatabase::sqlite_file();
    unlink( $sqlite ) if -f $sqlite;
    
    if ( $ENV{ USE_MONGODB } ) {
        $server->database->db->drop;
    }
    
    if ( $server->isa( 'Mail::Decency::ContentFilter' ) ) {
        remove_tree( $server->spool_dir );
    }
    
    if ( $server->isa( 'Mail::Decency::LogParser' ) ) {
        unlink( "$Bin/data/test.log" );
    }
}


sub empty_logger {
    return Mail::Decency::Helper::Logger->new(
        syslog    => 0,
        console   => 0,
    );
}


1;
