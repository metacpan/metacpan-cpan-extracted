package Koha::Contrib::Sudoc::PPNize::Updater;
# ABSTRACT: Mise à jour des PPN dans notices existantes
$Koha::Contrib::Sudoc::PPNize::Updater::VERSION = '2.31';
use Moose;
use Log::Dispatch;
use Log::Dispatch::Screen;
use Log::Dispatch::File;
use C4::Biblio;

extends 'AnyEvent::Processor';


# Le lecteur d'enregistrements utilisé par la conversion
has reader => (
    is => 'rw', 
    isa => 'Sudoc::PPNize::Reader',
);


# Moulinette SUDOC
has sudoc => ( is => 'rw', isa => 'Sudoc', required => 1 );

# doit ?
has doit => ( is => 'rw', isa => 'Bool', default => 0 );

# Le logger
has log => (
    is => 'rw',
    isa => 'Log::Dispatch',
    default => sub { Log::Dispatch->new() },
);


sub BUILD {
    my $self = shift;

    $self->log->add( Log::Dispatch::Screen->new(
        name      => 'screen',
        min_level => 'notice',
    ) );
    $self->log->add( Log::Dispatch::File->new(
        name      => 'file1',
        min_level => 'debug',
        filename  => $self->sudoc->sudoc_root . '/var/log/' .
             $self->sudoc->iln . "-ppnize.log",
        mode      => '>>',
    ) );
}


sub process {
    my $self = shift;
    my $equival = $self->reader->read();
    return 0 unless $equival;

    $self->SUPER::process();

    # On retrouve la notice biblio dont on a le numéro
    my $ppn = $equival->{ppn};
    my $biblionumber = $equival->{biblionumber};
    $self->log->info( "PPN $ppn => $biblionumber" . "\n" );
    my ($fm, $record) = $self->sudoc->koha->get_biblio( $equival->{biblionumber} );
    unless ($record) {
        # Pas de notice ayant ce biblionumber
        $self->log->warning("  Pas de notice ayant le biblionumber $biblionumber\n");
        return 1;
    }


    # On place le PPN dans le champ idoine
    my $conf = $self->sudoc->c->{$self->sudoc->iln}->{biblio};
    my $tag = $conf->{ppn_move};
    my $letter;
    if ( $tag =~ /(\d{3})([0-9a-z])/ ) { $tag = $1, $letter = $2; }
    elsif ( $tag =~ /(\d{3})/ ) { $tag = $1 };

    # On supprime le tag s'il existe
    $record->fields( [ grep { $_->tag ne $tag } @{$record->fields} ] );

    $record->append(
        $letter
        ? MARC::Moose::Field::Std->new( tag => $tag, subf => [ [ $letter => $ppn ] ] )
        : MARC::Moose::Field::Control->new( tag => $tag, value => $ppn )
    );
    
    ModBiblio($record->as('Legacy'), $biblionumber, $fm)
        if $self->doit;

    return 1;
}


no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Koha::Contrib::Sudoc::PPNize::Updater - Mise Ã  jour des PPN dans notices existantes

=head1 VERSION

version 2.31

=head1 AUTHOR

Frédéric Demians <f.demians@tamil.fr>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Fréderic Demians.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
