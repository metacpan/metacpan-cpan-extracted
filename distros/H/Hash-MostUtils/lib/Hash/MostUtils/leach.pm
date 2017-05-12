use strict;
use warnings;
package
	Hash::MostUtils::leach; # don't index me, please

use provide (
  if    => ge => 5.013 => 'Hash::MostUtils::leach::v5_13',
  else                 => 'Hash::MostUtils::leach::v5_10',
);

use Scalar::Util qw(refaddr);

{
  my %end;
  my %size;

  # n-ary each for lists
  sub _n_each {
    my $n = shift;
    my $data = shift;

    my $ident = refaddr($data);

    # does it look hashlike? cast to an array ref for indexing.
    $data = [ %$data ] if
      do { local $@; eval { scalar keys %$data; 1 } };

    # did the size change? if so, zero out our %end
    if (exists $size{$ident}) {
      if ($size{$ident} != $#{$data}) {
	$size{$ident} = $#{$data};
	$end{$ident} = 0;
      }
    } else {
      $size{$ident} = $#{$data};
    }

    if ($#{$data} < ($end{$ident} || 0)) {
      delete $end{$ident};
      return ();
    }

    $end{$ident} += $n;
    return @{$data}[$end{$ident} - $n .. $end{$ident} - 1];
  }
}

1;

__END__

=head1 NAME

Hash::MostUtils::leach - base implementation of n_each without the Perl-version-specific bits

=head1 DESCRIPTION

This module is included as part of the L<Hash::MostUtils> library.

Hash::MostUtils exports two functions which this module provides: C<leach> and C<n_each>. See
the documentation for those functions in Hash::MostUtils for a more thorough treatment of how
to use them.

C<leach> (and C<n_each>) both provide a C<splice>-like interface for operating on an array. In
Perl versions 5.12 and lower, the prototype for C<splice> is:

    sub splice (\@;$$@) { ... }

However, in Perl versions 5.13 and above, the prototype for C<splice> is:

    sub splice (+;$$@) { ... }

By extension, the functions C<leach> and C<n_each> need to have a similar version-specific
prototype on them.

This class serves as an interface to choose between the two prototypes based on your version of Perl.

=head1 COPYRIGHT AND LICENSE

    (c) 2013 by Belden Lyman

This library is free software: you may redistribute it and/or modify it under the same terms as Perl
itself; either Perl version 5.8.8 or, at your option, any later version of Perl 5 you may have
available.
