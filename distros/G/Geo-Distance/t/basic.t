#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;

BEGIN {
    $ENV{GEO_DISTANCE_PP} = 1;
    use_ok( 'Geo::Distance' );
}

ok(! defined &distance_hsin, 'prevent XS from loading; use pure Perl');

my $geo = eval{ return Geo::Distance->new() };
ok(!$@,'create a Geo::Distance object');

my $dist = eval{ $geo->distance( 'mile', "-81.044","35.244", "-80.8272","35.1935" ) };
ok( (not($@) and int($dist)==12), 'measure a distance by mile' );

SKIP: {
    eval{ require DBD::SQLite };
    skip "DBD::SQLite not installed" if $@;

    my $dbh = eval{ return DBI->connect( "dbi:SQLite:dbname=test.db", "", "", {AutoCommit => 0} ) };
    ok( !$@, 'connect/create SQLite test.db' );
    eval{ load_zips( $dbh ) };
    ok( !$@, 'populate test.db with sample zip code locations' );

    eval{ $geo->closest( dbh=>$dbh, table=>'zips', lon=>'-80.7881', lat=>'35.22', unit=>'mile', distance=>'5' ) };
    ok( !$@, 'run closest' );

    my $locations;

    $locations = $geo->closest( dbh=>$dbh, table=>'zips', lon=>'-80.7881', lat=>'35.22', unit=>'mile', distance=>'5' );
    ok( (@$locations==11), 'found correct number of locations by mile' );
    $locations = $geo->closest( dbh=>$dbh, table=>'zips', lon=>'-80.8577', lat=>'35.1316', unit=>'kilometer', distance=>'5' );
    ok( (@$locations==2), 'found correct number of locations by kilometer' );
    $locations = $geo->closest( dbh=>$dbh, table=>'zips', lon=>'-80.8577', lat=>'35.1316', unit=>'mile', distance=>'5', count=>3 );
    ok( (@$locations==3), 'found correct number of locations limited by count' );

    $dbh->disconnect;
    unlink('test.db');
}

sub load_zips {
    my $dbh = shift;

    $dbh->do(q{
        CREATE TABLE zips (
            zip CHAR(5),
            lon DECIMAL(13,3),
            lat DECIMAL(13,3)
        )
    });

    my $sth = $dbh->prepare(q{ INSERT INTO zips (lon,lat,zip) VALUES (?,?,?) });

    $sth->execute("-81.044","35.244","28012");
    $sth->execute("-81.0306","35.3119","28120");
    $sth->execute("-81.0079","35.0972","28217");
    $sth->execute("-80.9604","35.1467","28278");
    $sth->execute("-80.9586","35.026","29715");
    $sth->execute("-80.9571","35.2731","28214");
    $sth->execute("-80.8967","35.1596","28273");
    $sth->execute("-80.8964","35.2358","28208");
    $sth->execute("-80.8858","35.0709","28134");
    $sth->execute("-80.8702","35.2834","28216");
    $sth->execute("-80.8647","35.422","28078");
    $sth->execute("-80.8583","35.2081","28203");
    $sth->execute("-80.8577","35.1316","28210");
    $sth->execute("-80.8559","35.1796","28209");
    $sth->execute("-80.8419","35.229","28202");
    $sth->execute("-80.8272","35.1935","28207");
    $sth->execute("-80.8265","35.2522","28206");
    $sth->execute("-80.8232","35.2132","28204");
    $sth->execute("-80.8209","35.2886","28269");
    $sth->execute("-80.8167","35.0869","28226");
    $sth->execute("-80.8002","35.1345","28277");
    $sth->execute("-80.7932","35.1677","28211");
    $sth->execute("-80.7881","35.22","28205");
    $sth->execute("-80.776","35.2725","28262");
    $sth->execute("-80.7669","35.1355","28270");
    $sth->execute("-80.7501","35.3179","28213");
    $sth->execute("-80.7448","35.1908","28212");
    $sth->execute("-80.7387","35.244","28215");
    $sth->execute("-80.7279","34.9553","28173");
    $sth->execute("-80.7136","35.1219","28105");
    $sth->execute("-80.6846","35.1936","28227");
    $sth->execute("-80.6597","35.0831","28079");
    $sth->execute("-80.6594","35.3247","28075");
    $sth->execute("-80.6162","35.4141","28027");
    $sth->execute("-80.5319","35.2477","28107");
    $sth->execute("-80.53","35.3716","28025");

    $dbh->commit;
}

done_testing;
