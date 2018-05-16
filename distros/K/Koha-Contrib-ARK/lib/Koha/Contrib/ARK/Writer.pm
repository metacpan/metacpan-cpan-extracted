package Koha::Contrib::ARK::Writer;
$Koha::Contrib::ARK::Writer::VERSION = '1.0.3';
# ABSTRACT: Write biblio records into Koha Catalog
use Moose;

with 'MooseX::RW::Writer';

use Modern::Perl;
use C4::Biblio;


has ark => ( is => 'rw', isa => 'Koha::Contrib::ARK' );


sub write {
    my ($self, $biblionumber, $record) = @_;

    return unless $record;

    my $a = $self->ark;
    if ($a->doit) {
        my $fc = GetFrameworkCode($biblionumber);
        ModBiblio( $record->as('Legacy'), $biblionumber, $fc );
    }
    $a->current->{after} = Koha::Contrib::ARK::tojson($record)
        if $a->debug;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Koha::Contrib::ARK::Writer - Write biblio records into Koha Catalog

=head1 VERSION

version 1.0.3

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
