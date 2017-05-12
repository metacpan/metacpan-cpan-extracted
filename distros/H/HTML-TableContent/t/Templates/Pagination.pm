package t::Templates::Pagination;

use Moo;
use HTML::TableContent::Template;

with 'HTML::TableContent::Template::Javascript';

sub table_spec {
    return {
        pagination => 1,
        display => 5,
        wrap_html => ['<div>%s</div>']
    }
}

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
        {
            id => 4,
            name => 'rob',
            address => 'somewhere',
        },
        {
            id => 5,
            name => 'sam',
            address => 'somewhere else',
        },
        {
            id => 6,
            name => 'frank',
            address => 'out',
        },
        {
            id => 7,
            name => 'rob',
            address => 'somewhere',
        },
        {
            id => 8,
            name => 'sam',
            address => 'somewhere else',
        },
        {
            id => 9,
            name => 'frank',
            address => 'out',
        },       {
            id => 10,
            name => 'rob',
            address => 'somewhere',
        },
        {
            id => 11,
            name => 'sam',
            address => 'somewhere else',
        },
        {
            id => 12,
            name => 'frank',
            address => 'out',
        },
    ];
}

1;



