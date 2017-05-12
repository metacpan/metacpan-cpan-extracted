use strict;
use warnings;

package Gentoo::Perl::Distmap::FromOverlay;
BEGIN {
  $Gentoo::Perl::Distmap::FromOverlay::AUTHORITY = 'cpan:KENTNL';
}
{
  $Gentoo::Perl::Distmap::FromOverlay::VERSION = '0.1.0';
}

# ABSTRACT: Scrape an Overlay to produce a C<Distmap>

use Moose;
use MooseX::Has::Sugar;
use Moose::Util::TypeConstraints qw(class_type union);


my ($go)  = class_type undef, { class => 'Gentoo::Overlay' };
my ($gog) = class_type undef, { class => 'Gentoo::Overlay::Group' };

Moose::Util::TypeConstraints::coerce(
  $gog, $go,
  sub {
    require Gentoo::Overlay::Group;
    my $tree = Gentoo::Overlay::Group->new();
    $tree->add_overlay($_);
    $tree;
  }
);

has overlay => ( isa => $gog, ro, required, coerce );
has distmap => ( isa => 'Gentoo::Perl::Distmap', ro, lazy_build );

sub _warn {
  shift;
  require Carp;
  return Carp::carp(shift);
}

sub _on_metadata_xml_missing {
  my ( $self, $category, $package, $xml_file ) = @_;
  return $self->_warn( sprintf 'No metadata.xml for %s/%s %s', $category, $package, $xml_file );
}

sub _on_enter_category {
  my ( $self, $category, $c ) = @_;
  return;
}

sub _on_enter_package {
  my ( $self, $category, $package, $c ) = @_;
  return;
}

sub _on_enter_ebuild {
  my ( $self, $c ) = @_;
  return;
}

sub _get_xml_smart {
  my ( $self, $xml_file ) = @_;
  require XML::Smart;
  return XML::Smart->new( $xml_file->absolute()->stringify() );
}

sub _on_xml_missing_pkgmetadata {
  my ( $self, $xmlfile ) = @_;

  #  return;
  return $self->_warn( '<pkgmetadata> missing in ' . $xmlfile );
}

sub _on_xml_missing_upstream {
  my ( $self, $xmlfile ) = @_;
  return;

  #  return $self->_warn( 'pkgmetadata/upstream missing in ' . $xmlfile );
}

sub _on_xml_missing_remoteid {
  my ( $self, $xmlfile ) = @_;
  return;

  #  return $self->_warn( 'pkgmetadata/upstream/remote-id missing in ' . $xmlfile );
}

sub _on_ebuild {
  my ( $self, $distmapargs, $stash, $distmap ) = @_;
  return sub {
    my ( $it, $estash ) = @_;
    $self->_on_enter_ebuild($estash);
    my $version = $estash->{ebuild_name};
    my $p       = $stash->{package_name};
    $version =~ s/[.]ebuild$//;
    $version =~ s/^\Q${p}\E-//;
    $distmap->add_version( %{$distmapargs}, version => $version, );
  };
}

sub _on_remote {
  my ( $self, $remote, $stash, $distmap ) = @_;
  return unless exists $remote->{type};
  return unless $remote->{type} eq 'cpan';

  my $upstream = $remote->content();

  my $distmapargs = {
    category     => $stash->{category_name},
    package      => $stash->{package_name},
    repository   => $stash->{overlay_name},
    distribution => $upstream,
  };
  my $on_ebuild = $self->_on_ebuild( $distmapargs, $stash, $distmap );
  $stash->{package}->iterate( ebuilds => $on_ebuild );
  return;
}

sub _on_package {
  my ( $self, $distmap ) = @_;
  my $cat;

  return sub {
    my ( $it, $stash ) = @_;

    my $xml_file = $stash->{package}->path->child('metadata.xml');

    return $self->_on_metadata_xml_missing( $stash->{category_name}, $stash->{package_name}, $xml_file )
      unless -e -f $xml_file;

    if ( not $cat or $stash->{category_name} ne $cat ) {
      $cat = $stash->{category_name};
      $self->_on_enter_category( $cat, $stash );
    }

    $self->_on_enter_package( $stash->{category_name}, $stash->{package_name}, $stash );
    my $xml = $self->_get_xml_smart($xml_file);

    return $self->_on_xml_missing_pkgmetadata($xml_file) unless exists $xml->{pkgmetadata};
    return $self->_on_xml_missing_upstream($xml_file)    unless exists $xml->{pkgmetadata}->{upstream};
    return $self->_on_xml_missing_remoteid($xml_file)    unless exists $xml->{pkgmetadata}->{upstream}->{'remote-id'};

    for my $remote ( @{ $xml->{pkgmetadata}->{upstream}->{'remote-id'} } ) {
      $self->_on_remote( $remote, $stash, $distmap );
    }

  };
}

sub _build_distmap {
  my ($self) = @_;
  require Gentoo::Perl::Distmap;
  my $distmap  = Gentoo::Perl::Distmap->new();
  my $callback = $self->_on_package($distmap);
  $self->overlay->iterate( packages => $callback );
  return $distmap;
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Gentoo::Perl::Distmap::FromOverlay - Scrape an Overlay to produce a C<Distmap>

=head1 VERSION

version 0.1.0

=head1 SYNOPSIS

    use Gentoo::Perl::Distmap::FromOverlay;

    my $translator = Gentoo::Perl::Distmap::FromOverlay->new( overlay => Gentoo::Overlay->new( '/path/to/overlay' ) )
    # or
    my $og = Gentoo::Overlay::Group->new();
    $og->add_overlay('/path/to/overlay');
    my $translator = Gentoo::Perl::Distmap::FromOverlay->new( overlay => $og )
    # or
    my $translator = Gentoo::Perl::Distmap::FromOverlay->new( overlay => Gentoo::Overlay::Group::INI->load_named('foo')->overlay_group );

and then

    my $result = $translator->distmap;

And see L<< C<Gentoo::Perl::Distmap>|Gentoo::Perl::Distmap >> for details on using the result.

=head1 AUTHOR

Kent Fredric <kentfredric@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
