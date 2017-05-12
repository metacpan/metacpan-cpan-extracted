use Test::More tests => 7;

use Logfile::EPrints;
ok(1);

my $logline = '68.239.101.251 - - [06/Mar/2005:04:29:35 +0000] "GET /9271/01/Microsoft_Word_-_RemiseSenApp031_-_Sensors_and_their_applications_2003_Lime\\xe2\\x80\\xa6.pdf HTTP/1.1" 200 38896 "-" "Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; .NET CLR 1.0.3705)"';
my $hit = Logfile::EPrints::Hit::Combined->new($logline);
ok($hit);
ok($hit->address eq '68.239.101.251');
ok($hit->code eq '200');
ok($hit->datetime eq '20050306042935');

use Logfile::EPrints::Institution;
use Logfile::EPrints::Filter::Repeated;
ok(1);

open my $fh, 'examples/ecs.log' or die $!;

unlink('examples/repeatscache.db.dir');
unlink('examples/repeatscache.db.pag');

my $parser = Logfile::EPrints::Parser->new(
	handler=>Logfile::EPrints->new(
		identifier=>'oai:eprints.ecs.soton.ac.uk:',
		handler=>Logfile::EPrints::Institution->new(
			handler=>my $repeats = Logfile::EPrints::Filter::Repeated->new(
				file => 'examples/repeatscache.db',
				handler=>Handler->new(),
		)),
	),
);
$parser->parse_fh($fh);
close($fh);

is($repeats->{cache}->{'198.235.195.147xoai:eprints.ecs.soton.ac.uk:773'}, 1110068194, 'Repeats filter');

package Handler;

use vars qw( $AUTOLOAD );

sub new { bless {}, shift }

sub fulltext {
	my ($self,$hit) = @_;
#	warn $hit->homepage." => ".$hit->institution."\n" if $hit->homepage;
#	warn "fulltext: " . $hit->country . "/" . $hit->identifier . "/" . $hit->datetime . "\n";
}

sub repeated {
	my ($self,$hit) = @_;
#	warn sprintf("repeated: %s/%s/%s", $hit->identifier, $hit->address, $hit->datetime);
}

sub abstract {
	my ($self,$hit) = @_;
#	warn "abstract: " . $hit->country . "/" . $hit->identifier . "\n";
}

sub browse {
	my ($self,$hit) = @_;
#	warn "browse: " . $hit->section . "\n";
}

sub search {
	my ($self,$hit) = @_;
	my $uri = URI->new($hit->path,'http');
#	warn "search: " . join(',',$uri->query_form) . "\n";
}

sub DESTROY {}

sub AUTOLOAD {
	my $self = shift;
	$AUTOLOAD =~ s/^.*:://;
	warn "$AUTOLOAD\n";
}
