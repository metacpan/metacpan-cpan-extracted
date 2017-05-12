package MetaStore::Auth::UserGuest;
use strict;
use warnings;
use MetaStore::Auth::User;
our @ISA = qw(MetaStore::Auth::User);
our $VERSION = '0.1';

=pod

=head1 NAME

MetaStore::Auth::UserGuest

=head1 SYNOPSIS


=head1 DESCRIPTION

MetaStore::Auth::UserGuest

=head1 METHODS

=cut

sub _init {
    my $self = shift;
    my ( $attr ) = @_;
    $self->_attr({%{$attr || {}}});
    return 1;
}

=head2 id

User guest always have -1 

=cut

sub id {
    return -1;
}
1;
__END__

=head1 AUTHOR

Aliaksandr P. Zahatski, <zahatski@gmail.com>

=cut
