use strict;
use 5.010;

package FusqlFS::Backend::MySQL::Variables;
use FusqlFS::Version;
our $VERSION = $FusqlFS::Version::VERSION;
use parent 'FusqlFS::Artifact';

=head1 NAME

FusqlFS::Backend::MySQL::Variables - expose all MySQL variables

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 EXPOSED STRUCTURE

=cut

sub get
{
    my $self = shift;
    my $name = shift;
    my %vars = map { $_->{Variable_name} => $_->{Value} } @{$self->all_row('SHOW VARIABLES')};
    return $name? $vars{$name}: $self->dump(\%vars);
}

sub store
{
    my $self = shift;
    my $data = $self->load(shift);
    return unless $data;

    foreach my $varname (keys %$data) {
        $self->do('SET `%s` = ?', [$varname], $data->{$varname});
    }
}

1;
