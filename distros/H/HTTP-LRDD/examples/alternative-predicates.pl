use Data::Dumper;
use HTTP::LRDD;
use RDF::TrineX::Functions -shortcuts;

my $lrdd   = HTTP::LRDD->new;
my $lrdd_h = HTTP::LRDD->new(qw(hub));
my $lrdd_c = HTTP::LRDD->new(qw(copyright));

my $output = {};

foreach my $uri (qw(http://localhost/foo ftp://localhost/bar http://localhost/test/test.atom))
{
	$output->{$uri}->{'descriptors'} = [ $lrdd->discover($uri) ];
	$output->{$uri}->{'hubs'} =        [ $lrdd_h->discover($uri) ];
	$output->{$uri}->{'copyright'} =   [ $lrdd_c->discover($uri) ];
}

print Dumper( $output );

# XRD::Parser::hostmeta - check HTTPS before HTTP.
