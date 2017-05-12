package DBI::Customer;
use Gideon driver => 'DBI';

has id => (
    is          => 'rw',
    isa         => 'Num',
    primary_key => 1,
    serial      => 1,
    traits      => ['Gideon::DBI::Column']
);

has name => (
    is     => 'rw',
    isa    => 'Str',
    column => 'alias',
    traits => ['Gideon::DBI::Column']
);

__PACKAGE__->meta->store("dbi:customer");
__PACKAGE__->meta->make_immutable;
1;
