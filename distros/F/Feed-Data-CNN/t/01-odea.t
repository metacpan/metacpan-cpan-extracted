use Test::More;

use Feed::Data::CNN;

use Feed::Data;

my $cnn = Feed::Data::CNN->new();

my $showbiz = $cnn->showbiz;

=pod
$england->parse();

my $raw = $england->render('raw');

my $latin = $bbc->latin_america;

$latin->parse();

my $raw2 = $latin->render('raw');
=cut

ok(1);

done_testing();
