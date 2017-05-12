use 5.006;
use strict;
use warnings;

package Gentoo::Overlay::Package;

our $VERSION = '2.001002';

# ABSTRACT: Class for Package's in Gentoo Overlays

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Moo qw( has );
use MooX::HandlesVia;
use MooseX::Has::Sugar qw( ro required lazy lazy_build);
use Types::Standard qw( HashRef Str );
use Types::Path::Tiny qw( Path );
use MooX::ClassAttribute qw( class_has );
use Gentoo::Overlay::Types qw( Gentoo__Overlay_PackageName Gentoo__Overlay_Category );
use Gentoo::Overlay::Types qw( Gentoo__Overlay_RepositoryName Gentoo__Overlay_Category Gentoo__Overlay_Ebuild );
use Gentoo::Overlay::Exceptions qw( exception);
use namespace::clean -except => 'meta';













































has name => ( isa => Gentoo__Overlay_PackageName, required, ro, );
has category => ( isa => Gentoo__Overlay_Category, required, ro, handles => [qw( overlay )], );
has path => (
  isa => Path,
  ro,
  lazy,
  default => sub {
    my ($self) = shift;
    return $self->overlay->default_path( 'package', $self->category->name, $self->name );
  },
);




























class_has _scan_blacklist => (
  isa => HashRef [Str],
  ro,
  lazy,
  default => sub {
    return { map { $_ => 1 } qw( . .. metadata.xml ) };
  },
);

sub _scan_blacklisted {
  my ( $self, $what ) = @_;
  return exists $self->_scan_blacklist->{$what};
}




















































has _ebuilds => (
  isa => HashRef [Gentoo__Overlay_Ebuild],
  lazy,
  builder => 1,
  ro,
  handles_via => 'Hash',
  handles     => {
    _has_ebuild  => exists   =>,
    ebuild_names => keys     =>,
    ebuilds      => elements =>,
    get_ebuild   => get      =>,
  },
);









sub _build__ebuilds {
  my ($self) = shift;
  require Gentoo::Overlay::Ebuild;
  my $it = $self->path->iterator();
  my %out;
  while ( defined( my $entry = $it->() ) ) {
    my $ebuild = $entry->basename;
    next if Gentoo::Overlay::Ebuild->is_blacklisted($ebuild);
    next if -d $entry;
    ## no critic ( RegularExpressions )
    next if $entry !~ /\.ebuild$/;
    my $e = Gentoo::Overlay::Ebuild->new(
      name    => $ebuild,
      package => $self,
    );
    next unless $e->exists;
    $out{$ebuild} = $e;
  }
  return \%out;
}










## no critic ( ProhibitBuiltinHomonyms )
sub exists {
  my $self = shift;
  return if q{.} eq $self->name;
  return if q{..} eq $self->name;
  return if not -e $self->path;
  return if not -d $self->path;
  return 1;
}









sub is_blacklisted {
  my ( $self, $name ) = @_;
  if ( not defined $name ) {
    $name = $self->name;
  }
  return $self->_scan_blacklisted($name);
}









sub pretty_name {
  my $self = shift;
  return $self->category->name . q{/} . $self->name . q{::} . $self->overlay->name;
}



























sub iterate {
  my ( $self, $what, $callback ) = @_;    ## no critic (Variables::ProhibitUnusedVarsStricter)
  my %method_map = ( ebuilds => _iterate_ebuilds =>, );
  if ( exists $method_map{$what} ) {
    goto $self->can( $method_map{$what} );
  }
  return exception(
    ident   => 'bad iteration method',
    message => 'The iteration method %{what_method}s is not a known way to iterate.',
    payload => { what_method => $what },
  );
}











# ebuilds = {/ebuilds }
sub _iterate_ebuilds {
  my ( $self, undef, $callback ) = @_;
  my %ebuilds     = $self->ebuilds();
  my $num_ebuilds = scalar keys %ebuilds;
  my $last_ebuild = $num_ebuilds - 1;
  my $offset      = 0;
  for my $ename ( sort keys %ebuilds ) {
    local $_ = $ebuilds{$ename};
    $self->$callback(
      {
        ebuild_name => $ename,
        ebuild      => $ebuilds{$ename},
        num_ebuilds => $num_ebuilds,
        last_ebuild => $last_ebuild,
        ebuild_num  => $offset,
      }
    );
    $offset++;
  }
  return;

}
no Moo;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Gentoo::Overlay::Package - Class for Package's in Gentoo Overlays

