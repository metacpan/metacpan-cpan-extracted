# -*- perl -*-

use strict;


use HTML::EP ();


if (!eval { require DBD::CSV; require DBI; require Storable; require MD5 }) {
    print "1..0\n";
    exit 0;
}
print "1..55\n";

my $numTests = 0;
sub Test($;@) {
    my $result = shift;
    if (@_ > 0) { printf(@_); }
    ++$numTests;
    if (!$result) { print "not " };
    print "ok $numTests\n";
    $result;
}

sub Test2($$;@) {
    my $a = shift;
    my $b = shift;
    my $c = ($a eq $b);
    if (!Test($c, @_)) {
	print("Expected $b, got $a\n");
    }
    $c;
}

$ENV{'REQUEST_METHOD'} = 'GET';
$ENV{'QUERY_STRING'} = '';

my $dbh = DBI->connect("DBI:CSV:");
Test($dbh, "Creating a DBI handle\n");
unlink "sessions";
Test($dbh->do("CREATE TABLE sessions (ID INTEGER, SESSION VARCHAR(65535),"
	      . " LOCKED INTEGER, ACCESSED INTEGER)"),
     "Creating the sessions table\n")
    or print "Failed to create table: ", $dbh->errstr(), "\n";

my $parser = HTML::EP->new();
Test($parser, "Creating the parser\n");

my $input = '<ep-package name="HTML::EP::Session" require=1><ep-database dsn="DBI:CSV:"><ep-session id="">';
Test2($parser->Run($input), '', "Creating a session\n");

my $sth = $dbh->prepare("SELECT ID,SESSION,LOCKED FROM sessions");
$sth->execute();
my($id, $session, $locked) = $sth->fetchrow_array();
Test($id, "Checking ID\n") or print "Missing ID\n";
Test(substr($session, 0, 1) eq 's');
$session = Storable::thaw(substr($session, 1));
Test(($session and (ref($session) eq "HTML::EP::Session::DBI")),
     "Checking session\n")
    or print "Session failure, got " . DBI::neat($session), "\n";
Test($locked) or print "Session not locked\n";

# Force calling the destructor
undef $parser;
$sth->execute();
my $ref = $sth->fetchrow_arrayref();
Test($id eq $ref->[0])
    or print "Wrong ID, expected $id, got ", DBI::neat($ref->[0]), "\n";
Test(ref($session) eq ref(Storable::thaw(substr($ref->[1], 1))))
    or print("Session failure, got " . DBI::neat(Storable::thaw(substr($ref->[1], 1))),
	     "\n");
Test(!$ref->[2])
    or print("Session locked: 'locked' = ", DBI::neat($ref->[2]), "\n");

# Add items to the session
$parser = HTML::EP->new();
$input = qq{
<ep-package name="HTML::EP::Session" require=1>
<ep-database dsn="DBI:CSV:">
<ep-session id="$id">
<ep-session-item item=01 add=2>
<ep-session-item item=02 num=2>
<ep-session-item item=03 add=2>
<ep-session-item item=03 add=1>
<ep-session-item item=04 num=2>
<ep-session-item item=04 num=1>
<ep-session-store>
};
Test2($parser->Run($input), "\n" x 11, "Storing items\n");

$sth = $dbh->prepare("SELECT ID,SESSION,LOCKED FROM sessions WHERE ID = ?");
$sth->execute($id);
($id, $session, $locked) = $sth->fetchrow_array();
Test($id) or print "Missing ID\n";
$session = Storable::thaw(substr($session, 1));
Test($session and ref($session) eq "HTML::EP::Session::DBI")
    or print "Session failure, got " . DBI::neat($session), "\n";
Test(!$locked) or print "Session not locked\n";

my $items = $session->{'items'};
Test($items and ref($items) eq 'HASH') or print "items not a hash ref\n";
Test($items->{'01'} == 2)
    or printf("Items 01: Expected 2, got %s\n", DBI::neat($items->{'01'}));
Test($items->{'02'} == 2)
    or printf("Items 02: Expected 2, got %s\n", DBI::neat($items->{'02'}));
Test($items->{'03'} == 3)
    or printf("Items 03: Expected 3, got %s\n", DBI::neat($items->{'03'}));
Test($items->{'04'} == 1)
    or printf("Items 04: Expected 1, got %s\n", DBI::neat($items->{'04'}));

$input = qq{
<ep-package name="HTML::EP::Session" require=1>
<ep-database dsn="DBI:CSV:">
<ep-session id="$id">
<ep-session-delete>
};
$parser = HTML::EP->new();
Test2($parser->Run($input), "\n" x 5, "Deleting id\n");
Test($sth->execute($id));
Test(!$sth->fetchrow_arrayref());


#
#   Repeat the same tests in hex mode
#
$parser = HTML::EP->new();
Test($parser, "Creating the hex parser\n");

