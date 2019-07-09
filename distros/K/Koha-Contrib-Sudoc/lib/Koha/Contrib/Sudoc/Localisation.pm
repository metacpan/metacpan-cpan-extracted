package Koha::Contrib::Sudoc::Localisation;
# ABSTRACT: Localisation auto de notices biblio
$Koha::Contrib::Sudoc::Localisation::VERSION = '2.31';
use Moose;

extends 'AnyEvent::Processor';

use Modern::Perl;
use utf8;
use Koha::Contrib::Sudoc;
use Koha::Contrib::Sudoc::BiblioReader;
use C4::Items;
use C4::Context;
use YAML;
use Encode;
use Business::ISBN;
use List::Util qw/first/;


# Moulinette SUDOC
has sudoc => (
    is => 'rw',
    isa => 'Koha::Contrib::Sudoc',
    default => sub { Koha::Contrib::Sudoc->new; },
);


has select => ( is => 'rw');

has reader => ( is => 'rw', isa => 'Koha::Contrib::Sudoc::BiblioReader' );

# Type de sortie : isbn, ppn ou dat
has type => (
    is => 'rw',
    isa => 'Str',
    default => 'isbn',
    trigger => sub {
        my ($self, $type) = @_;
        if ( $type !~ /isbn|dat|ppn/i ) {
            say "Type inconnu: $type";
            exit;
        }
        return $type;
    },
);

# Champ contenant le PPN
has ppn => (
    is => 'rw',
    isa => 'Str',
    default => '001',
    trigger => sub {
        my ($self, $ppn) = @_;
        if ( $ppn !~ /^[0-9]{3}$/ && $ppn !~ /^[0-9]{3}[a-z]$/ ) {
            say "Champ PPN invalide: $ppn";
            exit;
        }
        return $ppn;
    },
);


# Où placer la cote Koha dans la notice ABES, par défaut 930 $a
has coteabes => (
    is => 'rw',
    isa => 'Str',
    default => '930 $a'
);

# Test de recouvrement (on sort moins d'info)
has test => ( is => 'rw', isa => 'Bool', default => 1 );

# Nombre max de lignes par fichier
has lines => ( is => 'rw', isa => 'Int', default => 1000 );

# Disponibilité pour le PEB ?
has peb => ( is => 'rw', isa => 'Bool', default => 1 );

has ismarc21 => (
    is => 'rw',
    isa => 'Bool',
    default => sub { C4::Context->preference('marcflavour') =~ /marc21/i; }  
);


#
# Les fichiers par RCR, avec branch Koha correspondante. Les info proviennent
# du fichier de conf sudoc.conf et sont construites à l'instantiation de
# l'objet.
# Par exemple :
# {
#   BIB1 => {
#     branch => 'BIB1',         
#     rcr    => '1255872545',  # RCR correspondant à la biblio Koha
#     key    => {
#        cle1 => [ [biblionumber1, cote1],  [biblionumber2, cote2], ... ],
#        cle2 => [ [
#     },
#     line   => 123,           # N° de ligne dans le fichier courant
#     index  => 2,             # Index du ficier (fichier.index)
#   },
#   BIB2 => {
#     ...
# }
#   
has loc => (
    is => 'rw',
    isa => 'HashRef',
    default => sub {
        my $self = shift;
        my %loc;
        my $hbranch = $self->sudoc->c->{branch};
        while ( my ($branch, $rcr) = each %$hbranch ) {
            $loc{$branch} = {
                branch => $branch,
                rcr    => $rcr,
                key    => {},
            };
        }
        $self->loc( \%loc );
    },
);


# Listes de mots vides supprimés des titres/auteurs
# Cette liste est fournie par l'ABES
my @stopwords = qw(
per
org
mti
rec
isb
isn
ppn
dew
cla
msu
mee
cti
cot
lai
pai
rbc
res
the
prs
aut
num
tou
edi
sou
tir
bro
geo
mch
epn
tab
tco
dpn
sim
dup
vma
lva
pfm
mfm
pra
mra
kil
sel
col
nos
num
msa
cod
inl
cll
ati
nli
slo
rcr
typ
dep
spe
dom
reg
mno
mor
eta
nom
for
vil
dat
dac
dam
nrs
adr
apu
tdo
lan
pay
fct
a
ad
alla
am
at
aus
bei
cette
como
dalla
del
dem
des
dr
during
einem
es
fuer
i
impr
l
leur
mes
nel
o
over
por
r
ses
so
sur
this
under
vom
vous
with
ab
against
alle
among
atque
aussi
bis
ceux
cum
dans
dell
den
desde
du
e
einer
et
g
ihre
in
la
leurs
mit
no
oder
p
pour
s
sic
some
te
to
une
von
w
y
depuis
di
durant
ed
eines
f
gli
ihrer
into
las
lo
n
nos
of
par
qu
sans
since
sous
that
ueber
unless
vor
was
zu
der
die
durante
ein
el
for
h
il
its
le
los
nach
notre
on
per
quae
se
sive
st
the
um
unter
vos
we
zur
across
all
altre
asi
aupres
b
ce
comme
dall
degli
dello
deren
dont
durch
eine
en
from
his
im
j
les
m
ne
nous
ou
plus
que
selon
sn
sul
their
und
upon
votre
which
);


