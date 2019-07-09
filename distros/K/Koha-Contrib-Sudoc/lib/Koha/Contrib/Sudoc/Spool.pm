package Koha::Contrib::Sudoc::Spool;
# ABSTRACT: Spool des fichiers de notices
$Koha::Contrib::Sudoc::Spool::VERSION = '2.31';
use Moose;
use Modern::Perl;
use File::Copy;
use DateTime;
use Format::Human::Bytes;



my $dirstatus = [
    [
        "Fichiers contenant les autorités qui ont été chargées :",
        'done',
        'c',
    ], 
    [
        "Fichiers contenant les notices biblio qui ont été chargées :",
        'done',
        '[a|b]',
    ], 
    [
        "Fichiers contenant les autorités en attente de chargement :",
        'waiting',
        'c',
    ], 
    [
        "Fichiers contenant les notices biblio en attente de chargement :",
        'waiting',
        '[a|b]',
    ], 
    [
        "Fichiers des autorités en cours de transfert :",
        'staged',
        'c',
    ], 
    [
        "Fichiers de notices biblio en cours de transfert :",
        'staged',
        '[a|b]',
    ], 
];


# Moulinette SUDOC
has sudoc => (
    is => 'rw',
    isa => 'Koha::Contrib::Sudoc',
    required => 1,
);

has root => (
    is => 'rw',
    isa => 'Str',
    lazy => 1,
    builder => '_build_root',
);

sub _build_root { shift->sudoc->root . '/var/spool'; }


sub _sortable_name {
    my $name = shift;
    if ( $name =~ /^TR(\d*)R(\d*)([A-C])(.*)$/ ) {
        my $letter = $3 eq 'A' ? 'B' :
                     $3 eq 'B' ? 'A' : $3;
        $name = sprintf("TR%05dR%05d", $1, $2) . $letter . $4;
    }
    elsif ( $name =~ /^(.*)R(\d*)([A-C])(.*)\.RAW$/ ) {
        my $letter = $3 eq 'A' ? 'B' :
                     $3 eq 'B' ? 'A' : $3;
        $name = "$1R$2$letter$4.RAW";
    }
    return $name;
}


sub files {
    my ($self, $where, $type) = @_;
    my $dir = $self->root . "/$where";
    opendir(my $hdir, $dir) || die "Impossible d'ouvrir $dir: $!";
    [ sort { _sortable_name($a) cmp _sortable_name($b) }
        grep { /$type\d{3}.raw$/i } readdir($hdir) ];
}


sub first_batch_files {
    my ($self, $where, $type) = @_;

    my $files = $self->files($where, $type);
    return $files unless @$files;

    my ($prefix_first) = $files->[0] =~ /^(.*)001.RAW/;
    my @first_files;
    for my $file (@$files) {
        my ($prefix) = $file =~ /^(.*)\d{3}.RAW/;
        last if $prefix ne $prefix_first;
        push @first_files, $file;
    }
    return \@first_files;
}


sub file_path {
    my ($self, $name) = @_;
    
    for my $where (qw /waiting done/) {
        my $path = $self->root . "/$where/$name";
        return $path if -f $path;
    }
    return;
}


sub move_done {
    my ($self, $name) = @_;
    my $path = $self->root . "/waiting/$name";
    return unless -f $path;
    my $target = $self->root . "/done/$name";
    move($path, $target);   
}


sub staged_to_waiting {
    my $self = shift;
    
    my $staged = $self->root . "/staged";
    my $target = $self->root . "/waiting";
    opendir(my $hdir, $staged) || die "Impossible d'ouvrir $staged: $!";
    my @files = sort grep { not /^\./ } readdir($hdir);
    for my $file (@files) {
        move("$staged/$file", $target);
    }
}


sub list {
    my $self = shift;
    for ( @$dirstatus ) {
        my ($msg, $where, $type) = @$_;
        my $files = $self->sudoc->spool->files($where, $type);
        next unless @$files;
        say $msg;
        chdir $self->sudoc->root . "/var/spool/$where";
        my $count = 0;
        for my $file (@$files) {
            $count++;
            my (undef, undef, undef, undef, undef, undef, undef, $size, $atime,
                $mtime, $ctime) = stat($file);
            my $dt = DateTime->from_epoch( epoch => $mtime );
            say sprintf ("  %3d. ", $count), $file,
                " - " . $dt->dmy('.') . ', ' . Format::Human::Bytes::base10($size);
        }
    }
}


sub vide {
    my $self = shift;
    for ( @$dirstatus ) {
        my ($msg, $where, $type) = @$_;
        my @files = @{ $self->sudoc->spool->files($where, $type) };
        next unless @files;
        chdir $self->sudoc->root . "/var/spool/$where";
        @files = grep {
            my (undef, undef, undef, undef, undef, undef, undef, $size, , ,) =
                stat($_);
            $size == 0;
        } @files;
        next unless @files;
        for my $file (@files) {
            unlink $file;
            say "$file: supprimé";
        }
    }
}


sub command {
    my $self = shift;
    if ( @_ ) {
        if ($_[0] =~ /vide/i ) {
            $self->vide();
            return;
        }
        for my $file (@_) {
            my $path = $self->file_path($file);
            unless ( $path ) {
                say "Le fichier '$file' n'existe pas";
                next;
            }
            say "Fichier $path";
            system( "yaz-marcdump $path | less" );
        }
    }
    else {
        $self->list();
    }
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Koha::Contrib::Sudoc::Spool - Spool des fichiers de notices

=head1 VERSION

version 2.31

=head1 DESCRIPTION

Le spool se trouve dans le sous-répertore C<var/spool> du répertoire racine
pointé par la variable d'environnement C<SUDOC>. Les fichiers arrivent de
l'ABES dans le répertoire C<staged>. Puis quand ils sont entièrement
téléchargés, ils sont déplacés en C<waiting>. De là, ils sont chargés un à un
dans Koha. Après chargement, ils sont déplacés en C<done>.

=head1 METHODS

=head2 files

Retourne les fichiers d'une categorie (staged/waiting/done) et d'un
type donnée. Par ex: 

 $files = $spool->file('waiting', 'c');
 $files = $spool->file('done', '[a|b]');

=head2 first_batch_files($where, $type)

Retourne dans un tableau le premier lot de fichiers d'une catégorie et d'un
type donnée. For example:

 my @files = $spool->first_batch_files('waiting', '[a|b]');

=head2 file_path($name)

Retourne la pathname d'un fichier qu'on retrouve, dans l'ordre, soit
dans le spool C<waiting> soit dans le spool C<done>. Si le fichier
n'existe pas, retourne undef.

=head2 move_done($name)

Déplace un fichier dans le spool 'done'

=head2 staged_to_waiting

Déplace tous les fichiers de l'ILN courant de staged dans waiting

=head2 list

Liste le contenu des répertoires du spool

=head2 vide

Supprime du spool tous les fichiers vides.

=head2 command

Sans paramètre, liste le contenu des répertoires du spool, en appelant
L<list>. Les paramètres sont des noms de fichiers du spool. Leur contenu est
affiché.

=head1 AUTHOR

Frédéric Demians <f.demians@tamil.fr>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Fréderic Demians.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
