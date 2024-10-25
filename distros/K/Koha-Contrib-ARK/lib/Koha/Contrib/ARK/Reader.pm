package Koha::Contrib::ARK::Reader;
# ABSTRACT: Read Koha biblio records with/without ARK
$Koha::Contrib::ARK::Reader::VERSION = '1.1.2';
use Moose;
use Moose::Util::TypeConstraints;
use Modern::Perl;
use C4::Context;
use C4::Biblio;
use MARC::Moose::Record;

with 'MooseX::RW::Reader';


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

has fromwhere => (
    is => 'rw',
    isa => 'Str'
);


has total => ( is => 'rw', isa => 'Int', default => 0 );


has sth_bn => (is => 'rw');


sub BUILD {
    my $self = shift;
 
    my $dbh = C4::Context->dbh;
    my $fromwhere = "FROM biblio_metadata";
    if ($self->fromwhere) {
        $fromwhere .= " WHERE " . $self->fromwhere;
    }
    else {
        $fromwhere .= " WHERE " .
            $self->ark->field_query .
            ($self->select eq 'WithoutArk' ? " =''" : " <> ''" )
                if $self->select ne 'All';
    }

    #$fromwhere = "FROM biblio_metadata WHERE biblionumber=875167";

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

    my $biblio = Koha::Biblios->find($biblionumber);
    $self->ark->set_current($biblio);

    return 1;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Koha::Contrib::ARK::Reader - Read Koha biblio records with/without ARK

=head1 VERSION

version 1.1.2

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

This software is Copyright (c) 2024 by Fréderic Demians.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
