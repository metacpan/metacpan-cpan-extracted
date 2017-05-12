#!perl -w
use strict;
use Hibiscus::XMLRPC;
use DBI;
use Getopt::Long;
use POSIX qw(strftime);

use vars '$VERSION';
$VERSION = '0.02';

GetOptions(
    'create'   => \my $create,
    'hbciuser:s' => \my $hbciuser,
    'hbcipass:s' => \my $hbcipass,
    'dsn:s'    => \my $dsn,
    'dbuser:s' => \my $dbuser,
    'dbpass:s' => \my $dbpass,
    'table:s'  => \my $table,
    'url:s'    => \my $url,
);

$table ||= 'transactions';

my $month = strftime '%Y-%m', localtime;

my @url = $url ? (url => $url) : ();
my $client = Hibiscus::XMLRPC->new(
    @url,
    user     => $hbciuser,
    password => $hbcipass,
);

my $dbh = DBI->connect(
    $dsn,$dbuser,$dbpass, { RaiseError => 1, PrintError => 0 }
) or die DBI->error;

my $create_sql = <<SQL;
create table "$table" (
    konto_id 	      decimal(8,0) not null,
    empfaenger_name   varchar(1024),
    empfaenger_konto  varchar(34),
    empfaenger_blz 	  decimal(8,0),
    art 	          varchar(32),
    betrag 	          decimal(18,2) not null,
    valuta 	          date,
    datum 	          date not null,
    zweck 	          varchar(1024),
    saldo 	          decimal(18,2) not null,
    primanota         decimal(4),
    customer_ref      varchar(1024),
    umsatz_typ 	      varchar(1024),
    kommentar 	      varchar(1024)
);
SQL

if( $create ) {
    $dbh->do($create_sql);
};

$dbh->do(<<SQL);
    delete from "$table"
SQL

my @columns = qw(
konto_id 	      
empfaenger_name   
empfaenger_konto  
empfaenger_blz 	  
art 	
betrag 	
valuta 	
datum 	
zweck 	
saldo 	
primanota
customer_ref
umsatz_typ 	
kommentar 	
);

my $cols = join ",",@columns;
my $placeholders = join ',', ('?') x @columns;
my $sth = $dbh->prepare(<<SQL);
    insert into "$table" ($cols) values (?,?,?,?,?,?,?,?,?,?,?,?,?,?)
SQL

my $tr = $client->transactions()->get;
print sprintf '%d transactions', scalar @$tr;
my @results;
my( $err,$rows) = $sth->execute_for_fetch(sub {my $r = shift @$tr; [@{$r}{@columns}] if $r }, \@results);

