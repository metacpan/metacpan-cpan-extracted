use Locale::Country;
use YAML::Syck;
use LWP::Simple;
use Time::HiRes 'usleep';

Locale::Country::rename_country('tw' => 'Taiwan');

my $gmap_apikey = shift;

my $results;
for my $code (all_country_codes) {
    my $name = code2country($code);
    $content = get("http://maps.google.com/maps/geo?output=csv&q=$name&key=$gmap_apikey");
    if ($content =~ m/\n/) {
	warn "===> ambiguous results for $code / $name";
	next;
    }
    $results->{$code} = [(split /,/, $content)[2,3]];
    usleep 200;
}

DumpFile('output.yml', $results);

1;
