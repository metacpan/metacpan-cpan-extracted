package Math::Int128::die_on_overflow;

use strict;
use warnings;

our $VERSION = '0.22';

sub import {
    require Math::Int128;
    Math::Int128::_set_may_die_on_overflow(1);
    $^H{'Math::Int128::die_on_overflow'} = 1
}


sub unimport {
    undef $^H{'Math::Int128::die_on_overflow'}
}

1;

__END__

=encoding UTF-8

=head1 NAME

Math::Int128::die_on_overflow - catch overflows when using Math::Int128

=head1 SYNOPSIS

  use Math::Int128 qw(uint128);
  use Math::Int128::die_on_overflow;

  my $number = uint128(2**64);
  say($number * $number); # overflow error!


=head1 SEE ALSO

L<Math::Int128>.

=head1 COPYRIGHT AND LICENSE

Copyright E<copy> 2011, 2013 by Salvador Fandiño (sfandino@yahoo.com)

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
