# index_diff, char_diff

use strict;
use warnings;

use Test::More tests => 8;
use Lingua::Orthon;

my $orthon = Lingua::Orthon->new(match_level => 1);

my $di = $orthon->index_diff(qw/bring being/);
ok( $di == 1, "Error in index_diff: expected 1, observed $di" );

$di = $orthon->index_diff(qw/being being/);
ok( $di == 0, "Error in index_diff: expected 0, observed $di" );

my (@diff) = $orthon->char_diff(qw/bring being/);
ok( scalar @diff == 2, "Error in char_diff: expected 2, observed " . ( scalar @diff ) );
ok( $diff[0] eq 'r', "Error in char_diff: expected 'r', observed '$diff[0]'" );
ok( $diff[1] eq 'e', "Error in char_diff: expected 'e', observed '$diff[1]'" );

(@diff) = $orthon->char_diff(qw/being being/);
ok( scalar @diff == 0, "Error in char_diff: expected 0, observed " . ( scalar @diff ) );

# still ignoring case:
$orthon->set_eq(match_level => 2);
(@diff) = $orthon->char_diff(qw/being Being/);
ok( scalar @diff == 0, "Error in char_diff: expected 0, observed " . ( scalar @diff ) );

# sensitive to case:
$orthon->set_eq(match_level => 3);
(@diff) = $orthon->char_diff(qw/being Being/);
ok( scalar @diff == 2, "Error in char_diff: expected 2, observed " . ( scalar @diff ) );


1;
