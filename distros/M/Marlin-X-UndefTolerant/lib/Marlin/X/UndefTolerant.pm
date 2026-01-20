use 5.008008;
use strict;
use warnings;

package Marlin::X::UndefTolerant;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.020000';

use Marlin::Util          qw( true false );
use Types::Common         qw( -types );

use Marlin -with => 'Marlin::X';

sub adjust_setup_steps {
	my $plugin = shift;
	my $steps  = shift;
	
	my $callback = __PACKAGE__ . '::setup_for_undef_tolerant';
	
	# Insert the 'setup_for_undef_tolerant' step directly
	# after 'canonicalize_attributes'. We want the attributes
	# to be in a predicatable format, but we don't want them
	# to have been used for anything yet!
	@$steps = map {
		( $_ eq 'canonicalize_attributes' )
			? ( 'canonicalize_attributes', $callback )
			: ( $_ );
	} @$steps;
};

sub setup_for_undef_tolerant {
	my $plugin = shift;
	my $marlin = shift;
	
	# Loop through attributes...
	for my $attr ( @{ $marlin->attributes } ) {
		
		# Skip attributes which have it explicitly set to true or false.
		next if exists $attr->{undef_tolerant};
		
		# Skip attributes which aren't initialized in the constructor.
		next if exists($attr->{init_arg}) && !defined($attr->{init_arg});
		
		# Skip any required attributes!
		next if $attr->{required};
		
		# Skip any attributes where undef is a legitimate value.
		my $type = $attr->{isa};
		next if $type && $type->check(undef);
		
		# If we got this far, default the attribute to be undef-tolerant.
		$attr->{undef_tolerant} = true;
	}
	
	return $marlin;
}

__PACKAGE__
__END__

=pod

=encoding utf-8

=head1 NAME

Marlin::X::UndefTolerant - Marlin extension to make your constructor forgive undefs.

=head1 SYNOPSIS

  package Local::Date {
    use Types::Common 'Int';
    use Marlin ':UndefTolerant',
      'year?'  => Int,
      'month?' => Int,
      'day?'   => Int;
  }
  
  my $xmas = Local::Date->new( day => 25, month => 12, year => undef );
  $xmas->has_day;     # true
  $xmas->has_month;   # true
  $xmas->has_year;    # false

=head1 IMPORTING THIS MODULE

The standard way to import Marlin extensions is to include them in the
list passed to C<< use Marlin >>:

  package Local::Date {
    use Types::Common 'Int';
    use Marlin ':UndefTolerant',
      'year?'  => Int,
      'month?' => Int,
      'day?'   => Int;
  }

It is possible to additionally load it with C<< use Marlin::X::UndefTolerant >>,
which won't I<do> anything, but might be useful to automatic dependency
analysis.

  package Local::Date {
    use Types::Common 'Int';
    use Marlin::X::UndefTolerant;
    use Marlin ':UndefTolerant',
      'year?'  => Int,
      'month?' => Int,
      'day?'   => Int;
  }

=head1 DESCRIPTION

Marlin has a built-in feature for making attributes undef-tolerant.
It makes the constructor treat C<< attributename => undef >> as
being equivalent to not passing the value to the constructor at all.

However, adding C<< undef_tolerant => true >> to all your attributes
is annoying, so this extension does it for you.

You can override it on a per-attribute basis by setting
C<< undef_tolerant => false >> explicitly.

It will also skip any attributes which:

=over

=item *

Are required attributes;

=item *

Have an C<undef> init_arg; or

=item *

Have an explicit type constraint defined which allows C<undef> as
a valid value (for example B<< Maybe[Str] >> or B<< Bool >>).

=back

=head1 BUGS

Please report any bugs to
L<https://github.com/tobyink/p5-marlin-x-undeftolerant/issues>.

=head1 SEE ALSO

L<Marlin>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2026 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

🐟🐟
