package TestDatabase;

use strict;
use DBI;
use DBD::SQLite;
use FindBin qw/ $Bin /;

sub sqlite_file {
    my $file = $ENV{ SQLITE_FILE };
    unless ( $file ) {
        my $schema = $ENV{ DB_SCHEMA } || "schema";
        my $table  = $ENV{ DB_TABLE }  || "table";
        $file = "$Bin/data/sqlite.db";
        create_sqlite( "${schema}_${table}", $file );
    }
    return $file;
}

sub create_sqlite {
    my ( $table, $file ) = @_;
    
    if ( -f $file ) {
        unlink( $file );
    }
    my $dbh = DBI->connect("dbi:SQLite:dbname=$file","","");
    
    my $sql = <<SQL;
CREATE TABLE $table (
    something VARCHAR( 50 ),
    data INT
);
SQL
    my $sth = $dbh->prepare( $sql ); 
    $sth->execute();
    $dbh->disconnect;
    return ;
}



1;
