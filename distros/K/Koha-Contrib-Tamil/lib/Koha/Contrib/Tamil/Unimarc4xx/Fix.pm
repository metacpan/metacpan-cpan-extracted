package Koha::Contrib::Tamil::Unimarc4xx::Fix;
# ABSTRACT: Class checking mother/child biblios inconsistencies
$Koha::Contrib::Tamil::Unimarc4xx::Fix::VERSION = '0.074';
use Moose;

extends 'AnyEvent::Processor';

use Modern::Perl;
use utf8;
use MARC::Moose::Record;
use C4::Biblio qw/ ModBiblio /;
use YAML;


binmode(STDOUT, ':encoding(utf8)');

has tags => (is => 'rw', isa => 'ArrayRef', default => sub { [] });

has doit => ( is => 'rw', isa => 'Bool', default => 0 );

has sansid => ( is => 'rw', isa => 'HashRef', default => sub { {} } );

has invalide => ( is => 'rw', isa => 'HashRef', default => sub { { } } );

has title => ( is => 'rw', isa => 'HashRef', default => sub { { } } );


has verbose => ( is => 'rw', isa => 'Bool', default => 1 );

has sth => (
    is => 'rw',
    lazy => 1,
    default => sub {
        my $self = shift;
		my $dbh  = C4::Context->dbh;
        my $where = join(' OR ', map {
            "ExtractValue(metadata, '//datafield[\@tag=$_]') <> ''"
            } @{$self->tags});
        my $query = "
            SELECT biblionumber
              FROM biblio_metadata
         LEFT JOIN biblio USING(biblionumber)
             WHERE $where
          ORDER BY biblionumber ASC
        ";
        my $sth = $dbh->prepare($query);
        $sth->execute;
        $self->sth($sth);
	},
);


has fh => (
    is => 'rw',
    lazy => 1,
    default => sub {
        my $self = shift;
        my $fh_per_type = {};
        my @types = qw/
            ok
            9-invalide
            fixed
            orpheline
            orpheline-title
            sansid-mere
            sansid-fille
        /;
        for my $type (@types) {
            my $file = "$type.txt";
            open my $fh, ">encoding(utf8)", $file;
            $fh_per_type->{$type} = $fh;
        }
        return $fh_per_type;
    },
);

sub usage {
    say shift;
    exit;
}

before 'run' => sub {
    my $self = shift;
    my @tags;
    for (@_) {
        if (/doit/) {
            $self->doit(1);
        }
        elsif (/^4[0-9]{2}$/) {
            push @tags, $_;
        }
    }
    unless (@tags) {
        say "Il faut au moins un tag 4xx";
        exit;
    }
    $self->tags(\@tags);
};


before 'start_process' => sub {
    my $self = shift;

};


