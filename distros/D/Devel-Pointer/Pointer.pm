package Devel::Pointer;

use 5.006;
use strict;
use warnings;

require Exporter;
require DynaLoader;

our @ISA = qw(Exporter DynaLoader);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

our @EXPORT = qw(
	    address_of
        deref
        unsmash_sv
        unsmash_av
        unsmash_hv
        unsmash_cv
);
our $VERSION = '1.00';

bootstrap Devel::Pointer $VERSION;

# Preloaded methods go here.

1;
__END__

=head1 NAME

Devel::Pointer - Fiddle around with pointers

=head1 SYNOPSIS

  use Devel::Pointer;
  $a = address_of($b);   # a = &b;
  $b = deref($a);        # b = *a;

  $a = unsmash_sv(0+$scalar_ref);
  @a = unsmash_av(0+$array_ref);
  %a = unsmash_hv(0+$hash_ref);
  &a = unsmash_cv(0+$code_ref); 
  # OK, you can't do that, but you get the idea

  $c = deref(-1);        # *(-1), and the resulting segfault.

=head1 DESCRIPTION

The primary purpose of this is to turn a smashed reference
address back into a value. Once a reference is treated as
a numeric value, you can't dereference it normally; although
with this module, you can.

Be careful, though, to avoid dereferencing things that don't
want to be dereferenced.

=head2 EXPORT

All of the above

=head1 AUTHOR

Simon Cozens, C<simon@cpan.org>

=head1 SEE ALSO

L<Devel::Peek>, L<perlref>, L<B::Generate> 

=cut
