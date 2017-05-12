package t::Templates::Search;

use Moo;
use HTML::TableContent::Template;

with 'HTML::TableContent::Template::Javascript';

caption title => (
    class => 'some-class',
    id => 'caption-id',
    text => 'table caption',
);

header id => (
    class => 'some-class',
    id => 'something-id',
    search => 1,
);

header name => (
    class => 'okay',
    search => 1,
);

header address => (
    class => 'what',
    search => 1,
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



