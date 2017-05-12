package Retro;
# ABSTRACT: Convertisseur spécifique pour une rétroconversion

use Moose;

extends 'Koha::Contrib::Sudoc::Converter';


override 'merge' => sub {
    my ($self, $sudoc, $koha) = @_;

    # On ajoute à la notice Koha les champ 6xx et 995 de la notice Sudoc
    my @tags = ( (map { sprintf("6%02d", $_) } ( 0..99 )), '995');
    for my $tag (@tags) {
        my @fields = $sudoc->field($tag); 
        next unless @fields;
        $koha->append(@fields);
    }

    # On ajoute à la notice Koha les champs de la notice Sudoc qui n'existe
    # pas déjà dans la notice Koha, exception faite des champs traités plus
    # haut et du champ 410.
    my @all_tags = map { sprintf("%03d", $_) } ( 1..999 );
    for my $tag (@all_tags) {
        next if $tag ~~ @tags || $tag == '410'; # On passe, déjà traité plus haut
        my @fields = $sudoc->field($tag);
        next unless @fields;
        next if $koha->field($tag);
        $koha->append(@fields);
    }

    # On remplace la notice Sudoc par la notice Koha.
    $sudoc->fields( $koha->fields );
};


# Les champs à supprimer de la notice entrante.
my @todelete = qw(035 917 930 991 999);

after 'clean' => sub {
    my ($self, $record) = @_;

    # Suppression des champs SUDOC dont on ne veut pas dans le catalogue
    $record->fields( [ grep { not $_->tag ~~ @todelete } @{$record->fields} ] );
};


1;
