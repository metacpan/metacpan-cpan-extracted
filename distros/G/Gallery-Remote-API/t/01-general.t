use Test::More;
use Test::Mock::LWP;
use URI;

$Mock_ua->mock(
	cookie_jar => sub {},
);

use_ok( 'Gallery::Remote::API' );

my $gallery;

#testing construction

eval { $gallery = new Gallery::Remote::API; };
ok($@ =~ /^Must pass arguments as a hashref; 'url' required at minimum/,
	"contructor croaked without any args");

eval { $gallery = Gallery::Remote::API->new({}); };
ok($@ =~ /^'url' to the gallery installation is a required argument/,
	"contructor croaked without required arg");

eval { $gallery = Gallery::Remote::API->new({ url => [] }); };
ok($@ =~ /^url must be a URI object, or a string/,
	"contructor croaked on non-scalar url");

eval { $gallery = Gallery::Remote::API->new({ url => 'foo.com', version => 3 }); };
ok($@ =~ /^Accepted values for Gallery version are '1' or '2'/,
	"contructor croaked on unsupported version");

$gallery = Gallery::Remote::API->new({ url => URI->new('foo.com'), version => 1 });
isa_ok($gallery,'Gallery::Remote::API','URI object url constructed ok');
cmp_ok($gallery->version, '==', 1, 'accepted version arg');

$gallery = Gallery::Remote::API->new({ url => 'foo.com' });
isa_ok($gallery,'Gallery::Remote::API','string url constructed ok');
cmp_ok($gallery->version, '==', 2, 'defaulted to version 2');

eval { $gallery->login; };
ok($@ =~ /^Must define username during object construction to login/,
	"login croaked without username");

$gallery = Gallery::Remote::API->new({ url => 'foo.com', username => 'user' });
eval { $gallery->login; };
ok($@ =~ /^Must define password during object construction to login/,
	"login croaked without password");


#testing LWP commands

my $result;
$gallery = Gallery::Remote::API->new({ url => 'foo.com', username => 'user', password => 'pass' });

$Mock_response->set_always(status_line => '404 NOT FOUND');
$Mock_response->set_always(message => '404, dude!');
$Mock_response->set_always(is_success => 0);
$Mock_ua->mock (
	post => sub { return $Mock_response; }
);

$result = $gallery->login;
ok(! defined $result,'login returned undef');
$result = $gallery->result;
ok(defined $result,'result available via accessor');
cmp_ok($result->{status},'eq','server_error', "status set to 'server_error'");
cmp_ok($result->{status_text},'eq','404, dude!', 'status_text set to response message');

undef $result;

$Mock_response->set_always(is_success => 1);
$Mock_response->set_always(content => "status=0\nstatus_text=success, huzzah!");
$Mock_ua->mock (
	post => sub { return $Mock_response; }
);

$result = $gallery->login;
isa_ok($result,'HASH','login command returned hash results');
cmp_ok($result->{status},'eq','0', "success status extracted from content");
cmp_ok($result->{status_text},'eq','success, huzzah!', 'status_text extracted from content');
cmp_ok($gallery->response,'eq',"status=0\nstatus_text=success, huzzah!","response available from accessor");

undef $result;

$result = $gallery->execute_command('fetch-albums');
isa_ok($result,'HASH','arbitrary command returned hash results');
cmp_ok($result->{status},'eq','0', "success status extracted from content");
cmp_ok($result->{status_text},'eq','success, huzzah!', 'status_text extracted from content');
cmp_ok($gallery->response,'eq',"status=0\nstatus_text=success, huzzah!","response available from accessor");


done_testing;

