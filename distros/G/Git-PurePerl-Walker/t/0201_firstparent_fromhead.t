use strict;
use warnings;

use Test::More tests => 9;
use FindBin;
use Path::Tiny qw( path );

use lib path($FindBin::Bin)->child("tlib")->absolute->stringify;
use t::util { '$repo' => 1 };
use Git::PurePerl::Walker::Method::FirstParent::FromHEAD;

my $expected = {
  'HEAD'   => '010fb4bcf7d92c031213f43d0130c811cbb355e7',
  'HEAD~1' => '10003632f7b967108151e20639e4b425c5e4c731',
};

my $method_factory = Git::PurePerl::Walker::Method::FirstParent::FromHEAD->new();
my $method         = $method_factory->for_repository($repo);

is( $method->_commit->sha1, $expected->{HEAD}, 'At Head' );
is( $method->current->sha1, $expected->{HEAD}, 'At Head' );
is( $method->start,         $expected->{HEAD}, 'At Head' );
ok( $method->has_next, "Has more items" );
is( $method->peek_next->sha1, $expected->{'HEAD~1'}, 'peak_next gives head~1' );

$method->next;

is( $method->_commit->sha1, $expected->{'HEAD~1'}, 'At Head~1' );
is( $method->current->sha1, $expected->{'HEAD~1'}, 'At Head~1' );
is( $method->start,         $expected->{'HEAD'},   'At Head' );
ok( !$method->has_next, "Has no more items" );
