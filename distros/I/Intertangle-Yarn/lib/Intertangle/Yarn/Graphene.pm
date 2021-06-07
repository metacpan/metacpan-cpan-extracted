use Modern::Perl;
package Intertangle::Yarn::Graphene;
# ABSTRACT: Load the Graphene graphic types library
$Intertangle::Yarn::Graphene::VERSION = '0.002';
use Glib::Object::Introspection;
use DynaLoader;

my $_GRAPHENE_BASENAME = 'Graphene';
my $_GRAPHENE_VERSION = '1.0';
my $_GRAPHENE_PACKAGE = __PACKAGE__;

my @_FLATTEN_ARRAY_REF_RETURN_FOR = qw/
/;

use Env qw(@GI_TYPELIB_PATH @PATH);
use Alien::Graphene;

sub import {
	my @search_path = ();
	if( Alien::Graphene->install_type eq 'share' ) {
		unshift @GI_TYPELIB_PATH, Alien::Graphene->gi_typelib_path;
		@search_path = ( search_path => Alien::Graphene->gi_typelib_path );
		if( $^O eq 'MSWin32' ) {
			push @PATH, Alien::Graphene->rpath;
		} else {
			push @DynaLoader::dl_library_path, Alien::Graphene->rpath;
			my @files = DynaLoader::dl_findfile("-lgraphene-1.0");
			DynaLoader::dl_load_file($files[0]) if @files;
		}
	}

	Glib::Object::Introspection->setup(
		basename => $_GRAPHENE_BASENAME,
		version  => $_GRAPHENE_VERSION,
		package  => $_GRAPHENE_PACKAGE,
		flatten_array_ref_return_for => \@_FLATTEN_ARRAY_REF_RETURN_FOR,
		@search_path,
	);
}

sub Inline {
	return unless $_[-1] eq 'C';

	require Intertangle::API::Glib;
	require Hash::Merge;
	my $glib = Intertangle::API::Glib->Inline($_[-1]);

	my @nosearch = $^O eq 'MSWin32' ? (':nosearch') : ();
	my @search   = $^O eq 'MSWin32' ? ( ':search' ) : ();
	my $graphene = {
		CCFLAGSEX => join(" ", delete $glib->{CCFLAGSEX}, Alien::Graphene->cflags),
		LIBS => join(" ", @nosearch, delete $glib->{LIBS}, Alien::Graphene->libs, @search),
		AUTO_INCLUDE => <<C,
#include <graphene.h>
#include <graphene-gobject.h>
C
	};

	my $merge = Hash::Merge->new('RETAINMENT_PRECEDENT');
	$merge->merge( $glib, $graphene );
}

package Intertangle::Yarn::Graphene::DataPrinterRole {
	use Role::Tiny;
	use Module::Load;

	BEGIN {
		eval {
			autoload Data::Printer::Filter;
			autoload Term::ANSIColor;
			autoload Package::Stash;
		};
	}

	sub _data_printer {
		my ($self, $ddp) = @_;

		my $FIELDS = Package::Stash->new( ref $self )->get_symbol( '@FIELDS' );
		my $data = {
			map { $_ => $self->$_ } @$FIELDS
		};

		my $text = '';

		$text .= "(";
		$text .= $ddp->maybe_colorize( ref($self), 'class' );
		$text .= ") ";
		my $ml_save = $ddp->multiline(0);
		$text .= $ddp->parse($data);
		$ddp->multiline($ml_save);

		$text;
	}
}
$Intertangle::Yarn::Graphene::DataPrinterRole::VERSION = '0.002';


