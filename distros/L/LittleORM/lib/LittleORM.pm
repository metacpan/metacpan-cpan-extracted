#!/usr/bin/perl

use strict;


package LittleORM::Meta::Role;

use Moose::Role;

has 'found_orm'	=> ( is => 'rw', isa => 'Bool', default => 0 );

no Moose::Role;

package LittleORM;

our $VERSION = '0.25';

=head1 NAME

LittleORM - ORM for Perl with Moose.

=head1 VERSION

Version 0.25

=cut

=head1 SYNOPSIS

Please refer to L<LittleORM::Tutorial> for thorough description of LittleORM.

=cut

=head1 AUTHOR

Eugene Kuzin, C<< <eugenek at 45-98.org> >>, JID: C<< <gnudist at jabber.ru> >>
with significant contributions by
Kain Winterheart, C<< <kain.winterheart at gmail.com> >>


=head1 BUGS

Please report any bugs or feature requests to C<bug-littleorm at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=LittleORM>.  I will
be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc LittleORM


You can also look for information at:

=over 4

=item * Project home:

L<https://github.com/gnudist/littleorm>

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=LittleORM>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/LittleORM>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/LittleORM>

=item * Search CPAN

L<http://search.cpan.org/dist/LittleORM/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Eugene Kuzin.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut


use Moose;
use Moose::Exporter;
use Moose::Util::MetaRole;

use Carp::Assert 'assert';
use Scalar::Util ();

Moose::Exporter -> setup_import_methods( with_meta => [ 'has_field' ],
					 also      => 'Moose' );
sub init_meta
{
	my ( $class, %args ) = @_;
	
	Moose -> init_meta( %args );
	
	return &Moose::Util::MetaRole::apply_metaroles(
		for             => $args{ 'for_class' },
		class_metaroles => {
			class => [ 'LittleORM::Meta::Role' ]
		}
	    );
}

sub has_field
{
	my ( $meta, $name, %args ) = @_;
	
	unless( $meta -> found_orm() )
	{
		my @isa = $meta -> linearized_isa();
		my $ok  = 0;
		
		foreach my $class ( @isa )
		{
			if( $class -> isa( 'LittleORM::Model' ) )
			{
				$meta -> found_orm( $ok = 1 );
				
				last;
			}
		}
		
		assert( $ok, sprintf( 'Class "%s" must extend LittleORM::Model', $isa[ 0 ] ) );
	}

	return &__has_field_no_check( $meta, $name, %args );
}
	
sub __has_field_no_check
{
	my ( $meta, $name, %args ) = @_;

	if( ref( $args{ 'traits' } ) eq 'ARRAY' )
	{
		push @{ $args{ 'traits' } }, 'LittleORM::Meta::Trait';
	} else
	{
		$args{ 'traits' } = [ 'LittleORM::Meta::Trait' ];
	}
	
	unless( ref( $args{ 'description' } ) eq 'HASH' )
	{
		$args{ 'description' } = {};
	}

	my $attr = undef;

	unless( $args{ 'description' } -> { 'ignore' } )
	{
		$args{ 'is' }   = 'rw';
		$args{ 'lazy' } = 1;

		foreach my $key ( 'builder', 'default' )
		{
			assert( not( exists $args{ $key } ), sprintf( 'There is a problem with attribute "%s": you should not use "%s" in LittleORM attribute. Consider using "description => { coerce_from => sub{ ... } }" instead, or just add "description => { ignore => 1 }".', $name, $key ) );
		}

		$args{ 'default' } = sub 
		{
			my $self = shift;

			if( $attr -> isa( 'Moose::Meta::Role::Attribute' ) )
			{
				$attr = $self -> meta() -> find_attribute_by_name( $name );
			}

			return $self -> __lazy_build_value( $attr );
		};
		$args{ 'description' } -> { '__orm_initialized_attr_has_field_' } = 'yes';
	}

	$attr = $meta -> add_attribute( $name, %args );

	Scalar::Util::weaken( $attr );

	return 1;
}

no Moose::Util::MetaRole;
no Moose::Exporter;
no Moose;

-1;