$input = '<ep-package name="HTML::EP::Session" require=1><ep-database dsn="DBI:CSV:"><ep-session id="" hex=1>';
Test2($parser->Run($input), '', "Creating a hex session\n");

$sth = $dbh->prepare("SELECT ID,SESSION,LOCKED FROM sessions");
$sth->execute();
($id, $session, $locked) = $sth->fetchrow_array();
Test($id, "Checking ID\n") or print "Missing ID\n";
Test(substr($session, 0, 1) eq 'h');
$session = Storable::thaw(pack("H*", substr($session, 1)));
Test(($session and (ref($session) eq "HTML::EP::Session::DBI")),
     "Checking hex session\n")
    or print "Session failure, got " . DBI::neat($session), "\n";
Test($locked) or print "Session not locked\n";

# Force calling the destructor
undef $parser;
$sth->execute();
$ref = $sth->fetchrow_arrayref();
Test($id eq $ref->[0])
    or print "Wrong ID, expected $id, got ", DBI::neat($ref->[0]), "\n";
Test(ref($session) eq ref(Storable::thaw(pack("H*", substr($ref->[1], 1)))))
    or print("Session failure, got " . DBI::neat(Storable::thaw(pack("H*", substr($ref->[1], 1)))),
	     "\n");
Test(!$ref->[2])
    or print("Session locked: 'locked' = ", DBI::neat($ref->[2]), "\n");

# Add items to the session
$parser = HTML::EP->new();
$input = qq{
<ep-package name="HTML::EP::Session" require=1>
<ep-database dsn="DBI:CSV:">
<ep-session id="$id" hex=1>
<ep-session-item item=01 add=2>
<ep-session-item item=02 num=2>
<ep-session-item item=03 add=2>
<ep-session-item item=03 add=1>
<ep-session-item item=04 num=2>
<ep-session-item item=04 num=1>
<ep-session-store>
};
Test2($parser->Run($input), "\n" x 11, "Storing items\n");

$sth = $dbh->prepare("SELECT ID,SESSION,LOCKED FROM sessions WHERE ID = ?");
$sth->execute($id);
($id, $session, $locked) = $sth->fetchrow_array();
Test($id) or print "Missing ID\n";
$session = Storable::thaw(pack("H*", substr($session, 1)));
Test($session and ref($session) eq "HTML::EP::Session::DBI")
    or print "Session failure, got " . DBI::neat($session), "\n";
Test(!$locked) or print "Session not locked\n";

$items = $session->{'items'};
Test($items and ref($items) eq 'HASH') or print "items not a hash ref\n";
Test($items->{'01'} == 2)
    or printf("Items 01: Expected 2, got %s\n", DBI::neat($items->{'01'}));
Test($items->{'02'} == 2)
    or printf("Items 02: Expected 2, got %s\n", DBI::neat($items->{'02'}));
Test($items->{'03'} == 3)
    or printf("Items 03: Expected 3, got %s\n", DBI::neat($items->{'03'}));
Test($items->{'04'} == 1)
    or printf("Items 04: Expected 1, got %s\n", DBI::neat($items->{'04'}));

$input = qq{
<ep-package name="HTML::EP::Session" require=1>
<ep-database dsn="DBI:CSV:">
<ep-session id="$id" hex=1>
<ep-session-delete>
};
$parser = HTML::EP->new();
Test2($parser->Run($input), "\n" x 5, "Deleting id\n");
Test($sth->execute($id));
Test(!$sth->fetchrow_arrayref());


$ENV{'SCRIPT_NAME'} = '/cgi-bin/ep.cgi';
$parser = HTML::EP->new();
$input = q{
<ep-package name="HTML::EP::Session">
<ep-session id="session" class="HTML::EP::Session::Cookie">
};
Test2($parser->Run($input), qq{\n\n\n}, "Creating a cookie session\n");
my $cookie = $parser->{'_ep_cookies'}->{'session'};
Test($cookie);
Test($cookie->name eq 'session');
Test($cookie->value);
Test($cookie->expires);


print "Testing HTML::EP::Session::Dumper.\n";
unlink "testfile";
$parser = HTML::EP->new();
$input = q{
<ep-package name="HTML::EP::Session">
<ep-session id="testfile" class="HTML::EP::Session::Dumper">
<ep-session-item item="foo" num=5>
<ep-session-store>
};
Test2($parser->Run($input), qq{\n\n\n\n\n}, "Creating a dumper session\n");
Test(-f "testfile");
$session = do "testfile";
Test($session and ref($session) eq "HTML::EP::Session::Dumper");
Test($session->{'items'}->{'foo'} == 5);
$parser = HTML::EP->new();
$input = q{
<ep-package name="HTML::EP::Session">
<ep-session id="testfile" class="HTML::EP::Session::Dumper">
<ep-session-delete>
};
Test2($parser->Run($input), qq{\n\n\n\n});
Test(! -f "testfile");


exit 0;

END { unlink 'sessions', 'testfile' };

