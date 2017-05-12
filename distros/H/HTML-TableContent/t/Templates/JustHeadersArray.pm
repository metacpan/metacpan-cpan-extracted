package t::Templates::JustHeadersArray;

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

sub _data {
    my $self = shift;

    return [
        [qw/id name address/],
        [ 1, 'rob', 'somewhere'],
        [ 2, 'sam', 'somewhere else'],
        [ 3, 'frank', 'out'],
    ];
}

1;



