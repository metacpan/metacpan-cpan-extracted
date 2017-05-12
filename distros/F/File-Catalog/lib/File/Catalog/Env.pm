# acces aux cots
# et aux "bonnes" variables d'environnement

package File::Catalog::Env;

use strict;
use warnings;
use 5.010;
use Env;
use Exporter 'import';

our @EXPORT_OK = qw(nom_local);

=head1 NAME

File::Catalog::Env - The great new File::Catalog::Env!

=head1 VERSION

Version 0.002

=cut

our $VERSION = 0.002;

my $serveur;
my $windows;
my $exe7z;
my $tmp;

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

# Linux/Moba
BEGIN {
    if (exists $ENV{MOBASTARTUPDIR}) {

        # Moba
        $serveur = $ENV{COMPUTERNAME};
        $windows = 1;
    }
    else {
        # Linux
        $serveur = $ENV{HOSTNAME};
        $windows = 0;
    }

    # tmp
    $tmp = (exists $ENV{TMPZ}) ? $ENV{TMPZ} : ((exists $ENV{TMP}) ? $ENV{TMP} : "/tmp");
}

=head1 SUBROUTINES/METHODS

=head2 windows

=cut

sub windows {
    return $windows;
}

=head2 serveur

=cut

sub serveur {
    return $serveur;
}

=head2 exe7z

=cut

sub exe7z {

    if (!defined $exe7z) {
        my $ok7za = !(system('7za &>/dev/null') >> 8);
        my $ok7z  = !(system('7z &>/dev/null') >> 8);
        die "7z introuvable !\n" unless ($ok7z or $ok7za);
        $exe7z = ($ok7za) ? "7za" : "7z";
    }

    return $exe7z;
}

=head2 tmp

=cut

sub tmp {
    return $tmp;
}

=head2 nom_local

=cut

sub nom_local {
    my $repfic = shift;
    $repfic =~ s|^/drives/([a-z])/|$1:/| if $windows;
    return $repfic;
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
