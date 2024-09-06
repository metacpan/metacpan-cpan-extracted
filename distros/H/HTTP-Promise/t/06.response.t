#!/usr/local/bin/perl
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use vars qw( $DEBUG $CRLF );
    use Test2::V0;
    use Scalar::Util ();
    our $CRLF = "\015\012";
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

BEGIN
{
    use ok( 'HTTP::Promise::Response' );
    use ok( 'HTTP::Promise::Request' );
};

use strict;
use warnings;

my( $res, $rv );
$res = HTTP::Promise::Response->new;
isa_ok( $res => ['HTTP::Promise::Response'] );

# for m in `egrep -E '^sub ([a-z]\w+)' ./lib/HTTP/Promise/Response.pm| awk '{ print $2 }'`; do echo "can_ok( \$res => '$m' );"; done
# perl -lnE '/^sub (?!init|[A-Z]|_)/ and say "can_ok( \$res, \''", [split(/\s+/, $_)]->[1], "\'' );"' ./lib/HTTP/Promise/Response.pm
can_ok( $res => 'as_string' );
can_ok( $res => 'base' );
can_ok( $res => 'clone' );
can_ok( $res => 'code' );
can_ok( $res => 'current_age' );
can_ok( $res => 'filename' );
can_ok( $res => 'fresh_until' );
can_ok( $res => 'freshness_lifetime' );
can_ok( $res => 'is_fresh' );
can_ok( $res => 'is_info' );
can_ok( $res => 'is_success' );
can_ok( $res => 'is_redirect' );
can_ok( $res => 'is_error' );
can_ok( $res => 'is_client_error' );
can_ok( $res => 'is_server_error' );
can_ok( $res => 'parse' );
can_ok( $res => 'previous' );
can_ok( $res => 'redirects' );
can_ok( $res => 'status' );
can_ok( $res => 'status_line' );

