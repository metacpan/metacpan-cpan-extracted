package t::Templates::TableInnerSubStuff;

use Moo;
use HTML::TableContent::Template;

sub table_spec {
   return {
       class => 'some-table-class',
       id => 'some-table-id',
       inner_html => 'wrap_div',
   };
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

sub wrap_div {
    return ['<div>%s</div>'];
}

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



