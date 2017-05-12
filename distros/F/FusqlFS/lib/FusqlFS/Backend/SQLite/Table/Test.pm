use strict;
use 5.010;

package FusqlFS::Backend::SQLite::Table::Test;
use FusqlFS::Version;
our $VERSION = $FusqlFS::Version::VERSION;

use FusqlFS::Backend::SQLite::Test;

our $fusqlh;

sub set_up
{
    $fusqlh = FusqlFS::Backend::SQLite::Test->set_up();
    return unless $fusqlh;

    $fusqlh->{subpackages}->{tables}->create('fusqlfs_table');
}

sub tear_down
{
    FusqlFS::Backend::SQLite::Test->tear_down();
}

1;
