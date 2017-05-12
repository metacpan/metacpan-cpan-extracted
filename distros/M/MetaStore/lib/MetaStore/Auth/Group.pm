package MetaStore::Auth::Group;

use strict;
use warnings;
use MetaStore::Item;
use Data::Dumper;
our @ISA = qw(MetaStore::Item);

our $VERSION = '0.01';


=pod

=head1 NAME

MetaStore::Auth::Group - abstract class for group of users

=head1 SYNOPSIS


=head1 DESCRIPTION

MetaStore::Auth::Group

=head1 METHODS

=cut

sub _init {
    my $self = shift;
    return $self->SUPER::_init(@_);
}

1;
__END__

=head1 AUTHOR

Aliaksandr P. Zahatski, <zahatski@gmail.com>

=cut
