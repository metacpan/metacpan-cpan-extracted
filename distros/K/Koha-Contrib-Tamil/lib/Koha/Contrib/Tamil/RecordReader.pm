package Koha::Contrib::Tamil::RecordReader;
#ABSTRACT: Koha biblio/authority records reader
$Koha::Contrib::Tamil::RecordReader::VERSION = '0.063';
use Moose;

with 'MooseX::RW::Reader';


use Modern::Perl;
use utf8;
use Moose::Util::TypeConstraints;
use MARC::Record;
use MARC::File::XML;
use C4::Context;
use C4::Biblio;
use C4::Items;


subtype 'Koha::RecordType'
    => as 'Str',
    => where { /biblio|authority/i },
    => message { "$_ is not a valid Koha::RecordType (biblio or authority" };

subtype 'Koha::RecordSelect'
    => as 'Str',
    => where { /all|queue|queue_update|queue_delete/ },
    => message {
        "$_ is not a valide Koha::RecordSelect " .
        "(all or queue or queue_update or queue_delete)"
    };

has koha => ( is => 'rw', isa => 'Koha::Contrib::Tamil::Koha', required => 1 );

has source => (
    is       => 'rw',
    isa      => 'Koha::RecordType',
    required => 1,
    default  => 'biblio',
);

has select => (
    is       => 'rw',
    isa      => 'Koha::RecordSelect',
    required => 1,
    default  => 'all',
);

has xml => ( is => 'rw', isa => 'Bool', default => '0' );

has sth => ( is => 'rw' );

# Last returned record biblionumber;
has id => ( is => 'rw' );

# Items extraction required
has itemsextraction => ( is => 'rw', isa => 'Bool', default => 0 );

# Biblio records normalizer, if necessary
has normalizer => ( is => 'rw' );

# Read all records? (or queued records)
has allrecords => ( is => 'rw', isa => 'Bool', default => 1 );

# Mark as done an entry is Zebra queue
has sth_queue_done => ( is => 'rw' );

# SQL statement to get marcxml record
has sth_biblio => ( is => 'rw' );
has sth_biblio_del => ( is => 'rw' );

# Items tag
has itemtag => ( is => 'rw' );

# Las returned record frameworkcode
# FIXME: a KohaRecord class should contain this information 
has frameworkcode => ( is => 'rw', isa => 'Str' );


sub BUILD {
    my $self = shift;
    my $dbh  = $self->koha->dbh;

    # Récupération du tag contenant les exemplaires
    my ( $itemtag, $itemsubfield ) = GetMarcFromKohaField("items.itemnumber",'');
    $self->itemtag($itemtag);

    # Koha version => items extraction if >= 3.4
    my $version = C4::Context->preference('Version');
    $self->itemsextraction(
        $version =~ /^3/ && $version ge '3.04' || $version =~ /^[0-9]{2}/ ? 1 : 0 );

    if ( $version ge '3.09' && $self->source =~ /biblio/i &&
         C4::Context->preference('IncludeSeeFromInSearches') )
    {
        require Koha::RecordProcessor;
        my $normalizer = Koha::RecordProcessor->new( { filters => 'EmbedSeeFromHeadings' } );
        $self->normalizer($normalizer);
        # Necessary for as_xml method
        MARC::File::XML->default_record_format( C4::Context->preference('marcflavour') );
    }

    # Since version 17.05 marcxml biblio record is stored in biblio_metadata table.
    if ( $version =~ /^([0-9]{2})/ && $1 >= 17 ) {
        $self->sth_biblio( $dbh->prepare(
            "SELECT metadata FROM biblio_metadata WHERE biblionumber=? " ) );
        $self->sth_biblio_del( $dbh->prepare(
            "SELECT metadata FROM deletedbiblio_metadata WHERE biblionumber=? " ) );
    }
    else {
        $self->sth_biblio( $dbh->prepare(
            "SELECT marcxml FROM biblioitems WHERE biblionumber=? " ) );
        $self->sth_biblio_del( $dbh->prepare(
            "SELECT marcxml FROM deletedbiblioitems WHERE biblionumber=? " ) );
    }

    my $operation = $self->select =~ /update/i
                    ? 'specialUpdate'
                    : 'recordDelete';
    $self->allrecords( $self->select =~ /all/i ? 1 : 0 );
    my $sql =
        $self->source =~ /biblio/i
            ? $self->allrecords
                ? "SELECT NULL, biblionumber FROM biblio"
                : "SELECT id, biblio_auth_number FROM zebraqueue
                   WHERE server = 'biblioserver'
                     AND operation = '$operation' AND done = 0"
            : $self->allrecords
                ? "SELECT NULL, authid FROM auth_header"
                : "SELECT id, biblio_auth_number FROM zebraqueue
                   WHERE server = 'authorityserver'
                     AND operation = '$operation' AND done = 0";
    my $sth = $self->koha->dbh->prepare( $sql );
    $sth->execute();
    $self->sth( $sth );

    unless ( $self->allrecords ) {
        $self->sth_queue_done( $self->koha->dbh->prepare(
            "UPDATE zebraqueue SET done=1 WHERE id=?" ) );
    }
    
    __PACKAGE__->meta->add_method( 'get' =>
        $self->source =~ /biblio/i
            ? $self->xml && !$self->normalizer
              ? \&get_biblio_xml
              : \&get_biblio_marc
            : $self->xml
              ? \&get_auth_xml
              : \&get_auth_marc
    );
}



