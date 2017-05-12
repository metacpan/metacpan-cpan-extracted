package DBI::Person;
use Gideon driver => 'DBI';

has first_name => (
    is     => 'rw',
    isa    => 'Str',
    traits => ['Gideon::DBI::Column']
);

has last_name => (
    is     => 'rw',
    isa    => 'Str',
    traits => ['Gideon::DBI::Column']
);

__PACKAGE__->meta->store("dbi:person");
__PACKAGE__->meta->make_immutable;
1;
