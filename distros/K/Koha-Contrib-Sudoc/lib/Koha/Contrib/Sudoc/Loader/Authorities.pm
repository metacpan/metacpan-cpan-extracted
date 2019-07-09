package Koha::Contrib::Sudoc::Loader::Authorities;
# ABSTRACT: Chargeur de notices d'autorité
$Koha::Contrib::Sudoc::Loader::Authorities::VERSION = '2.31';
use Moose;

extends 'Koha::Contrib::Sudoc::Loader';

use Modern::Perl;
use utf8;
use C4::AuthoritiesMarc;
use MARC::Moose::Record;


sub handle_record {
    my ($self, $record) = @_;

    # FIXME: Ici et pas en-tête parce qu'il faut que l'environnement Shell soit
    # déjà fixé avant de charger ces modules qui ont besoin de KOHA_CONF et qui
    # le garde
    use C4::Biblio;
    use C4::Items;

    my $conf = $self->sudoc->c->{auth};

    # FIXME Reset de la connexion tous les x enregistrements
    $self->sudoc->koha->zconn_reset()  unless $self->count % 100;

    my $ppn = $record->field('001')->value;
    $self->log->notice( 'Autorité #' . $self->count . " ppn $ppn\n");
    my $record_text = $record->as('Text');
    $self->log->debug( $record_text );

    # On détermine le type d'autorité
    my $authtypecode;
    my $typefromtag = $conf->{typefromtag};
    for my $tag ( keys %$typefromtag ) {
        if ( $record->field($tag) ) {
            $authtypecode = $typefromtag->{$tag};
            last;
        }
    }
    unless ( $authtypecode ) {
        $self->warning("  ERREUR : Autorité sans vedette\n");
        return;
    }

    # On déplace le PPN de 001 en 009
    $self->sudoc->ppn_move($record, $conf->{ppn_move});

    # Y a-t-il déjà dans la base Koha une autorité ayant ce PPN ?
    # Si oui, on ajoute son authid à l'autorité entrante afin de forcer sa mise
    # à jour.
    my ($authid, $auth) = $self->sudoc->koha->get_auth_by_ppn($ppn);
    if ( $auth ) {
        $record->append(
            MARC::Moose::Field::Control->new( tag => '001', value => $authid) );
        $self->count_replaced( $self->count_replaced + 1 );
    }
    else {
        $self->count_added( $self->count_added + 1 );
    }

    if ( $self->doit ) {
        my $legacy = $record->as('Legacy');
        # FIXME: Bug SUDOC, certaines notices UTF8 n'ont pas 50 en position 13
        my $field = $legacy->field('100');
        if ( $field ) {
            my $value = $field->subfield('a');
            my $enc = substr($value, 13, 2);
            if ( $enc ne '50' ) {
                $self->log->warning(
                    "  Attention ! mauvais encodage en position 13. On le corrige.\n" );
                substr($value, 13, 2) = '50';
                $field->update( a => $value );
            }
        }
        ($authid) = AddAuthority($legacy, $authid, $authtypecode);
    }

    $authid = 0 unless $authid;
    $self->log->notice(
        ( $auth ? "  * Remplace $authid" : "  * Ajoute $authid" )
        . "\n"
    );
    $self->log->debug( "\n" );


    # On cherche un 035 avec $9 sudoc qui indique une fusion d'autorité Sudoc
    # 035$a contient le PPN de la notice qui a été fusionnée avec la notice en
    # cours de traitement.  On retrouve les notices biblio Koha liées à
    # l'ancienne autorité et on les modifie pour qu'elle pointent sur la
    # nouvelle autorité.
    for my $field ( $record->field('035') ) {
        my $sudoc = $field->subfield('9');
        next unless $sudoc && $sudoc =~ /sudoc/i;
        my $obsolete_ppn = $field->subfield('a');
        my ($obsolete_authid, $auth) =
            $self->sudoc->koha->get_auth_by_ppn($obsolete_ppn);
        next unless $auth;
        $self->log->notice(
          "  Fusion Sudoc avec cette autorité d'une autorité obsolète : " .
          "ppn $obsolete_ppn, authid $obsolete_authid\n" );
        my @modified_biblios;
        for ( $self->sudoc->koha->get_biblios_by_authid($obsolete_authid) ) {
            my ($biblionumber, $framework, $modif) = @$_;
            my $found = 0;
            for my $field ( $modif->field("[4-7]..") ) {
                $field->subf( [ map {
                    my ($letter, $value) = @$_;
                    if ( $letter eq '3' && $value eq $obsolete_ppn ) {
                        $value = $ppn;
                    }
                    elsif ( $letter eq '9' && $value eq $obsolete_authid ) {
                        $found = 1;
                        $value = $authid;
                    }
                    [ $letter, $value ];
                } @{$field->subf} ] );
            }
            if ( $found ) {
                push @modified_biblios, $biblionumber;
                $modif->delete('995');
                $self->log->debug( $modif->as('Text') );
                ModBiblio($modif->as('Legacy'), $biblionumber, $framework)
                    if $self->doit;
            }
        }
        if ( @modified_biblios ) {
            $self->log->notice(
                "  Notices biblio liées qui ont été modifiées : " .
                join(', ', @modified_biblios) . "\n" );
        }
    } 

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Koha::Contrib::Sudoc::Loader::Authorities - Chargeur de notices d'autoritÃ©

=head1 VERSION

version 2.31

=head1 AUTHOR

Frédéric Demians <f.demians@tamil.fr>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Fréderic Demians.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
