#!/usr/bin/perl 
use strict;
use DBI;
use WWW::Mechanize;
use HTML::TableExtract;

my $dbh = DBI->connect( "dbi:SQLite:iata_sqlite.db", "", "", { RaiseError => 1, AutoCommit => 0 } );

eval {
   $dbh->do(q{DROP TABLE iata});
   1;
};

eval {
   $dbh->do(q{CREATE TABLE iata(iata text,icao text,airport text, location text,primary key(iata))});
   1;
} or do {
    warn "can't create table iata\n";
};

my $mech = WWW::Mechanize->new();
$mech->agent_alias( "Linux Mozilla" );

my $sth = $dbh->prepare("replace INTO iata(iata,icao,airport,location) VALUES(?,?,?,?)");
for my $letter ( "A" .. "Z" ) {
    $mech->get("http://en.wikipedia.org/wiki/List_of_airports_by_IATA_code:_$letter");
    my $te = HTML::TableExtract->new( headers => [('IATA',qr{ICAO}, qr{Airport}, 'Location')] );
    $te->parse($mech->content);
    for my $ts ($te->tables){
        for my $row ($ts->rows){
            next if $row->[0] =~ /^-/;
            $sth->execute( @$row );
        }
    }
    sleep 3; # we are bad enough faking agent alias
}
$sth->finish();
eval {
    $dbh->do(q{create index if not exists iata_icao on iata(icao)});
    $dbh->do(q{create index if not exists iata_location on iata(location)});
    $dbh->do(q{create index if not exists iata_airport on iata(airport)});
1;
} or do {
    warn "creating indexes failed";
};
undef $sth;
$dbh->commit;
$dbh->disconnect();
