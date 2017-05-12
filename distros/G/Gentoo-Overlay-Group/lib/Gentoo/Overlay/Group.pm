use 5.006;
use strict;
use warnings;

package Gentoo::Overlay::Group;

our $VERSION = '1.000001';

# ABSTRACT: A collection of Gentoo::Overlay objects.

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Moo qw( has );
use MooX::HandlesVia;
use MooseX::Has::Sugar qw( ro lazy );
use Types::Standard qw( HashRef Str );
use Types::Path::Tiny qw( Dir );
use namespace::clean;

use Gentoo::Overlay 2.001001;
use Gentoo::Overlay::Types qw( Gentoo__Overlay_Overlay );
use Gentoo::Overlay::Exceptions qw( exception );
use Scalar::Util qw( blessed );





























has '_overlays' => (
  ro, lazy,
  isa => HashRef [Gentoo__Overlay_Overlay],
  default     => sub { return {} },
  handles_via => 'Hash',
  handles     => {
    _has_overlay  => exists   =>,
    overlay_names => keys     =>,
    overlays      => elements =>,
    get_overlay   => get      =>,
    _set_overlay  => set      =>,
  },
);

my $_str = Str();









sub _type_print {
  return
      ref $_     ? ref $_
    : defined $_ ? 'scalar<' . $_ . '>'
    :              'scalar=undef';

}









sub add_overlay {
  my ( $self, @args ) = @_;
  if ( 1 == @args and blessed $args[0] ) {
    goto $self->can('_add_overlay_object');
  }
  if ( $_str->check( $args[0] ) ) {
    goto $self->can('_add_overlay_string_path');
  }
  return exception(
    ident   => 'bad overlay type',
    message => <<'EOF',
Unrecognised parameter types passed to add_overlay.
  Expected: \n%{signatures}s.
  Got: [%{type}s]}.
EOF
    payload => {
      signatures => ( join q{},  map { qq{    \$group->add_overlay( $_ );\n} } qw( Str Path::Tiny Gentoo::Overlay ) ),
      type       => ( join q{,}, map { _type_print } @args ),
    },
  );
}










