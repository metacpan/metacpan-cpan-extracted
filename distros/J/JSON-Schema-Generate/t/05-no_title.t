use Test::More;

use strict;
use JSON::Schema::Generate;

my $data1 = '{
	"links" : {
		"cpantesters_reports" : "http://cpantesters.org/author/L/LNATION.html",
		"cpan_directory" : "http://cpan.org/authors/id/L/LN/LNATION",
		"metacpan_explorer" : "https://explorer.metacpan.org/?url=/author/LNATION",
		"cpantesters_matrix" : "http://matrix.cpantesters.org/?author=LNATION",
		"cpants" : "http://cpants.cpanauthors.org/author/LNATION",
		"backpan_directory" : "https://cpan.metacpan.org/authors/id/L/LN/LNATION"
	},
	"city" : "PLUTO",
	"updated" : "2020-02-16T16:43:51",
	"region" : "GHANDI",
	"is_pause_custodial_account" : false,
	"country" : "WO",
	"website" : [
		"https://www.lnation.org"
	],
	"asciiname" : "Robert Acock",
	"gravatar_url" : "https://secure.gravatar.com/avatar/8e509558181e1d2a0d3a5b55dec0b108?s=130&d=identicon",
	"pauseid" : "LNATION",
	"email" : [
		"lnation@cpan.org"
	],
	"release_count" : {
		"cpan" : 378,
		"backpan-only" : 34,
		"latest" : 114
	},
	"name" : "Robert Acock",
	"other": [
		true,
		null,
		"string",
		10
	]
}';

my $data2 = '{
	"asciiname" : "",
	"release_count" : {
		"latest" : 56,
		"backpan-only" : 358,
		"cpan" : 190
	},
	"name" : "Damian Conway",
	"email" : "damian@conway.org",
	"is_pause_custodial_account" : false,
	"gravatar_url" : "https://secure.gravatar.com/avatar/3d4a6a089964a744d7b3cf2415f81951?s=130&d=identicon",
	"links" : {
		"cpants" : "http://cpants.cpanauthors.org/author/DCONWAY",
		"cpan_directory" : "http://cpan.org/authors/id/D/DC/DCONWAY",
		"cpantesters_matrix" : "http://matrix.cpantesters.org/?author=DCONWAY",
		"cpantesters_reports" : "http://cpantesters.org/author/D/DCONWAY.html",
		"backpan_directory" : "https://cpan.metacpan.org/authors/id/D/DC/DCONWAY",
		"metacpan_explorer" : "https://explorer.metacpan.org/?url=/author/DCONWAY"
	},
	"pauseid" : "DCONWAY",
	"website" : [
		"http://damian.conway.org/"
	],
	"other": [
		null,
		false
	]
}';

my $schema = JSON::Schema::Generate->new(
	id => 'https://metacpan.org/author.json',
	title => 'The CPAN Author Schema',
	description => 'A representation of a cpan author.',
	no_title => 1
)->learn($data1)->learn($data2)->generate;

my $schema_file = 't/schemas/schema-no_title.json';
if ($ENV{GENERATE_SCHEMA_FILES} == 1) {
  open my $fh, '>', $schema_file;
  print $fh $schema;
  close $fh;
}

my $schema_from_file;
{
  local($/) = undef;
  open my $fh, "<", $schema_file or die "Failed to open '$schema_file'... $!";
  $schema_from_file = <$fh>;
  close $fh;
}

is ($schema, $schema_from_file, "schema matched previously generated");

use JSON::Schema;
my $validator = JSON::Schema->new($schema);
my $result = $validator->validate($data1);
ok($result);
done_testing;
