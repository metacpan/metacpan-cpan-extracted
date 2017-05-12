use strict;
use 5.010;

package FusqlFS::Backend::SQLite::Table::Data;
use FusqlFS::Version;
our $VERSION = $FusqlFS::Version::VERSION;
use parent 'FusqlFS::Artifact::Table::Data';

=head1 NAME

FusqlFS::Backend::SQLite::Table::Data - 

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 EXPOSED STRUCTURE

=cut

sub init
{
    my $self = shift;
    $self->SUPER::init();

    $self->{get_primary_expr} = 'PRAGMA table_info(%s)';
}

sub get_primary_key
{
    my $self = shift;
    my ($table) = @_;
    my $data = $self->all_row($self->{get_primary_expr}, [$table]);
    return unless $data;
    return map $_->{name}, grep $_->{pk}, @$data;
}

1;