package Intertangle::Yarn::Graphene::Size {
	our @FIELDS = qw(width height);
	use Role::Tiny::With;
	with 'Intertangle::Yarn::Graphene::DataPrinterRole';
	use overload
		'""' => \&op_str,
		'eq' => \&op_eq,
		'==' => \&op_eq;

	sub op_str {
		"[w: @{[ $_[0]->width ]}, h: @{[ $_[0]->height ]}]"
	}

	sub op_eq {
		$_[0]->width     == (Scalar::Util::blessed $_[1] ? $_[1]->width  : $_[1]->[0] )
		&& $_[0]->height == (Scalar::Util::blessed $_[1] ? $_[1]->height : $_[1]->[1] )
	}

	sub to_HashRef {
		+{ map { $_ => $_[0]->$_ } @FIELDS };
	}
}
$Intertangle::Yarn::Graphene::Size::VERSION = '0.002';

package Intertangle::Yarn::Graphene::Point {
	our @FIELDS = qw(x y);
	use Scalar::Util;
	use Role::Tiny::With;
	with 'Intertangle::Yarn::Graphene::DataPrinterRole';
	use overload
		'""' => \&op_str,
		'eq' => \&op_eq,
		'==' => \&op_eq,
		'neg' => \&op_neg;

	sub op_str {
		"[x: @{[ $_[0]->x ]}, y: @{[ $_[0]->y ]}]";
	}

	sub op_eq {
		$_[0]->x    == (Scalar::Util::blessed $_[1] ? $_[1]->x : $_[1]->[0] )
		&& $_[0]->y == (Scalar::Util::blessed $_[1] ? $_[1]->y : $_[1]->[1] )
	}

	sub op_neg {
		Intertangle::Yarn::Graphene::Point->new(
			x => - $_[0]->x,
			y => - $_[0]->y,
		);
	}

	sub to_HashRef {
		+{ map { $_ => $_[0]->$_ } @FIELDS };
	}

	sub to_ArrayRef {
		[ map { $_[0]->$_ } @FIELDS ];
	}

	sub to_Point3D {
		my ($self) = @_;
		my $point3d = Intertangle::Yarn::Graphene::Point3D->new(
			x => $self->x,
			y => $self->y,
			z => 0,
		);
	}
}
$Intertangle::Yarn::Graphene::Point::VERSION = '0.002';

package Intertangle::Yarn::Graphene::Point3D {
	our @FIELDS = qw(x y z);
	use Scalar::Util;
	use Role::Tiny::With;
	with 'Intertangle::Yarn::Graphene::DataPrinterRole';
	use overload
		'""' => \&op_str,
		'eq' => \&op_eq,
		'==' => \&op_eq;

	sub op_str {
		"[x: @{[ $_[0]->x ]}, y: @{[ $_[0]->y ]}], y: @{[ $_[0]->z ]}";
	}

	sub op_eq {
		$_[0]->x    == (Scalar::Util::blessed $_[1] ? $_[1]->x : $_[1]->[0] )
		&& $_[0]->y == (Scalar::Util::blessed $_[1] ? $_[1]->y : $_[1]->[1] )
		&& $_[0]->z == (Scalar::Util::blessed $_[1] ? $_[1]->z : $_[1]->[1] )
	}

	sub to_HashRef {
		+{ map { $_ => $_[0]->$_ } @FIELDS };
	}
}
$Intertangle::Yarn::Graphene::Point3D::VERSION = '0.002';

