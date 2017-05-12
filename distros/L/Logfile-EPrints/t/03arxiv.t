use Test::More tests => 15;

use Logfile::EPrints;
ok(1);

my $logline = 'hal9032.cs.uiuc.edu - - [03/Jul/2005:07:10:09 +0100] "GET /robots.txt" HTTP/1.0" 200 889 "-" ""Mozilla/5.0 (X11; U; Linux i686;en-US; rv:1.2.1) Gecko/20030225""';
my $hit = Logfile::EPrints::Hit::arXiv->new($logline);
ok($hit);
is($hit->hostname, 'hal9032.cs.uiuc.edu', 'hostname');
is($hit->code, '200', 'code');
is($hit->datetime, '20050703061009', 'datetime');
is($hit->page, '/robots.txt', 'page');

$logline = 'bigbird-l1.webworksgy.com - - [27/Aug/2005:04:00:32 +0100] [Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.7.8) Gecko/20050511 Firefox/1.0.4|-|0|http://uk.arxiv.org/abs/nlin.AO/0411066] "GET /pdf/nlin.AO/0411066 HTTP/1.0" 302 238';
$hit = Logfile::EPrints::Hit::Bracket->new($logline);
ok($hit);
is($hit->hostname, 'bigbird-l1.webworksgy.com', 'hostname webworksgy');
is($hit->page, '/pdf/nlin.AO/0411066', 'page pdf');
is($hit->code, 302, 'code 302');

my $handler;

$logline = '158.202.191.203.dynamic.qld.chariot.net.au - - [14/Aug/2007:14:24:31 +0100] [Mozilla/5.0 (Macintosh; U; Intel Mac OS X; en) AppleWebKit/417.9 (KHTML, like Gecko) Safari/417.8|-|51|http://front.math.ucdavis.edu/math.MP/0707?o=50] "GET /PS_cache/arxiv/pdf/0707/0707.2431v1.pdf HTTP/1.1" 200 216083';
$hit = Logfile::EPrints::Hit::Bracket->new($logline);

$handler = Handler->new;
Logfile::EPrints::Mapping::arXiv->new(
	handler => $handler
)->hit( $hit );

is($handler->{type}, 'fulltext', 'Fulltext hit');
is($hit->{identifier}, 'oai:arXiv.org:0707.2431', 'Identifier mapping');

$logline = 'hamster.dur.ac.uk - - [20/Aug/2007:19:06:56 +0100] [Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.7.13) Gecko/20060508 Fedora/1.7.13-1.2.1.legacy|-|0|http://xxx.soton.ac.uk/abs/0708.1199] "GET /pdf/0708.1199 HTTP/1.0" 200 66070';
$hit = Logfile::EPrints::Hit::Bracket->new($logline);

$handler = Handler->new;
Logfile::EPrints::Mapping::arXiv->new(
	handler => $handler
)->hit( $hit );

is($handler->{type}, 'fulltext', 'Fulltext hit');
is($hit->{identifier}, 'oai:arXiv.org:0708.1199', 'Identifier mapping');

ok(1);

package Handler;

use vars qw( $AUTOLOAD );

sub new { bless { type => '' }, shift }

sub fulltext {
	my ($self,$hit) = @_;
	$self->{type} = 'fulltext';
#	warn $hit->homepage." => ".$hit->institution."\n" if $hit->homepage;
#	warn "fulltext: " . $hit->country . "/" . $hit->identifier . "/" . $hit->datetime . "\n";
}

sub repeated {
	my ($self,$hit) = @_;
	$self->{type} = 'repeated';
#	warn sprintf("repeated: %s/%s/%s", $hit->identifier, $hit->address, $hit->datetime);
}

sub abstract {
	my ($self,$hit) = @_;
	$self->{type} = 'abstract';
#	warn "abstract: " . $hit->country . "/" . $hit->identifier . "\n";
}

sub browse {
	my ($self,$hit) = @_;
	$self->{type} = 'browse';
#	warn "browse: " . $hit->section . "\n";
}

sub search {
	my ($self,$hit) = @_;
	$self->{type} = 'search';
#	my $uri = URI->new($hit->path,'http');
#	warn "search: " . join(',',$uri->query_form) . "\n";
}

sub DESTROY {}

sub AUTOLOAD {
	my $self = shift;
	$AUTOLOAD =~ s/^.*:://;
	warn "$AUTOLOAD\n";
}
