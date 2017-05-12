package Grimlock::Schema::ResultSet::Entry;
{
  $Grimlock::Schema::ResultSet::Entry::VERSION = '0.11';
}
use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

sub front_page_entries {
  my ($self, $limit) = @_;
  return $self->search(
    {
      parent    => undef,
      published => 1
    }, 
    {
      rows => $limit || 50,
      order_by => { 
        -desc => 'created_at'
      },
    }
  );
}

1;

