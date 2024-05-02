use Test::More;

use Feed::Data::BBC;

use Feed::Data;

my $bbc = Feed::Data::BBC->new();

my $england = $bbc->england;

=pod
$england->parse();

my $raw = $england->render('raw');

my $latin = $bbc->latin_america;

$latin->parse();

my $raw2 = $latin->render('raw');
=cut

ok(1);

done_testing();