=head1 VERSION

version 2.001002

=head1 SYNOPSIS

    my $package = Overlay::Package->new(
        name => 'Moose',
        category => $category_object,
    );

    $package->exists() # Moose exists

    print $package->pretty_name() # dev-perl/Moose::gentoo

    print $package->path() # /usr/portage/dev-perl/Moose

    ::Package->is_blacklisted("..") # '..' is not a valid package name
    ::Package->is_blacklisted('metadata.xml') # is not a valid directory

=head1 METHODS

=head2 exists

Does the Package exist, and is it a directory?

    $package->exists();

=head2 is_blacklisted

Does the package name appear on a blacklist meaning auto-scan should ignore this?

    ::Package->is_blacklisted('..') # true

=head2 pretty_name

A pretty form of the name

    $package->pretty_name # dev-perl/Moose::gentoo

=head2 iterate

  $overlay->iterate( $what, sub {
      my ( $context_information ) = shift;

  } );

The iterate method provides a handy way to do walking across the whole tree stopping at each of a given type.

=over 4

=item * C<$what = 'ebuilds'>

  $overlay->iterate( ebuilds => sub {
      my ( $self, $c ) = shift;
      # $c->{ebuild_name}  # String
      # $c->{ebuild}       # Ebuild Object
      # $c->{num_ebuilds}  # How many ebuild are there to iterate
      # $c->{last_ebuild}  # Index ID of the last ebuild.
      # $c->{ebuild_num}   # Index ID of the current ebuild.
  } );

=back

=head1 ATTRIBUTES

=head2 name

The packages Short name.

    isa => Gentoo__Overlay_PackageName, required, ro

L<< C<PackageName>|Gentoo::Overlay::Types/Gentoo__Overlay_PackageName >>

=head2 category

The category object that this package is in.

    isa => Gentoo__Overlay_Category, required, ro

    accessors => overlay

L<< C<Category>|Gentoo::Overlay::Types/Gentoo__Overlay_Category >>

L</overlay>

=head2 path

The full path to the package.

    isa => Dir, lazy, ro

L<MooseX::Types::Path::Tiny/Dir>

=head1 ATTRIBUTE ACCESSORS

=head2 overlay

    $package->overlay -> Gentoo::Overlay::Category->overlay

L<Gentoo::Overlay::Category/overlay>

L</category>

=head2 ebuild_names

    for( $package->ebuild_names ){
        print $_;
    }

L</_ebuilds>

=head2 ebuilds

    my %ebuilds = $package->ebuilds;

L</_ebuilds>

=head2 get_ebuild

    my $ebuild = $package->get_ebuild('Moose-2.0.0.ebuild');

L</_ebuilds>

=head1 PRIVATE ATTRIBUTES

=head2 _ebuilds

    isa => HashRef[ Gentoo__Overlay_Ebuild ], lazy_build, ro

    accessors => _has_ebuild , ebuild_names,
                 ebuilds, get_ebuild

L</_has_ebuild>

L</ebuild_names>

L</ebuilds>

L</get_ebuild>

=head1 PRIVATE ATTRIBUTE ACCESSORS

=head2 _has_ebuild

    $package->_has_ebuild('Moose-2.0.0.ebuild');

L</_ebuilds>

=head1 PRIVATE CLASS ATTRIBUTES

=head2 _scan_blacklist

Class-Wide list of blacklisted package names.

    isa => HashRef[ Str ], ro, lazy,

    accessors => _scan_blacklisted

L</_scan_blacklisted>

L<< C<MooseX::Types::Moose>|MooseX::Types::Moose >>

=head1 PRIVATE CLASS ATTRIBUTE ACCESSORS

=head2 _scan_blacklisted

is C<$arg> blacklisted in the Class Wide Blacklist?

    ::Package->_scan_blacklisted( $arg )
       ->
    exists ::Package->_scan_blacklist->{$arg}

L</_scan_blacklist>

=head1 PRIVATE METHODS

=head2 _build__ebuilds

Generates the ebuild Hash-Table, by scanning the package directory.

L</_packages>

=head2 _iterate_ebuilds

  $object->_iterate_ebuilds( ignored_value => sub {  } );

Handles dispatch call for

  $object->iterate( ebuilds => sub { } );

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentnl@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
