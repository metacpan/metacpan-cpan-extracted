use Test::More tests => 14;

use_ok 'Flower::Node';

eval { my $node = Flower::Node->new(); };
ok ($@, "empty constructor not allowed");

eval { my $node = Flower::Node->new({ip => '1.1.1.1', port => 80}); };
ok ($@ =~ /parent/, "require parent");


eval { my $node = Flower::Node->new({parent => {}, port => 80}); };
ok ($@ =~ /ip/, "require ip");

eval { my $node = Flower::Node->new({parent => {}, ip => '1.1.1.1'}); };
ok ($@ =~ /port/, "require port");

my $node = Flower::Node->new({parent => {}, ip => '1.1.1.1', port => 80});
ok ($node =~ /1.1.1.1/,   'stringification');
ok ($node =~ /80/  ,      'stringification');
ok ($node =~ /\[undef\]/, 'stringification (empty uuid)');

ok (!$node->has_timed_out, 'has not timed out');
$node->{timeout} -= 3600;
ok ($node->has_timed_out, 'has timed out');

# this will not work because we don't have a server, but we can at
# least check that the cv and ua get set up.
ok (! $node->{ping_ua}, "has no ua");
ok (! $node->{ping_cv}, "has no cv");
$node->ping_if_necessary();
ok ($node->{ping_ua}, "has a ua now");
ok ($node->{ping_cv}, "has a cv now");


