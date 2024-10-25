package Koha::Contrib::ARK::Writer;
# ABSTRACT: Write biblio records into Koha Catalog
$Koha::Contrib::ARK::Writer::VERSION = '1.1.2';
use Moose;
use Modern::Perl;
use C4::Biblio qw/ ModBiblio /;

with 'MooseX::RW::Writer';


has ark => ( is => 'rw', isa => 'Koha::Contrib::ARK' );


sub write {
    my $self = shift;

    my $ark = $self->ark;
    return unless $ark->doit;

    my $current = $ark->current;
    my $biblio = $current->{biblio};
    my $record = $biblio->{record};

    return unless $record;

    ModBiblio(
        $record->as('Legacy'),
        $biblio->biblionumber,
        $biblio->frameworkcode
    );
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Koha::Contrib::ARK::Writer - Write biblio records into Koha Catalog

=head1 VERSION

version 1.1.2

=head1 ATTRIBUTES

=head2 ark

L<Koha::Contrib::ARK> object.

=head1 AUTHOR

Frédéric Demians <f.demians@tamil.fr>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2024 by Fréderic Demians.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
