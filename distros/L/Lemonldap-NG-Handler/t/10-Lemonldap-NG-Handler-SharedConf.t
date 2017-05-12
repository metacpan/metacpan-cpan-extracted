# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Lemonldap-NG-Handler-SharedConf.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More;
use Cwd 'abs_path';
use File::Basename;
use File::Temp;
my $numTests = 4;
unless ( eval { require Test::MockObject } ) {
    $numTests = 1;
    warn "Warning: Test::MockObject is needed to run deeper tests\n";
}

plan tests => $numTests;

my $ini = File::Temp->new();
my $dir = dirname( abs_path($0) );
my $tmp = File::Temp::tempdir();

print $ini "[all]

[configuration]
type=File
dirName=$dir
localStorage=Cache::FileCache
localStorageOptions={                             \\
    'namespace'          => 'lemonldap-ng-config',\\
    'default_expires_in' => 600,                  \\
    'directory_umask'    => '007',                \\
    'cache_root'         => '$tmp',               \\
    'cache_depth'        => 0,                    \\
}

";

$ini->flush();

use Env qw(LLNG_DEFAULTCONFFILE);
$LLNG_DEFAULTCONFFILE = $ini->filename;

#open STDERR, '>/dev/null';

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

$Lemonldap::NG::Handler::API::logLevel = 'error';
use_ok('Lemonldap::NG::Handler');

# we don't want to use all Apache::* stuff
$ENV{MOD_PERL}             = undef;
$ENV{MOD_PERL_API_VERSION} = 2;

# Create a fake Apache2::RequestRec
my $mock = Test::MockObject->new();
my $ret;
$mock->fake_module(
    'Lemonldap::NG::Handler::API',
    newRequest      => sub { 1 },
    header_in       => sub { "" },
    hostname        => sub { 'test1.example.com' },
    is_initial_req  => sub { '1' },
    remote_ip       => sub { '127.0.0.1' },
    args            => sub { undef },
    unparsed_uri    => sub { '/' },
    uri             => sub { '/' },
    uri_with_args   => sub { '/' },
    get_server_port => sub { '80' },
    set_header_out  => sub { $ret = join( ':', $_[1], $_[2], ); },
);

our $apacheRequest;

my $h = bless {}, 'Lemonldap::NG::Handler';

ok( $h->init(), 'Initialize handler' );
ok( $h->run($apacheRequest),
    'run Handler with basic configuration and no cookie' );

ok(
    "$ret" eq
'Location:http://auth.example.com/?url=aHR0cDovL3Rlc3QxLmV4YW1wbGUuY29tLw==',
    'testing redirection URL from previous run'
) or print STDERR "Got: $ret\n";

$LLNG_DEFAULTCONFFILE = undef;
