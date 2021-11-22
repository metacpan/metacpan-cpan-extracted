use Test::More;
use Lingua::EN::Inflexion;

sub test {
    my ($plural, $singular) = @_;

    is noun($plural)->singular, $singular  => "$plural --> $singular";
}

test 'staffs' => 'staff';
test 'staves' => 'stave';

test 'bases'  => 'base';

done_testing();


