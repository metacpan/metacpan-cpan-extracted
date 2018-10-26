use Test2::V0;

use Devel::Chitin::OpTree;
use Devel::Chitin::Location;

use Scalar::Util qw(refaddr);

plan tests => 5;

sub scalar_assignment {
    my $a = 1;
}

my $ops = _get_optree_for_sub_named('scalar_assignment');
ok($ops, 'create opreee');

my $count = 0;
my $last_op;
$ops->walk_inorder(sub { $last_op = shift; $count++ });
ok($count > 1, 'More then one op makes up scalar_assignment');
is $ops->deparse,
    '$a = 1',
    'deparse scalar_assignment';

is(refaddr($last_op->root_op), refaddr($ops), 'root_op property');

sub multi_statement_scalar_assignment {
    my $a = 1;
    my $b = 2;
}

is _get_optree_for_sub_named('multi_statement_scalar_assignment')->deparse,
    join("\n", q($a = 1;), q($b = 2)),
    'deparse multi_statement_scalar_assignment';

sub _get_optree_for_sub_named {
    my $subname = shift;
    Devel::Chitin::OpTree->build_from_location(
        Devel::Chitin::Location->new(
            package => 'main',
            subroutine => $subname,
            filename => __FILE__,
            line => 1,
        )
    );
}
