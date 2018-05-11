package Koha::Contrib::ARK::Reader;
$Koha::Contrib::ARK::Reader::VERSION = '1.0.2';
# ABSTRACT: Read Koha biblio records with/without ARK
use Moose;

with 'MooseX::RW::Reader';

use Modern::Perl;
use C4::Context;
use C4::Biblio;
use MARC::Moose::Record;


has ark => ( is => 'rw', isa => 'Koha::Contrib::ARK' );


has emptyark => (
    is => 'rw',
    isa => 'Bool',
    default => 0,
);


has total => ( is => 'rw', isa => 'Int', default => 0 );


has sth_bn => (is => 'rw');


sub BUILD {
    my $self = shift;
 
    my $dbh = C4::Context->dbh;
    my $fromwhere = "FROM biblio_metadata WHERE " .
        $self->ark->field_query .
        ($self->emptyark ? " =''" : " <> ''" );

    my $total = $dbh->selectall_arrayref("SELECT COUNT(*) $fromwhere");
    $total = $total->[0][0];
    $self->total( $total );
    $self->ark->log->info("Number of records to process = $total\n");

    my $sth = $dbh->prepare("SELECT biblionumber $fromwhere");
    $sth->execute;
    $self->sth_bn($sth);
}


sub read {
    my $self = shift;

    my ($biblionumber) = $self->sth_bn->fetchrow();
    return unless $biblionumber;

    $self->count( $self->count + 1 );

    my $record = GetMarcBiblio({ biblionumber => $biblionumber });
    $record = MARC::Moose::Record::new_from($record, 'Legacy');
    $self->ark->log->info("Biblio #$biblionumber\n");
    $self->ark->log->debug("ORIGINAL BIBLIO:\n", $record->as('Text')) if $record;

    return [$biblionumber, $record];
}


sub percentage {
    my $self = shift;
    my $p = ($self->count * 100) / $self->total;
    return sprintf("%.2f", $p);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Koha::Contrib::ARK::Reader - Read Koha biblio records with/without ARK

=head1 VERSION

version 1.0.2

=head1 ATTRIBUTES

=head2 ark

L<Koha::Contrib::ARK> object.

=head2 emptyark

If true, read biblio record without ARK. If false, read biblio records with
ARK. By default, false.

=head2 total

Total of records to read

=head1 AUTHOR

Frédéric Demians <f.demians@tamil.fr>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Fréderic Demians.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
