use Test::More;

use Feed::Data::BBC;

use Feed::Data;

my $bbc = Feed::Data::BBC->new();

my $england = $bbc->england;

$england->parse();

my $raw = $england->render('raw');

my $latin = $bbc->latin_america;

$latin->parse();

my $raw2 = $latin->render('styled_table');

open my $fh, '>', 'okay.html'; 
print $fh $raw2;
close $fh;

ok(1);

done_testing();
