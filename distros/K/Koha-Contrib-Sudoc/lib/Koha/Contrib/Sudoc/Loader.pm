package Koha::Contrib::Sudoc::Loader;
# ABSTRACT: Classe de base pour le chargement de notices biblio/autorité
$Koha::Contrib::Sudoc::Loader::VERSION = '2.31';
use Moose;
use Modern::Perl;
use utf8;
use MARC::Moose::Reader::File::Iso2709;
use Koha::Contrib::Sudoc::Converter;
use Log::Dispatch;
use Log::Dispatch::Screen;
use Log::Dispatch::File;
use Class::Load ':all';
use DateTime;


# Moulinette SUDOC
has sudoc => ( is => 'rw', isa => 'Koha::Contrib::Sudoc', required => 1 );

# Fichier des notices biblios/autorités
has file => ( is => 'rw', isa => 'Str', required => 1 );

# Chargement effectif ?
has doit => ( is => 'rw', isa => 'Bool', default => 0 );

# Compteur d'enregistrements traités
has count => (  is => 'rw', isa => 'Int', default => 0 );

# Compteur d'enregistrements ajoutés
has count_added => (  is => 'rw', isa => 'Int', default => 0 );

# Compteur d'enregistrements remplacés
has count_replaced => (  is => 'rw', isa => 'Int', default => 0 );

# Compteur d'enregistrements non traités
has count_skipped => ( is => 'rw', isa => 'Int', default => 0 );

# Converter
has converter => (
    is      => 'rw',
    isa     => 'Koha::Contrib::Sudoc::Converter',
);

# Le logger
has log => (
    is => 'rw',
    isa => 'Log::Dispatch',
    default => sub { Log::Dispatch->new() },
);


sub BUILD {
    my $self = shift;

    my $id = ref($self);
    ($id) = $id =~ /.*:(.*)$/;

    $self->log->add( Log::Dispatch::Screen->new(
        name      => 'screen',
        min_level => 'notice',
        stderr    => 0,
    ) );
    binmode(STDOUT, ':encoding(utf8)');
    $self->log->add( Log::Dispatch::File->new(
        name      => 'file1',
        min_level => 'debug',
        filename  => $self->sudoc->root . "/var/log/$id.txt",
        mode      => '>>',
        binmode   => ':encoding(utf8)',
    ) );
    $self->log->add( Log::Dispatch::File->new(
        name      => 'file2',
        min_level => $self->sudoc->c->{loading}->{log}->{level},
        filename  => $self->sudoc->root . "/var/log/email.txt",
        mode      => '>>',
        binmode   => ':encoding(utf8)',
    ) );

    # Instanciation du converter
    my $class = 'Koha::Contrib::Sudoc::Converter';
    if ( my $local_class = $self->sudoc->c->{biblio}->{converter} ) {
        my ($retcod, $error ) = try_load_class($local_class);
        if ( $retcod ) {
            $class = $local_class;
        }
        else {
            die $error ;
        }
    }
    load_class($class);
    $class = $class->new(sudoc => $self->sudoc, log => $self->log);
    $self->converter($class);
}



# C'est cette méthodes qui est surchargée par les sous-classes dédiées au
# traitement des notices biblio et d'autorités
sub handle_record {
    my ($self, $record) = @_;
}


sub run {
    my $self = shift;

    my $tz = DateTime::TimeZone->new( name => 'local' );
    my $dt = DateTime->now( time_zone => $tz );;
    $self->log->debug($dt->dmy . " " . $dt->hms . "\n");
    $self->log->notice("Chargement du fichier " . $self->file . "\n");
    $self->log->notice("** Test **\n") unless $self->doit;
    my $reader = MARC::Moose::Reader::File::Iso2709->new(
        file => $self->sudoc->spool->file_path( $self->file ) );
    while ( my $record = $reader->read() ) {
        $self->count( $self->count + 1 );
        $self->handle_record($record);
    }
    $self->converter->end();
    
    $self->sudoc->spool->move_done($self->file)  if $self->doit;
    my $format = '%#' . length($self->count) . "d\n";
    $self->log->notice(
        "Enregistrements traités :   " . sprintf($format, $self->count) .
        "Enregistrements ajoutés :   " . sprintf($format, $self->count_added) .
        "Enregistrements fusionnés : " . sprintf($format, $self->count_replaced ) .
        "Enregistrements ignorés :   " . sprintf($format, $self->count_skipped)
    );
    $self->log->notice("** Test ** Le fichier " . $self->file . " n'a pas été chargé\n")
        unless $self->doit;
    $self->log->notice("\n");
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Koha::Contrib::Sudoc::Loader - Classe de base pour le chargement de notices biblio/autoritÃ©

=head1 VERSION

version 2.31

=head1 AUTHOR

Frédéric Demians <f.demians@tamil.fr>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Fréderic Demians.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
