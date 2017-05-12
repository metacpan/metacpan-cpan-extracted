use strict;
use Lingua::LinkParser;

## outputs a fancy postscript linkage diagram

my $parser = new Lingua::LinkParser(verbosity => 0, display_on => 0);

$parser->opts('max_null_count' => 3);
$parser->opts('min_null_count' => 1);

my $sentence = $parser->create_sentence("This is cool.");

#open PSFH, ">postscript.ps";
#print PSFH $parser->get_postscript($sentence->linkage(1));

print $parser->get_postscript($sentence->linkage(1), 1);

#close PSFH;

