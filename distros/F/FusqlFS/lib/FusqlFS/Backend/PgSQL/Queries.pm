use strict;
use 5.010;

package FusqlFS::Backend::PgSQL::Queries;
use FusqlFS::Version;
our $VERSION = $FusqlFS::Version::VERSION;
use parent 'FusqlFS::Artifact';

=begin testing get

is $_tobj->get('query'), undef;

=end testing
=cut
sub get
{
    my $self = shift;
    my ($name) = @_;
    return $self->{$name}||undef;
}

=begin testing list

cmp_set $_tobj->list(), [];

=end testing
=cut
sub list
{
    my $self = shift;
    return [ keys %$self ];
}

=begin testing create after get list

isnt $_tobj->create('query'), undef;
isa_ok $_tobj->get('query'), 'CODE';
is_deeply $_tobj->list(), [ 'query' ];

=end testing
=cut
sub create
{
    my $self = shift;
    my ($name) = @_;
    $self->{$name} = sub () {
        my $query = shift;
        return '' unless $query;
        return $self->dump($self->all_row($query));
    };
}

=begin testing drop after rename

isnt $_tobj->drop('new_query'), undef;
is $_tobj->get('new_query'), undef;
is_deeply $_tobj->list(), [];

=end testing
=cut
sub drop
{
    my $self = shift;
    my ($name) = @_;
    delete $self->{$name};
}

=begin testing rename after create

my $oldquery = $_tobj->get('query');
isnt $_tobj->rename('query', 'new_query'), undef;
is $_tobj->get('query'), undef;
is $_tobj->get('new_query'), $oldquery;
is_deeply $_tobj->list(), [ 'new_query' ];

=end testing
=cut
sub rename
{
    my $self = shift;
    my ($name, $newname) = @_;
    return unless exists $self->{$name};
    $self->{$newname} = $self->{$name};
    delete $self->{$name};
}

1;

__END__

=begin testing SETUP

#!class FusqlFS::Backend::PgSQL::Test

=end testing
=cut
