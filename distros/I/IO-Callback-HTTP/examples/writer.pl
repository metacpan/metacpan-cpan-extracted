use 5.010;
use strict;
use IO::Callback::HTTP;
use HTTP::Request::Common 'POST';
use URI::Escape qw(uri_escape);

my $req = POST
	"http://dbpedia.org/sparql",
	Content_Type => 'application/x-www-form-urlencoded',
	Accept       => 'text/csv',
	;

my $fh = IO::Callback::HTTP->new(">", $req, success => \&done);
printf $fh 'query=%s', uri_escape(
	'SELECT * WHERE { <http://dbpedia.org/resource/Lewes> ?p ?o } LIMIT 1',
);
close $fh or die $!;

sub done
{
	my $res = shift;
	print $res->as_string;
}
