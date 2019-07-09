package Koha::Contrib::Sudoc;
# ABSTRACT: Chargeur Koha par Tamil
$Koha::Contrib::Sudoc::VERSION = '2.31';
use Moose;
use Modern::Perl;
use YAML qw( LoadFile Dump );
use Koha::Contrib::Sudoc::Koha;
use Koha::Contrib::Sudoc::Spool;
use MARC::Moose::Field::Std;
use MARC::Moose::Field::Control;
use File::Copy;
use Path::Tiny;
use Mail::Box::Manager;
use DateTime;
use File::ShareDir ':ALL';


# L'instance de Koha de l'ILN courant
has koha => (
    is => 'rw',
    isa => 'Koha::Contrib::Sudoc::Koha',
    default => sub { Koha::Contrib::Sudoc::Koha->new() }
);


# La racine de l'environnement d'exécution du chargeur
has root => (
    is => 'rw',
    isa => 'Str',
    default => sub {
        my $self = shift;
        my $root = $ENV{SUDOC};
        unless ($root) {
            say "Il manque la variable d'environnement SUDOC.";
            exit;
        }
        unless ( -d $root ) {
            say "variable d'environnement SUDOC=$root";
            say "Ce répertoire n'existe pas. Il faut le créer, puis initialiser le chargeur si nécessaire.";
            exit;
        }
        unshift @INC, "$root/lib";
        $self->root( $root );
    },
);

# Le contenu du fichier de config
has c => ( is => 'rw', );

# Le Spool
has spool => ( is => 'rw', isa => 'Koha::Contrib::Sudoc::Spool' );


sub BUILD {
    my $self = shift;

    # Lecture du fichier de config et création du hash branchcode => RCR par ILN
    my $file = $self->root . "/etc/sudoc.conf";
    return unless -e $file;
    my $c = LoadFile($file);
    my %branchcode;
    while ( my ($rcr, $branch) = each %{$c->{rcr}} ) {
        $branchcode{$branch} = $rcr;
    }
    $c->{branch} = \%branchcode;
    $self->c($c);

    # Contrôle de quelques paramètres
    my $loading = $c->{loading};
    unless ($loading) {
        say "Erreur sudoc.conf: Il manque la section 'loading'";
        exit;
    }
    my $log = $loading->{log};
    unless ($log) {
        say "Erreur sudoc.conf: Il manque la section 'loading::log'";
        exit;
    }
    if ( $log->{level} !~ /debug|notice/ ) {
        say "Erreur sudoc.conf: 'loading::log::level n'est pas égal à debug ou notice.";
        exit;
    }
    my $timeout = $loading->{timeout};
    unless ($timeout) {
        say "Erreur sudoc.conf: Il manque la section 'loading::timeout'";
        exit;
    }
    for ( qw/ transfer indexing / ) {
        my $value = $timeout->{$_};
        unless ( $value && $value =~ /^[0-9]+$/ && $value >= 1 && $value <= 60) {
            say "Erreur sudoc.conf: Le paramètre 'loading::timeout::$_' doit  être compris entre 1 et 60.";
            exit;
        }
    }

    # L'object Sudoc::Spool
    $self->spool( Koha::Contrib::Sudoc::Spool->new( sudoc => $self ) );
}


# Déplace le PPN (001) d'une notice SUDOC dans une zone Koha
sub ppn_move {
    my ($self, $record, $tag) = @_;

    return unless $tag && length($tag >= 3);

    my $letter;
    if ( $tag =~ /(\d{3})([0-9a-z])/ ) { $tag = $1, $letter = $2; }
    elsif ( $tag =~ /(\d{3})/ ) { $tag = $1 };   

    return if $tag eq '001';

    my $ppn = $record->field('001')->value;
    $record->append(
        $letter
        ? MARC::Moose::Field::Std->new( tag => $tag, subf => [ [ $letter => $ppn ] ] )
        : MARC::Moose::Field::Control->new( tag => $tag, value => $ppn )
    );

    $record->fields( [ grep { $_->tag ne '001' } @{$record->fields} ] );
}