package Intertangle::Yarn::Graphene::Vec2 {
	our @FIELDS = qw(x y);
	use Scalar::Util;
	use Role::Tiny::With;
	with 'Intertangle::Yarn::Graphene::DataPrinterRole';
	use overload
		'""' => \&op_str,
		'eq' => \&op_eq,
		'==' => \&op_eq,
		'neg' => \&op_neg;

	sub new {
		my ($class, %args) = @_;

		my $vec2 = Intertangle::Yarn::Graphene::Vec2->alloc();
		$vec2->init( $args{x}, $args{y} );

		$vec2;
	}

	sub x {
		$_[0]->dot( Intertangle::Yarn::Graphene::Vec2::x_axis() );
	}

	sub y {
		$_[0]->dot( Intertangle::Yarn::Graphene::Vec2::y_axis() );
	}

	sub op_str {
		"[x: @{[ $_[0]->x ]}, y: @{[ $_[0]->y ]}]";
	}

	sub op_eq {
		$_[0]->x    == (Scalar::Util::blessed $_[1] ? $_[1]->x : $_[1]->[0] )
		&& $_[0]->y == (Scalar::Util::blessed $_[1] ? $_[1]->y : $_[1]->[1] )
	}

	sub op_neg {
		$_[0]->negate;
	}

	sub to_HashRef {
		+{ map { $_ => $_[0]->$_ } @FIELDS };
	}

	sub to_Vec3 {
		my ($self) = @_;
		my $point3d = Intertangle::Yarn::Graphene::Vec3->new(
			x => $self->x,
			y => $self->y,
			z => 0,
		);
	}
}
$Intertangle::Yarn::Graphene::Vec2::VERSION = '0.002';

package Intertangle::Yarn::Graphene::Vec3 {
	our @FIELDS = qw(x y z);
	use Scalar::Util;
	use Role::Tiny::With;
	with 'Intertangle::Yarn::Graphene::DataPrinterRole';
	use overload
		'""' => \&op_str,
		'eq' => \&op_eq,
		'==' => \&op_eq;

	sub new {
		my ($class, %args) = @_;

		my $vec3 = Intertangle::Yarn::Graphene::Vec3->alloc();
		$vec3->init( $args{x}, $args{y}, $args{z} );

		$vec3;
	}

	sub x {
		$_[0]->dot( Intertangle::Yarn::Graphene::Vec3::x_axis() );
	}

	sub y {
		$_[0]->dot( Intertangle::Yarn::Graphene::Vec3::y_axis() );
	}

	sub z {
		$_[0]->dot( Intertangle::Yarn::Graphene::Vec3::z_axis() );
	}

	sub op_str {
		"[x: @{[ $_[0]->x ]}, y: @{[ $_[0]->y ]}, z: @{[ $_[0]->z ]}]";
	}

	sub op_eq {
		$_[0]->x    == (Scalar::Util::blessed $_[1] ? $_[1]->x : $_[1]->[0] )
		&& $_[0]->y == (Scalar::Util::blessed $_[1] ? $_[1]->y : $_[1]->[1] )
		&& $_[0]->z == (Scalar::Util::blessed $_[1] ? $_[1]->z : $_[1]->[2] )
	}

	sub to_HashRef {
		+{ map { $_ => $_[0]->$_ } @FIELDS };
	}
}
$Intertangle::Yarn::Graphene::Vec3::VERSION = '0.002';

package Intertangle::Yarn::Graphene::Rect {
	our @FIELDS = qw(origin size);
	use Role::Tiny::With;
	with 'Intertangle::Yarn::Graphene::DataPrinterRole';

	sub new {
		my ($class, %args) = @_;

		my $rect = Intertangle::Yarn::Graphene::Rect::alloc();
		$rect->init(
			$args{origin}->x, $args{origin}->y,
			$args{size}->width, $args{size}->height,
		);

		$rect;
	}
}
$Intertangle::Yarn::Graphene::Rect::VERSION = '0.002';

