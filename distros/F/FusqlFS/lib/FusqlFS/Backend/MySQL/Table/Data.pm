use strict;
use 5.010;

package FusqlFS::Backend::MySQL::Table::Data;
use FusqlFS::Version;
our $VERSION = $FusqlFS::Version::VERSION;
use parent 'FusqlFS::Artifact::Table::Data';

=head1 NAME

FusqlFS::Backend::MySQL::Table::Data - 

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 EXPOSED STRUCTURE

=cut

sub init
{
    my $self = shift;
    $self->SUPER::init();

    $self->{field_quote} = '`';
    $self->{get_primary_expr} = 'SHOW INDEX FROM `%s` WHERE Key_name = "PRIMARY"';
}

sub get_primary_key
{
    my $self = shift;
    my ($table) = @_;
    my @result = ();
    my $data = $self->all_row($self->{get_primary_expr}, [$table]);
    if ($data)
    {
        @result = map { $_->{Column_name} } @$data;
    }
    return @result;
}

sub concat
{
    shift @_;
    my $instance = $FusqlFS::Artifact::instance;
    return "CONCAT_WS('$instance->{fnsep}', `" . join('`, `', @_) . "`)";
}

1;
