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
            selector => 'input'
        },
        # extra
        tag => 'label',
        selector => 'input+label'
    }],
    'input+label');

$s = HTML::Selector::Element->new('+ label');
is_deeply($result = $s->{parsed},
    [{ 
        static => [ '_tag' => 'label' ],
        combinator => '+',
        chained => {
            static => [],
            is_root => 1,
            # extra
            selector => ''
        },
        sibling_root => '+',
        # extra
        tag => 'label',
        selector => '+ label'
    }],
    '+ label');

$s = HTML::Selector::Element->new('+ input[type=hidden] ~ label');
is_deeply($result = $s->{parsed},
    [{ 
        static => [ '_tag' => 'label' ],
        combinator => '~',
        chained => {
            static => [
               '_tag' => 'input',
               type => 'hidden'
            ],
            combinator => '+',
            chained => {
                static => [],
                selector => '',
                is_root => 1
            },
            sibling_root => '+',
            # extra
            tag => 'input',
            selector => '+ input[type=hidden]'
        },
        sibling_root => '+~',   # sibling of sibling of root = sibling of root
        # extra
        tag => 'label',
        selector => '+ input[type=hidden] ~ label'
    }],
    '+ input[type=hidden] ~ label');

$s = HTML::Selector::Element->new('div#container');
is_deeply($s->{parsed},
    [{ 
        static => [ 'id' => 'container', '_tag' => 'div' ],
        # extra
        tag => 'div',
        selector => 'div#container'
    }],
    'div#container');

$s = HTML::Selector::Element->new('> div + span');
is_deeply($s->{parsed},
    [$c = { 
        static => [ '_tag' => 'span' ],
        combinator => '+',
        chained => {
            static => [ '_tag' => 'div' ],
            combinator => '>',
            chained => {
                static => [],
                is_root => 1,
                # extra
                selector => ''
            },
            root_child => '>',
            # extra
            tag => 'div',
            selector => '> div'
        },
        # extra
        root_child => '>+',
        tag => 'span',
        selector => '> div + span'
    }],
    '> div + span');

$s = HTML::Selector::Element->new('> div + span a');
is_deeply($s->{parsed},
    # built upon previous one; we need an extra reference to $s->{cheined} in $s->{root_child}  # so it is not exactly a "tree"
    [{
        static => [ '_tag' => 'a' ],
        combinator => ' ',
        chained => $c,
        root_child => $c,
        # extra
        tag => 'a',
        selector => '> div + span a'
    }],
    '> div + span a');


done_testing();
