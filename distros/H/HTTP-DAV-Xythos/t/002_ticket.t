# -*- perl -*-

# t/002_ticket.t - login to a ticket

use Test::More tests => 5;

use HTTP::DAV::Xythos;

if ( -e "./test.txt"  ) {
    unless ( open TST, '<', "./test.txt" ) {
        warn "ERROR: couldn't open ./test.txt: $!\n";
        exit;
    }
}
else {
    ok(1);
    ok(1);
    ok(1);
    ok(1);
    ok(1);
    exit 0;
}

my $ticket;
my $pass;
while ( <TST> ) {
    chomp;
    if ( /ticket=(.*)/ ) {
        $ticket = $1;
    }
    if ( /pass=(.*)/ ) {
        $pass = $1;
    }
}
$pass = "" if $pass eq "nopass";

my $object = HTTP::DAV::Xythos->new (
    ticket => $ticket,
    pass   => $pass,
);
isa_ok ($object, 'HTTP::DAV::Xythos');

my ($xythos_base) = $ticket =~ m#^(https?://.*?)/#;
ok($object->{webdav_url} =~ /^$xythos_base/,"webdav_url");
my $r;
ok($object->open( -url=>$object->{webdav_url} ),"open");
ok($r=$object->propfind( -url=>$object->{webdav_url}, -depth=>1),"propfind");
ok($r->is_collection,"is_collection");


