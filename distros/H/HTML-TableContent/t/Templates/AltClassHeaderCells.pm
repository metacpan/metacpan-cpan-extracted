package t::Templates::AltClassHeaderCells;

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
        alternate_classes => [qw/first-head-first-class first-head-second-class first-head-third-class/],
    }
);

header name => (
    class => 'okay',
    cells => {
        alternate_classes => [qw/second-head-first-class second-head-second-class second-head-third-class/],
    }
);

header address => (
    class => 'what',
    cells => {
        alternate_classes => [qw/third-head-first-class third-head-second-class third-head-third-class/],
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



