use warnings;
use strict;
use Test::More;

# <test-body>

use Encode;

require_ok('HTML5::DOM');

my $encodings = ["WINDOWS-1251", "KOI8-U", "KOI8-R", "UTF-16LE", "UTF-8"];
my $test_str = "тест test :)";

for my $enc (@$encodings) {
	my $parser;
	
	my $from_str = $test_str;
	Encode::from_to($from_str, "UTF-8", $enc);
	
	my $to_str = $from_str;
	Encode::from_to($to_str, $enc, "UTF-8");
	
	$parser = HTML5::DOM->new({encoding => $enc});
	ok($parser->parse($from_str)->body->text eq $to_str, $enc.' - set encoding in new()');
	
	$parser = HTML5::DOM->new;
	ok($parser->parse($from_str, {encoding => $enc})->body->text eq $to_str, $enc.' - set encoding in parse()');
	
	$parser = HTML5::DOM->new;
	
	my ($enc_id) = HTML5::DOM::Encoding::detectAuto($to_str);
	if (!$enc_id) {
		ok($parser->parse($from_str, {default_encoding => $enc})->body->text eq $to_str, $enc.' - set default_encoding in parse()');
	}
}

done_testing;

# </test-body>
