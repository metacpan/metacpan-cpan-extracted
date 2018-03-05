package Koha::Contrib::Tamil::Authority::FromFile;
# ABSTRACT: Find Koha authorities from an ISO2709 file
$Koha::Contrib::Tamil::Authority::FromFile::VERSION = '0.054';

use Moose;

extends qw/ AnyEvent::Processor
            Koha::Contrib::Tamil::Logger     /;

use Modern::Perl;
use utf8;
use FindBin qw( $Bin );
use Carp;
use YAML;
use Koha::Contrib::Tamil::Koha;
use MARC::Moose::Reader::File::Marcxml;
use MARC::Moose::Formater::Marcxml;
use MARC::Moose::Formater::Text;
use MARC::Moose::Parser::Iso2709;
use YAML qw/Dump LoadFile/  ;
use Try::Tiny;


has koha => ( is => 'rw', isa => 'Koha::Contrib::Tamil::Koha' );

has reader => ( is => 'rw', isa => 'MARC::Moose::Reader' );


has writer => ( is => 'rw', isa => 'MARC::Moose::Writer' );


has authority => (
    is => 'rw',
    isa => 'Str',
    required => 1,
    trigger => sub {
        my ($self, $name) = @_;
        #FIXME: Le fichier des autorités est écrasé
        # On pourrait le signaler.
        #croak "Le fichier des autorités existe déjà : ", $name if $name;
        open my $fh, ">", $name or croak "Impossible de créer le fichier $name";
        binmode($fh, ':utf8');
        $self->authority_writer( $fh );
        return $name;
    },
);


has authority_writer => ( is => 'rw' );

# Le cache des autorités déjà trouvées
# Un ref à un tableau à deux dimensions :
# 0: l'autorité principale
# 1: l'autorité non vedette
has cache_auth => (
    is      => 'rw',
    isa     => 'ArrayRef',
    default => sub {
        [ {}, {} ]
    }
);

has use_cache_auth => (is => 'rw', isa => 'Bool', default => '1');