sub iterate {
  my ( $self, $what, $callback ) = @_;    ## no critic (Variables::ProhibitUnusedVarsStricter)
  my %method_map = (
    ebuilds    => _iterate_ebuilds    =>,
    categories => _iterate_categories =>,
    packages   => _iterate_packages   =>,
    overlays   => _iterate_overlays   =>,
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







sub _iterate_ebuilds {
  my ( $self, undef, $callback ) = @_;
  my $real_callback = sub {
    my (%package_config) = %{ $_[1] };
    my $inner_callback = sub {
      my (%ebuild_config) = %{ $_[1] };
      $self->$callback( { ( %package_config, %ebuild_config ) } );
    };
    $package_config{package}->_iterate_ebuilds( ebuilds => $inner_callback );
  };
  $self->_iterate_packages( packages => $real_callback );
  return;
}







# categories = { /overlays/categories

sub _iterate_categories {
  my ( $self, undef, $callback ) = @_;
  my $real_callback = sub {
    my (%overlay_config) = %{ $_[1] };
    my $inner_callback = sub {
      my (%category_config) = %{ $_[1] };
      $self->$callback( { ( %overlay_config, %category_config ) } );
    };
    $overlay_config{overlay}->_iterate_categories( categories => $inner_callback );
  };
  $self->_iterate_overlays( overlays => $real_callback );
  return;
}







sub _iterate_packages {
  my ( $self, undef, $callback ) = @_;
  my $real_callback = sub {
    my (%category_config) = %{ $_[1] };
    my $inner_callback = sub {
      my (%package_config) = %{ $_[1] };
      $self->$callback( { ( %category_config, %package_config ) } );
    };
    $category_config{category}->_iterate_packages( packages => $inner_callback );
  };
  $self->_iterate_categories( categories => $real_callback );
  return;
}







# overlays = { /overlays }
sub _iterate_overlays {
  my ( $self, undef, $callback ) = @_;
  my %overlays     = $self->overlays;
  my $num_overlays = scalar keys %overlays;
  my $last_overlay = $num_overlays - 1;
  my $offset       = 0;
  for my $overlay_name ( sort keys %overlays ) {
    local $_ = $overlays{$overlay_name};
    $self->$callback(
      {
        overlay_name => $overlay_name,
        overlay      => $overlays{$overlay_name},
        num_overlays => $num_overlays,
        last_overlay => $last_overlay,
        overlay_num  => $offset,
      }
    );
    $offset++;
  }
  return;
}

my $_gentoo_overlay = Gentoo__Overlay_Overlay();
my $_path_class_dir = Dir();

# This would be better in M:M:TypeCoercion







sub _add_overlay_object {
  my ( $self, $overlay, @rest ) = @_;

  if ( $_gentoo_overlay->check($overlay) ) {
    goto $self->can('_add_overlay_gentoo_object');
  }
  if ( $_path_class_dir->check($overlay) ) {
    goto $self->can('_add_overlay_path_class');
  }
  return exception(
    ident   => 'bad overlay object type',
    message => <<'EOF',
Unrecognised parameter object types passed to add_overlay.
  Expected: \n%{signatures}s.
  Got: [%{type}s]}.
EOF
    payload => {
      signatures => ( join q{}, map { qq{    \$group->add_overlay( $_ );\n} } qw( Str Path::Tiny Gentoo::Overlay ) ),
      type => ( join q{,}, blessed $overlay, map { _type_print } @rest ),
    },
  );
}







sub _add_overlay_gentoo_object {
  my ( $self, $overlay, ) = @_;
  $_gentoo_overlay->assert_valid($overlay);
  if ( $self->_has_overlay( $overlay->name ) ) {
    return exception(
      ident   => 'overlay exists',
      message => 'The overlay named %{overlay_name}s is already added to this group.',
      payload => { overlay_name => $overlay->name },
    );
  }
  $self->_set_overlay( $overlay->name, $overlay );
  return;
}







sub _add_overlay_path_class {    ## no critic ( RequireArgUnpacking )
  my ( $self, $path, ) = @_;
  $_path_class_dir->assert_valid($path);
  my $go = Gentoo::Overlay->new( path => $path, );
  @_ = ( $self, $go );
  goto $self->can('_add_overlay_gentoo_object');
}







sub _add_overlay_string_path {    ## no critic ( RequireArgUnpacking )
  my ( $self, $path_str, ) = @_;
  $_str->assert_valid($path_str);
  my $path = $_path_class_dir->coerce($path_str);
  @_ = ( $self, $path );
  goto $self->can('_add_overlay_path_class');
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Gentoo::Overlay::Group - A collection of Gentoo::Overlay objects.

=head1 VERSION

version 1.000001

=head1 SYNOPSIS

This is a wrapper around L<< C<Gentoo::Overlay>|Gentoo::Overlay >> that makes it easier to perform actions on a group of overlays.

  my $group = Gentoo::Overlay::Group->new();
  $group->add_overlay('/usr/portage');
  $group->add_overlay('/usr/local/portage/');
  $group->iterate( packages => sub {
    my ( $self, $context ) = @_;
    # Traverse-Order:
    # ::gentoo
    #   category_a
    #     package_a
    #     package_b
    #   category_b
    #     package_a
    #     package_b
    # ::hentoo
    #   category_a
    #     package_a
    #     package_b
    #   category_b
    #     package_a
    #     package_b
  });

=head1 METHODS

=head2 add_overlay

  $object->add_overlay( '/path/to/overlay' );
  $object->add_overlay( Path::Tiny::path( '/path/to/overlay' ) );
  $object->add_overlay( Gentoo::Overlay->new( path => '/path/to/overlay' ) );

=head2 iterate

  $object->iterate( ebuilds => sub {


  });

=head1 ATTRIBUTE ACCESSORS

=head2 overlay_names

  my @names = $object->overlay_names

=head2 overlays

  my @overlays = $object->overlays;

=head2 get_overlay

  my $overlay = $object->get_overlay('gentoo');

=head1 PRIVATE ATTRIBUTES

=head2 _overlays

  isa => HashRef[ Gentoo__Overlay_Overlay ], ro, lazy

=head1 PRIVATE ATTRIBUTE ACCESSORS

=head2 _has_overlay

  if( $object->_has_overlay('gentoo') ){
    Carp::croak('waah');
  }

=head2 _set_overlay

  $object->_set_overlay( 'gentoo' => $overlay_object );

=head1 PRIVATE FUNCTIONS

=head2 _type_print

Lightweight flat dumper optimized for displaying user parameters in a format similar to a method signature.

  printf '[%s]', join q{,} , map { _type_print } @array

=head1 PRIVATE METHODS

=head2 _iterate_ebuilds

  $object->_iterate_ebuilds( ignored => sub { } );

=head2 _iterate_categories

  $object->_iterate_categories( ignored => sub { } );

=head2 _iterate_packages

  $object->_iterate_packages( ignored => sub { } );

=head2 _iterate_overlays

  $object->_iterate_overlays( ignored => sub { } );

=head2 _add_overlay_object

  $groupobject->_add_overlay_object( $object );

=head2 _add_overlay_gentoo_object

  $groupobject->_add_overlay_gentoo_object( $gentoo_object );

=head2 _add_overlay_path_class

  $groupobject->_add_overlay_path_class( $path_class_object );

=head2 _add_overlay_string_path

  $groupobject->_add_overlay_string_path( $path_string );

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentnl@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
