package File::Catalog;

use 5.010;
use strict;
use warnings FATAL => 'all';
use Env;
use Cwd qw(abs_path);
use File::Basename qw(dirname basename);
use Fcntl ':mode';
use Digest::MD5::File qw(file_md5_hex);
use Log::Log4perl qw(:easy);
use Term::ProgressBar;
use UI::Dialog;
use Data::Dumper qw(Dumper);

use File::Catalog::Env qw(nom_local);
use File::Catalog::DB;

=head1 NAME

File::Catalog - The great new File::Catalog!

=head1 VERSION

Version 0.003

=cut

our $VERSION = '0.003';

# timeout pour operations systeme
#my $timeout_court = 30;     # secondes
#my $timeout_long  = 300;    # secondes

# repertoires ignores
my @exclusions_rep = qw(.git .svn CVS _no_ktl RECYCLER $RECYCLE.BIN);
my @exclusions_fic = qw(Thumbs.db sync.ffs_db);

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use File::Catalog;

    my $foo = File::Catalog->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=head2 initialiser

=cut

sub initialiser {
    my ($class, %options) = @_;
    my $self = {};
    bless $self, $class;
    $self->{i}   = 0;
    $self->{moi} = basename($0);

    # init log
    my $opt_debug = (exists $options{debug}) ? $options{debug} : undef;
    Log::Log4perl->easy_init(($opt_debug) ? $DEBUG : $INFO);
    DEBUG "debug: ON";

    # taille max en kio pour calcul md5
    # (juste plus grand qu'une photo)
    $self->{no_md5} = (exists $options{no_md5}) ? $options{no_md5} : 0;
    $self->{taille_limite_md5} =
      (exists $options{taille_limite_md5})
      ? $options{taille_limite_md5}
      : 1024 * 10;

    # rep tmp
    $self->{tmp} =
      (exists $options{tmp} and defined $options{tmp})
      ? $options{tmp}
      : File::Catalog::Env::tmp();
    DEBUG "tmp: $self->{tmp}";

    # archives
    $self->{archives} = (exists $options{archives}) ? $options{archives} : 0;
    DEBUG "archives: $self->{archives}";
    if ($self->{archives}) {

        # saisie du mot de passe si besoin
        my $opt_pwd =
          (exists $options{password}) ? $options{password} : undef;
        if (defined($opt_pwd) and !$opt_pwd) {
            my $d = new UI::Dialog(
                backtitle => $self->{moi},
                title     => 'Mot de passe'
            );
            $opt_pwd = $d->password(text => 'Tu peux taper ton mot de passe. Je ne regarde pas...');
        }
        $self->{password} = $opt_pwd;
        DEBUG "password: $self->{password}" if $opt_pwd;

        # 7zip
        $self->{exe7z} = File::Catalog::Env::exe7z();
        $self->{opt7z} = (defined $opt_pwd) ? "-p$opt_pwd" : "";
        DEBUG "exe7z: $self->{exe7z}" if $opt_pwd;
    }

    # bd par defaut
    #my $serveur = File::Catalog::Env::serveur();
    my $fic_bd = (exists $options{bd}) ? $options{bd} : undef;
    $fic_bd = ".ktl.sqlite" unless defined $fic_bd;
    $self->{fic_bd} = $fic_bd;
    DEBUG "fic_bd: $self->{fic_bd}";
    $self->{db} =
      File::Catalog::DB->connect($self->{fic_bd}, $options{extension});

    # contexte archive
    $self->{ctx_arch} = 0;

    # retour
    return $self;
}

=head2 terminer

=cut

# fermeture
sub terminer {
    my ($self) = @_;

    $self->{db}->disconnect();
}

=head2 parcourir_repertoire

=cut

# parcours
sub parcourir_repertoire {
    my ($self, $repertoire, $volume) = @_;
    my $err = 0;

    # volume courant
    if (!defined $volume) {
        chomp($volume = `df -P $repertoire | tail -n 1`);
        $volume =~ s|.+%\s+||;

        # (re)initialisation de la liste des fichiers catalogues
        $self->{repficcat} = [];
    }
    DEBUG "$volume: $repertoire";

    # listage repertoire
    if (opendir my $fh_rep, $repertoire) {
        my @lst_fic = grep { !/^\.\.?$/ } readdir $fh_rep;
        closedir $fh_rep or die "Pb fermeture repertoire $repertoire !\n";

        # analyse
        foreach my $entree (@lst_fic) {
            $err = $self->analyser_entree("$repertoire/$entree", $volume);
        }
    }
    else {
        WARN "Echec ouverture repertoire $repertoire !\n";
    }

    return $err;
}

=head2 analyser_entree

=cut

