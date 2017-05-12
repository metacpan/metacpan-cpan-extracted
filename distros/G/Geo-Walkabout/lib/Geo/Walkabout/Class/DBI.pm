package Geo::Walkabout::Class::DBI;

use base qw(Class::DBI);

__PACKAGE__->set_db('Main', 'dbi:Pg:dbname=Walkabout', undef, undef,
                    { AutoCommit => 0, ChopBlanks => 1 } );

1;
