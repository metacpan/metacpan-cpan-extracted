use strict;
use warnings;

use Test::More;
use Kelp;

my $app = Kelp->new(mode => 'test');

my $main_sereal = $app->sereal;
my $new_sereal = $app->get_encoder(sereal => 'new_one');

ok ref $main_sereal eq ref $new_sereal, 'objects classes ok';
ok $main_sereal != $new_sereal, 'not the same objects';

done_testing;

