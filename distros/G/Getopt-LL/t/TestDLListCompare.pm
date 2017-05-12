package TestDLListCompare;
use Test::Builder qw( );
use Class::Dot qw(property isa_Int isa_Array isa_Object);

property count  => isa_Int(0);
property array  => isa_Array;
property tester => isa_Object;


sub new {
    my ($class, $test_array) = @_;
    my $self = { };
    bless $self, $class;

    $self->set_array($test_array);
    my $test = Test::Builder->new( );
    #$test->plan(tests => scalar @{$test_array});

    $self->set_tester($test);

    return $self;
}


sub compare {
    my ($self, $node_data, $node, $nodes_so_far) = @_;
    my $test_array    = $self->array;
    my $count         = $self->count;
    my $test          = $self->tester;

    $test->ok( $node->data eq $test_array->[$count],
        sprintf('traverse(): integrity: node.data[%s] == copy[%s]',
            $node->data, $test_array->[$count] )
    );
    $test->ok( $node_data  eq $test_array->[$count], '--"--' );

    $test->ok( $count == $nodes_so_far,
        sprintf('traverse(): interface: nodes_so_far[%d] == count[%d]',
            $nodes_so_far, $count )
    );

    $self->set_count( $count + 1 );
    return 1;
}

1;

package _Array::Overload;

use overload '@{}' => sub {
    return [keys %{$_[0]}];
};

use overload 'bool' => sub {
    1
};

sub new {
    return bless {'a' => 1, 'b' => 2 }, shift;
}

