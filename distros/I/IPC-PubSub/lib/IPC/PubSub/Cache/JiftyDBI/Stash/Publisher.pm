package IPC::PubSub::Cache::JiftyDBI::Stash::Publisher;
use strict;
use warnings;

use vars qw/$TABLE_PREFIX/;

use Jifty::DBI::Schema;
use Jifty::DBI::Record schema {
    column channel  => type is 'text';
    column name     => type is 'text';
    column idx      => type is 'int';
};


sub table_prefix {
    my $self = shift;
    $TABLE_PREFIX = shift if (@_);
    return ($TABLE_PREFIX);
}

sub table {
    my $self = shift;
    return $self->table_prefix . $self->SUPER::table();
}

package IPC::PubSub::Cache::JiftyDBI::Stash::PublisherCollection;
use base qw/Jifty::DBI::Collection/;

sub table {
    my $self = shift;
    my $tab = $self->new_item->table();
    return $tab;
}

1;