$rv = $res->is_success;
diag( "is_success returned '", ( $rv // '' ), "' (is defined? ", defined( $rv ) ? 'yes' : 'no', ")" ) if( $DEBUG );

is( $res->is_success, undef, 'Empty res: is_success' );
is( $res->is_info, undef, 'Empty res: is_info' );
is( $res->is_redirect, undef, 'Empty res: is_redirect' );
is( $res->is_error, undef, 'Empty res: is_error' );
is( $res->is_client_error, undef, 'Empty res: is_client_error' );
is( $res->is_server_error, undef, 'Empty res: is_server_error' );
is( $res->filename, undef, 'Empty res: filename' );

my $time = time;

my $req = HTTP::Promise::Request->new( GET => 'http://www.example.com' );
$req->date( $time - 30 );

my $r = HTTP::Promise::Response->new( 200 => 'OK' );
$r->client_date( $time - 20 );
$r->date( $time - 25 );
$r->last_modified( $time - 5000000 );
$r->request( $req );

# diag( $r->as_string ) if( $DEBUG );

my $current_age = $r->current_age;

ok( $current_age >= 35 && $current_age <= 40, 'current_age' );

my $freshness_lifetime = $r->freshness_lifetime;
ok( $freshness_lifetime >= 12 * 3600, 'freshness_lifetime' );
is( $r->freshness_lifetime( heuristic_expiry => 0 ), undef, 'freshness_lifetime with heuristic_expiry set to 0' );

my $is_fresh = $r->is_fresh;
ok( $is_fresh, 'is_fresh' );
is( $r->is_fresh( heuristic_expiry => 0 ), undef, 'is_fresh with heuristic_expiry set to 0' );

diag( "current_age        = $current_age" ) if( $DEBUG );
diag( "freshness_lifetime = $freshness_lifetime" ) if( $DEBUG );
diag( "response is ", ( $is_fresh ? '' : ' not ' ), 'fresh' ) if( $DEBUG );
diag( "it will be fresh for ", ( $freshness_lifetime - $current_age ), ' more seconds' ) if( $DEBUG );

# OK, now we add an Expires header
$r->expires( $time );
diag( "\n", $r->dump( prefix => '# ' ) ) if( $DEBUG );

$freshness_lifetime = $r->freshness_lifetime;
is( $freshness_lifetime, 25, 'freshness_lifetime' );
$r->remove_header( 'expires' );

# Now we try the 'Age' header and the Cache-Contol:
$r->header( 'Age', 300 );
$r->push_header( 'Cache-Control', 'junk' );
$r->push_header( Cache_Control => 'max-age = 10' );

diag( $r->as_string ) if( $DEBUG );

$current_age = $r->current_age;
$freshness_lifetime = $r->freshness_lifetime;

diag( "current_age = $current_age" ) if( $DEBUG );
diag( "freshness_lifetime = $freshness_lifetime" ) if( $DEBUG );

ok( $current_age >= 300, 'current_age' );
is( $freshness_lifetime, 10, 'freshness_lifetime' );

# should return something
ok( $r->fresh_until, 'fresh_until' );
# should return something
ok( $r->fresh_until( heuristic_expiry => 0 ), 'fresh_until with heuristic_expiry set to 0' );

diag( "Creating a response object from parsing response string:\n", $r->as_string( "\x0d\x0a" ) ) if( $DEBUG );
my $r2 = HTTP::Promise::Response->parse( $r->as_string( "\x0d\x0a" ) );
diag( HTTP::Promise::Response->error ) if( $DEBUG && !defined( $r2 ) );
is( $r2->status, 'OK', 'status() returns as expected' );

my @h = $r2->header( 'Cache-Control' );
is( @h, 2, 'multiple headers instances' );

$r->remove_header( 'Cache-Control' );

# should still return something
ok( $r->fresh_until, 'fresh_until' );
is( $r->fresh_until( heuristic_expiry => 0 ), undef, 'fresh_until with heuristic_expiry set to 0' );

is( $r->redirects->length, 0, 'no redirect yet' );
diag( "Setting previous response to '$r2'" ) if( $DEBUG );
$r->previous( $r2 );
is( Scalar::Util::refaddr( $r->previous ), Scalar::Util::refaddr( $r2 ), 'previous' );
is( $r->redirects->length, 1, 'redirects -> 1' );

$r->debug( $DEBUG ) if( $DEBUG );
my $clone = $r->clone;
diag( "Unable to clone response object: ", $r->error ) if( $DEBUG && !defined( $r ) );
diag( "Setting 2nd previous response to '$clone'" ) if( $DEBUG );
$r2->previous( $clone );
is( $r->redirects->length, 2, 'redirects -> 2' );
for( $r->redirects->list )
{
    ok( $_->is_success, "redirect is_success" );
}

is( $r->base, $r->request->uri, 'base = request->uri' );
$r->push_header( 'Content-Location', '/1/A/a' );
is( $r->base, 'http://www.example.com/1/A/a', 'Content-Location -> base' );
$r->push_header( 'Content-Base', '/2/;a=/foo/bar' );
is( $r->base, 'http://www.example.com/2/;a=/foo/bar', 'Content-Base -> base' );
$r->push_header( 'Content-Base', '/3/' );
is( $r->base, 'http://www.example.com/2/;a=/foo/bar', 'additional Content-Base does not affect base' );

{
	my @warn;
	local $SIG{__WARN__} = sub{ push( @warn, @_ ); };
	no warnings;
	$r2 = HTTP::Promise::Response->parse( undef );
	is( $#warn, -1, 'response parse no warning' );
	use warnings;
	$r2 = HTTP::Promise::Response->parse( undef );
	is( $#warn, 0, 'response parse use warning' );
	like( $warn[0], qr/Undefined argument to/, 'response parse warning' );
}
is( $r2->code, undef , 'code');
is( $r2->status, undef, 'status' );
is( $r2->protocol, undef, 'protocol' );
is( $r2->status_line, "000 Unknown code", 'status_line' );
$r2->protocol( 'HTTP/1.0' );
is( $r2->as_string( "\n" ), "HTTP/1.0 000 Unknown code\n\n", 'as_string' );
is( $r2->dump, "HTTP/1.0 000 Unknown code\n\n(no content)\n", 'dump' );
is( $r2->current_age, 0, 'current_age' );
is( $r2->freshness_lifetime, 3600, 'freshness_lifetime' );
is( $r2->freshness_lifetime( h_default => 900 ), 900, 'freshness_lifetime' );
is( $r2->freshness_lifetime( h_min => 7200 ), 7200, 'freshness_lifetime' );
is( $r2->freshness_lifetime( time => time ), 3600, 'freshness_lifetime' );
$r2->last_modified( time - 900 );
is( $r2->freshness_lifetime, 90, 'freshness_lifetime' );
is( $r2->freshness_lifetime( h_lastmod_fraction => 0.2 ), 180, 'freshness_lifetime' );
is( $r2->freshness_lifetime( h_min => 300 ), 300, 'freshness_lifetime' );
$r2->last_modified( time - 1000000 );
is( $r2->freshness_lifetime( h_max => 7200 ), 7200, 'freshness_lifetime' );
is( $r2->freshness_lifetime( heuristic_expiry => 0 ), undef, 'freshness_lifetime' );
is( $r2->freshness_lifetime( heuristic_expiry => 1 ), 86400, 'freshness_lifetime' );
ok( $r2->is_fresh( time => time ), 'is_fresh' );
ok( $r2->fresh_until( time => time + 10 ), 'fresh_until' );

$r2->client_date(1);
# Allow 10s for slow boxes
diag( "Current age is: ", $r2->current_age, " (", overload::StrVal( $r2->current_age ), ")" ) if( $DEBUG );
# cmp_ok( abs( time - $r2->current_age->as_string ), '<', 10);
my $time_diff = time - $r2->current_age;
diag( "Time diff is '$time_diff' (", overload::StrVal( $time_diff ), ")" ) if( $DEBUG );
cmp_ok( abs( "$time_diff" ), '<', 10, 'current_age' );
is( $r2->freshness_lifetime, 60, 'freshness_lifetime' );
$r2->date( time );
$r2->header( Age => -1 );
# Allow 10s for slow boxes
$time_diff = time - $r2->current_age;
cmp_ok( abs( "$time_diff" ), '<', 10, 'current_age' );
diag( "\$r2->freshness_lifetime is '", $r2->freshness_lifetime, "'" ) if( $DEBUG );
$r2->debug( $DEBUG );
is( $r2->freshness_lifetime, 86400, 'freshness_lifetime' );
$req = HTTP::Promise::Request->new;
$r2->request( $req );

# Allow 10s for slow boxes
$time_diff = time - $r2->current_age;
cmp_ok( abs( "$time_diff" ), '<', 10, 'current_age' );
$req->date(2);
$r2->request( $req );

# Allow 10s for slow boxes
$time_diff = time - $r2->current_age;
cmp_ok( abs( "$time_diff" ), '<', 10, 'current_age' );

$r2->debug( $DEBUG ) if( $DEBUG );
$r2->header( 'Content-Disposition' => "attachment; filename=foo.txt\n" );
is( $r2->filename, 'foo.txt', 'filename' );
$r2->header( 'Content-Disposition' => "attachment; filename=\n" );
is( $r2->filename, undef, 'filename' );
$r2->header( 'Content-Disposition' => "attachment\n" );
is( $r2->filename, undef, 'filename' );
$r2->header( 'Content-Disposition' => "attachment; filename==?US-ASCII?B?Zm9vLnR4dA==?=\n" );
is( $r2->filename, 'foo.txt', 'filename' );
$r2->header( 'Content-Disposition' => "attachment; filename==?NOT-A-CHARSET?B?Zm9vLnR4dA==?=\n" );
is( $r2->filename, '=?NOT-A-CHARSET?B?Zm9vLnR4dA==?=', 'filename' );
$r2->header( 'Content-Disposition' => "attachment; filename==?US-ASCII?Z?Zm9vLnR4dA==?=\n" );
is( $r2->filename, '=?US-ASCII?Z?Zm9vLnR4dA==?=', 'filename' );
$r2->header( 'Content-Disposition' => "attachment; filename==?US-ASCII?Q?foo.txt?=\n" );
is( $r2->filename, 'foo.txt', 'filename' );
$r2->remove_header ('Content-Disposition' );
$r2->header( 'Content-Location' => '/tmp/baz.txt' );
is( $r2->filename, 'baz.txt', 'filename' );
$r2->remove_header( 'Content-Location' );
$req->uri( 'http://www.example.com/bar.txt' );
is( $r2->filename, 'bar.txt', 'filename' );

done_testing();

__END__

