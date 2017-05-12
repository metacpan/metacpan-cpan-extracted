package File::Same;

$File::Same::VERSION   = '0.11';
$File::Same::AUTHORITY = 'cpan:MSERGEANT';

=head1 NAME

File::Same - Detect which files are the same as a given one.

=head1 VERSION

Version 0.11

=cut

use 5.006;
use strict; use warnings;
use Digest::MD5;
use File::Spec;

my %md5s;

=head1 DESCRIPTION

File::Same uses MD5 sums to decide which files are the same in a given directory,
set of directories or set of files. It was originally written to test which files
are the same picture in multiple directories or under multiple filenames, but can
be generally useful for other systems.

File::Same will use an internal cache, for performance reasons.

File::Same will also be careful not to return C<$original> in the list of matched
files.

All of the functions return a list of files that match, with full path expanded.

=head1 SYNOPSIS

    use strict; use warnings;
    use File::Same;

    my @same1 = File::Same::scan_dirs('sample.txt', ['other', '.']);

    my @same2 = File::Same::scan_files('sample.txt', ['ex1.txt', 'ex2.txt']);

    my @same3 = File::Same::scan_dir('sample.txt', 'somedir');

=head1 METHODS

=head2 scan_files($original, \@list)

Scan a list of files to compare against a given file.

=cut

sub scan_files {
    my ($original, $files) = @_;

    my @results;
    my $orig_md5 = $md5s{$original};

    if (!$orig_md5) {
        my $ctx = Digest::MD5->new();
        open(FILE, $original) || die "Cannot open '$original' : $!";
        binmode(FILE);
        $ctx->addfile(*FILE);
        $orig_md5 = $ctx->hexdigest;
        close(FILE);
    }

    foreach my $file (@$files) {
        if (my $md5 = $md5s{$file}) {
            if ($orig_md5 eq $md5) {
                push @results, $file;
            }
        }
        else {
            my $ctx = Digest::MD5->new();
            open(FILE, $file) || die "Cannot open '$file' : $!";
            binmode(FILE);
            $ctx->addfile(*FILE);
            if ($orig_md5 eq $ctx->hexdigest) {
                push @results, $file;
            }
            close(FILE);
        }
    }

    return grep {_not_same($_, $original)} @results;
}

=head2 scan_dir($original, $dir)

Scan an entire directory to find files the same as this one.

=cut

sub scan_dir {
    my ($original, $dir) = @_;

    opendir(DIR, $dir) || die "Cannot opendir '$dir' : $!";
    my @files = grep { -f } map { File::Spec->catfile($dir, $_) } readdir(DIR);
    closedir(DIR);

    return scan_files($original, \@files);
}

=head2 scan_dirs($original, \@dirs)

Scan a list of directories to find files the same as this one.

=cut

sub scan_dirs {
    my ($original, $dirs) = @_;

    my @results;

    foreach my $dir (@$dirs) {
        push @results, scan_dir($original, $dir);
    }

    return @results;
}

#
#
# PRIVATE METHODS

sub _not_same {
    my ($file, $orig) = @_;

    return 0
        if (File::Spec->rel2abs($file) eq File::Spec->rel2abs($orig));

    return 1;
}

=head1 AUTHOR

=over 4

=item Original author Matt Sergeant, C<< <matt at sergeant.org> >>

=item Currently maintained by Mohammad S Anwar, C<< <mohammad.anwar at yahoo.com> >>

=back

=head1 REPOSITORY

L<https://github.com/manwar/File-Same>

=head1 SEE ALSO

L<Digest::MD5> - used to generate a checksum for every file.

L<File::Find::Duplicates> - another that can be used to find duplicates.

=head1 BUGS

Please report any bugs or feature requests to C<bug-file-same at rt.cpan.org>,  or
through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=File-Same>.
I will  be notified and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc File::Same

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=File-Same>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/File-Same>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/File-Same>

=item * Search CPAN

L<http://search.cpan.org/dist/File-Same/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2001 MessageLabs Limited.

This is free  software, you may use it and distribute  it under the same terms as
Perl itself.

Any  use,  modification, and distribution of the Standard or Modified Versions is
governed by this Artistic License.By using, modifying or distributing the Package,
you accept this license. Do not use, modify, or distribute the Package, if you do
not accept this license.

If your Modified Version has been derived from a Modified Version made by someone
other than you,you are nevertheless required to ensure that your Modified Version
 complies with the requirements of this license.

This  license  does  not grant you the right to use any trademark,  service mark,
tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge patent license
to make,  have made, use,  offer to sell, sell, import and otherwise transfer the
Package with respect to any patent claims licensable by the Copyright Holder that
are  necessarily  infringed  by  the  Package. If you institute patent litigation
(including  a  cross-claim  or  counterclaim) against any party alleging that the
Package constitutes direct or contributory patent infringement,then this Artistic
License to you shall terminate on the date that such litigation is filed.

Disclaimer  of  Warranty:  THE  PACKAGE  IS  PROVIDED BY THE COPYRIGHT HOLDER AND
CONTRIBUTORS  "AS IS'  AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES. THE IMPLIED
WARRANTIES    OF   MERCHANTABILITY,   FITNESS   FOR   A   PARTICULAR  PURPOSE, OR
NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY YOUR LOCAL LAW. UNLESS
REQUIRED BY LAW, NO COPYRIGHT HOLDER OR CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL,  OR CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE
OF THE PACKAGE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1; # End of File::Same
