package MetaStore::DAOItem;

=head1 NAME

MetaStore::DAOItem - Base class.

=head1 SYNOPSIS

    use MetaStore::DAOItem;
    use base qw( MetaStore::DAOItem );


=head1 DESCRIPTION

Base class.

=head1 METHODS

=cut

use Data::Dumper;
use strict;
use warnings;
use WebDAO;
use MetaStore::Item;
our @ISA = qw( MetaStore::Item   );
our $VERSION = '0.01';

sub _init {
    my $self = shift;
    $self->WebDAO::_sysinit(\@_);
    return $self->SUPER::_init(@_);
}

1;
__END__

=head1 SEE ALSO

MetaStore, MetaStore::Item, README

=head1 AUTHOR

Zahatski Aliaksandr, E<lt>zag@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Zahatski Aliaksandr

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

