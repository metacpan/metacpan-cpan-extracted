package Koha::Contrib::Mirabel;
$Koha::Contrib::Mirabel::VERSION = '1.0.0';
# ABSTRACT: Synchronise un catalogue Koha avec Mir@bel
use Moose;

use Modern::Perl;
use utf8;
use FindBin qw($Bin);
use List::Util qw/first/;
use YAML qw/LoadFile Dump/;
use XML::Simple;
use LWP::Simple;
use DateTime;
use C4::Biblio;
use MARC::Moose::Record;
use MARC::Moose::Field::Std;



has url => (
    is => 'rw',
    isa => 'Str',
    default => 'http://www.reseau-mirabel.info/site/service?',
);



has partenaire => ( is => 'rw', isa => 'Int' );



has tag => ( is => 'rw', isa => 'Str' );



has verbose => ( is => 'rw', isa => 'Bool', default => 1 );



has doit => ( is => 'rw', isa => 'Bool', default => 0 );


sub BUILD {
    my $self = shift;

    my $partenaire = C4::Context->preference('MirabelPartenaire');
    die "Il manque la préférence MirabelPartenaire" unless $partenaire;
    $self->partenaire($partenaire);

    my $tag = C4::Context->preference('MirabelTag');
    die "Il manque la préférence MirabelTag" unless $tag;
    $self->tag($tag);
}


sub get_biblio {
    my ($self, $biblionumber) = @_;

    my $record = GetMarcBiblio( { biblionumber => $biblionumber } );
    return unless $record;
    return MARC::Moose::Record::new_from($record, 'Legacy');
}


sub update {
    my ($self, $biblionumber, $services) = @_;

    say '_' x 40, " #$biblionumber" if $self->verbose;

    my $record = $self->get_biblio($biblionumber);
    unless ($record) {
        say 'ERREUR: Notice présente dans Mir@bel mais supprimée du Catalogue Koha'
            if $self->verbose;
        return;
    }
    print $record->as('Text') if $self->verbose;

    # On supprime de la notice biblio les champs cibles existants
    $record->delete( $self->tag );

    for my $service (@$services) {
        say "Mir\@bel #", $service->{id}, "\n",
            join("\n",
                 map { "  $_: " . $service->{$_} } grep { $_ ne 'id' }
                    keys %$service )
          if $self->verbose;
        my @sf = (
            [ 3 => $service->{id} ],
            [ 4 => $service->{type} ],
            [ a => $service->{urldirecte} || $service->{urlservice} ],
            [ b => $service->{nom} ],
        );
        if (my $value = $service->{acces}) { push @sf, [ c => $value ]; }

        my @coll;
        push @coll, $service->{debut} if $service->{debut};
        push @coll, '-';
        push @coll, $service->{fin} if $service->{fin};
        push @sf, [ d => join('', @coll) ] if @coll > 1;

        if (my $value = $service->{couverture}) { push @sf, [ e => $value ]; }
        if (my $value = $service->{lacunaire}) { push @sf, [ f => $value ]; }
        $record->append( MARC::Moose::Field::Std->new(
            tag => $self->tag, subf => \@sf ) );
    }
    print "\nAPRÈS:\n", $record->as('Text') if $self->verbose;

    # On réécrit la notice
    if ( $self->doit ) {
        $record = $record->as('Legacy');
        ModBiblioMarc( $record, $biblionumber, GetFrameworkCode($biblionumber) );
    }
}



sub sync {
    my $self = shift;

    if ($self->verbose) {
        say "Synchro";
        say "** TEST **" unless $self->doit;
    }

    my $doc = get($self->url . 'partenaire=' . $self->partenaire);
    my $xml = XML::Simple->new(
        keyattr => [], SuppressEmpty => 1,
        ForceArray => [ 'revue', 'service' ], );
    my $result = $xml->XMLin($doc);

    for my $revue (@{$result->{revue}}) {
        $self->update($revue->{idpartenairerevue}, $revue->{services}->{service});
    }
}



sub all_bibs {
    my $tag = shift->tag;
    my $query =
        "SELECT biblionumber " .
        "FROM   biblio_metadata " .
        "WHERE  ExtractValue(metadata,'//datafield[\@tag=$tag]/subfield[\@code]')";
    my $st = C4::Context->dbh->prepare($query);
    $st->execute;
    my @bibs;
    while (my ($biblionumber) = $st->fetchrow ) {
        push @bibs, $biblionumber;
    }
    return \@bibs;
}
    


