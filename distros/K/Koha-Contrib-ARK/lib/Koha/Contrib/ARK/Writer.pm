package Koha::Contrib::ARK::Writer;
$Koha::Contrib::ARK::Writer::VERSION = '1.0.2';
# ABSTRACT: Write biblio records into Koha Catalog
use Moose;

with 'MooseX::RW::Writer';

use Modern::Perl;
use C4::Biblio;


has ark => ( is => 'rw', isa => 'Koha::Contrib::ARK' );


sub write {
    my ($self, $br) = @_;
    my ($biblionumber, $record) = @$br;

    return unless $record;

    if ($self->ark->doit) {
        my $fc = GetFrameworkCode($biblionumber);
        ModBiblio( $record->as('Legacy'), $biblionumber, $fc );
    }
    $self->ark->log->debug("BIBLIO AFTER PROCESSING:\n", $record->as('Text'));
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Koha::Contrib::ARK::Writer - Write biblio records into Koha Catalog

=head1 VERSION

version 1.0.2

=head1 ATTRIBUTES

=head2 ark

L<Koha::Contrib::ARK> object.

=head1 AUTHOR

Frédéric Demians <f.demians@tamil.fr>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Fréderic Demians.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
