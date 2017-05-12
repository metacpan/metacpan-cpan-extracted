use strict;
use warnings;

use Import::Box;

my $t = Import::Box->new(
    'Test2::Tools::Basic' => [qw/ok done_testing/],
    'Test2::Tools::Compare' => [qw/is like/],
);

$t->ok(1, "OO works fine");

$t->import('Test2::Tools::Class' => [qw/can_ok/]);
$t->can_ok($t, qw/ok done_testing is like can_ok/);

ok $t(1, "Indirect object syntax (uhg)");

my $t2 = Import::Box->new;
$t->ok($t != $t2, "Not the same instance");
$t->ok($$t ne $$t2, "Not the same stash (Implementation Detail)");
$t->ok(!$t2->can('ok'), "Not the same stash (Behavior)");

require Data::Dumper;
my $dd = Import::Box->box('Data::Dumper');
$t->ok($dd->can('Dumper'), "Boxed up Data::Dumper");

{
    no strict;

    BEGIN {
        my $t3 = Import::Box->new;
        $t3->import('strict');
    }

    $t->ok(
        eval '$xyz = 1' || 0,
        "OO import does not effect compiling scope",
    );
}

$t->done_testing;
