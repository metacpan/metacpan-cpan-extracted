use 5.012;
use warnings;
use Test::More;
use Test::Warnings;

use Geo::Geos::Envelope;

use Geo::Geos::Index::STRtree;

subtest "STRtree" => sub {
    my $t = Geo::Geos::Index::STRtree->new;
    ok $t;

    my $p1 = ['p1'];
    my $e1 = Geo::Geos::Envelope->new(1, 2, 3, 4);
    $t->insert($e1, $p1);
    is_deeply $t->query($e1), [$p1];

    my @visited;
    $t->query($e1, sub { push @visited, @_; });
    is_deeply \@visited, [$p1];

    $t->remove($e1, $p1); # ??? should be true
    is_deeply $t->query($e1), [];

    subtest "safety check" => sub {
        my $t = Geo::Geos::Index::STRtree->new;
        my $e1 = Geo::Geos::Envelope->new(1, 2, 3, 4);
        my $p1 = ['p1'];
        $t->insert($e1, $p1);
        undef $p1;
        is_deeply $t->query($e1), [['p1']];
    };
};

done_testing;
