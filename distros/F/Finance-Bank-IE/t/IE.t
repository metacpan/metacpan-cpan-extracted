#!perl
use strict;
use warnings;

use Test::MockModule;
use Test::More tests => 32;

use File::Basename;
use Cwd;
use Errno;

my $www_mechanize_mock;

BEGIN {
    $www_mechanize_mock = new Test::MockModule( 'WWW::Mechanize' );
    use_ok( "Finance::Bank::IE" );
}

# reset
ok( Finance::Bank::IE->reset(), "can reset" );

# _agent
my $agent;
ok( $agent = Finance::Bank::IE->_agent(), "can create an agent" );
Finance::Bank::IE->reset();
my $agent2 = Finance::Bank::IE->_agent();
# this is a little flaky; it should be something like "agent doesn't
# share *any* state with agent2"
ok( $agent != $agent2, "reset works" ) or diag "$agent, $agent2";

# if we can't create a new WWW::Mechanize object, fail
Finance::Bank::IE->reset();
$www_mechanize_mock->mock( 'new', sub {
                               return undef
                           });
# this confess()es, so we need to catch it
$agent = undef;
eval {
    $agent = Finance::Bank::IE->_agent();
};
ok( !$agent, "can handle WWW::Mechanize new() failure" );
$www_mechanize_mock->unmock_all();

# cached_config
Finance::Bank::IE->reset();
my $config = { foo => 'bar' };
ok( !Finance::Bank::IE->cached_config(), "no config returned if none present" );
ok( my $cached = Finance::Bank::IE->cached_config( $config ), "saves config" );
is_deeply( $cached, $config, "correctly saves config" );
ok( $cached = Finance::Bank::IE->cached_config(), "retrieves cached config" );
is_deeply( $cached, $config, "correctly retrieves config" );

# _dprintf
my $savestderr = fileno( STDERR );
open my $olderr, '>&', \*STDERR or die $!;
close( STDERR );
my $stderr;
open STDERR, '>', \$stderr;
my $olddebug = delete $ENV{DEBUG};
Finance::Bank::IE->_dprintf( "hello world\n" );
ok( !$stderr, "_dprintf suppressed if DEBUG is unset" );
$ENV{DEBUG} = 1;
Finance::Bank::IE->_dprintf( "hello world\n" );
ok( $stderr eq "[Finance::Bank::IE] hello world\n", "_dprintf prints if DEBUG is set" ) or diag $stderr;

# reset everything
if ( defined( $olddebug )) {
    $ENV{DEBUG} = $olddebug;
} else {
    delete $ENV{DEBUG};
}
close( STDERR );
open STDERR, '>&', $olderr or die $!;

# _get_class
ok( Finance::Bank::IE->_get_class() eq "IE", "_get_class (class)" );
# we don't have new() just yet
my $bogus = bless {}, "Finance::Bank::IE";
ok( $bogus->_get_class() eq "IE", "_get_class (object)" );

# _scrub_page
ok( Finance::Bank::IE->_scrub_page( "foo" ) eq "foo", "_scrub_page" );

# _save_page
SKIP: {
    skip "tests causing too many problems right now", 8;

my $oldsave = delete $ENV{SAVEPAGES};
$agent = Finance::Bank::IE->_agent();
my $file = 'file://' . File::Spec->catfile( getcwd(), $0 );
my $bogussuffix = "doesnotexist";
my $saved1 = "data/savedpages/IE/foo";
my $saved2 = "data/savedpages/IE/404-foo" . $bogussuffix;
my $saved3 = "data/savedpages/IE/index.html";
my $saved4 = "data/savedpages/IE/index.html_q=1";
my $saved5 = "data/savedpages/IE/index.html_q=1&w=2";
unlink( $saved1 );
unlink( $saved2 );
unlink( $saved3 );
unlink( $saved4 );
unlink( $saved5 );
$agent->get( $file );
Finance::Bank::IE->_save_page();
$agent->get( $file . $bogussuffix );
Finance::Bank::IE->_save_page();
ok( ! -e $saved1, "_save_page (off, found)" );
ok( ! -e $saved2, "_save_page (off, not found)" );
$ENV{SAVEPAGES} = 1;
$agent->get( $file );
Finance::Bank::IE->_save_page();
$agent->get( $file . $bogussuffix );
Finance::Bank::IE->_save_page();
ok( -e $saved1, "_save_page (on, found)" );
ok( -e $saved2, "_save_page (on, not found)" );

$agent->get( $file );
$agent->response()->request->uri( 'http://www.example.com/' );
Finance::Bank::IE->_save_page();
ok( -e $saved3, "_save_page (on, index.html)" );

Finance::Bank::IE->_save_page( "q=1" );
ok( -e $saved4, "_save_page (on, index.html, param q=1)" );

Finance::Bank::IE->_save_page( "q=1", "w=2" );
ok( -e $saved5, "_save_page (on, index.html, params q=1, w=2)" );

# unsaveable file. Need to capture stderr.
chmod( 0400, $saved3 );
$savestderr = fileno( STDERR );
open $olderr, '>&', \*STDERR or die $!;
close( STDERR );
open STDERR, '>', \$stderr;
my $error = Finance::Bank::IE->_save_page();
ok( $error == Errno::EACCES, "unwritable file $saved3" );
close( STDERR );
open STDERR, '>&', $olderr or die $!;

if ( defined( $oldsave )) {
    $ENV{SAVEPAGES} = $oldsave;
} else {
    delete $ENV{SAVEPAGES};
}
}

# _streq
ok( !Finance::Bank::IE->_streq( "a", undef ), "compare string & undef" );
ok( !Finance::Bank::IE->_streq( undef, "a" ), "compare undef & string" );
ok( Finance::Bank::IE->_streq( "a", "a" ), "compare same string" );
ok( !Finance::Bank::IE->_streq( "a", "b" ), "compare unequal strings" );

# _rebuild_tag
my @tagtests = (
    [ [ "E", "tr", "</tr>" ], "</tr>" ],
    [ [ "S", "tr", {}, [], "<tr>" ], "<tr>" ],
    [ [ "S", "a", { href => "foo" }, [ "href" ], "<a href=\"foo\">" ],
      "<a href=\"foo\">" ],
    [ [ "S", "a", {}, [ "href" ], "<a href=\"foo\">" ], "<a>" ],
    );
for my $tagtest ( @tagtests ) {
    is( Finance::Bank::IE->_rebuild_tag( $tagtest->[0] ), $tagtest->[1], "rebuild " . $tagtest->[1] );
}

# as_qif
my @details = (
    { date => "1970-01-01", payee => "Foo", amount => 1 },
    { date => "1970-01-02", payee => "Bar", amount => 2 },
    );
is( Finance::Bank::IE->as_qif( \@details ), "!Type:Bank
D1970-01-01
PFoo
T1.00
^
D1970-01-02
PBar
T2.00
^
");

END {
    #unlink( $saved1 );
    #unlink( $saved2 );
    #unlink( $saved3 );
    #unlink( $saved4 );
    #unlink( $saved5 );
}
