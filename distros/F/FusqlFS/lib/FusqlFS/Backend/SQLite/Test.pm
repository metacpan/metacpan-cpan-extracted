use strict;
use 5.010;

package FusqlFS::Backend::SQLite::Test;
use FusqlFS::Version;
our $VERSION = $FusqlFS::Version::VERSION;

our $fusqlh;

sub set_up
{
    use FusqlFS::Backend::SQLite;
    $fusqlh = FusqlFS::Backend::SQLite->new(host => '', port => '', database => '/tmp/fusqlfs_test.sqlite', user => '', password => '', format => 'native');
}

sub tear_down
{
    $fusqlh->{dbh}->disconnect();
    $fusqlh->destroy();

    unlink '/tmp/fusqlfs_test.sqlite';
}

1;