sub read {
    my $self = shift;
    while ( my ($queue_id, $id) = $self->sth->fetchrow ) {
        # Suppress entry in zebraqueue table
        $self->sth_queue_done->execute($queue_id) if $queue_id;
        if ( my $record = $self->get( $id ) ) {
            $record = $self->normalizer->process($record) if $self->normalizer;
            $self->count($self->count+1);
            $self->id( $id );
            return $record;
        }
    }
    return 0;
}



sub get_biblio_xml {
    my ($self, $id) = @_;

    $self->sth_biblio->execute( $id );
    my ($marcxml) = $self->sth_biblio->fetchrow;
    unless ( $marcxml ) {
        $self->sth_biblio_del->execute( $id );
        ($marcxml) = $self->sth_biblio_del->fetchrow;
    }

    # Items extraction if Koha v3.4 and above
    # FIXME: It slows down drastically biblio records export
    if ( $self->itemsextraction ) {
        my @items = @{ $self->koha->dbh->selectall_arrayref(
            "SELECT * FROM items WHERE biblionumber=$id",
            {Slice => {} } ) };
        if (@items){
            my $record = MARC::Record->new;
            $record->encoding('UTF-8');
            my @itemsrecord;
            my $not_onloan_count = 0;
            foreach my $item (@items) {
                $not_onloan_count++ unless $item->{onloan};
                my $record = Item2Marc($item, $id);
                push @itemsrecord, $record->field($self->itemtag);
            }
            push @itemsrecord, MARC::Field->new('999', ' ', ' ', 'x' => $not_onloan_count);
            $record->insert_fields_ordered(@itemsrecord);
            my $itemsxml = $record->as_xml_record();
            $marcxml =
                substr($marcxml, 0, length($marcxml)-10) .
                substr($itemsxml, index($itemsxml, "</leader>\n", 0) + 10);
        }
    }
    if ( C4::Context->preference('Frantiq') ) {
        require Frantiq::Pactol::BiblioNormalizer;
        Frantiq::Pactol::BiblioNormalizer::process(\$marcxml);
    }
    return $marcxml;
}


# Same as Koha::Contrib::Tamil::get_biblio_marc, but if the record doesn't
# exist in biblioitems, it is search in deletedbiblioitems.
sub get_biblio_marc {
    my ( $self, $id ) = @_;

    $self->sth_biblio->execute( $id );
    my ($marcxml) = $self->sth_biblio->fetchrow;
    unless ( $marcxml ) {
        $self->sth_biblio_del->execute( $id );
        ($marcxml) = $self->sth_biblio_del->fetchrow;
    }

    $marcxml =~ s/[^\x09\x0A\x0D\x{0020}-\x{D7FF}\x{E000}-\x{FFFD}\x{10000}-\x{10FFFF}]//g;
    my $record = MARC::Record->new();
    if ($marcxml) {
        $record = eval { 
            MARC::Record::new_from_xml( $marcxml, "utf8" ) };
        if ($@) { warn " problem with: $id : $@ \n$marcxml"; }

        # Items extraction if Koha v3.4 and above
        # FIXME: It slows down drastically biblio records export
        if ( $self->itemsextraction ) {
            my @items = @{ $self->koha->dbh->selectall_arrayref(
                "SELECT * FROM items WHERE biblionumber=$id",
                {Slice => {} } ) };
            if (@items){
                my @itemsrecord;
                foreach my $item (@items) {
                    my $record = Item2Marc($item, $id);
                    push @itemsrecord, $record->field($self->itemtag);
                }
                $record->insert_fields_ordered(@itemsrecord);
            }
        }
        return $record;
    }
    return;
}


sub get_auth_xml {
    my ( $self, $id ) = @_;
    my $sth = $self->koha->dbh->prepare(
        "select marcxml from auth_header where authid=? "  );
    $sth->execute( $id );
    my ($xml) = $sth->fetchrow;

    # If authority isn't found we build a mimimalist record
    # Usefull for delete Zebra requests
    unless ( $xml ) {
        return
            "<record 
               xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"
               xsi:schemaLocation=\"http://www.loc.gov/MARC21/slim http://www.loc.gov/standards/marcxml/schema/MARC21slim.xsd\"
               xmlns=\"http://www.loc.gov/MARC21/slim\">
             <leader>                        </leader>
             <controlfield tag=\"001\">$id</controlfield>
             </record>\n";
    }

    my $new_xml = '';
    foreach ( split /\n/, $xml ) {
        next if /^<collection|^<\/collection/;
        $new_xml .= "$_\n";
    }
    return $new_xml;
}


no Moose;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Koha::Contrib::Tamil::RecordReader - Koha biblio/authority records reader

=head1 VERSION

version 0.063

=head1 SYNOPSYS

  # Read all biblio records and returns MARC::Record objects
  # Do it for a default Koha instace.
  my $reader = Koha::Contrib::Tamil::RecordReader->new( koha => Koha->new() );
  while ( $record = $reader->read() ) {
      print $record->as_formatted(), "\n";
  }

  my $reader = Koha::Contrib::RecordReader->new(
    koha => k$, source => 'biblio', select => 'all' );

  my $reader = Koha::Contrib::Tamil::RecordReader->new(
    koha => k$, source => 'biblio', select => 'queue' );

  my $k = Koha::Contrib::Tamil::Koha->new(
    '/usr/local/koha-world/etc/koha-conf.xml' );
  # Return XML records.
  my $reader = Koha::Contrib::Tamil::RecordReader->new(
    koha => k$, source => authority, select => 'queue', xml => 1 );

=head1 AUTHOR

Frédéric Demians <f.demians@tamil.fr>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Fréderic Démians.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
