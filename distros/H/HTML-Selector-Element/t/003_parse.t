use Test::More;

require_ok('HTML::Selector::Element');
my $s;
$s = HTML::Selector::Element->new('input+label');
is_deeply($s->{parsed},
    [{ 
        static => [ '_tag' => 'label' ],
        combinator => '+',
        chained => {
            static => [ '_tag' => 'input' ],
            # extra
            tag => 'input',
        },
        # extra
        tag => 'label',
    }],
    'input+label');

$s = HTML::Selector::Element->new('+ label');
is_deeply($s->{parsed},
    [{ 
        static => [ '_tag' => 'label' ],
        combinator => '+',
        chained => {
            static => [],
            is_root => 1,
            # extra
        },
        sibling_root => '+',
        # extra
        tag => 'label',
    }],
    '+ label');

$s = HTML::Selector::Element->new('div#container');
is_deeply($s->{parsed},
    [{ 
        static => [ 'id' => 'container', '_tag' => 'div' ],
        # extra
        tag => 'div',
    }],
    'div#container');

done_testing();