sub clean {
    my $self = shift;

    if ($self->verbose) {
        say "Suppression dans Koha des services retirés de Mir\@bel depuis un an";
        say "** TEST **" unless $self->doit;
    }

    # Récupération des identifiants des services supprimés depuis un an
    my $dt = DateTime->now->subtract( years => 1 );
    my $doc = get($self->url . 'suppr=' . $dt->ymd);
    my $xml = XML::Simple->new( ForceArray => [ 'service' ], );
    my $result = $xml->XMLin($doc);
    my @ids = sort { $a <=> $b } @{$result->{service}};
    my %is_removed_id = map { $_ => 1 } @ids;
    say "Services supprimés : ", join(', ', @ids), "\n" if $self->verbose;

    # Modification des notices contenant un service supprimé
    my $found = 0;
    my $tag = $self->tag;
    for my $biblionumber (@{$self->all_bibs}) {
        my $record = GetMarcBiblio($biblionumber);
        $record = MARC::Moose::Record::new_from($record, 'Legacy');
        my $has_id = 0;
        for my $field ( $record->field($tag) ) {
            my $id = first { $_->[0] eq '3' } @{$field->subf};
            next unless $id;
            $has_id = $is_removed_id{$id->[1]};
            last if $has_id;
        }
        next unless $has_id;
        $found = 1;

        say '_' x 40, " #$biblionumber";
        print $record->as('Text') if $self->verbose;

        # On supprime les zones dont l'id ($3) appartient à la liste des
        # services Mir@bel supprimés
        $record->fields( [ grep {
            $_->tag eq $tag
            ? ! first { $_->[0] eq '3' && $is_removed_id{$_->[1]} } @{$_->subf}
            : 1
        } @{$record->fields} ] );

        print "APRÈS\n", $record->as('Text') if $self->verbose;
        if ( $self->doit ) {
            $record = $record->as('Legacy');
            ModBiblioMarc( $record, $biblionumber, GetFrameworkCode($biblionumber) );
        }
    }

    say "Aucune notice ne contient de service Mir\@bel supprimé"
        if !$found && $self->verbose;
}


sub full_clean {
    my $self = shift;

    if ($self->verbose) {
        say "Suppression dans Koha de tous les champs Mir\@bel";
        say "** TEST **" unless $self->doit;
    }

    for my $biblionumber (@{$self->all_bibs}) {
        my $record = $self->get_biblio($biblionumber);
        next unless $record->field($self->tag); # Impossible normalement...
        say '_' x 40, " #$biblionumber";
        print $record->as('Text') if $self->verbose;
        $record->delete( $self->tag );
        print "APRÈS\n", $record->as('Text') if $self->verbose;
        if ( $self->doit ) {
            $record = $record->as('Legacy');
            ModBiblioMarc( $record, $biblionumber, GetFrameworkCode($biblionumber) );
        }
    }
}


__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Koha::Contrib::Mirabel - Synchronise un catalogue Koha avec Mir@bel

=head1 VERSION

version 1.0.0

=head1 ATTRIBUTES

=head2 partenaire

Le numéro de partenaire Mir@bel. Récupéré dans la préférence MirabelPartenaire
de l'instance courtante de Koha.

=head2 tag

Le tag du champ des notices biblio où se trouvent les infor Mir@bel. Récupéré
dans la préférence MirabelTag de l'instance courtante de Koha.

=head2 verbose

Mode verbeux pas défaut. Ecrit sur la sortie standard des info sur les
traitements réalisés.

=head2 doit

Effecture réellement les traitements de mise à jour du Catalogue Koha. Par défaut NON.

=head1 METHODS

=head2 sync

Synchronise le Catalogue Koha avec les info de Mir@bel.

=head2 all_bibs

Retourne un ArrayRef des biblionumbers des notices ayant au moins un service
Mir@bel dans MirabelTag

=head2 clean

Nettoie les notices du Catalogue Koha des info Mir@bel qui ont été supprimées
de Mir@bel depuis 1 an.

=head2 full_clean

Supprime tous les champs MirabelTag des notices du Catalogue Koha.

=head1 AUTHOR

Frédéric Demians <f.demians@tamil.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Frédéric Demians.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
