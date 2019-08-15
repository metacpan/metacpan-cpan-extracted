use 5.012;
use warnings;
use Test::More;
use Test::Warnings;

use Geo::Geos::Coordinate;
use Geo::Geos::Envelope;

use Geo::Geos::Index::Quadtree;

subtest "Quadtree" => sub {

    subtest "c-tor, toString, depth, size, insert, remove, queryAll" => sub {
        my $t = Geo::Geos::Index::Quadtree->new;
        ok $t;
        is $t->depth, 1;
        is $t->size, 0;
        is_deeply $t->queryAll, [];

        my $p1 = ['p1'];
        my $e1 = Geo::Geos::Envelope->new(1, 2, 3, 4);
        $t->insert($e1, $p1);

        is_deeply $t->queryAll, [$p1];
        like $t->toString, qr/ITEMS:/;

        $t->remove($e1, $p1); # ??? should be true
        is_deeply $t->queryAll, [];
    };

    subtest "query1" => sub {
        my $t = Geo::Geos::Index::Quadtree->new;
        my $p1 = ['p1'];
        my $e1 = Geo::Geos::Envelope->new(1, 1, 3, 3);
        $t->insert($e1, $p1);

        is_deeply $t->query($e1), [$p1];
    };

    subtest "query2" => sub {
        my $t = Geo::Geos::Index::Quadtree->new;
        my $p1 = ['p1'];
        my $e1 = Geo::Geos::Envelope->new(1, 1, 3, 3);
        $t->insert($e1, $p1);

        my @visited;
        $t->query($e1, sub { push @visited, @_; });
        is_deeply \@visited, [$p1];
    };

    subtest "safety check" => sub {
        subtest "via undef" => sub {
            my $t = Geo::Geos::Index::Quadtree->new;
            my $p1 = ['p1'];
            my $e1 = Geo::Geos::Envelope->new(1, 1, 3, 3);
            $t->insert($e1, $p1);

            my $p2 = 'string';
            my $e2 = Geo::Geos::Envelope->new(1, 1, 2, 2);
            $t->insert($e2, $p2);

            my $p3 = 314156;
            my $e3 = Geo::Geos::Envelope->new(5, 5, 6, 6);
            $t->insert($e3, $p3);

            my $p4 = { k => 'v'};
            my $e4 = Geo::Geos::Envelope->new(6, 6, 7, 7);
            $t->insert($e4, $p4);

            my $p5 = Geo::Geos::Coordinate->new(0,2);
            my $e5 = Geo::Geos::Envelope->new(7, 7, 8, 8);
            $t->insert($e5, $p5);

            undef $p1;
            undef $p2;
            undef $p3;
            undef $p4;
            undef $p5;

            is_deeply $t->queryAll, ['string', ['p1'], 314156, {k => 'v'}, Geo::Geos::Coordinate->new(0,2)];
        };

        subtest "via explict out-of-scope exit" => sub {
            my $t = Geo::Geos::Index::Quadtree->new;
            {
                my $p1 = ['p1'];
                my $e1 = Geo::Geos::Envelope->new(1, 1, 3, 3);
                $t->insert($e1, $p1);

                my $p2 = 'string';
                my $e2 = Geo::Geos::Envelope->new(1, 1, 2, 2);
                $t->insert($e2, $p2);

                my $p3 = 314156;
                my $e3 = Geo::Geos::Envelope->new(5, 5, 6, 6);
                $t->insert($e3, $p3);

                my $p4 = { k => 'v'};
                my $e4 = Geo::Geos::Envelope->new(6, 6, 7, 7);
                $t->insert($e4, $p4);

                my $p5 = Geo::Geos::Coordinate->new(0,2);
                my $e5 = Geo::Geos::Envelope->new(7, 7, 8, 8);
                $t->insert($e5, $p5);
            };
            is_deeply $t->queryAll, ['string', ['p1'], 314156, {k => 'v'}, Geo::Geos::Coordinate->new(0,2)];
        };
    };


   subtest "key correcness" => sub {
       my $t = Geo::Geos::Index::Quadtree->new;
       my $p1 = 5;
       my $e1 = Geo::Geos::Envelope->new(1, 1, 3, 3);
       $t->insert($e1, $p1);
       is_deeply $t->query($e1), [$p1];

       $t->remove($e1, 2 + 3);
       is_deeply $t->queryAll, [];
    };
};

done_testing;
