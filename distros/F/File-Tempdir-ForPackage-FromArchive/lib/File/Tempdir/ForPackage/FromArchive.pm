use strict;
use warnings;

package File::Tempdir::ForPackage::FromArchive;
BEGIN {
  $File::Tempdir::ForPackage::FromArchive::AUTHORITY = 'cpan:KENTNL';
}
{
  $File::Tempdir::ForPackage::FromArchive::VERSION = '0.1.0';
}

# ABSTRACT: Inflate any archive to a temporary directory and work in it.


use Moo;
use Sub::Quote qw( quote_sub );
extends 'File::Tempdir::ForPackage';

has archive => (
  is       => ro =>,
  required => 1,
  isa      => (
    ## no critic (RequireInterpolationOfMetachars)
    quote_sub q| if ( not -r -e $_[0] ){ | . q| die "archive is not readable: $_[0]"; | . q| }|
  ),
);

around _build__dir => sub {
  my ( $orig, $self, @rest ) = @_;
  require Archive::Any;
  my $dir = $orig->( $self, @rest );
  my $archive = Archive::Any->new( $self->archive );
  $archive->extract($dir);
  return $dir;
};

no Moo;

1;

__END__
=pod

=encoding utf-8

=head1 NAME

File::Tempdir::ForPackage::FromArchive - Inflate any archive to a temporary directory and work in it.

=head1 VERSION

version 0.1.0

=head1 SYNOPSIS

 use File::Tempdir::ForPackage::FromArchive;

 my $stash = File::Tempdir::ForPackage::FromArchive->new(
  archive => 'path/to/archive.tar.gz',
 );
 while(1){
  $stash->run_once_in(sub{
   #  Disk thrashes here as
   #  archive is repeatedly checked out,
   #  modified, then erased.
  });
 }

=head1 DESCRIPTION

Most features of this module are provided by L<< File::Tempdir::C<ForPackage>|File::Tempdir::ForPackage >>, except that empty Tempdirs are constructed containing the contents of the specified archive with Archive-Any.

This is useful if you have some sort of mutable directory state that you need to bundle with your distribution for testing as a nested archive, and you don't want changes to persist between test runs.

=head1 AUTHOR

Kent Fredric <kentfredric@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

