package Koha::Contrib::Tamil::Authority::EditorsBuilder;
$Koha::Contrib::Tamil::Authority::EditorsBuilder::VERSION = '0.069';
use Moose;

extends 'AnyEvent::Processor';

use 5.010;
use utf8;
use C4::Context;
use C4::Biblio;
use Business::ISBN;
use YAML;


has verbose => ( is => 'rw', isa => 'Bool' );

has koha => ( is => 'rw', isa => 'Koha::Contrib::Tamil::Koha' );

# Data structure containing isbn-code-collection found
#  {
#    '0-20' => [
#       "Tamil Press",
#       [
#           "Koha Gold Collection",
#           "Tamil success stories",
#           "Forever happy collection",
#       ]
#    '2-930' => ...
has editor_from_isbn => ( is => 'rw', isa => 'HashRef', default => sub { {} } );

# Tableau des éditeurs sans ISBN
has editor_without_isbn => ( is => 'rw', isa => 'HashRef', default => sub { {} } );

# Tableau des éditeurs avec ISBN invalide
has editor_with_invalid_isbn => ( is => 'rw', isa => 'HashRef', default => sub { {} } );

# Array of biblionumbers
has biblionumbers => ( is => 'rw', isa => 'ArrayRef' );



before 'run' => sub {
    my ($self, $delete) = @_;

    my $sth = $self->koha->dbh->prepare(
        "SELECT biblionumber
           FROM biblioitems
    ");
    $sth->execute;
    my @biblionumbers = ();
    while (my ($biblionumber) = $sth->fetchrow) {
        push @biblionumbers, $biblionumber;
    }
    $self->biblionumbers( \@biblionumbers );

    say "Step 1: Extracting isbn-editors-collections from biblio records"
        if $self->verbose;
};


override 'process' => sub {
    my $self = shift;

    if ( $self->count == @{$self->biblionumbers} ) {
        # Nettoyage des listes d'ISBN
        my %found;
        for my $isbn ( keys %{ $self->editor_from_isbn } ) {
            my $editor = $self->editor_from_isbn->{ $isbn };
            my $name = $editor->[0];
            $found{ $name } = 1;
        }
        for ( keys %{ $self->editor_without_isbn } ) {
            delete $self->editor_without_isbn->{ $_ }  if $found{$_};
        }
        for ( keys %{ $self->editor_with_invalid_isbn } ) {
            delete $self->editor_with_invalid_isbn->{ $_ }  if $found{$_};
        }
        return 0;
    }

    my $biblionumber = $self->biblionumbers->[$self->count];
    $self->SUPER::process();

    my $record = GetMarcBiblio($biblionumber);
    return 1 unless $record;
    
    # Si pas d'éditeur, on ne fait rien
    my $name = $record->field('210');
    return 1 unless $name;
    $name = $name->subfield('c');
    return 1 unless $name;

    # Si on n'a pas d'ISBN, on ne fait rien et on met de côté le nom de
    # l'éditeur
    my $isbn = $record->field('010');
    unless ( $isbn ) {
        $self->editor_without_isbn->{ $name } = 1;
        return 1;
    }
    $isbn = $isbn->subfield('a');
    unless ( $isbn ) {
        $self->editor_without_isbn->{ $name } = 1;
        return 1;
    }

    # On normalise l'ISBN
    $isbn = Business::ISBN->new($isbn);
    unless ( $isbn ) {
        $self->editor_with_invalid_isbn->{ $name } = 1;
        return 1;
    }
    unless ( $isbn->is_valid ) {
        $self->editor_with_invalid_isbn->{ $name } = 1;
        return 1;
    }
    my $isbn_prefix = $isbn->group_code . '-' . $isbn->publisher_code;
    return 1 unless $isbn_prefix;

    my $collection = $record->field('225');
    $collection = $collection
                  ? $collection->subfield('a') || '_SANS_COLLECTION_'
                  : '_SANS_COLLECTION';

    my $editor = $self->editor_from_isbn->{ $isbn_prefix } ||
                 ( $self->editor_from_isbn->{ $isbn_prefix } = [ $name, {}, ] );
    $editor->[1]->{$collection}++;

    return 1;
};


override 'process_message' => sub {
    my $self = shift;
    my $total = @{ $self->biblionumbers } + 0;
    my $percent = $self->count * 100 / $total;
    print sprintf("  %#6d / %d (%d", $self->count, $total, $percent) . "%)\n";
};


no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Koha::Contrib::Tamil::Authority::EditorsBuilder

=head1 VERSION

version 0.069

=head1 AUTHOR

Frédéric Demians <f.demians@tamil.fr>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by Fréderic Démians.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
