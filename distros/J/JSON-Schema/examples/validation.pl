use lib 'JSON-Hyper/lib';
use lib 'JSON-Schema/lib';
use DateTime;
use JSON qw[from_json to_json];
use JSON::Hyper;
use JSON::Schema;
use LWP::Simple qw[get];

my $instance  = from_json(<<'JSON');
{
	"fn"   : [ "Toby Inkster" ],
	"givenName"  : "Toby",
	"familyName" : "Inkster",
	"adr" : {"country-name":"England","region":"East Sussex","locality":"Lewes"}
}
JSON

#$instance->{'givenName'} = DateTime->now;

$JSON::Hyper::DEBUG = 1;
my $schema    = get('http://json-schema.org/card');
my $validator = JSON::Schema->new($schema);
my $result    = $validator->validate($instance);

print $result ? "Valid\n" : "Invalid\n";
unless ($result)
{
	print "    ERRORS\n";
	foreach my $e ($result->errors)
	{
		print "    - $e\n";
		foreach (qw(title description))
		{
			print "      ".uc($_).": ".$e->{$_}."\n"
				if defined $e->{$_};
		}
	}	
}
