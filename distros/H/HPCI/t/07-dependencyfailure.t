###07-dependencyfailure.t#######################################
# This file tests the handling of dependency loops between stages

### Includes ####################################################

# Safe Perl
use warnings;
use strict;
use Carp;

use Test::More tests => 14;   #look into this more later
use Test::Exception;

use HPCI;

my $cluster = $ENV{HPCI_CLUSTER} || 'uni';

my $group = HPCI->group (cluster => $cluster, base_dir => 'scratch', name => 'D_Failure1' );

ok($group, "D_Failure1 Group created.");

# Try submitting self dependent stage (A -> A)
my $stage1 = $group->stage(
    name => 'Stage1',
    command => "sleep 5 && echo \"hi\"",
    );
ok($stage1, "Stage 1 created.");

$group->add_deps(
    pre_req => $stage1,
    dep => $stage1
);
dies_ok {$group->execute()} 'including self-dependent stage should fail';

# Try submitting stages with dependency loop (A -> B -> C -> B)
$group = HPCI->group (cluster => $cluster, base_dir =>'scratch', name => 'D_Failure2');
ok($group, "D_Failure2 Group created.");
my @stages;
foreach my $i (0..2){
    push(@stages,$group ->stage(
        command => "sleep 2 && echo \"hi\"",
        name => "Stage$i")
    );
    ok($stages[$i], "Stage$i created.");
}

$group ->add_deps(
    pre_req => $stages[0],
    dep => $stages[1]
);
$group->add_deps(
    pre_req =>$stages[1],
    dep => $stages[2]
);
$group->add_deps(
    pre_req=>$stages[2],
    dep => $stages[1]
);
dies_ok{$group->execute()} 'existing dependency loop should fail';


# Try submitting stages with dependency loop (A -> B -> C -> D -> A)
$group = HPCI ->group(cluster=>$cluster, base_dir =>'scratch', name => 'D_Failure3');
ok($group, "D_Failure3 Group created.");
@stages = ();
foreach my $i (0..3){
    push(@stages,$group ->stage(
        command => "sleep 2 && echo \"hi\"",
        name => "Stage$i")
    );
    ok($stages[$i], "Stage$i created.");
}
 $group -> add_deps(
    pre_req => $stages[0],
    dep => $stages[1]
);
$group-> add_deps(
    pre_req =>$stages[1],
    dep => $stages[2]
);
$group->add_deps(
    pre_req=>$stages[2],
    dep => $stages[3]
);
$group->add_deps(
    pre_req=>$stages[3],
    dep => $stages[0]
);
dies_ok{$group->execute()} 'existing dependency loop should fail';

done_testing();
