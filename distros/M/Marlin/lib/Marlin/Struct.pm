use 5.008008;
use strict;
use warnings;
use utf8;

package Marlin::Struct;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.007001';

use Marlin ();

my $uniq_id = 0;

sub import {
	my $me = shift;
	my $caller = caller;
	
	my %defs;
	
	while ( @_ ) {
		my ( $name, $definition ) = splice @_, 0, 2;
		my $class_name = sprintf '%s::__ANON__::_%06d', $me, ++$uniq_id;
		
		my $marlin = Marlin->new(
			'-caller' => \$caller,
			'-this'   => \$class_name,
			@$definition,
		);
		$marlin->{_caller} = $caller;
		$defs{$name} = $marlin;
		@{ $marlin->parents } = map {
			$defs{$_->[0]} ? [ $defs{$_->[0]}->this ] : $_
		} @{ $marlin->parents };
		$Marlin::META{$marlin->this} = $marlin;
		$marlin->do_setup;
		
		my $type = $marlin->make_type_constraint($name);
		my @exportables = @{ $type->exportables };
		for my $e ( @exportables ) {
			Eval::TypeTiny::set_subname( $me . '::' . $e->{name}, $e->{code} );
			if ( Marlin::_HAS_NATIVE_LEXICAL_SUB ) {
				no warnings ( "$]" >= 5.037002 ? 'experimental::builtin' : () );
				builtin::export_lexically( $e->{name}, $e->{code} );
			}
			elsif ( Marlin::_HAS_MODULE_LEXICAL_SUB ) {
				'Lexical::Sub'->import( $e->{name}, $e->{code} );
			}
			else {
				no strict 'refs';
				*{ $caller . '::' . $e->{name} } = $e->{code};
			}
		}
	}
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Marlin::Struct - quickly create struct-like classes

=head1 SYNOPSIS

  use v5.20.0;
  use Types::Common 'Num';
  
  use Marlin::Struct
    Point    => [ 'x!' => Num, 'y!' => Num ],
    Point3D  => [ 'z!' => Num, -parent => \'Point' ];
  
  
  my $point   = Point->new( x => 1, y => 2 );
  my $point3d = Point3D[ 1, 2, 3 ];
  
  is_Point( $point3d ) or die;
  assert_Point( $point3d );
  
  use Marlin::Struct
    Rectangle => [ 'corner1!' => Point, 'corner2! => Point ]; 

=head1 DESCRIPTION

This module quickly creates "anonymous-like" classes and gives you a lexical
function to construct instances.

=head1 BUGS

Please report any bugs to
L<https://github.com/tobyink/p5-marlin/issues>.

=head1 SEE ALSO

L<Marlin>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2025 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
