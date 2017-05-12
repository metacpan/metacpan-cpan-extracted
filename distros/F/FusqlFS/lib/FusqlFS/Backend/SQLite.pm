use strict;
use 5.010;

package FusqlFS::Backend::SQLite;
use FusqlFS::Version;
our $VERSION = $FusqlFS::Version::VERSION;
use parent 'FusqlFS::Backend::Base';

sub init
{
    $_[0]->autopackages('tables');
}

sub dsn
{
    return "SQLite:dbname=$_[3]";
}

1;
