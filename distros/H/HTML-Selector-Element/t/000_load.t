use Test::More;

require_ok('HTML::Selector::Element');
my $s = HTML::Selector::Element->new('div.head + div.sub_content label');
is($s->isa('HTML::Selector::Element'), 1, 'isa');
is_deeply($s->{parsed},
    [{ 
        static => [ '_tag' => 'label' ],
        combinator => ' ',
        chained => {
            static => [ '_tag' => 'div', 'class' => qr/(?<!\S)sub_content(?!\S)/ ],
            combinator => '+',
            chained => {
                static => [ '_tag' => 'div', 'class' => qr/(?<!\S)head(?!\S)/ ],
                # extra
                tag => 'div',
                selector => 'div.head'
            },
            # extra
            tag => 'div',
            selector => 'div.head + div.sub_content'
        },
        # extra
        tag => 'label',
        selector => 'div.head + div.sub_content label'
    }],
    'parsed');
done_testing();
