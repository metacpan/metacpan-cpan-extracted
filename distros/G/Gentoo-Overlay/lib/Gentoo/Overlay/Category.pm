use 5.006;
use strict;
use warnings;

package Gentoo::Overlay::Category;

our $VERSION = '2.001002';

# ABSTRACT: A singular category in a repository;

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Moo 1.006000 qw( has );
use MooseX::Has::Sugar qw( ro required coerce lazy lazy_build );
use Types::Standard qw( HashRef Str );
use Types::Path::Tiny qw( File Dir Path );
use MooX::ClassAttribute qw( class_has );
use MooX::HandlesVia;
use Gentoo::Overlay::Types qw( Gentoo__Overlay_CategoryName Gentoo__Overlay_Package Gentoo__Overlay_Overlay );
use Gentoo::Overlay::Exceptions qw( exception );
use namespace::clean -except => 'meta';































has name => ( isa => Gentoo__Overlay_CategoryName, required, ro );
has overlay => ( isa => Gentoo__Overlay_Overlay, required, ro, coerce );
has path => ( lazy, ro,
  isa     => Path,
  default => sub {
    my ($self) = shift;
    return $self->overlay->default_path( category => $self->name );
  },
);




















































has _packages => (
  isa => HashRef [Gentoo__Overlay_Package],
  lazy,
  builder => 1,
  ro,
  handles_via => 'Hash',
  handles     => {
    _has_package  => exists   =>,
    package_names => keys     =>,
    packages      => elements =>,
    get_package   => get      =>,
  },
);









sub _build__packages {
  my ($self) = shift;
  require Gentoo::Overlay::Package;

  my $it = $self->path->iterator();
  my %out;
  while ( defined( my $entry = $it->() ) ) {
    my $package = $entry->basename;
    next if Gentoo::Overlay::Package->is_blacklisted($package);
    my $p = Gentoo::Overlay::Package->new(
      name     => $package,
      category => $self,
    );
    next unless $p->exists;
    $out{$package} = $p;
  }
  return \%out;
}




























class_has _scan_blacklist => (
  isa => HashRef [Str],
  ro,
  lazy,
  default => sub {
    return { map { $_ => 1 } qw( metadata profiles distfiles eclass licenses packages scripts . .. ) };
  },
);

sub _scan_blacklisted {
  my ( $self, $what ) = @_;
  return exists $self->_scan_blacklist->{$what};
}









## no critic ( ProhibitBuiltinHomonyms )
sub exists {
  my $self = shift;
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
  return $self->name . '/::' . $self->overlay->name;
}











































sub iterate {
  my ( $self, $what, $callback ) = @_;    ## no critic (Variables::ProhibitUnusedVarsStricter)
  my %method_map = (
    packages => _iterate_packages =>,
    ebuilds  => _iterate_ebuilds  =>,
  );
  if ( exists $method_map{$what} ) {
    goto $self->can( $method_map{$what} );
  }
  return exception(
    ident   => 'bad iteration method',
    message => 'The iteration method %{what_method}s is not a known way to iterate.',
    payload => { what_method => $what, },
  );
}











# packages = { /packages }
sub _iterate_packages {
  my ( $self, undef, $callback ) = @_;
  my %packages     = $self->packages();
  my $num_packages = scalar keys %packages;
  my $last_package = $num_packages - 1;
  my $offset       = 0;
  for my $pname ( sort keys %packages ) {
    local $_ = $packages{$pname};
    $self->$callback(
      {
        package_name => $pname,
        package      => $packages{$pname},
        num_packages => $num_packages,
        last_package => $last_package,
        package_num  => $offset,
      }
    );
    $offset++;
  }
  return;

}











# ebuilds = { /packages/ebuilds }
sub _iterate_ebuilds {
  my ( $self, undef, $callback ) = @_;
  my $real_callback = sub {

    my (%pconfig) = %{ $_[1] };
    my $inner_callback = sub {
      my %econfig = %{ $_[1] };
      $self->$callback( { ( %pconfig, %econfig ) } );
    };
    $pconfig{package}->_iterate_ebuilds( 'ebuilds' => $inner_callback );
  };
  $self->_iterate_packages( packages => $real_callback );
  return;

}
no Moo;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Gentoo::Overlay::Category - A singular category in a repository;

=head1 VERSION

version 2.001002

=head1 SYNOPSIS

