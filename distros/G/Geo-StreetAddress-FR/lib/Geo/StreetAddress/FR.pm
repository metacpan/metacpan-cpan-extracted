package Geo::StreetAddress::FR;

use warnings;
use strict;
use Carp;

use base qw(Class::Accessor::Fast);

our $VERSION = '0.0.4';

__PACKAGE__->mk_accessors( qw(adresse  message) );

our %extension_type_with_number = (
    'etg'    => 'etage',
    'et'     => 'etage',
    'etage'  => 'etage',
    'ent'    => 'entree',
    'entree' => 'entree',
);

our %extension_type = (
    'res'                => 'residence',
    'resid'              => 'residence',
    'residence'          => 'residence',
    'bat'                => 'batiment',
    'batiment'           => 'batiment',
    'cour'               => 'cours',
    'cours'              => 'cours',
    'foyer'              => 'foyer',
    'ferme'              => 'ferme',
    'hlm'                => 'immeuble',
    'immeuble'           => 'immeuble',
    'immeubles'          => 'immeuble',
    'esc'                => 'escalier',
    'escalier'           => 'escalier',
    'porte'              => 'porte',
    'maison de retraite' => 'maison',
    'Mais Retr'          => 'maison',
);

our %street_type = (
    'all'               => 'allee',
    'allee'             => 'allee',
    'allees'            => 'allee',
    'av'                => 'avenue',
    'avenue'            => 'avenue',
    'bd'                => 'boulevard',
    'bld'               => 'boulevard',
    'bois'              => 'bois',
    'boulevard'         => 'boulevard',
    'bourg'             => 'bourg',
    'cami'              => 'cami',
    'camp militaire'    => 'militaire',
    'carrefour'         => 'carrefour',
    'cavee'             => 'cavee',
    'centre commercial' => 'commerce',
    'ch'                => 'chateau',
    'chat'              => 'chateau',
    'chateau'           => 'chateau',
    'chaussee'          => 'chaussee',
    'chauss'            => 'chaussee',
    'che'               => 'chemin',
    'chem'              => 'chemin',
    'chemin'            => 'chemin',
    'cht'               => 'chateau',
    'cite'              => 'cite',
    'cloitre'           => 'cloitre',
    'clos'              => 'clos',
    'domaine'           => 'domaine',
    'esplanade'         => 'esplanade',
    'faubourg'          => 'faubourg',
    'fbg'               => 'faubourg',
    'fg'                => 'fg',
    'gde rue'           => 'rue',
    'gr'                => 'rue',
    'grand cour'        => 'cours',
    'grand rue'         => 'rue',
    'grande route'      => 'route',
    'grande rue'        => 'rue',
    'hameau'            => 'hameau',
    'imp'               => 'impasse',
    'impasse'           => 'impasse',
    'jardin'            => 'jardin',
    'jardins'           => 'jardin',
    'ldt'               => 'lieu',
    'lieu dit'          => 'lieu',
    'lot'               => 'lotissement',
    'lotiss'            => 'lotissement',
    'lotissement'       => 'lotissement',
    'mail'              => 'mail',
    'marche'            => 'marche',
    'montee'            => 'montee',
    'moulin'            => 'moulin',
    'parc'              => 'parc',
    'passage'           => 'passage',
    'passe'             => 'passee',
    'pavillon'          => 'pavillon',
    'petite route'      => 'route',
    'petite rue'        => 'petite rue',
    'pl'                => 'place',
    'place'             => 'place',
    'placette'          => 'place',
    'promenade'         => 'promenade',
    'quai'              => 'quai',
    'quartier'          => 'quartier',
    'quart'             => 'quartier',
    'rampe'             => 'rampe',
    'rdpt'              => 'rondpoint',
    'rond point'        => 'rondpoint',
    'route'             => 'route',
    'rte'               => 'route',
    'r'                 => 'rue',
    'rue'               => 'rue',
    'ruelle'            => 'rue',
    'rues'              => 'rue',
    'sen'               => 'sentier',
    'sente'             => 'sentier',
    'sentier'           => 'sentier',
    'squ'               => 'square',
    'sq'                => 'square',
    'square'            => 'square',
    'tertre'            => 'tertre',
    'tour'              => 'tour',
    'traverse'          => 'traverse',
    'venelle'           => 'venelle',
    'vieille route'     => 'route',
    'villa'             => 'village',
    'village'           => 'village',
    'voie'              => 'voie',
    'zi'                => 'zi',
    'zone artisanale'   => 'za',
    'zone industrielle' => 'zi',
);

