package Example::Model::Employee;

use base qw/Jifty::DBI::Record/;

sub Table { "Employees" }

sub Schema {
    return {
      Name => { type => 'varchar', },
      Dexterity => { type => 'integer', },
    }
}

1;