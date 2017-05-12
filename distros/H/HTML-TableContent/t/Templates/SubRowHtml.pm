package t::Templates::SubRowHtml;

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

row one => (
    inner_html => 'special_row',    
    links => ['some/endpoint'],
);

sub render_row {
    my ($self, $element) = @_;

    return ['<div>%s</div>'];
}

sub special_row {
    my ($self, $element) = @_;

    return [ '<div><a href="%s">%s</a></div>', 'get_first_link', '_render_element' ];
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