override 'process' => sub {
    my $self = shift;
    my ($biblionumber) = $self->sth->fetchrow;
    return unless $biblionumber;

    my $biblio = Koha::Biblios->find($biblionumber);
    my $record = MARC::Moose::Record::new_from($biblio->metadata->record(), 'Legacy');

    my $tag_regex = join('|', @{$self->tags});
    my $orpheline = 0;
    my $sansid = 0;      # Une zone 4xx avec $9, mais la mère n'a pas d'ISBN/ISSN
    my $fille_fixed = 0;
    my $newrec = $record->clone();
    my $dump = sub {
        my $rec = shift;
        my @lines = $rec->field('01.|090|100|101|200|21.|4..|7..|8..');
        @lines = map {
            $_->tag . ' ' .
            join(' ', map { '$' . $_->[0] . ' ' . $_->[1] } @{$_->subf});
        } @lines;
        return join("\n", @lines);
    };
    my @fixed; # Fixed fields
    my $title;
    for my $field ($newrec->field('01.|090|100|101|21.|4..|7..|8..')) {
        my $line = $field->tag . " " . join(' ', map { '$' . $_->[0] . ' ' . $_->[1] } @{$field->subf});
        push @fixed, $line;
        next if $field->tag !~ /$tag_regex/;
        my $issn = $field->subfield('x');
        my $isbn = $field->subfield('y');
        if ($issn || $isbn) {
            # On a un ISSN/ISBN => on ne fait rien
            my $fh = $self->fh->{ok};
            say $fh $biblionumber;
            next;
        }
        my $id_mere = $field->subfield('9');
        unless ($id_mere) {
            $orpheline = 1;
            push @fixed, '>>> Pas de $9';
            if (my $title = $field->subfield('t')) {
                $self->title->{$title} ||= [];
                push @{$self->title->{$title}}, $biblionumber;
            }
            next;
        }
        my $mere_biblio = Koha::Biblios->find($id_mere);
        my $mere_record;
        $mere_record = MARC::Moose::Record::new_from($mere_biblio->metadata->record(), 'Legacy') if $mere_biblio;
        unless ($mere_record) {
            # Lien invalide
            my $title = $field->subfield('t');
            $self->invalide->{$id_mere} ||= { title => $title, bib => [] };
            push @{$self->invalide->{$id_mere}->{bib}}, $biblionumber;
            next;
        }
        my $issn_mere = $mere_record->field('011');
        $issn_mere = $issn_mere->subfield('a') if $issn_mere;
        my $isbn_mere = $mere_record->field('010');
        $isbn_mere = $isbn_mere->subfield('a') if $isbn_mere;
        if ($issn_mere || $isbn_mere) {
            # ISSN/ISBN trouvé
            my @subf = @{$field->subf};
            if ($issn_mere) {
                push @{$field->subf}, [ x => $issn_mere ];
                push @fixed, ">>> ISSN >>> " . join(' ', map { '$' . $_->[0] . ' ' . $_->[1] } @{$field->subf});
            }
            else {
                push @{$field->subf}, [ y => $isbn_mere ];
                push @fixed, ">>> ISBN >> " . join(' ', map { '$' . $_->[0] . ' ' . $_->[1] } @{$field->subf});
            }
            $fille_fixed = 1;
        }
        else {
            # Pas trouvé : mère sans ISSN/ISBN
            $self->sansid->{$id_mere} = $mere_record;
            push @fixed, ">>> ISBN/ISSN absent de la notice mère";
            $sansid = 1;
        }
    }
    if ($fille_fixed) {
        my $fh = $self->fh->{'fixed'};
        say $fh join("\n", @fixed), "\n";
        # Mise à jour de la notice biblio
        if ($self->doit) {
            ModBiblio( $newrec->as('Legacy'), $biblio->biblionumber, $biblio->frameworkcode );
        }

    }
    if ($sansid) {
        my $fh = $self->fh->{'sansid-fille'};
        say $fh join("\n", @fixed), "\n";
    }

    if ($orpheline) {
        my $fh = $self->fh->{'orpheline'};
        say $fh join("\n", @fixed), "\n";
    }

    return super();
};


before 'end_process' => sub {
    my $self = shift;
    #shift->writer->end();
};


override 'start_message' => sub {
    my $self = shift;
};


override 'process_message' => sub {
    my $self = shift;
    say $self->count;
};


override 'end_message' => sub {
    my $self = shift;

    my $fh = $self->fh->{'sansid-mere'};
    my $sansid = $self->sansid;
    for my $biblionumber ( sort { $a cmp $b } keys %$sansid) {
        my $record = $sansid->{$biblionumber};
        say $fh $record->as('Text');
    }

    $fh = $self->fh->{'orpheline-title'};
    for my $title (sort keys %{$self->title}) {
        say $fh "$title\t", join(',', @{$self->title->{$title}});
    }

    $fh = $self->fh->{'9-invalide'};
    for my $biblionumber (sort keys %{$self->invalide}) {
        my $invalide = $self->invalide->{$biblionumber};
        say $fh "$biblionumber\t", $invalide->{title}, "\t",
                join(',', @{$invalide->{bib}});
    }
};


no Moose;
__PACKAGE__->meta->make_immutable;

=pod

=encoding UTF-8

=head1 NAME

Koha::Contrib::Tamil::Unimarc4xx::Fix - Class checking mother/child biblios inconsistencies

=head1 VERSION

version 0.074

=head1 SYNOPSIS

=head1 ATTRIBUTES

=head2 verbose

Verbosity. By default 0 (false).

=head1 AUTHOR

Frédéric Demians <f.demians@tamil.fr>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2025 by Fréderic Démians.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut

__END__

1;


