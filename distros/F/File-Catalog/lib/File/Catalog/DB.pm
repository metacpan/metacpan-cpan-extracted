# base de donnees du catalogage

package File::Catalog::DB;

use 5.010;
use warnings;
use strict;
use DBI;
use Log::Log4perl qw(:easy);
use Data::Dumper qw(Dumper);

=head1 NAME

File::Catalog::DB - The great new File::Catalog::DB!

=head1 VERSION

Version 0.003

=cut

our $VERSION = 0.003;

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use File::Catalog;

    my $foo = File::Catalog->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=cut

=head1 SUBROUTINES/METHODS

=head2 connect

=cut

# creation/connection/construction/preparation
sub connect {
    my ($class, $nomfic, $extension) = @_;
    my $self = {};
    bless $self, $class;

    # memo nouvelle base ou pas
    $self->{new} = !-f $nomfic;

    # connection
    $self->{dbh} = DBI->connect("dbi:SQLite:dbname=$nomfic", "", "")
      or die "Connection impossible a la base de donnees $nomfic !\n $! \n $@\n$DBI::errstr";

    # creation des tables si nouvelle base
    if ($self->{new}) {

        # creation tables BD
        $self->{dbh}->do("CREATE TABLE Fichier (repfic TEXT PRIMARY KEY, rep TEXT, fic TEXT, volinode TEXT)");
        $self->{dbh}->do(
            "CREATE TABLE Inode (
 volinode TEXT PRIMARY KEY, volume TEXT, inode INTEGER, mode INTEGER, size INTEGER,
 atime INTEGER, mtime INTEGER, ctime INTEGER, archive INTEGER, md5sum TEXT)"
        );
    }

    # preparation des requetes
    $self->definir_requetes();

    # initialiser les colonnes complementaires
    $self->initialiser_extension($extension);

    # preparation des requetes
    $self->preparer_requetes();

    # retour
    return $self;
}

=head2 initialiser_extension

=cut

# prise en compte des colonnes complementaires
sub initialiser_extension {
    my ($self, $extension) = @_;

    if (defined $extension) {
        DEBUG "extension BD definie";

        #ZZZ tester le contenu de extension : list, columns, trigger
        my @liste = @{ $extension->{list} };
        my $types = $extension->{columns};

        # pour chaque element de la liste
        foreach my $col (@liste) {
            DEBUG "ajout colonne $col";

            # ajouter une colonne
            my $type = (exists $types->{$col}) ? $types->{$col} : 'TEXT';
            $self->{dbh}->do("ALTER TABLE Fichier ADD COLUMN $col $type")
              if $self->{new};

            # maj requete insertF
            $self->{requete}->{insertF} =~ s/\?/\?, \?/;
        }

        if ($self->{new}) {

            # ajout d'un index
            my $nom_index = "idx_" . join "_", @liste;
            my $liste_index = join ",", @liste;
            $self->{dbh}->do("CREATE INDEX $nom_index ON Fichier ($liste_index)");
        }

        # memoriser le trigger associe
        $self->{trigger} = $extension->{trigger};

        # memoriser les requetes a preparer
        my $requetes = $extension->{requests};
        foreach my $requete (keys %$requetes) {
            $self->{requete}->{$requete} = $requetes->{$requete};
        }
    }
    else {
        DEBUG "pas d'extension BD";

        # trigger par defaut
        $self->{trigger} = sub {
            return (1);    # 1 pour ok tout va bien
        };
    }
}

=head2 handler

=cut

# acces handler
sub handler {
    my ($self) = @_;
    return $self->{dbh};
}

=head2 disconnect

=cut

# deconnection
sub disconnect {
    my ($self) = @_;
    $self->{dbh}->disconnect;
}

=head2 definir_requetes

=cut

# definition des requetes
sub definir_requetes {
    my ($self) = @_;
    my $db = $self->{dbh};

    $self->{requete}->{insertF} = "INSERT INTO Fichier VALUES (?, ?, ?, ?)";
    $self->{requete}->{updateF} = "UPDATE Fichier SET volinode = ? WHERE repfic = ?";
    $self->{requete}->{deleteF} = "DELETE from Fichier WHERE repfic = ?";

    $self->{requete}->{insertI} = "INSERT INTO Inode VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
    $self->{requete}->{updateI} =
"UPDATE Inode SET mode = ?, size = ?, atime = ?, mtime = ?, ctime = ?, archive = ?, md5sum = ? WHERE volinode = ?";
    $self->{requete}->{deleteI} = "DELETE from Inode WHERE volinode = ?";

    $self->{requete}->{lister_volumes} = "SELECT DISTINCT volume FROM Inode ORDER BY volume";

    $self->{requete}->{lister_archives} =
      "SELECT I.md5sum, F.repfic FROM Fichier AS F LEFT JOIN Inode AS I ON F.volinode = I.volinode
 WHERE I.archive = 1
 ORDER BY I.md5sum";

    $self->{requete}->{lister_doublons} =
      "SELECT I.md5sum, F.repfic FROM Fichier F LEFT JOIN Inode I ON F.volinode = I.volinode
 WHERE I.md5sum IN (SELECT md5sum FROM (SELECT md5sum, count(*) AS nb FROM Inode GROUP BY md5sum HAVING nb > 1))
 AND F.repfic glob ?
 ORDER BY I.md5sum, I.mtime, F.repfic";

    $self->{requete}->{lister_doublons_volume} =
      "SELECT F.repfic FROM Fichier F LEFT JOIN Inode I ON F.volinode = I.volinode
 WHERE I.volume = ?
 AND I.md5sum IN (SELECT DISTINCT md5sum FROM Inode WHERE volume = ?)
 ORDER BY I.mtime, F.repfic";

    $self->{requete}->{lister_fichiers} =
      "SELECT I.md5sum, I.archive, F.repfic FROM Fichier AS F LEFT JOIN Inode AS I ON F.volinode = I.volinode
 WHERE F.repfic glob ?
 ORDER BY F.repfic";

    $self->{requete}->{lister_repertoires} = "SELECT DISTINCT F.rep, COUNT(*) FROM Fichier AS F
 WHERE F.rep glob ?
 GROUP BY F.rep
 ORDER BY F.rep";

    $self->{requete}->{lire_volinode} = "SELECT * FROM Inode WHERE volinode = ?";

    $self->{requete}->{lister_volinodes} = "SELECT volinode FROM Fichier WHERE repfic = ?";

    $self->{requete}->{lire_volinode_archive} =
      "SELECT F.volinode, I.archive FROM Fichier F LEFT JOIN Inode I ON F.volinode = I.volinode
 WHERE F.repfic = ?";

    $self->{requete}->{nb_occurrences_volinode} = "SELECT count(*) FROM Fichier WHERE volinode = ?";

    $self->{requete}->{nb_occurrences_md5sum} = "SELECT count(*) FROM Inode WHERE md5sum = ?";
}

