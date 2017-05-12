package t::Templates::HeaderCells;

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
    cells => {
        class => 'something',
        increment_id => 'some-id-',
    }
);

header name => (
    class => 'okay',
);

header address => (
    class => 'what',
    cells => {
        class => 'else',
        increment_id => 'some-other-id-',
    }
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