our %_Street_Type_List    = map { $_ => 1 } %street_type;
our %_Extension_Type_List = map { $_ => 1 } %extension_type;
our %_Extension_Type_Number_List
    = map { $_ => 1 } %extension_type_with_number;

my @comp = ( 'a' .. 'z' );
push @comp, 'bis', 'ter', 'quater', 'quinque', 'quinquies';

our %Addr_Match = (
    type             => join( "|", keys %_Street_Type_List ),
    extension        => join( "|", keys %_Extension_Type_List ),
    extension_number => join( "|", keys %_Extension_Type_Number_List ),
    complement       => join( "|", @comp ),
);

{
    use re 'eval';

    $Addr_Match{ adresse } = qr/
    (?:
        ([\d]+)(($Addr_Match{complement})?)     (?{ $_{numero_voie} = $1; $_{complement} = $2 })
        \s($Addr_Match{type})	                (?{ $_{type_voie} = $^N })
        (?:
            \s(.*)\s(($Addr_Match{extension}).*) (?{$_{nom_voie} = $5; $_{extension} = $^N})
            |
            \s(.*)				                 (?{ $_{nom_voie} = $^N })
            |
            \s(.*)\s(($Addr_Match{type}).*)      (?{$_{nom_voie} = $5; $_{extension} = $^N})
        )
    )
    |
    (?:
        ($Addr_Match{type})\b        (?{ $_{type_voie} = $^N })
        \s(.*)                       (?{ $_{nom_voie} = $^N })
    )
    |
    (?:
        (($Addr_Match{extension}|$Addr_Match{extension_number}).*)  (?{$_{extension} = $^N})
        (?:
            \s(([\d]+)?)                    (?{ $_{numero_voie} = $^N})
            (($Addr_Match{complement})?)    (?{ $_{complement} = $^N})
            \s($Addr_Match{type})\b         (?{ $_{type_voie} = $^N })
            \s(.*)                          (?{ $_{nom_voie} = $^N })
            |
            \s($Addr_Match{extension})\b    (?{ $_{type_voie} = $^N })
            \s(.*)                          (?{ $_{nom_voie} = $^N })
        )
    )    /ix;
}

# warn $Addr_Match{adresse};

=head1 NAME

Geo::StreetAddress::FR - Perl extension for parsing French street addresses


=head1 SYNOPSIS

    use Geo::StreetAddress::FR;

    my $adresse = Geo::StreetAddress::FR->new;
    $adresse->rue("15 grande rue");
    $adresse->parse();
    print $adresse->numero_voie. " " . $adresse->type_voie. " " .$adresse->nom_voie;


=head1 DESCRIPTION

    Geo::StreetAddress::FR is a street address parser for France.

=head2 METHODS

=head3 parse

parse a street address, returning an address element.

    my $res = $adress->parse("bat C 13B route Bordeaux");
    print $res->numero_voie; # will print 13
    print $res->type_voie;   # will print route
    print $res->nom_voie;    # will print Bordeaux
    print $res->complement;  # will print B
    print $res->extension;   # will print bat C

return 'undef' if $adress->message is set, or if the adress can't be parsed.

=cut

sub parse {
    my $self = shift;

    local %_;

    $self->_adress_missing();

    return undef if defined $self->message();

    if ( $self->adresse =~ /$Addr_Match{adresse}/ios ) {
        my %part    = %_;
        my $adresse = Geo::StreetAddress::FR::Element->new;
        $adresse->nom_voie( $part{ 'nom_voie' } );
        $adresse->numero_voie( $part{ 'numero_voie' } );
        $adresse->type_voie( $part{ 'type_voie' } );
        $adresse->complement( $part{ 'complement' } );
        $adresse->extension( $part{ 'extension' } );
        return $adresse;
    }
    return undef;
}

sub _adress_missing {
    my $self = shift;
    $self->message( undef );
    return if defined $self->adresse;
    $self->message(
        "You have to set an adress : \$mystreetobject->adresse(\"name of my adress\")"
    );
}

1;

package Geo::StreetAddress::FR::Element;
use base qw(Class::Accessor::Fast);

__PACKAGE__->mk_accessors(
    qw(rue type_voie nom_voie complement numero_voie extension) );

1;
__END__

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to
C<bug-geo-streetaddress-fr@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 SEE ALSO

L<Geo::StreetAddress::US>

Ideas and part of the code are coming from this module.

=head1 AUTHOR

franck cuny  C<< <franck.cuny@gmail.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, franck cuny C<< <franck.cuny@gmail.com> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.
