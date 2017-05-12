package Example::Model::Address;

use base qw/Jifty::DBI::Record/;

# Class and instance method

sub Table { "Addresses" }

# Class and instance method

sub Schema {
    return {
        Name => { type => 'varchar', },
        Phone => { type => 'varchar', },
        EmployeeId => { REFERENCES => 'Example::Model::Employee', },
    }
}

1;