sub BUILD {
    my $self = shift;

    my $reader = Koha::Contrib::Sudoc::BiblioReader->new(
        koha => $self->sudoc->koha );
    $reader->select($self->select) if $self->select;
    $self->reader($reader);

    my $type = $self->type;
    __PACKAGE__->meta-> add_method( 'write_keys' =>
        $type =~ /dat/i ? \&write_dat  :
        $type =~ /ppn/i  ? \&write_ppn : \&write_isbn
    );
}



sub populate_key {
    my ($self, $items, $key) = @_;

    return unless @$items;
    my $biblionumber = $items->[0]->{biblionumber}; 
    for my $ex ( @$items ) {
        my $branch = $ex->{homebranch};
        my $loc = $self->loc->{$branch};
        next unless $loc;
        my $keys = $loc->{key};
        my $cote = $ex->{itemcallnumber} || '';
        $cote =~ s/;//g;
        my $bibcote = $keys->{$key} ||= [];
        # On ne prend pas les doublons pour un même biblionumber
        next if first { $_->[0] eq $biblionumber; } @$bibcote;
        push @$bibcote, [$biblionumber, $cote];
        last;
    }
}


sub write_ppn {
    my ($self, $record) = @_;

    my $tag = $self->ppn;
    my $letter;
    $letter = $1  if $tag =~ /([a-z])$/;

    my $ppn = $record->field($tag);
    return unless $ppn;
    $ppn = $letter ? $ppn->subfield($letter) : $ppn->value;
    next unless $ppn;

    my $biblionumber = $self->sudoc->koha->get_biblionumber($record);
    my $items = GetItemsByBiblioitemnumber($biblionumber);
    $self->populate_key($items, $ppn);
}


