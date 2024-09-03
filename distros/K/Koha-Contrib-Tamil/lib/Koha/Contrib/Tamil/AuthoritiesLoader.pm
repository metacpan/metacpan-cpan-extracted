package Koha::Contrib::Tamil::AuthoritiesLoader;
#ABSTRACT: Authorities loader into a Koha instance
$Koha::Contrib::Tamil::AuthoritiesLoader::VERSION = '0.073';
use Moose;

extends 'AnyEvent::Processor';

use Carp;
use IO::File;
use C4::Context;


# Le nom du fichier les autorités
# Le fichier est au format:
# NP<TAB>a|Demians-Archimbaud<TAB>b|Frédéric
has input => ( is => 'rw', isa => 'Str' );

# Le filehandle du fichier lu
has input_fh => ( is => 'rw', isa => 'IO::File' );

# L'équivalence type auth vers tag autorité
# Lue dans la table auth_types
#   { NP => '100', CO => '200' }
has type_to_tag => ( is => 'rw', isa => 'HashRef' );


sub run  {
    my $self = shift;

    # On récupère l'équivalence type d'autorité => tag
    my %ttt;
    my $dbh = C4::Context->dbh();
    my $sth = $dbh->prepare( q(
        SELECT   authtypecode, auth_tag_to_report
        FROM     auth_types ) );
    $sth->execute;
    while ( my ( $authtypecode, $auth_tag_to_report ) = $sth->fetchrow ) {
        $ttt{ $authtypecode } = $auth_tag_to_report;
    }
    $self->type_to_tag( \%ttt );

    my $fh = IO::File->new( $self->input, 'r' );
    if ( $fh ) {
      $self->input_fh( $fh );
      $self->SUPER::run();
    }
    else {
        croak "Unable to open file: " . $self->input;
    }
};



sub process {
    my $self = shift;

    my $fh = $self->input_fh;
    my $line = $fh->getline();
    if ( $line ) {
        chop $line;
        $self->SUPER::process();
        my ( $type, $sub ) = $line =~ /(\w+)\t(.*)/;
        my ( @subfields ) = split /\t|\|/, $sub; 
        my $ttt = $self->type_to_tag;
        unless ( $ttt->{ $type } ) {
            croak "Unknown authority type code: " . $type;
        }        
      	if ( $#subfields > 0 ) {
            my $record = MARC::Record->new();
            my $leader = $record->leader();
            substr($leader, 5, 3) = 'naa';
            substr($leader, 9, 1) = 'a';    # encodage utf8
            $record->encoding( 'UTF-8' );
            $record->leader($leader);
            $record->append_fields( MARC::Field->new(
                $ttt->{ $type }, '', '', @subfields));
            #print "TYPE: $type\n", $record->as_formatted(), "\n\n";
            my ($authid) = AddAuthority($record, 0, $type);
    	}
        return 1;
    }

    # Fin du traitement
    close $self->input_fh;

    return 0;
}



no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Koha::Contrib::Tamil::AuthoritiesLoader - Authorities loader into a Koha instance

=head1 VERSION

version 0.073

=head1 AUTHOR

Frédéric Demians <f.demians@tamil.fr>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2024 by Fréderic Démians.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
