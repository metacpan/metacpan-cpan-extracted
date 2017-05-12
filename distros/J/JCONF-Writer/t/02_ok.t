use strict;
use JCONF::Writer;
use Test::More;

eval {
	require Parse::JCONF;
};
if ($@) {
	plan skip_all => 'Parse::JCONF not installed';
}

my $writer = JCONF::Writer->new;
my $parser = Parse::JCONF->new;
my $cfg;

$cfg = {a => 1, b => 2, c => 3};
is_deeply($parser->parse($writer->from_hashref($cfg)), $cfg, 'simple hash');

$cfg = {
	wiki => {
		links => [
			{href => "ru.wikipedia.org", text => "ru"},
			{href => "en.wikipedia.org", text => "en"},
			{href => "de.wikipedia.org", text => "de"},
		]
	},
	version => {
		text => "1.900",
		num  => 1.9
	},
	description => "Wikipedia -- the free encyclopedia"
};
is_deeply($parser->parse($writer->from_hashref($cfg)), $cfg, 'difficult hash');

$cfg = {esc => q!"The string" \\!};
is_deeply($parser->parse($writer->from_hashref($cfg)), $cfg, 'escapes');

done_testing;
