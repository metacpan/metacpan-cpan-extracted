use Kelp::Base -strict;
use Test::More;
use Kelp;

my $app = Kelp->new(mode => 'test');

my $main_yaml = $app->yaml;
my $new_yaml = $app->get_encoder(yaml => 'new_one');

ok ref $main_yaml eq ref $new_yaml, 'objects classes ok';
ok $main_yaml != $new_yaml, 'not the same objects';

done_testing;

