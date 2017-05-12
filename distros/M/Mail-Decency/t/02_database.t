#!/usr/bin/perl

use strict;
use Test::More tests => 2;
use Mail::Decency::Helper::Database;
use FindBin qw/ $Bin /;
use lib "$Bin/lib";
use TestDatabase;


SKIP: {
    
    skip "MongoDB not installed, skipping tests", 1 unless eval "use MongoDB; 1;";
    skip "MongoDB tests, set USE_MONGODB=1, MONGODB_DATABASE to the database (default: test_decency, will be dropped afterwards), MONGODB_HOST to the host to be used (default: 127.0.0.1) and MONGODB_PORT to the port to be used (default: 27017) in Env to enable", 1 unless $ENV{ USE_MONGODB };
    
    subtest "MongoDB" => sub {
        plan tests => 4;
        
        # get mongo connection
        my %create;
        $create{ host } = $ENV{ MONGODB_HOST } if $ENV{ MONGODB_HOST };
        $create{ port } = $ENV{ MONGODB_PORT } if $ENV{ MONGODB_PORT };
        
        test_db( "MongoDB", %create );
    };
};


SKIP: {
    
    skip "DBD::SQLite not installed, skipping tests", 1 unless eval "use DBD::SQLite; 1;";
    
    subtest "DBD::SQLite" => sub {
        plan tests => 4;
        
        # get mongo connection
        my %create;
        my $file = TestDatabase::sqlite_file();
        $create{ args } = [ "dbi:SQLite:dbname=$file" ];
        
        test_db( "DBD", %create );
        unlink $file unless $ENV{ SQLITE_FILE };
    };
};






sub test_db {
    my ( $type, %create ) = @_;
    
    my $db = Mail::Decency::Helper::Database->create( $type => \%create );
    my $schema = $ENV{ DB_SCHEMA } || "schema";
    my $table  = $ENV{ DB_TABLE }  || "table";
    
    # fetch null-data
    my $value = 'there-'. time();
    my $ref = $db->get( $schema => $table => {
        something => $value
    } );
    ok( !$ref, "Not existing data not found" );
    
    # create data
    eval {
        $db->set( $schema => $table => {
            something => $value
        } );
    };
    ok( !$@, "Data created" );
    
    
    # re-read data
    $ref = $db->get( $schema => $table => {
        something => $value
    } );
    ok(
        $ref && ref( $ref ) eq "HASH" && defined $ref->{ something } && $ref->{ something } eq $value,
        "Data fetched"
    );
    
    # remove data
    $db->remove( $schema => $table => {
        something => $value
    } );
    $ref = $db->get( $schema => $table => {
        something => $value
    } );
    ok( !$ref, "Data has been removed" );
    
    
}



