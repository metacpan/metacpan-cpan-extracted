package t::Templates::HeaderHtmlCustom;

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
    text => 'User Id',
);

header name => (
    class => 'okay',
    text => 'User Name',
);

header address => (
    class => 'what',
    text => 'User Address',
);

sub render_header {
    my ($self, $element) = @_;

    return ['<a href="some/endpoint?sort=%s">%s</a>', 'template_attr', 'text'];
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



