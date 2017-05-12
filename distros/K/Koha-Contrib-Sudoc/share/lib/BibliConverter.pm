package BibliConverter;
# ABSTRACT: Convertisseur spécifique

use Moose;

extends 'Koha::Contrib::Sudoc::Converter';

use MARC::Moose::Field::Std;


sub record_is_peri {
    my $record = shift;
    my $leader = $record->leader();
    $leader && substr($leader, 7, 1) eq 's';
}


# On supprime purement et simplement les notices PERI qui n'ont pas
# de zone 955
override skip => sub {
    my ($self, $record) = @_;
    record_is_peri($record) && not $record->field('955') ? 1 : 0;
};


after init => sub {
    my ($self, $sudoc) = @_;

    # Déplacement des zones 606 locales (avec $5) en 610
    for my $field ($sudoc->field('606') ) {
        next unless $field->subfield('5');
        $field->tag('610');
        $field->subf( [ grep { not $_->[0] =~ /2|5/ } @{$field->subf} ] );
    }
};


# Création des exemplaires Koha en 995 en fonction des données locales SUDOC
after 'itemize' => sub {
    my ($self, $record) = @_;

    # On reprend tout, donc on efface les exemplaires créés avec la
    # logique par défaut
    $record->delete('995');

    # On ne crée pas d'exemplaire pour les périodiques
    return if record_is_peri($record);

    # On crée les exemplaires à partir de 930, 915 et 999
    my $myrcr = $self->sudoc->c->{rcr};
    my $f999; # Le champ 999 courant
    my $subf;   # Les sous-champs en cours de construction
    my $append = sub { # Ajout à $subf d'un sous-champ de $f999
        my $letter = shift;
        return unless $f999;
        my $value = $f999->subfield($letter);
        return unless $value;
        push @$subf, [ $letter => $value ];
    };
    while ( my ($rcr, $item_rcr) = each %{$self->item} ) {
        my $branch = $myrcr->{$rcr};
        while ( my ($id, $ex) = each %$item_rcr ) { # Les exemplaires d'un RCR
            $subf = [];
            $f999 = $ex->{999};

            $append->('a');

            # $b et $c = Les codes de site Koha
            push @$subf, [ b => $branch ], [ c => $branch ];

            # $d = Le code rétroconversion de 991$a
            my $value = $ex->{991};
            if ( $value ) {
                $value = $value->subfield('a');
                push @$subf, [ d => $value ] if $value;
            }

            $append->('e');

            # $f Code à barres
            # On prend le code à barres en 915$b, et s'il n'y en a pas on prend
            # l'EPN SUDOC ($id)
            $value = $ex->{915};
            $value = $value->subfield('b')  if $value;
            $value = $id unless $value;
            push @$subf, [ f => $value ];

            $append->($_) for ( "g" .. "i" );

            # $j Numéro d'inventaire
            $append->('j');

            # $k Cote = 930$a
            $value = $ex->{930}->subfield('a');
            push @$subf, [ k => $value ] if $value;

            # On copie telles quelles toutes les lettres de 999 en 995
            # pour l'intervalle l..z
            $append->($_) for ( "l" .. "z" );
            $record->append( MARC::Moose::Field::Std->new(
                tag => '995',
                subf => $subf ) );
        }
    }
};


# Les champs à supprimer de la notice entrante.
my @todelete = qw( 915 917 930 991 999);
 
after 'clean' => sub {
    my ($self, $record) = @_;
    
    # Pour les périodiques, on place les cotes en 687, on ne crée pas
    # d'exemplaires.
    if ( record_is_peri($record) ) {
        while ( my ($rcr, $item_rcr) = each %{$self->item} ) {
            while ( my ($id, $ex) = each %$item_rcr ) {
                my @sf;
                my $value = $ex->{930}->subfield('a');
                push @sf, [ a => $value ] if $value;
                $value = $ex->{930}->subfield('z');
                push @sf, [ z => $value ] if $value;
                $record->append( MARC::Moose::Field::Std->new(
                    tag => '687',
                    subf => \@sf ) ) if @sf;
            }
        }
    }

    # On détermine le type de doc biblio
    my $tdoc;
    if ( record_is_peri($record) ) {
        $tdoc = 'PERI';
    }
    elsif ( my $field = $record->field('999') ) {
        $tdoc = $field->subfield('r');
    }
    $tdoc = 'MONO' unless $tdoc;
    my $invisible = 0;

    # Suppression des champs SUDOC dont on ne veut pas dans le catalogue
    # Koha
    $record->fields( [ grep { not $_->tag ~~ @todelete } @{$record->fields} ] );

    $record->append( MARC::Moose::Field::Std->new(
        tag => '915', 
        subf => [
            [ a => $tdoc      ],
            [ b => $invisible ],
        ] ) );

    # On supprime 995 pour les articles et les périodiques
    $record->fields( [ grep { not $_->tag eq '995' } @{$record->fields} ] )
        if $tdoc eq 'PERI' || $tdoc eq 'ART';
};


# Trois frameworks : biblio->framework, ART et PER. Toute notice est associée
# à biblio->framework sauf les notices de périodique PER et d'article (ART)
override 'framework' => sub {
    my ($self, $record) = @_;
    record_is_peri($record) ? 'PER' : 
    $record->field('463')   ? 'ART' : $self->SUPER::framework($record);
};

1;