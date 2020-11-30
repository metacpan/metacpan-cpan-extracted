## MatrixDecomposition.pm --- matrix decompositions and its applications.

# Copyright (C) 2010 Ralph Schleicher.  All rights reserved.

# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

## Code:

package Math::MatrixDecomposition;

use strict;
use warnings;
use Carp;

BEGIN
{
  our $VERSION = '1.04';
}

my %sym =
  (
   'lu'  => 'LU',
   'eig' => 'Eigen',
  );

my %mod =
  (
   ':LU'    => 'LU',
   ':Eigen' => 'Eigen',
  );

my %tag =
  (
   ':all' => [keys (%sym)],
   ':ALL' => [values (%mod)],
  );

sub import
{
  my $from = shift;
  my $to = caller (0);

  # Resolve aliases.
  my @list = ();

  for my $item (@_)
    {
      if ($item =~ m/\A:/)
	{
	  croak ("Unknown tag '$item'")
	    unless $mod{$item} || $tag{$item};

	  push (@list, $mod{$item} || @{ $tag{$item} });
	}
      else
	{
	  push (@list, $item);
	}
    }

  # Resolve symbols.
  my %seen = ();

  for my $item (@list)
    {
      if ($from = $sym{$item})
	{
	  $seen{$from} //= {};
	  ++$seen{$from}{$item};
	}
      elsif ($item =~ m/\A[A-Z]/)
	{
	  $seen{$item} //= {};
	}
      else
	{
	  croak ("Unknown symbol '$item'");
	}
    }

  # Load modules and export symbols.
  no strict 'refs';

  for my $mod (keys (%seen))
    {
      $from = __PACKAGE__ . "::" . $mod;
      eval ("require $from;");
      croak ($@) if $@;

      for my $sym (keys (%{ $seen{$mod} }))
	{
	  *{"$to\::$sym"} = \&{"$from\::$sym"};
	}
    }
}

1;

__END__

=head1 NAME

Math::MatrixDecomposition - matrix decompositions and its applications


=head1 SYNOPSIS

    use Math::MatrixDecomposition qw(lu eig);


=head1 DESCRIPTION

The design goals of this package are listed in the following table.

=over

=item *

Pure Perl code, that means no external dependencies except core modules
and other pure Perl modules.

=item *

Native data types for operands, that means no dedicated classes for
vectors and matrices.

=back

The import list of the C<use> statement is a wrapper for loading
selected modules and procedures into your program.  Capitalized tag
names are interpreted as module names, that means the statement

    use Math::MatrixDecomposition qw(:LU :Eigen);

is equivalent to

    use Math::MatrixDecomposition::LU;
    use Math::MatrixDecomposition::Eigen;

Bare words are interpreted as subroutines, that means the statement

    use Math::MatrixDecomposition qw(lu eig);

is equivalent to

    use Math::MatrixDecomposition::LU qw(lu);
    use Math::MatrixDecomposition::Eigen qw(eig);


=head1 SEE ALSO

Math::MatrixDecomposition::L<LU|Math::MatrixDecomposition::LU>,
Math::MatrixDecomposition::L<Eigen|Math::MatrixDecomposition::Eigen>


=head2 External Links

=over

=item *

Wikipedia, L<http://en.wikipedia.org/wiki/Matrix_decomposition>

=back


=head1 AUTHOR

Ralph Schleicher <ralph@cpan.org>

=cut

## MatrixDecomposition.pm ends here
