package Koha::Contrib::Tamil::Indexer;
# ABSTRACT: Class doing Zebra Koha indexing
$Koha::Contrib::Tamil::Indexer::VERSION = '0.065';
use Moose;

use 5.010;
use utf8;
use Carp;
use Koha::Contrib::Tamil::Koha;
use Koha::Contrib::Tamil::RecordReader;
use Koha::Contrib::Tamil::RecordWriter::File::Marcxml;
use AnyEvent::Processor::Conversion;
use File::Path;
use IO::File;
use Locale::TextDomain 'Koha-Contrib-Tamil';


with 'MooseX::Getopt';

has koha => (
    is       => 'rw',
    isa      => 'Koha::Contrib::Tamil::Koha',
    required => 0,
    traits  => [ 'NoGetopt' ],
);

has conf => (
    is      => 'rw',
    isa     => 'Str',
    trigger => sub {
        my ( $self, $file ) = @_;
        $self->koha( Koha::Contrib::Tamil::Koha->new( conf_file => $file ) );
        return $file;
    },
);

has source => (
    is      => 'rw',
    isa     => 'Koha::RecordType',
    default => 'biblio'
);

has select => (
    is       => 'rw',
    isa      => 'Koha::RecordSelect',
    required => 1,
    default  => 'all',
);

has directory => (
    is      => 'rw',
    isa     => 'Str',
    default => './koha-index',
);

has keep => ( is => 'rw', isa => 'Bool', default => 0 );

has verbose => ( is => 'rw', isa => 'Bool', default => 0 );

has help => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
    traits  => [ 'NoGetopt' ],
);

has blocking => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
    traits  => [ 'NoGetopt' ],
);



sub run {
    my $self = shift;

    # Is it a full indexing of all Koha DB records?
    my $is_full_indexing = $self->select =~ /all/i;

    # Is it biblio indexing (if not it's authority)
    my $is_biblio_indexing = $self->source =~ /biblio/i;

    $self->koha( Koha::Contrib::Tamil::Koha->new() ) unless $self->koha;

    # STEP 1: All biblio records are exported in a directory

    unless ( -d $self->directory ) {
        mkdir $self->directory
            or die "Unable to create directory: " . $self->directory;
    }
    my $from_dir = $self->directory . "/" . $self->source;
    mkdir $from_dir;
    for my $dir ( ( "$from_dir/update", "$from_dir/delete") ) {
        rmtree( $dir ) if -d $dir;
        mkdir $dir;
    }

    # DOM indexing? otherwise GRS-1
    # Par défaut DOM depuis 18.11 avec dispartion des param zebra_bib_index_mode
    my $is_dom = $self->source eq 'biblio' ? 'zebra_bib_index_mode' : 'zebra_auth_index_mode';
    $is_dom = $self->koha->conf->{config}->{$is_dom} || '';
    $is_dom = $is_dom =~ /grs/i ? 0 : 1;

    # STEP 1.1: Records to update
    print __"Exporting records to update", "\n" if $self->verbose;
    my $exporter = AnyEvent::Processor::Conversion->new(
        reader => Koha::Contrib::Tamil::RecordReader->new(
            koha   => $self->koha,
            source => $self->source,
            select => $is_full_indexing ? 'all' : 'queue_update',
            xml    => '1'
        ),
        writer => Koha::Contrib::Tamil::RecordWriter::File::Marcxml->new(
            fh => IO::File->new( "$from_dir/update/records", '>:encoding(utf8)' ),
            valid => $is_dom ),
        blocking    => $self->blocking,
        verbose     => $self->verbose,
    );
    $exporter->run();

    # STEP 1.2: Record to delete, if zebraqueue
    if ( ! $is_full_indexing ) {
        print __"Exporting records to delete", "\n" if $self->verbose;
        $exporter = AnyEvent::Processor::Conversion->new(
            reader => Koha::Contrib::Tamil::RecordReader->new(
                koha   => $self->koha,
                source => $self->source,
                select => 'queue_delete',
                xml    => '1'
            ),
            writer => Koha::Contrib::Tamil::RecordWriter::File::Marcxml->new(
                fh => IO::File->new( "$from_dir/delete/records", '>:utf8' ),
                valid => $is_dom ),
            blocking    => $self->blocking,
            verbose     => $self->verbose,
        );
        $exporter->run();
    }

    # STEP 2: Run zebraidx

    my $cmd;
    my $zconfig  = $self->koha->conf->{server}->{
       $is_biblio_indexing ? 'biblioserver' : 'authorityserver' }->{config};
    my $db_name  = $is_biblio_indexing ? 'biblios' : 'authorities';
    my $cmd_base = "zebraidx -c " . $zconfig;
    $cmd_base   .= " -n" if $is_full_indexing; # No shadow: no indexing daemon
    $cmd_base   .= $self->verbose ? " -v warning,log" : " -v none";
    $cmd_base   .= " -g marcxml";
    $cmd_base   .= " -d $db_name";

    if ( $is_full_indexing ) {
        $cmd = "$cmd_base init";
        print "$cmd\n" if $self->verbose;
        system( $cmd );
    }

    $cmd = "$cmd_base update $from_dir/update";
    print "$cmd\n" if $self->verbose;
    system( $cmd );

    if ( ! $is_full_indexing ) {
        $cmd = "$cmd_base adelete $from_dir/delete";
        print "$cmd\n" if $self->verbose;
        system( $cmd );
        my $cmd = "$cmd_base commit";
        print "$cmd\n" if $self->verbose;
        system( $cmd );
    }

    rmtree( $self->directory ) unless $self->keep;
}


no Moose;
__PACKAGE__->meta->make_immutable;

=pod

=encoding UTF-8

=head1 NAME

Koha::Contrib::Tamil::Indexer - Class doing Zebra Koha indexing

=head1 VERSION

version 0.065

=head1 METHODS

=head2 run

Runs the indexing task.

=HEAD1 SYNOPSIS

 my $indexer = Koha::Contrib::Tamil::Indexer->new(
   source => 'biblio',
   select => 'queue'
 );
 $indexer->run();

 my $indexer = Koha::Contrib::Tamil::Indexer->new(
   source    => 'authority',
   select    => 'all',
   directory => '/tmp',
   verbose   => 1,
 );
 $indexer->run();

=HEAD1 DESCRIPTION

Indexes Koha biblio/authority records, full indexing or queued record indexing.

=head1 AUTHOR

Frédéric Demians <f.demians@tamil.fr>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Fréderic Démians.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut

__END__

1;

