package File::ShareDir::Tarball;
BEGIN {
  $File::ShareDir::Tarball::AUTHORITY = 'cpan:YANICK';
}
{
  $File::ShareDir::Tarball::VERSION = '0.2.2';
}
# ABSTRACT: Deal transparently with shared files distributed as tarballs


use strict;
use warnings;

use parent qw/ Exporter /;

use Carp;

use File::ShareDir;
use Archive::Tar;
use File::Temp qw/ tempdir /;
use File::chdir;

our @EXPORT_OK   = qw{
    dist_dir dist_file
};
our %EXPORT_TAGS = (
    all => [ @EXPORT_OK ],
);

my $shared_files_tarball = 'shared-files.tar.gz';

# we don't want to extract the same dirs again and 
# again within a single program
my %DIR_CACHE;

sub dist_dir {
    my $dist = shift;

    return $DIR_CACHE{$dist} if $DIR_CACHE{$dist};

    my $dir = File::ShareDir::dist_dir($dist);

    # no tarball? Assume regular shared dir
    return $DIR_CACHE{$dist} = $dir 
        unless -f "$dir/$shared_files_tarball";

    my $archive = Archive::Tar->new;
    $archive->read("$dir/$shared_files_tarball");

    # because that would be a veeery bad idea
    croak "archive '$shared_files_tarball' contains files with absolute path, aborting"
        if grep { m#^/# } $archive->list_files;

    my $tmpdir = tempdir( CLEANUP => 1 );
    local $CWD = $tmpdir;

    $archive->extract;

    return $DIR_CACHE{$dist} = $tmpdir;
}

sub dist_file {
    my $dist = File::ShareDir::_DIST(shift);
    my $file = File::ShareDir::_FILE(shift);

    my $path = dist_dir($dist).'/'.$file;

	return undef unless -e $path;

    croak("Found dist_file '$path', but not a file") 
        unless -f $path;

    croak("File '$path', no read permissions") 
        unless -r $path;

	return $path;
}


1;

__END__

=pod

=head1 NAME

File::ShareDir::Tarball - Deal transparently with shared files distributed as tarballs

=head1 VERSION

version 0.2.2

=head1 SYNOPSIS

    use File::ShareDir::Tarball ':all';

    # use exactly like File::ShareDir
    $dir = dist_dir('File-ShareDir');

=head1 DESCRIPTION

If the shared files of a distribution are contained in a
tarball (see L<Dist::Zilla::Plugin::ShareDir::Tarball> for
why you would want to do that), automatically 
extract the archive in a temporary
directory and return the path to that directory. If called for a regular distribution without a bundle file
(C<shared-files.tar.gz>), it'll return the original shared dir. 
In other words,
from the consumer point of view, it'll behave just like L<File::ShareDir>.

=head1 EXPORT TAGS

=head2 :all

Exports C<dist_dir()> and C<dist_file()>.

=head1 EXPORTABLE FUNCTIONS

=head2 dist_dir( $distribution )

Behaves just like C<dist_dir()> from L<File::ShareDir>.

=head2 dist_file( $distribution, $file )

Behaves just like C<dist_file()> from L<File::ShareDir>.

=head1 SEE ALSO

=over

=item L<Test::File::ShareDir>

To test or use a shared dir that is not deployed yet. 

=item L<Dist::Zilla::Plugin::ShareDir::Tarball>

L<Dist::Zilla> plugin to create the tarball effortlessly.

=item L<Module::Build::CleanInstall>

Provides an alternative to this module by subclassing L<Module::Build> and,
upon installation, remove the files from previous installations as given in
the I<packlist>.

=back

=head1 AUTHOR

Yanick Champoux <yanick@babyl.dyndns.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
