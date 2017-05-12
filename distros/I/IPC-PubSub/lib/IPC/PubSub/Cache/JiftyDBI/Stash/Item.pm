package IPC::PubSub::Cache::JiftyDBI::Stash::Item;
use strict;
use warnings;

use vars qw/$TABLE_PREFIX/;

use Jifty::DBI::Schema;
use Jifty::DBI::Record schema {
    column data_key    => type is 'text';
    column val    => type is 'blob', filters are 'Jifty::DBI::Filter::Storable';
    column expiry => type is 'int';
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


package IPC::PubSub::Cache::JiftyDBI::Stash::ItemCollection;
use base qw/Jifty::DBI::Collection/;

sub table {
    my $self = shift;
    my $tab = $self->new_item->table();
    return $tab;
}


1;