# Crée les sous-répertoires d'un ILN, s'ils n'existent pas déjà
sub init {
    my $self = shift;

    say "La variable d'environnement SUDOC définit le répertoire racine : ", $self->root;
    say "Initialisation du répertoire des données du Chargeur SUDOC d'un ILN.";
    chdir($self->root);

    say "Création des répertoire 'etc', 'lib' et 'var'.";
    mkdir $_  for qw/ etc lib var /;

    if ( -f 'etc/sudoc.conf') {
        say "Le fichier 'etc/sudoc.conf' existe déjà. On ne le remplace pas par le fichier modèle.";
    }
    else {
        say "Création d'un fichier modèle 'etc/sudoc.conf'.";
        my $conf_path = dist_file('Koha-Contrib-Sudoc', 'etc/sudoc.conf');
        copy($conf_path, "etc/sudoc.conf");
    }
    
    say "Création des répertoires 'var/log' et 'var/spool'.";
    chdir('var');
    mkdir $_ for qw/ log spool /;

    chdir('spool');
    mkdir $_ for qw/ staged waiting done /;
}


sub reset_email_log {
    my $root = shift->root;
    unlink "$root/var/log/email.txt";
}


# Envoi courriel GTD
sub send_gtd_email {
    my ($self, $jobid, $dir) = @_;
    $dir ||= 'staged';

    # La date
    my $year = DateTime->now->year;

    my $c = $self->c->{trans};

    my $head = Mail::Message::Head->new;
    $head->add( From    => $c->{email}->{koha} );
    $head->add( To      => $c->{email}->{abes} );
    $head->add( Subject => 'GET TITLE DATA'    );
    my @data = (
        "GTD_ILN = " . $self->c->{iln},
        "GTD_YEAR = $year",
        "GTD_FILE_TO = " . $c->{ftp_host},
        "GTD_REMOTE_DIR = $dir",
    );
    push @data, "GTD_ORDER = TR$jobid*"  if $jobid;
    my $body = Mail::Message::Body::Lines->new(data => join("\n", @data));
    my $message = Mail::Message->new(head => $head, body => $body);
    $message->send;
}


# Chargement de tous les fichiers qui se trouvent dans 'waiting'
sub load_waiting {
    my $self = shift;

    my $c = $self->c;
    my $loading = $c->{loading};

    # Temps nécessaire entre deux chargements de fichier pour indexation
    my $timeout = $loading->{timeout}->{indexing} * 60;
    my $doit = $loading->{doit};
    $self->reset_email_log();

    # Etape 1 - Chargement de tous les fichiers autorités (type c)
    for my $file ( @{ $self->spool->files('waiting', 'c') } ) {
        my $loader = Koha::Contrib::Sudoc::Loader::Authorities->new(
            sudoc => $self, file => $file, doit => $doit );
        $loader->run();
        sleep($timeout);
    }

    # Etape 2 - Chargement de tous les fichiers biblio (type a et b)
    for my $file ( @{ $self->spool->files('waiting', '[a|b]') } ) {
        my $loader = Koha::Contrib::Sudoc::Loader::Biblios->new(
            sudoc => $self, file => $file, doit => $doit );
        $loader->run();
        sleep($timeout);
    }

    # Envoi des log s'il y en a
    my $logfile = $self->root . "/var/log/email.txt";
    return unless -e $logfile;
    my $head = Mail::Message::Head->new;
    $head->add( From    => $loading->{log}->{from}     );
    $head->add( To      => $loading->{log}->{to}       );
    $head->add( Subject => 'Chargeur Sudoc Koha Tamil' );
    my $body = Mail::Message::Body::Lines->new( data => path($logfile)->slurp );
    my $message = Mail::Message->new(head => $head, body => $body);
    $message->send;  
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Koha::Contrib::Sudoc - Chargeur Koha par Tamil

=head1 VERSION

version 2.31

=head1 DESCRIPTION

Koha::Contrib::Sudoc est le Chargeur Sudoc pour Koha développé par Tamil. Le
fonctionnement de cet outil est décrit ici :
L<http://www.tamil.fr/sudoc/sudoc.html>.

=head1 AUTHOR

Frédéric Demians <f.demians@tamil.fr>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Fréderic Demians.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