has equivalence => (
    is => 'rw',
    isa => 'Str',
    trigger => sub {
        my ($self, $name) = @_;
        open my $fh, "<:utf8", $name or croak "Impossible d'ouvrir le fichier $name";
        my %equival;
        while (<$fh>) {
            chop;
            while (/\t$/) { s/\t$//; }
            my ($key, $id) = /(.*)\t(\d*)$/;
            next unless $key;
            $equival{lc $key} = $id;
        }
        $self->equival(\%equival);
    },
);

# Les equivalences mots clés fichiers source => autorité Koha
has equival => ( is => 'rw', isa => 'HashRef', default => sub { {} }, );

# Compte des autorités remplacées
has replaced => (
    is => 'rw',
    isa => 'HashRef',
    default => sub {
        { autorite => 0, vedette => 0, equival => 0, non => 0, rejete => 0, } }, );


# Définition des autorités : etc/config.yaml

my $c;
my %authdef;
my $authdef_perid = {};

sub BUILD {
    my $file = 'config.yaml';
    unless ( -e $file) {
        say "Configuration file doesn't exist: $file";
        exit;
    }
    $c = LoadFile($file);
    my @authorities = @{$c->{authorities}};
    for my $authority (@authorities) {
        my $def = {};
        $def->{$_} = $authority->{$_}  for qw/ name id heading idx /; 
        if ( my $cd = $authority->{biblio}->{cd} ) {
            $def->{rejected} = $cd->{tag};
        }
        if ( my $de = $authority->{biblio}->{de} ) {
            $def->{tag} = $de->{tag};
        }
        my $tag = $authority->{biblio}->{de}->{tag};
        $tag = [ $tag ] if ref $tag ne 'ARRAY';
        $authdef{$_} = $def  for @$tag;
    }
    for (values %authdef) {
        $authdef_perid->{$_->{id}} = $_;
    }
}


sub get_field_term {
    my ($field, $auth) = @_;

    my @search;
    my @view = ( $auth->{id} );
    for my $subf ( @{$field->subf} ) {
        my ($letter, $value) = @$subf;
        if ( $letter ne '9' && $letter ne '4' ) {
            push @search, $value;
            push @view, "$letter|$value";
        }
    }
    return { search => join(' ', @search), view   => join("\t", @view) };
}


sub search_authority {
    my ($self, $auth, $term) = @_;

    my $search = $term->{search};
    $search =~ s/["\-]/ /g;
    $search =~ s/ {2,}/ /g;

    my $type = $auth->{id};
    my $indexes = $auth->{idx};
    my ($id, $replace) = (0, 0);
    my $record;

    #   say "auth:", Dump($auth);
    #say "term:", Dump($term);
    if ($self->use_cache_auth) {
        my $i = 0;
        for my $index (@$indexes) {
            $record = $self->cache_auth->[$i]->{"$index$search"};
            if ($record) {
                $id = $record->field('001')->value;
                $id = $id + 0;  # Indispensable, sinon pas tjrs numérique
                $replace = $i > 0;
                return $id, $record, $replace;
            }
            $i++;
        }
    }

    my $zconn = $self->koha->zconn( 'authorityserver' );

    # Recherche de l'index le plus précis à l'index le moins précis
    my $rs;
    my $i_index = 0;
    for my $index (@$indexes) {
        my $query = '@and @attr 1=authtype ' . $type .
                    ' @attr 4=1 @attr 6=3 @attr 1=' . $index . ' "' . $search . '"';
        try {
            #say "Recherche: $query";
            $rs = $zconn->search_pqf( $query );
            #say "           OK" if $rs && $rs->size() > 0;
        } catch {
            $self->log->info("ERROR ZOOM $_ -- query: $query\n");
        };
        last if $rs && $rs->size() > 0;
        $replace = 1;
        $i_index++;
    }

    if ( $rs && $rs->size() >= 1 ) {
        ($id, $record) = _get_marc_record($rs);
        my $index = $indexes->[$i_index];
        $self->cache_auth->[$replace]->{"$index$search"} = $record
            if $self->use_cache_auth && $record;
    }
    $rs->destroy() if $rs;
    $rs = undef;
    return $id, $record, $replace;
}


sub _get_marc_record {
    my $rs = shift;
    my $record = $rs->record(0);
    $record = MARC::Moose::Record::new_from($record->raw(), 'iso2709');
    my $id = $record->field('001')->value;
    $id = $id + 0;  # Indispensable, sinon pas tjrs numérique
    return ($id, $record);
}


sub get_authority_by_id {
    my ($self, $id) = @_;
    my $query = '@attr 1=localnumber '. $id;
    my $zconn = $self->koha->zconn( 'authorityserver' );
    my $rs = $zconn->search_pqf($query);
    my $record;
    ($id, $record) = _get_marc_record($rs)  if $rs->size() == 1;
    return $record;
}


sub process_field {
    my ($self, $field) = @_;

    my $auth = $authdef{$field->tag};
    return $field unless $auth;
    return if ref $field ne 'MARC::Moose::Field::Std';
    return $field if $field->subfield('9'); # Déjà le numéro d'autorité

    my $term = get_field_term($field, $auth);
    my ($id, $marc_auth, $replace_equival, $replace_vedette);
    # Le terme a-t-il une équivalence ?
    $id = $self->equival->{lc $term->{view}};
    if ($id) {
        if ( $marc_auth = $self->get_authority_by_id($id) ) {
            $replace_equival = 1;
            my $cat = $c->{authtype};
            my $code = $marc_auth->field($cat->{tag})->subfield($cat->{letter});
            $auth = $authdef_perid->{$code};
        }
        else {
            $id = 0;
        }
    }
    else {
        # Sinon on cherche dans les autorités
        ($id, $marc_auth, $replace_vedette) =
            $self->search_authority($auth, $term);
    }
    $self->replaced->{
        !$id             ? 'non' :
        $replace_equival ? 'equival' :
        $replace_vedette ? 'vedette' : 'autorite' }++;
    # print $field->tag, " : $term : $id\n";
    if ( $id ) {
        my @subfields = ();
        my $from = $marc_auth->field( $auth->{heading} );
        if ( $from ) {
            push @subfields, [ 9 => $id ];
            if ( my @values = $field->subfield('4') ) {
                push @subfields, [ 4 => $_ ] for @values;
            }
            foreach my $subf ( @{$from->subf} ) {
                my ($letter, $value) = @$subf;
                #print "letter:value = $letter:$value\n";
                next if $letter =~ /[0-9]/;
                #print "après: letter:value = $letter:$value\n";
                utf8::decode($value); #FIXME aille.
                push @subfields, [ $letter => $value];
            }
            $field->subf( \@subfields );

            # Faut-il changer le tag
            my $auth_code = $marc_auth->field($c->{authtype}->{tag})->subfield($c->{authtype}->{letter});
            my $target_auth = $authdef_perid->{$auth_code};
            my $tag_move_text = '';
            if ( $target_auth->{id} ne $auth->{id} ) {
                $field->tag( $target_auth->{tag} );
                $tag_move_text =
                    " +tag " . $auth->{tag} . " => " . $target_auth->{tag} .
                    " [" . $target_auth->{name} . "]";
            }


            my $original_text = $term->{search};
            #utf8::decode($original_text);
            my $replaced_text = join(' ', map { '$' . $_->[0] . ' ' . $_->[1] } @subfields);
            #utf8::decode($replaced_text);
            $self->log->info(
                "[$auth->{name}] " .
                ( $replace_equival ? "Remplacement par équivalence" :
                  $replace_vedette ? "Remplacement par vedette"     :
                                     "Remplacement par autorité"      ) .
                ": \"$original_text\" => \"$replaced_text\"$tag_move_text\n"
            );
            return $field;
        }
        $self->log->warning(
            "Récupéré une autorité sans vedette en " . $auth->{headind} . ":\n" .
            $marc_auth->as('Text')
        );
        return $field;
    }
    # On rejette certains champs non trouvés dans un autre tag
    if ( $auth->{rejected} ) {
        $field->tag( $auth->{rejected} );
        $self->replaced->{rejete}++;
    }
    # Terme non trouvé => on l'écrit
    my $fh = $self->authority_writer;
    print $fh $term->{view}, "\n";
    return $field;
}


# Lie une notice biblio aux autorités Frantiq, soit au moyen de la liste
# d'équivalence soit en effectuant une recherche sur les autorités Koha.
# Pour certains termes (Pactol), les termes qui n'ont pas été trouvés sont
# déplacés en zone non-descripteur

sub process {
    my $self = shift;

    my $record = $self->reader->read();

    # Fin du traitement
    unless ( $record ) {
        close $self->authority_writer;

        # Le fichier des termes non trouvés dans le thesau Frantiq
        # On tri et on ne garde qu'un exemplaire de chaque descripteur
        # FIXME: à faire en Perl...
        my $name = $self->authority;
        my $cmd = "sort -f " . $name . " | uniq -i >$name~; " .
                  "mv $name~ $name";
        system( $cmd );
        return 0;
    }

    $self->SUPER::process();
    $self->log->info(
        ('-' x 80) . " #" . $self->count . "\n" .
        $record->as('Text'));

    $record->fields( [ 
        map { $self->process_field($_) } @{$record->fields}
    ] );

    $self->log->info( "\n" . $record->as('Text'));
    $self->writer->write( $record );
    $self->koha->zconn_reset() if $self->count % 10;

    return 1;
}


override 'start_message' => sub {
    my $self = shift;
    say "Notices lues : autorités / vedettes / équivalences / non / rejetées";
};


override 'process_message' => sub {
    my $self = shift;
    say sprintf("%#6d", $self->reader->count), ' (',
        sprintf("%d", $self->reader->percentage), '%) : ',
        $self->replaced->{autorite}, ' / ',
        $self->replaced->{vedette}, ' / ',
        $self->replaced->{equival}, ' / ',
        $self->replaced->{non}, ' / ',
        $self->replaced->{rejete};
};


override 'end_message' => sub {
    my $self = shift;
    $self->log->warning(
        "Notices autoritisées   : " . $self->count . "\n" .
        "Autorités trouvées     : " . $self->replaced->{autorite} . "\n" .
        "Vedettes trouvées      : " . $self->replaced->{vedette} . "\n" .
        "Équivalences trouvées  : " . $self->replaced->{equival} . "\n" .
        "Autorités non trouvées : " . $self->replaced->{non} . "\n" .
        "Autorités déplacées    : " . $self->replaced->{rejete} . "\n"
    );
};


override 'run' => sub {
    my $self = shift;
    $self->writer->begin;
    $self->SUPER::run();
    $self->writer->end;
};


no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Koha::Contrib::Tamil::Authority::FromFile - Find Koha authorities from an ISO2709 file

=head1 VERSION

version 0.054

=head1 ATTRIBUTES

=head2 reader

L<MARC::Moose::Reader> of the file to be authoritized

=head2 writer

L<MARC::Moose::Writer> to write in authoritized biblio records

=head2 authority

Name of the file in which to write non found authorities

=head2 authority_writer

Filehandle to write in authorities.

=head2 equivalence

File containing equivalence with Koha authorities.

=head1 AUTHOR

Frédéric Demians <f.demians@tamil.fr>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Fréderic Démians.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