package Intertangle::Yarn::Graphene::Matrix {
	use Module::Load;
	use overload
		'""' => \&op_str,
		'*'  => \&op_transform,
		'x'  => \&op_matmult;

	sub new_from_arrayref {
		my ($class, $data) = @_;
		my $obj = $class->new;
		$obj->init_from_arrayref( $data );

		$obj;
	}

	sub new_from_float {
		my ($class, $data) = @_;
		my $obj = $class->new;
		$obj->init_from_float( $data );

		$obj;
	}

	sub init_from_arrayref {
		my ($class, $data) = @_;

		unless(
			@$data == 4
				&& @{ $data->[0] }  == 4
				&& @{ $data->[1] }  == 4
				&& @{ $data->[2] }  == 4
				&& @{ $data->[3] }  == 4
		) {
			die "Matrix data must be a 4x4 ArrayRef";
		}

		$class->init_from_float(
			[
				@{ $data->[0] },
				@{ $data->[1] },
				@{ $data->[2] },
				@{ $data->[3] },
			]
		);
	}

	sub to_ArrayRef {
		my ($self) = @_;
		my $data = [
			map {
				my $row = $self->get_row($_);
				[ $row->get_x, $row->get_y, $row->get_z, $row->get_w ]
			} 0..3
		];

		$data;
	}

	sub _data_printer {
		my ($self, $ddp) = @_;

		BEGIN {
			eval {
				autoload Data::Printer::Filter;
				autoload Term::ANSIColor;
			};
		}

		my $text = '';

		$text .= "(";
		$text .= $ddp->maybe_colorize( ref($self), 'class' );
		$text .= ") ";
		my $ml_save = $ddp->multiline(0);
		$text .= $ddp->parse($self->to_ArrayRef);
		$ddp->multiline($ml_save);

		$text;
	}

	sub op_str {
		my $row_text = sub { "@{[ $_[0]->get_x ]} @{[ $_[0]->get_y ]} @{[ $_[0]->get_z ]} @{[ $_[0]->get_w ]}" };
		my $text = "";
		$text .= "[\n";
		$text .= " "x4 . $row_text->( $_[0]->get_row(0) ) . "\n";
		$text .= " "x4 . $row_text->( $_[0]->get_row(1) ) . "\n";
		$text .= " "x4 . $row_text->( $_[0]->get_row(2) ) . "\n";
		$text .= " "x4 . $row_text->( $_[0]->get_row(3) ) . "\n";
		$text .= "]\n";
	}

	sub transform_point {
		my ($self, $point ) = @_;

		my $point3d = $point->to_Point3D;
		my $t_point3d = $self->transform_point3d( $point3d );

		return Intertangle::Yarn::Graphene::Point->new(
			x => $t_point3d->x,
			y => $t_point3d->y,
		);
	};

	sub transform {
		my ($matrix, $other) = @_;

		my $result;

		if(      $other->isa('Intertangle::Yarn::Graphene::Vec4') )     { $result = $matrix->transform_vec4( $other )
		} elsif( $other->isa('Intertangle::Yarn::Graphene::Vec3') )     { $result = $matrix->transform_vec3( $other )
		} elsif( $other->isa('Intertangle::Yarn::Graphene::Point') )    { $result = $matrix->transform_point( $other )
		} elsif( $other->isa('Intertangle::Yarn::Graphene::Point3D') )  { $result = $matrix->transform_point3d( $other )
		} elsif( $other->isa('Intertangle::Yarn::Graphene::Rect') )     { $result = $matrix->transform_rect( $other )
		} elsif( $other->isa('Intertangle::Yarn::Graphene::Bounds') )   { $result = $matrix->transform_bounds( $other )
		} elsif( $other->isa('Intertangle::Yarn::Graphene::Box') )      { $result = $matrix->transform_box( $other )
		} elsif( $other->isa('Intertangle::Yarn::Graphene::Sphere') )   { $result = $matrix->transform_sphere( $other )
		} else {
			die "Unknown type for transformation: @{[ ref $other ]}";
		}


		$result;
	}

	sub op_transform {
		$_[0]->transform( $_[1] );
	}

	sub op_matmult {
		$_[0]->multiply( $_[1] );
	}
}
$Intertangle::Yarn::Graphene::Matrix::VERSION = '0.002';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Intertangle::Yarn::Graphene - Load the Graphene graphic types library

=head1 VERSION

version 0.002

=head1 METHODS

=head2 Inline

  use Inline C with => qw(Intertangle::Yarn::Graphene);

Returns the flags needed to configure L<Inline::C> to use with
C<graphene-gobject-1.0>.

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
