package t::Templates::BigData;

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
    class => 'thing',
);

row one_hundred => (
    class => 'hundred',
);

row one_hundred_fifty => (
    class => 'one_hundred_fifty',
);

row one_thousand_one => (
    class => 'one_thousand_one',
);

1;