# analyse
sub analyser_entree {
    my ($self, $entree, $volume, $force_archive) = @_;
    my $rep_tmp = $self->{tmp};
    (my $repfic = $entree) =~ s|^$rep_tmp/||;
    my $rep = dirname $repfic;
    my $fic = basename $repfic;
    return 0 if $fic ~~ @exclusions_fic;
    my $archive  = ($fic =~ /\.(gz|tar|tgz|zip|bz2|tbz2|7z)$/);
    my @stat     = lstat $entree;
    my $inode    = $stat[1];
    my $volinode = "$volume/$inode";
    my $rows;
    my $err = 0;

    #--- table Fichier
    $rows =
      $self->{db}->execute('lister_volinodes', $repfic)->fetchall_arrayref();
    if (my $row = shift @$rows) {

        # si maj volinode
        if ($row->[0] ne $volinode) {

            # maj table Fichier
            $self->{db}->execute('updateF', $volinode, $repfic);
            push @{ $self->{repficcat} }, $repfic;
        }
        else {
            DEBUG "$repfic deja vu";
        }
    }
    else {

        # insertion table Fichier
        DEBUG "insertF: " . $repfic;
        my @autres_infos = $self->{db}->{trigger}->($fic);
        my $ok_trigger   = shift @autres_infos;
        if ($ok_trigger) {
            $self->{db}->execute('insertF', $repfic, $rep, $fic, $volinode, @autres_infos);
            push @{ $self->{repficcat} }, $repfic;
        }
        else {
            $volinode = undef;
        }
    }

    #--- table Inode
    my $md5;
    my $majmd5 = 0;
    if ($volinode) {
        $rows = $self->{db}->execute('lire_volinode', $volinode)->fetchall_arrayref();
        if (my $row = shift @$rows) {

            # si maj infos
            if (
                $row->[3] != $stat[2]       # mode
                or $row->[4] != $stat[7]    # taille

                #or $row->[5] != $stat[8]  # acces
                or $row->[6] != $stat[9]     # modif
                or $row->[7] != $stat[10]    # creation
              )
            {
                my $old_md5 = $row->[8];

                # maj table Inode
                $md5 = $self->md5sum($entree, \@stat) unless $self->{no_md5};
                $self->{db}
                  ->execute("updateI", $stat[2], $stat[7], $stat[8], $stat[9], $stat[10], $archive, $md5, $volinode);
                $majmd5 = (defined $md5 and ($old_md5 ne $md5));
                DEBUG "majmd5: " . $majmd5;
            }
            else {
                DEBUG "inode $inode deja vu";
            }
        }
        else {

            # insertion table Inode
            $md5 = $self->md5sum($entree, \@stat) unless $self->{no_md5};
            DEBUG "insertI: " . $volinode;
            $self->{db}->execute(
                'insertI', $volinode, $volume,   $inode,   $stat[2], $stat[7],
                $stat[8],  $stat[9],  $stat[10], $archive, $md5
            );
            $majmd5 = 1;
        }
    }

    #--- progression
    if (    S_ISREG($stat[2])
        and defined($self->{barre})
        and !$self->{ctx_arch})
    {
        $self->{barre}->update(++$self->{nbfic});
    }

    #--- archive
    if ($md5 and ($self->{archives} or $force_archive) and $archive) {

        DEBUG "archive: " . $md5;

        # nb occurrences md5sum
        my $count = $self->{db}->nb_occurrences_md5sum($md5);
        DEBUG "count = $count";
        if ($count > 1 or !$majmd5) {
            DEBUG "archive $fic deja analysee";
        }
        else {

            #INFO "analyse archive $fic";
            #DEBUG "timeout: $timeout_court";

            #ZZZ essayer de trouver la taille necessaire
            #ZZZ pour eviter de saturer l'espace temporaire
            #my $err = timeout $timeout_court => sub {
            my $entree7z = nom_local($entree);
            my $cmd      = "$self->{exe7z} $self->{opt7z} t \"$entree7z\" > $rep_tmp/$md5.log 2>&1";
            DEBUG $cmd;
            $err = system($cmd) >> 8;

            #};
            #if ($@) {
            #WARN "[PB] test timed-out : $entree";
            #$err = 5;
            #}
            if ($err) {
                WARN "[PB] archive non reconnue ($err) : $entree";
                my @log = `cat $rep_tmp/$md5.log`;
                foreach (@log) {
                    ERROR $_;
                }
            }
            else {
                $err = $self->analyser_archive($entree, $md5);
            }
        }
    }

    # fin si repertoire exclu
    return $err if $fic ~~ @exclusions_rep;

    # repertoire
    $err = $self->parcourir_repertoire($entree, $volume) if S_ISDIR $stat[2];

    return $err;
}

=head2 lister_resultat

=cut

# liste des fichiers catalogues
# par la commande precedente
sub lister_resultat {
    my ($self) = @_;

    return $self->{repficcat};
}

=head2 analyser_archive

=cut

