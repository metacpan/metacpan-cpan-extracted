use Test::More tests => 24;

use Logfile::EPrints;

my $accesslog = <<EOL;
127.0.0.1 - - [03/May/2005:05:49:19 +0100] "GET /9055/02/ECDL__2004__handout_abstract.pdf HTTP/1.0" 200 - "-" "htdig/3.1.6 (_wmaster\@soton.ac.uk)"
127.0.0.1 - - [03/May/2005:05:50:19 +0100] "GET /9055/02/ECDL__2004__handout_abstract.pdf HTTP/1.0" 200 - "-" "htdig/3.1.6 (_wmaster\@soton.ac.uk)"
127.0.0.1 - - [03/May/2005:05:51:19 +0100] "GET /9055/02/ECDL__2004__handout_abstract.pdf HTTP/1.0" 200 - "-" "htdig/3.1.6 (_wmaster\@soton.ac.uk)"
127.0.0.1 - - [03/May/2005:06:49:19 +0100] "GET /9055/02/ECDL__2004__handout_abstract.pdf HTTP/1.0" 200 - "-" "htdig/3.1.6 (_wmaster\@soton.ac.uk)"

EOL

my @hits = map {
	Logfile::EPrints::Hit::Combined->new($_)
} split /\n/, $accesslog;

my $session;
my $handler = Logfile::EPrints::Mapping::EPrints->new(
	identifier => 'foo',
	handler => Logfile::EPrints::Filter::Session->new(
	handler => MyHandler->new( session => \$session ),
));
$handler->hit( $hits[0] );

is($session->{first_seen},1115095759,'first_seen');

$handler->hit( $hits[1] );

is($session->{last_seen},1115095819,'last_seen');

$handler->hit( $hits[2] );

is($session->{address},'127.0.0.1','address');

$handler->hit( $hits[3] );

is($session->{first_seen},1115099359,'session_end');

$handler = Logfile::EPrints::Mapping::EPrints->new(
	identifier => 'foo',
	handler => Logfile::EPrints::Filter::Session->new(
	handler => Logfile::EPrints::Filter::MaxPerSession->new(
	fulltext => 10,
	handler => MyHandler->new( session => \$session ),
)));

%Logfile::EPrints::Filter::Session::SESSIONS = ();

for(1..10)
{
	# hack to generate unique identifiers
	$handler->{identifier} = ">>iter$_<<";
	is($handler->hit( $hits[0] ),"OK","(Queueing for Max Fulltext=10)");
}
$handler->{identifier} = ">>last<<";
is(ref(my $negate = $handler->hit( $hits[0] )),"Logfile::EPrints::Hit::Negate","Maxed out");

is($negate->address,"127.0.0.1","Hit::Negate blow-back");

$handler = Logfile::EPrints::Mapping::EPrints->new(
	identifier => 'foo',
	handler => Logfile::EPrints::Filter::Session->new(
	handler => MyHandler->new( session => \$session ),
));

%Logfile::EPrints::Filter::Session::SESSIONS = ();
$Logfile::EPrints::Filter::Session::TIDY_ON = 4;

# Set up the session
$handler->hit( $_ ) for @hits[0..2];

ok(exists($Logfile::EPrints::Filter::Session::SESSIONS{$hits[0]->address}),"Session Init");

my $hit = bless $hits[3], ref($hits[3]);
$hit->{address} = "127.0.0.2";

ok($hit->address eq "127.0.0.2","Changed address");

$handler->hit( $hit );

ok(exists($Logfile::EPrints::Filter::Session::SESSIONS{$hit->address}),"Second Session");
ok(scalar(keys(%Logfile::EPrints::Filter::Session::SESSIONS)) == 2,"Two Sessions");

$handler->hit( $hit ); # Should trigger tidyup

ok(!exists($Logfile::EPrints::Filter::Session::SESSIONS{$hits[0]->address}),"Session Removed");

$accesslog = <<EOL;
127.0.0.1 - - [03/May/2006:05:49:17 +0100] "GET /9055/ HTTP/1.0" 200 - "-" "htdig/3.1.6 (_wmaster\@soton.ac.uk)"
127.0.0.1 - - [03/May/2006:05:49:19 +0100] "GET /9055/02/ECDL__2004__handout_abstract.pdf HTTP/1.0" 200 - "-" "htdig/3.1.6 (_wmaster\@soton.ac.uk)"
127.0.0.1 - - [03/May/2006:05:49:21 +0100] "GET /9055/02/ECDL__2004__handout_abstract.pdf HTTP/1.0" 200 - "-" "htdig/3.1.6 (_wmaster\@soton.ac.uk)"
127.0.0.1 - - [03/May/2006:05:49:23 +0100] "GET /9056/02/ECDL__2004__handout_abstract.pdf HTTP/1.0" 200 - "-" "htdig/3.1.6 (_wmaster\@soton.ac.uk)"

EOL

@hits = map {
	Logfile::EPrints::Hit::Combined->new($_)
} split /\n/, $accesslog;

$handler->hit( $hits[0] ); # abstract
$handler->hit( $hits[1] ); # fulltext

is($hits[1]->{abstract_referrer}, $hits[0], "abstract referrer");

$handler->hit( $hits[2] ); # repeated fulltext

is($hits[2]->{abstract_referrer}, $hits[0], "abstract referrer");

$handler->hit( $hits[3] ); # different fulltext

ok(!defined($hits[3]->{abstract_referrer}), "no prior abstract");

package MyHandler;

sub new
{
	my( $class, %self ) = @_;
	bless \%self, $class;
}

sub abstract {}

sub fulltext
{
	my( $self, $hit ) = @_;
	${$self->{session}} = $hit->{session};
	return "OK";
}

1;
