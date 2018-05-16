package Koha::Contrib::ARK::Reader;
$Koha::Contrib::ARK::Reader::VERSION = '1.0.3';
# ABSTRACT: Read Koha biblio records with/without ARK
use Moose;

with 'MooseX::RW::Reader';

use Moose::Util::TypeConstraints;
use Modern::Perl;
use C4::Context;
use C4::Biblio;
use MARC::Moose::Record;


has ark => ( is => 'rw', isa => 'Koha::Contrib::ARK' );


subtype 'BiblioSelect'
    => as 'Str'
    => where { $_ =~ /WithArk|WithoutArk|All/ }
    => message { 'Invalid biblio selection' };

has select => (
    is => 'rw',
    isa => 'BiblioSelect',
    default => 'All',
);

has total => ( is => 'rw', isa => 'Int', default => 0 );


has sth_bn => (is => 'rw');


sub BUILD {
    my $self = shift;
 
    my $dbh = C4::Context->dbh;
    my $fromwhere = "FROM biblio_metadata";
    $fromwhere .= " WHERE " .
        $self->ark->field_query .
        ($self->select eq 'WithoutArk' ? " =''" : " <> ''" )
            if $self->select ne 'All';

    my $total = $dbh->selectall_arrayref("SELECT COUNT(*) $fromwhere");
    $total = $total->[0][0];
    $self->total( $total );

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
    
    $self->ark->set_current( $biblionumber, $record );

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

version 1.0.3

=head1 ATTRIBUTES

=head2 ark

L<Koha::Contrib::ARK> object.

=head2 select

Selection of biblio records : All, WithArk, WithoutArk

=head2 total

Total of records to read

=head1 AUTHOR

Frédéric Demians <f.demians@tamil.fr>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Fréderic Demians.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
