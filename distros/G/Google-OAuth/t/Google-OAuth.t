# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Google-OAuth.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 37 ;
BEGIN { 
	use_ok('Google::OAuth') ;
	use_ok('Google::OAuth::Install') ;
	use_ok('Google::OAuth::Config') ;
	use_ok('LWP::UserAgent') ;
	use_ok('JSON') ;
	use_ok('NoSQL::PL2SQL') ;
	use_ok('NoSQL::PL2SQL::DBI') ;
	};

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

sub linkcompare {
	my @links = map { join '', sort split //, $_ } @_ ;
	return $links[0] eq $links[1] ;
	}

my @test ;
push @test, split /\n/, <<'eof' ;
https://accounts.google.com/o/oauth2/auth?response_type=code&approval_prompt=force&redirect_uri=XFygUanB0BYszi3ehzNxfJM5BBV6xkSm7CcKmEAo&client_id=Js6XzxwxR9KA0g0kkEdEFjPPyv9kNKLfmfUuhu3A&access_type=offline&scope=https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fcalendar.readonly
https://accounts.google.com/o/oauth2/auth?response_type=code&approval_prompt=force&redirect_uri=XFygUanB0BYszi3ehzNxfJM5BBV6xkSm7CcKmEAo&client_id=Js6XzxwxR9KA0g0kkEdEFjPPyv9kNKLfmfUuhu3A&access_type=offline&scope=https%3A%2F%2Fwww.google.com%2Fm8%2Ffeeds+https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fcalendar+https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fcalendar.readonly+https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fdrive.readonly
https://accounts.google.com/o/oauth2/auth?response_type=code&approval_prompt=force&redirect_uri=XFygUanB0BYszi3ehzNxfJM5BBV6xkSm7CcKmEAo&client_id=FTNmkFXfh6OZH5jXsW7qLe3bgsnl7ZObPfsuscNy&access_type=offline&scope=https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fcalendar.readonly
https://accounts.google.com/o/oauth2/auth?client_id=FTNmkFXfh6OZH5jXsW7qLe3bgsnl7ZObPfsuscNy&foo=client_secret&scope=https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fcalendar.readonly
timeZone=America%2FNew_York&description=US+Holidays&colorId=15&accessRole=reader&etag=%22GZxpEFttRDAOmLHnWRxLHHWPGwk%2FkomAuKJmJeZLAvxlc0nIjOqTkKA%22&kind=calendar%23calendarListEntry&foregroundColor=%23000000&summary=US+Holidays&id=en.usa%23holiday%40group.v.calendar.google.com&backgroundColor=%239fc6e7&selected=true
eof

my $token = bless( {
                 'refresh_token' => '1/uZmWq1bdeLR5AnjD3yTV1Q93BSxL1wjeulxSzVaAbq8',
                 'expires_in' => '3600',
                 'emailkey' => 'perlmonster@gmail.com',
                 'requested' => 1366410947,
                 'access_token' => 'ya29.Et6DoQjLzjpioHPGbMyDeGfUS00SuTlIrIsZE_FIDzXtU0IJ1-AnAg',
                 'token_type' => 'Bearer'
               }, 'Google::OAuth' );

my $json = <<'eof' ;
{
 "kind": "calendar#calendarList",
 "etag": "\"GZxpEFttRDAOmLHnWRxLHHWPGwk/PlPjmjzcESbTBnWfLUd5E8QtBFI\"",
 "items": [
  {
   "kind": "calendar#calendarListEntry",
   "etag": "\"GZxpEFttRDAOmLHnWRxLHHWPGwk/rlBZV92t2W1zCqj28DRxbmcr5Fs\"",
   "id": "#contacts@group.v.calendar.google.com",
   "summary": "Contacts' birthdays and events",
   "description": "Your contacts' birthdays and anniversaries",
   "timeZone": "America/New_York",
   "colorId": "12",
   "backgroundColor": "#fad165",
   "foregroundColor": "#000000",
   "selected": true,
   "accessRole": "reader"
  },
  {
   "kind": "calendar#calendarListEntry",
   "etag": "\"GZxpEFttRDAOmLHnWRxLHHWPGwk/komAuKJmJeZLAvxlc0nIjOqTkKA\"",
   "id": "en.usa#holiday@group.v.calendar.google.com",
   "summary": "US Holidays",
   "description": "US Holidays",
   "timeZone": "America/New_York",
   "colorId": "15",
   "backgroundColor": "#9fc6e7",
   "foregroundColor": "#000000",
   "selected": true,
   "accessRole": "reader"
  }
 ]
}
eof

my $item = {
               'timeZone' => 'America/New_York',
               'colorId' => '15',
               'description' => 'US Holidays',
               'accessRole' => 'reader',
               'etag' => '"GZxpEFttRDAOmLHnWRxLHHWPGwk/komAuKJmJeZLAvxlc0nIjOqTkKA"',
               'kind' => 'calendar#calendarListEntry',
               'foregroundColor' => '#000000',
               'summary' => 'US Holidays',
               'id' => 'en.usa#holiday@group.v.calendar.google.com',
               'selected' => 'true',
               'backgroundColor' => '#9fc6e7'
             } ;

my $t ;
my $ok ;

is( Google::OAuth->dsn->table, 'googletokens', 'DSN name' ) ;
is( ref Google::OAuth->dsn->db, 'NoSQL::PL2SQL::DBI::Null', 'DSN source' ) ;

$t = Google::OAuth::Client->new->scope(
                'calendar.readonly' 
		)->token_request ;
ok( linkcompare( $t, $test[0] ), 'Default credentials' ) ;

$t = Google::OAuth::Client->new->scope(
		'm8.feeds', 'calendar', 'calendar.readonly', 'drive.readonly', 
		)->token_request ;
ok( linkcompare( $t, $test[1] ), 'Expanded scope' ) ;


my @credentials = qw(
	client_id
	FTNmkFXfh6OZH5jXsW7qLe3bgsnl7ZObPfsuscNy
	client_secret
	Op6MR5gl73VY2yJkrb86dT4iySguvM8HhSqC2dEm
	) ;

is( Google::OAuth->setclient( @credentials ), undef, 'setclient' ) ;

$t = Google::OAuth::Client->new->scope(
                'calendar.readonly' 
		)->token_request ;
ok( linkcompare( $t, $test[2] ), 'Modified credentials' ) ;

$t = Google::OAuth::Client->new(
		'client_id', { foo => 'client_secret' }
		)->scope(
                'calendar.readonly' 
		)->token_request ;
ok( linkcompare( $t, $test[3] ), 'token_request override' ) ;

is( ref $token, 'Google::OAuth', 'Test token found' ) ;
is( $Google::OAuth::Config::test{grantcode}, 
		'1/fk7qwDysHKcwfa2S8ZKWTv2-nwTfxpPva3dzmujc_gQ', 
		'Grant Code found' ) ;

my $event = Google::OAuth::CGI->new( $item )->query_string ;
ok( linkcompare( $event, $test[4] ), 'CGI::Simple object' ) ;

my $tqis = 'http://www.tqis.com/pen/GoogleAuth/test.htm' ;

is( $token->response( GET => $tqis )->code, 200, 'token response GET' ) ;

my $request = $token->request( POST => $tqis, $event ) ;

my @headers = %{ $request->headers } ;
my %headers = map { $_ => 1 } (
  'content-type',
  'application/x-www-form-urlencoded',
  'content-length',
  '319',
  'authorization',
  'Bearer ya29.Et6DoQjLzjpioHPGbMyDeGfUS00SuTlIrIsZE_FIDzXtU0IJ1-AnAg'
  ) ;
map { delete $headers{$_} } @headers ;

is( @headers, 6, 'POST request header keys' ) ;
is( keys %headers, 0, 'POST request header values' ) ;
is( $request->content(), $event, 'POST request content' ) ;

my $response = LWP::UserAgent->new->request( $request ) ;
is( $response->code, 200, 'token request POST' ) ;
my $content = $response->content ;
chomp( $content ) ;
is( $content, $event, 'POST request response content' ) ;

$reponse = $token->response( POST => $tqis, $event ) ;
is( $response->code, 200, 'token response POST' ) ;

$content = $response->content ;
chomp( $content ) ;
is( $content, $event, 'POST response content' ) ;

$content = $token->content( POST => $tqis, $event ) ;
chomp( $content ) ;
is( $content, $event, 'POST content' ) ;

$reponse = $token->response( POST => $tqis, $event ) ;
is( $token->response( GET => $tqis )->code, 200, 'token response GET' ) ;

is( length( $json ), 987, 'json scalar found' ) ;

my $google = Google::OAuth->get_token( 'redirect_uri', 
			{ code => $Google::OAuth::Config::test{grantcode} },
			{ grant_type => 'authorization_code' } ) ;
ok( ref $google, ref $google? 'get_token': $google || 'no output' ) ;

my $grant = Google::OAuth->grant_code( 
		$Google::OAuth::Config::test{grantcode} ) ; 
is( ref $grant, ref $token, 'grant_code blessed' ) ;
is( $grant->{error}, 'invalid_request', 'grant_code error' ) ;
is( scalar keys %$grant, 2, 'grant_code keys' ) ;
map { delete $grant->{$_} } qw( requested error ) ;
is( scalar keys %$grant, 0, 'grant_code elements' ) ;

my $rr = 'refresh_token' ;
my $access = Google::OAuth->get_token( 
			{ $rr => $token->{$rr} }, 
			{ grant_type => $rr } 
			) ;
is( ref $access, ref $token, 'access token blessed' ) ;
is( $access->{error}, 'invalid_client', 'access token error' ) ;
is( scalar keys %$access, 2, 'access token keys' ) ;
map { delete $access->{$_} } qw( requested error ) ;
is( scalar keys %$access, 0, 'access token elements' ) ;

1