sub write_isbn {
    my ($self, $record) = @_;

    my @isbns = $record->field($self->ismarc21 ? '020' : '010');
    return unless @isbns;

    my $biblionumber = $self->sudoc->koha->get_biblionumber($record);
    my $items = GetItemsByBiblioitemnumber($biblionumber);
    for my $isbn ( @isbns ) {
        $isbn = $isbn->subfield('a');
        next unless $isbn;
        # Si c'est un EAN, on convertit en ISBN...
        if ( $isbn =~ /^978/ ) {
            if ( my $i = Business::ISBN->new($isbn) ) {
                if ( $i = $i->as_isbn10 ) {
                    $isbn = $i->as_string;
                }
            }
        }
        $isbn =~ s/ //g;
        $isbn =~ s/-//g;
        # On nettoie les ISBN de la forme 122JX(vol1)
        $isbn = $1 if $isbn =~ /(.*)\(/;
        next unless $isbn;
        $self->populate_key($items, $isbn);
    }
}


sub _clean_string {
    my $value = shift;

    # Suppression des accents, passage en minuscule
    $value = decode('UTF-8', $value) unless utf8::is_utf8($value);
    $value = lc $value;
    $value =~ y/âàáäçéèêëïîíôöóøùûüñčć°/aaaaceeeeiiioooouuuncco/;

    $value =~ s/;/ /g;
    $value =~ s/,/ /g;
    $value =~ s/"/ /g;
    $value =~ s/\?/ /g;
    $value =~ s/!/ /g;
    $value =~ s/'/ /g;
    $value =~ s/\'/ /g;
    $value =~ s/\)/ /g;
    $value =~ s/\(/ /g;
    $value =~ s/\]/ /g;
    $value =~ s/\[/ /g;
    $value =~ s/:/ /g;
    $value =~ s/=/ /g;
    $value =~ s/-/ /g;
    $value =~ s/\x{0088}/ /g;
    $value =~ s/\x{0089}/ /g;
    $value =~ s/\x{0098}/ /g;
    $value =~ s/\x{0099}/ /g;
    $value =~ s/\x9c/ /g;
    $value =~ s/\./ /g;

    while ( $value =~ s/  / / ) { ; }

    return $value;
}


sub write_dat {
    my ($self, $record) = @_;

    my ($tag, $letter) = $self->ismarc21 ? ('260', 'c') : ('210', 'd');
    my $date = $record->field($tag);
    return unless $date;
    $date = $date->subfield($letter) || '';
    return unless $date =~ /(\d{4})/;
    $date = $1;

    my $auteur;
    for my $tag ( $self->ismarc21 ? qw( 100 700 110 710 ) : qw( 700 701 702 710 711 712 ) ) {
        $auteur = $record->field($tag);
        next unless $auteur;
        $auteur = $auteur->subfield('a') || '';
        if ( $auteur =~ /^(.+),/ ) { $auteur = $1; }
        $auteur = _clean_string($auteur);
        last if $auteur;
    }
    $auteur ||= '';

    # Traitement du titre
    my $titre = $record->field($self->ismarc21 ? '245' : '200') || '';
    $titre = $titre->subfield('a') || '' if $titre;

    # Suppression des accents, passage en minuscule
    $titre = _clean_string($titre);

    # Les mots vides
    for my $word ( @stopwords ) {
        $titre =~ s/\b$word\b/ /gi;
    }

    while ( $titre =~ s/  / / ) { ; }
    $titre =~ s/^ *//;
    $titre =~ s/ *$//;
    
    my $dat = "$date;$auteur;$titre";
    my $biblionumber = $self->sudoc->koha->get_biblionumber($record);
    my $items = GetItemsByBiblioitemnumber($biblionumber);
    $self->populate_key($items, $dat);
}




sub process {
    my $self = shift;

    my $record = $self->reader->read();
    return 0 unless $record;

    # Si la notice contient déjà un PPN, inutile de la traiter
    my $tag = $self->sudoc->c->{biblio}->{ppn_move} || '001';
    my $letter;
    if ( $tag =~ /(\d{3})([0-9a-z])/ ) { $tag = $1, $letter = $2; }
    elsif ( $tag =~ /(\d{3})/ ) { $tag = $1 };   
    my $field = $record->field($tag);

    return 1 if $field && ( ( $letter && $field->subfield($letter) ) ||
                            $field->value );

    $self->SUPER::process();
    $self->write_keys($record);
    return 1;
}


sub start_message {
    say "Lecture des notices biblio du Catalogue Koha";
}


sub end_message {
    my $self = shift;

    say "Notices lues :     ", $self->reader->count, "\n",
        "Notices traitées : ", $self->count;
}


sub end_process {
    my $self = shift;
    say "Génération des fichiers ABES de localisation automatique";

    my $max_lines = $self->lines;
    my $type = $self->type;

    my ($prefix, $header) =
        $type =~ /dat/i  ? ('r', 'date;auteur;titre') :
        $type =~ /ppn/i  ? ('p', 'PPN') : ('i', 'ISBN');
    $header = "$header;" . $self->coteabes . ';L035 $a'; 
    for my $loc ( values %{$self->loc} ) {
        my $fh;
        open my $fh_mult, ">:encoding(utf8)",
          $prefix . $loc->{rcr} . ( $self->peb ? 'u' : 'g' ) . "_clemult.txt";
        $loc->{index} = 0;
        $loc->{line} = 99999999;
        for my $key ( sort keys %{$loc->{key}} ) {
            my @bncote = @{$loc->{key}->{$key}};
            if ( @bncote == 1 ) {
                if ( $loc->{line} >= $self->lines ) {
                    $loc->{index}++;
                    my $name = $prefix . $loc->{rcr} .
                               ( $self->peb ? 'u' : 'g' ) .
                               '_' .
                               sprintf("%04d", $loc->{index}) . '.txt';
                    close($fh) if $fh;
                    open $fh, ">:encoding(utf8)", $name;
                    say $fh $header; 
                    $loc->{line} = 1;
                }
                if ( $self->test ) {
                    say $fh $key;
                }
                else {
                    my ($biblionumber, $cote) = @{$bncote[0]};
                    say $fh "$key;$cote;$biblionumber"
                }
                $loc->{line}++;
            }
            else {
                say $fh_mult
                  "$key\n  ",
                  join("\n  ", map { $_->[0] . " " . $_->[1] } @bncote);
            }
        }
    }
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Koha::Contrib::Sudoc::Localisation - Localisation auto de notices biblio

=head1 VERSION

version 2.31

=head1 AUTHOR

Frédéric Demians <f.demians@tamil.fr>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Fréderic Demians.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
