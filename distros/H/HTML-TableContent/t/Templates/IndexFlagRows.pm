package t::Templates::IndexFlagRows;

use Moo;
use HTML::TableContent::Template;

caption title => (
    class => 'some-class',
    id => 'caption-id',
    text => 'table caption',
);

header id => (
    class => 'some-class',
    id => 'something-id',
);

header name => (
    class => 'okay',
);

header address => (
    class => 'what',
);

row anything => (
    index => 1,
    class => 'first',
    id => 'first-row'
);

row something => (
    index => 2,
    class => 'second',
    id => 'second-row',
);

row amazing => (
    index => 3,
    class => 'third',
    id => 'third-row',
);

sub _data {
    my $self = shift;

    return [
        {
            id => 1,
            name => 'rob',
            address => 'somewhere',
        },
        {
            id => 2,
            name => 'sam',
            address => 'somewhere else',
        },
        {
            id => 3,
            name => 'frank',
            address => 'out',
        },
    ];
}

1;



