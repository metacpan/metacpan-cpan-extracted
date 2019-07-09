package Koha::Contrib::Sudoc::Loader::Biblios;
# ABSTRACT: Chargeur de notices biblio
$Koha::Contrib::Sudoc::Loader::Biblios::VERSION = '2.31';
use Moose;

extends 'Koha::Contrib::Sudoc::Loader';

use Modern::Perl;
use utf8;
use YAML;
use C4::Biblio;
use C4::Items;



# On cherche les notices doublons SUDOC. On renvoie la liste des notices
# Koha correspondantes.
sub doublons_sudoc {
    my ($self, $record) = @_;
    my @doublons;
    # On cherche un 035 avec $9 sudoc qui indique une fusion de notices Sudoc 035$a
    # contient le PPN de la notice qui a été fusionnée avec la notice en cours de
    # traitement.
    for my $field ( $record->field('035') ) {
        my $sudoc = $field->subfield('9');
        next unless $sudoc && $sudoc =~ /sudoc/i;
        my $ppn = $field->subfield('a');
        my ($biblionumber, $framework, $koha_record) =
            $self->sudoc->koha->get_biblio_by_ppn( $ppn );
        if ($koha_record) {
            $self->log->notice("  Fusion Sudoc du ppn $ppn avec le biblionumber $biblionumber\n");
            push @doublons, {
                ppn          => $ppn,
                record       => $koha_record,
                biblionumber => $biblionumber,
                framework    => $framework,
            };
        }
    } 
    return \@doublons;
}


sub handle_record {
    my ($self, $record) = @_;

    # FIXME Reset de la connexion tous les x enregistrements
    $self->sudoc->koha->zconn_reset()  unless $self->count % 10;

    my $ppn = $record->field('001')->value;
    $self->log->notice("Notice #" . $self->count . " ppn $ppn\n");
    $self->log->debug( $record->as('Text') );

    # On déplace le PPN
    $self->sudoc->ppn_move($record, $self->sudoc->c->{biblio}->{ppn_move});

    $self->converter->build($record);

    # Est-ce qu'il faut passer la notice ?
    if ( $self->converter->skip($record) ) {
        $record = undef;
        $self->count_skipped( $self->count_skipped + 1 );
        $self->log->notice( "  * Ignorée\n" );
        return;
    }

    # On cherche si la notice entrante ne se trouve pas déjà dans le
    # catalogue Koha.
    my ($biblionumber, $framework, $koha_record);
    ($biblionumber, $framework, $koha_record) =
        $self->sudoc->koha->get_biblio_by_ppn( $ppn );
    if ($koha_record) {
        $self->log->debug("  ppn trouvé dans la notice Koha $biblionumber\n");
    }
    else {
        # On cherche un 035 avec un $5 contenant un RCR de l'ILN, auquel cas $a contient
        # le biblionumber d'une notice Koha
        my $rcr_hash = $self->sudoc->c->{rcr};
        for my $field ( $record->field('035') ) {
            my $rcr = $field->subfield('5');
            next unless $rcr;
            next unless my $branch = $rcr_hash->{$rcr};
            next unless $biblionumber = $field->subfield('a');
            ($framework, $koha_record) =
                $self->sudoc->koha->get_biblio( $biblionumber );
            if ($koha_record) {
                $self->log->notice(
                  "  Fusion de la notice Koha $biblionumber trouvée en 035\$a " .
                  "pour le RCR $rcr ($branch)\n" );
                last;
            }
        }
    }

    # Les doublons SUDOC. Il n'y a qu'un seul cas où on peut en faire
    # quelque chose. Si on a déjà trouvé une notice Koha ci-dessus, on
    # ne peut rien faire : en effet, on a déjà une cible pour fusionner
    # la notice entrante. S'il y a plus d'un doublon qui correspond à
    # des notices Koha, on ne sait à quelle notice Koha fusionner la
    # notice entrante.
    my $doublons = $self->doublons_sudoc($record);
    if ( @$doublons ) {
        if ( $koha_record || @$doublons > 1 ) {
            $self->log->warning(
                "  Attention ! la notice entrante doit être fusionnées à plusieurs notices " .
                  "Koha existantes. À FAIRE MANUELLEMENT\n" );
        }
        else {
            # On fusionne le doublon SUDOC (unique) avec la notice SUDOC entrante
            my $d = shift @$doublons;
            ($biblionumber, $framework, $koha_record) =
                ($d->{biblionumber}, $d->{framework}, $d->{record});
        }
    }
    $self->converter->init( $record );
    $self->converter->authoritize( $record );
    $self->converter->linking( $record );
    $self->converter->itemize( $record, $koha_record );

    if ( $koha_record ) {
        # Modification d'une notice
        $self->count_replaced( $self->count_replaced + 1 );
        $self->converter->merge($record, $koha_record);
        $self->converter->clean($record);
        ModBiblio($record->as('Legacy'), $biblionumber, $framework)
            if $self->doit;
        $self->converter->biblio_modify($record, $biblionumber, $framework);
    }
    else {
        # Nouvelle notice
        $self->count_added( $self->count_added + 1 );
        $self->converter->clean($record);
        $framework = $self->converter->framework($record);
        if ( $self->doit ) {
            my $marc = $record->as('Legacy');
            my ($biblionumber, $biblioitemnumber) =
                AddBiblio($marc, $framework, { defer_marc_save => 1 });
            my ($itemnumbers_ref, $errors_ref) =
                AddItemBatchFromMarc($marc, $biblionumber, $biblioitemnumber, $framework);
            $self->log->warning( "erreur pendant l'ajout de l'exemplaire :\n" . Dump($errors_ref) )
                if @$errors_ref;
            C4::Biblio::_strip_item_fields($marc, $framework);
            ModBiblioMarc($marc, $biblionumber, $framework);
        }
        $self->converter->biblio_add($record, $biblionumber, $framework);
    }
    $self->log->debug("\n");
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Koha::Contrib::Sudoc::Loader::Biblios - Chargeur de notices biblio

=head1 VERSION

version 2.31

=head1 AUTHOR

Frédéric Demians <f.demians@tamil.fr>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Fréderic Demians.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
