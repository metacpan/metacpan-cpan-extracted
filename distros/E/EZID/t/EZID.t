use Modern::Perl;
use Test::More tests => 9;
use String::Random qw(random_regex);

BEGIN { use_ok('EZID') };

my $ezid = new EZID({username => 'apitest', password => 'apitest'});
my $response;

$response = $ezid->get();
ok(not defined $response);

$response = $ezid->get('foo');
ok(not defined $response);
ok($ezid->error_msg =~ /unrecognized identifier scheme/);

$response = $ezid->get('ark:/99999/unknownidentifier');
ok(not defined $response);
ok($ezid->error_msg =~ /no such identifier/);

$response = $ezid->create('foo');
ok(not defined $response);

my $identifier = 'ark:/99999/fk4' . random_regex('\w{5}');

$response = $ezid->create($identifier);
is($response->{success}, $identifier);

$response = $ezid->get($identifier);
ok($response->{success});

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