sub analyser_archive {
    my ($self, $archive, $md5) = @_;
    my $err = 0;

    # debut contexte archive
    $self->{ctx_arch}++;

    # md5
    if (!$md5) {
        my @stat = lstat $archive;
        $md5 = $self->md5sum($archive, \@stat);
    }

    # tar, zip, bz2, 7z : 7za x -o{Directory} + rm -rf
    # tgz, tar.gz : gunzip -c + 7za x -o{Directory} + rm -rf
    # tbz2, tar.bz2 : bunzip2 -c + 7za x -o{Directory} + rm -rf
    my $archive7z = nom_local($archive);
    my $rep_tmp   = $self->{tmp};
    my $reptmp    = "$rep_tmp/$md5";
    my $reptmp7z  = nom_local($reptmp);

    #INFO "analyse sous $reptmp";

    # extraction
    if ($archive =~ /\.(tar\.gz|tgz|tar\.bz2|tbz2)$/) {

        # cas d'une archive (b|g)zippee
        my $dec = ($archive =~ /\.t?gz$/) ? "gunzip" : "bunzip2";
        my $cmd = "$dec -c \"$archive\" > $reptmp.tar 2>$reptmp.log";
        DEBUG $cmd;
        $err = system($cmd) >> 8;
        if ($err) {
            ERROR "[PB] gunzip ($err) : $archive";
        }
        else {

            # extraction avec tar
            mkdir $reptmp;
            my $cmd = "tar xf $reptmp7z.tar -C $reptmp7z > $reptmp.log 2>&1";
            DEBUG $cmd;
            $err = system($cmd) >> 8;
        }
    }
    else {

        # extraction avec 7zip
        my $cmd = "$self->{exe7z} $self->{opt7z} x -y -o\"$reptmp7z\" \"$archive7z\" > $reptmp.log 2>&1";
        DEBUG $cmd;
        $err = system($cmd) >> 8;
    }

    if (!-d $reptmp) {

        # cas reptmp inexistant
        ERROR "[PB] repertoire $reptmp inexistant ($archive) !";
    }
    if ($err or !-d $reptmp) {

        # affichage du log en cas d'erreur
        ERROR "[PB] extraction archive ($err) : $archive";
        my @log = `cat $reptmp.log`;
        foreach (@log) {
            ERROR $_;
        }
    }
    else {

        # parcours de l'arborescence temporaire
        $self->parcourir_repertoire($reptmp, $md5);
    }

    # nettoyage
    my $cmd = "rm -rf $reptmp*";
    DEBUG $cmd;
    my $cr = system($cmd) >> 8;

    # fin contexte archive
    $self->{ctx_arch}--;

    # retour
    return $err || $cr;
}

=head2 purger_entree

=cut

# purge d'une entree du catalogue
# les fichiers et leur inode sont supprimes du catalogue
# les fichiers ne sont pas supprimes du disque
# on n'accede a aucun moment au disque
sub purger_entree {
    my ($self, $entree) = @_;

    DEBUG "purge: $entree";

    # recherche de l'entree dans le catalogue
    my $lst = $self->{db}->lister_fichiers($entree);

    foreach my $elt (@$lst) {
        my ($md5sum, $type, $repfic) = @{$elt};

        # volinode de ce repfic
        my ($volinode, $archive) =
          @{ $self->{db}->lire_volinode_archive($repfic) };

        # nombre de fichiers supplementaires pour ce volinode
        my $nbfic = $self->{db}->nb_occurrences_volinode($volinode) - 1;
        DEBUG sprintf "autres occurrences de ce fichier = %d", $nbfic;

        # si nbfic
        if ($nbfic) {
            INFO sprintf("%s ! reste %d occurrence%s de ce fichier", $md5sum, $nbfic, ($nbfic > 1) ? "s" : "");
        }
        else {

            # alors supprimer enregistrement table Inode
            DEBUG "deleteI: " . $volinode;
            $self->{db}->execute('deleteI', $volinode);
        }

        # delete repfic
        # supprimer enregistrement table Fichier
        DEBUG "deleteF: " . $repfic;
        $self->{db}->execute('deleteF', $repfic);

        # progression
        if (defined $self->{barre}) {
            $self->{barre}->update(++$self->{nbfic});
        }

        # archive : TODO ...

    }

}

=head2 md5sum

=cut

# calcul du md5
sub md5sum {
    my ($self, $fic, $refStat) = @_;

    if (!$refStat) {
        my @stat = lstat($fic);
        $refStat = \@stat;
    }
    my $md5;
    if (S_ISREG $refStat->[2]) {
        if ($refStat->[7] < $self->{taille_limite_md5} * 1024) {

            # taille inferieure a la limite
            $md5 = file_md5_hex($fic);
        }
        else {

            # taille bornee a la limite
            my $tmp =
              $self->{tmp} . "/" . $self->{moi} . "_" . $$ . "_" . $self->{i}++;
            my $cmd = "dd if=\"$fic\" of=$tmp bs=1024 count=$self->{taille_limite_md5} 2>/dev/null";
            DEBUG $cmd;
            my $err = system($cmd) >> 8;
            $md5 = file_md5_hex($tmp);
            unlink $tmp;
        }
    }
    return $md5;
}

=head1 AUTHOR

Patrick Hingrez, C<< <info-perl at phiz.fr> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-file-catalog at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=File-Catalog>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc File::Catalog


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=File-Catalog>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/File-Catalog>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/File-Catalog>

=item * Search CPAN

L<http://search.cpan.org/dist/File-Catalog/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2015 Patrick Hingrez.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1;    # End of File::Catalog