Still limited functionality, more to come.

    my $category = ::Overlay::Category->new(
        name => 'dev-perl',
        overlay => '/usr/portage' ,
    );

    my $category = ::Overlay::Category->new(
        name => 'dev-perl',
        overlay => $overlay_object ,
    );

    $category->exists()  # is the category there, is it a directory?

    $category->pretty_name()  #  dev-perl/::gentoo

    $category->path()  # /usr/portage/dev-perl

    ::Overlay::Category->is_blacklisted('..') # is '..' a blacklisted category

=head1 METHODS

=head2 exists

Does the category exist, and is it a directory?

    $category->exists();

=head2 is_blacklisted

Does the category name appear on a blacklist meaning auto-scan should ignore this?

    ::Category->is_blacklisted('..') # true

    ::Category->is_blacklisted('metadata') # true

=head2 pretty_name

A pretty form of the name.

    $category->pretty_name  # dev-perl/::gentoo

=head2 iterate

  $overlay->iterate( $what, sub {
      my ( $context_information ) = shift;

  } );

The iterate method provides a handy way to do walking across the whole tree stopping at each of a given type.

=over 4

=item * C<$what = 'packages'>

  $overlay->iterate( packages => sub {
      my ( $self, $c ) = shift;
      # $c->{package_name}  # String
      # $c->{package}       # Package Object
      # $c->{num_packages}  # How many packages are there to iterate
      # $c->{last_package}  # Index ID of the last package.
      # $c->{package_num}   # Index ID of the current package.
  } );

=item * C<$what = 'ebuilds'>

  $overlay->iterate( ebuilds => sub {
      my ( $self, $c ) = shift;
      # $c->{package_name}  # String
      # $c->{package}       # Package Object
      # $c->{num_packages}  # How many packages are there to iterate
      # $c->{last_package}  # Index ID of the last package.
      # $c->{package_num}   # Index ID of the current package.

      # $c->{ebuild_name}   # String
      # See ::Ebuild for the rest of the fields provided by the ebuild Iterator.
      # Very similar though.
  } );

=back

=head1 ATTRIBUTES

=head2 name

The classes short name

    isa => Gentoo__Overlay_CategoryName, required, ro

L<< C<CategoryName>|Gentoo::Overlay::Types/Gentoo__Overlay_CategoryName >>

=head2 overlay

The overlay it is in.

    isa => Gentoo__Overlay_Overlay, required, coerce

L<Gentoo::Overlay::Types/Gentoo__Overlay_Overlay>

=head2 path

The full path to the category

    isa => Dir, lazy, ro

L<MooseX::Types::Path::Tiny/Dir>

=head1 ATTRIBUTE ACCESSORS

=head2 package_names

    for( $category->package_names ){
        print $_;
    }

L</_packages>

=head2 packages

    my %packages = $category->packages;

L</_packages>

=head2 get_package

    my $package = $category->get_package('Moose');

L</_packages>

=head1 PRIVATE ATTRIBUTES

=head2 _packages

    isa => HashRef[ Gentoo__Overlay_Package ], lazy_build, ro

    accessors => _has_package , package_names,
                 packages, get_package

L</_has_package>

L</package_names>

L</packages>

L</get_package>

=head1 PRIVATE ATTRIBUTE ACCESSORS

=head2 _has_package

    $category->_has_package('Moose');

L</_packages>

=head1 PRIVATE CLASS ATTRIBUTES

=head2 _scan_blacklist

Class-Wide list of blacklisted directory names.

    isa => HashRef[ Str ], ro, lazy

    accessors => _scan_blacklisted

L</_scan_blacklisted>

L<< C<MooseX::Types::Moose>|MooseX::Types::Moose >>

=head1 PRIVATE CLASS ATTRIBUTE ACCESSORS

=head2 _scan_blacklisted

is C<$arg> blacklisted in the Class Wide Blacklist?

    ::Category->_scan_blacklisted( $arg )
       ->
    exists ::Category->_scan_blacklist->{$arg}

L</_scan_blacklist>

=head1 PRIVATE METHODS

=head2 _build__packages

Generates the package Hash-Table, by scanning the category directory.

L</_packages>

=head2 _iterate_packages

  $object->_iterate_packages( ignored_value => sub {  } );

Handles dispatch call for

  $object->iterate( packages => sub { } );

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
