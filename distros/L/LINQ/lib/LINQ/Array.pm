use 5.006;
use strict;
use warnings;

if ( $] < 5.010000 ) {
	require UNIVERSAL::DOES;
}

package LINQ::Array;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.001';

use Role::Tiny::With ();

Role::Tiny::With::with( qw( LINQ::Collection ) );

sub new {
	my $class = shift;
	bless [ @{ $_[0] } ], $class;
}

sub count {
	my $self = shift;
	return $self->where( @_ )->count if @_;
	scalar @$self;
}

sub to_list {
	my $self = shift;
	@$self;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

LINQ::Array - a LINQ collection with an arrayref backend

=head1 SYNOPSIS

  use LINQ qw( LINQ );
  use LINQ::Array;
  
  my $linq  = LINQ( [ 1 .. 3 ] );
  
  # Same:
  my $linq  = 'LINQ::Array'->new( [ 1 .. 3 ] );

=head1 METHODS

LINQ::Array supports all the methods defined in L<LINQ::Collection>.

=begin trustme

=item new

=item count

=item to_list

=end trustme

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=LINQ>.

=head1 SEE ALSO

L<LINQ>, L<LINQ::Collection>.

L<https://en.wikipedia.org/wiki/Language_Integrated_Query>

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2021 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