=head2 preparer_requetes

=cut

# preparation des requetes
sub preparer_requetes {
    my ($self) = @_;
    my $db = $self->{dbh};

    foreach my $req (keys %{ $self->{requete} }) {
        DEBUG $req . ": " . $self->{requete}->{$req};
        $self->{$req} = $db->prepare($self->{requete}->{$req});
    }
}

=head2 execute

=cut

# acces aux requetes preparees
sub execute {
    my ($self, $requete, @params) = @_;
    $self->{$requete}->execute(@params)
      or $self->{logger}->error("Pb execution requete '" . $requete . "'");
    return $self->{$requete};
}

#=== acces base de donnees ===

=head2 lire_volinode_archive

=cut

# volinode
sub lire_volinode_archive {
    my ($self, $repfic) = @_;

    my $row = $self->execute('lire_volinode_archive', $repfic)->fetchrow_arrayref();
    $self->{lire_volinode_archive}->finish();

    return $row;
}

=head2 nb_occurrences_volinode

=cut

# volinode
sub nb_occurrences_volinode {
    my ($self, $volinode) = @_;

    my $row = $self->execute('nb_occurrences_volinode', $volinode)->fetchrow_arrayref();
    $self->{nb_occurrences_volinode}->finish();

    return $row->[0];
}

=head2 nb_occurrences_md5sum

=cut

# md5sum
sub nb_occurrences_md5sum {
    my ($self, $md5sum) = @_;

    my $row = $self->execute('nb_occurrences_md5sum', $md5sum)->fetchrow_arrayref();
    $self->{nb_occurrences_md5sum}->finish();

    return $row->[0];
}

=head2 lister_volumes

=cut

# volumes
sub lister_volumes {
    my ($self) = @_;

    my $rows = $self->execute('lister_volumes')->fetchall_arrayref();

    return map { join " ", @$_ } @$rows;
}

=head2 lister_archives

=cut

# archives
sub lister_archives {
    my ($self) = @_;
    my %cpt;

    my $rows = $self->execute('lister_archives')->fetchall_arrayref();

    return map { $_->[0] . " [" . $cpt{ $_->[0] }++ . "] " . $_->[1] } @$rows;
}

=head2 lister_doublons

=cut

# doublons
sub lister_doublons {
    my ($self, $filtre) = @_;
    my %cpt;

    $filtre = '*' unless defined $filtre;
    my $rows = $self->execute('lister_doublons', $filtre)->fetchall_arrayref();

    return map { $_->[0] . " [" . $cpt{ $_->[0] }++ . "] " . $_->[1] } @$rows;
}

=head2 lister_doublons_volumes

=cut

# doublons
sub lister_doublons_volumes {
    my ($self, $volref, $voldbl) = @_;

    my $rows = $self->execute('lister_doublons_volumes', $voldbl, $volref)->fetchall_arrayref();

    return map { $_->[0] } @$rows;
}

=head2 lister_fichiers

=cut

# fichiers
# glob gere les wildcards * et ?
sub lister_fichiers {
    my ($self, $filtre) = @_;

    $filtre = '*' unless defined $filtre;
    my $rows = $self->execute('lister_fichiers', $filtre)->fetchall_arrayref();

    return $rows;
}

=head2 lister_repertoires

=cut

# fichiers
# glob gere les wildcards * et ?
sub lister_repertoires {
    my ($self, $filtre) = @_;

    $filtre = '*' unless defined $filtre;
    my $rows = $self->execute('lister_repertoires', $filtre)->fetchall_arrayref();

    return map { $_->[1] . "\t" . $_->[0] } @$rows;
}

=head2 afficher

=cut

# affichage
sub afficher {
    my ($self) = @_;
    my $db = $self->{dbh};

    my $txt;
    $txt .= "=== Fichier ===\n";
    my $rowsF = $db->selectall_arrayref("SELECT * FROM Fichier ORDER BY repfic");
    foreach my $row (@$rowsF) {
        $txt += join(", ", @$row) . "\n";
    }
    $txt .= "=== Inode ===\n";
    my $rowsI = $db->selectall_arrayref("SELECT * FROM Inode ORDER BY volinode");
    foreach my $row (@$rowsI) {
        @$row[$#$row] = "{}" unless @$row[$#$row];
        $txt += join(", ", @$row) . "\n";
    }

    return $txt;
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

1;    # End of File::Catalog::DB
