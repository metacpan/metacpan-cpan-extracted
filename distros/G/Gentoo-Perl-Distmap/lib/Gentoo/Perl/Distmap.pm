use strict;
use warnings;

package Gentoo::Perl::Distmap;
BEGIN {
  $Gentoo::Perl::Distmap::AUTHORITY = 'cpan:KENTNL';
}
{
  $Gentoo::Perl::Distmap::VERSION = '0.2.0';
}

# ABSTRACT: A reader/writer for the C<metadata/perl/distmap.json> file.

use 5.010000;
use Moose;



has map => (
  isa     => 'Gentoo::Perl::Distmap::Map',
  is      => ro =>,
  default => sub {
    require Gentoo::Perl::Distmap::Map;
    Gentoo::Perl::Distmap::Map->new();
  },
  handles => [qw( multi_repository_dists all_mapped_dists mapped_dists dists_in_repository add_version )],
);


sub load {
  my ( $self, $method, $source ) = @_;
  require Gentoo::Perl::Distmap::Map;
  return $self->new(
    map => Gentoo::Perl::Distmap::Map->from_rec(
      $self->decoder->decode( $self->can( '_load_' . $method )->( $self, $method, $source ) )
    )
  );
}


sub save {
  my ( $self, $method, $target ) = @_;
  return $self->can( '_save_' . $method )->( $self, $self->encoder->encode( $self->map->to_rec ), $target );
}


sub _save_string     { return $_[1] }
sub _save_filehandle { return $_[2]->print( $_[1] ) }
sub _save_file       { require Path::Tiny; return $_[0]->_save_filehandle( $_[1], Path::Tiny::path( $_[2] )->openw() ) }


sub _load_file { require Path::Tiny; return scalar Path::Tiny::path( $_[2] )->slurp() }
sub _load_filehandle { local $/ = undef; return scalar $_[2]->getline }
sub _load_string { return $_[2] }


sub decoder {
  return state $json = do { require JSON; JSON->new->pretty->utf8->canonical; }
}

sub encoder {
  return state $json = do { require JSON; JSON->new->pretty->utf8->canonical; }
}
__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Gentoo::Perl::Distmap - A reader/writer for the C<metadata/perl/distmap.json> file.

=head1 VERSION

version 0.2.0

=head1 SYNOPSIS

	my $dm  = Gentoo::Perl::Distmap->load(  file => '../path/to/distmap.json' );
	$dm->save( file => '/tmp/foo.x' );

	for my $dist ( sort $dm->dists_in_repository('gentoo') ) {
		/* see the upstream distnames visible in gentoo */
	}
	for my $dist ( sort $dm->dists_in_repository('perl-experimental') ) {
		/* see the upstream distnames visible in perl-experimental */
	}
	for my $dist ( sort $dm->multi_repository_dists ) {
		/* see the dists that exist in more than one repository */
	}
-	for my $dist ( sort $dm->mapped_dists ) {
		/* see the dists that have at least one version in the dataset */
		/* note: dists with empty version sets should be deemed a bug  */
	}

Interface for creating/augmenting/comparing C<.json> files still to be defined, basic functionality only at this time.

=head1 ATTRIBUTES

=head2 map

=head1 METHODS

=head2 save

	$instance->save( file => $filepath );
	$instance->save( filehandle => $fh );
	my $string = $instance->save( string => );

=head1 CLASS METHODS

=head2 load

	my $instance = G:P:Distmap->load( file => $filepath );
	my $instance = G:P:Distmap->load( filehandle => $fh );
	my $instance = G:P:Distmap->load( string => $str );

=head2 decoder

	$decoder = G:P:Distmap->decoder();

=head2 encoder

	$encoder = G:P:Distmap->encoder();

=head1 ATTRIBUTE METHODS

=head2 map -> map

=head2 multi_repository_dists -> map

=head2 all_mapped_dists -> map

=head2 mapped_dists -> map

=head2 dists_in_repository -> map

=head2 add_version -> map

=head1 PRIVATE METHODS

=head2 _save_string

=head2 _save_filehandle

=head2 _save_file

=head1 PRIVATE CLASS METHODS

=head2 _load_file

=head2 _load_filehandle

=head2 _load_string

=head1 AUTHOR

Kent Fredric <kentfredric@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
