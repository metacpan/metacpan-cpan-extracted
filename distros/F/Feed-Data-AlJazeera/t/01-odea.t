use Test::More;

use Feed::Data::AlJazeera;

use Feed::Data;

my $bbc = Feed::Data::AlJazeera->new();

my $english = $bbc->english;

=pod
$english->parse();

my $raw = $english->render('raw');
=cut

ok(1);

done_testing();
