package MetaStore::Auth::User;

use strict;
use warnings;
use MetaStore::Item;
use Data::Dumper;
our @ISA = qw(MetaStore::Item);

our $VERSION = '0.01';


=pod

=head1 NAME

MetaStore::Auth::User

=head1 SYNOPSIS



=head1 DESCRIPTION

MetaStore::Auth::User

=head1 METHODS

=cut

sub _init {
    my $self = shift;
    return $self->SUPER::_init(@_);
}

=head2 session_id

session_id

=cut

sub session_id {
    my $self = shift;
    my $sess_id = shift;
    defined $sess_id ? $self->attr->{sess_id} = $sess_id : $self->attr->{sess_id};
}

1;
__END__

=head1 AUTHOR

Aliaksandr P. Zahatski, <zahatski@gmail.com>

=cut
