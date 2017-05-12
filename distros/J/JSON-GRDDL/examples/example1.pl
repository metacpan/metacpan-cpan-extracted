use 5.010;
use lib "lib";
use JSON::GRDDL;
use LWP::Simple qw[get];
use RDF::TrineShortcuts;

my $grddl = JSON::GRDDL->new;

my $url   = 'http://buzzword.org.uk/2008/jsonGRDDL/example1.json';
my $model = $grddl->data(get($url), $url);
print rdf_string($model, 'turtle');
