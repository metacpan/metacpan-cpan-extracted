package t::Templates::SubCellHtml;

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

cell one__one => (
    links => ['some/endpoint'],
    inner_html => 'special_cell',
);

sub render_row {
    my ($self, $element) = @_;

    return ['<div>%s</div>'];
}

sub render_cell {
    my ($self, $element) = @_;

    return ['<span>%s</span>'];
}

sub special_cell {
    return ['<span><a href="%s">%s</a></span>', 'get_first_link', 'text'];
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



