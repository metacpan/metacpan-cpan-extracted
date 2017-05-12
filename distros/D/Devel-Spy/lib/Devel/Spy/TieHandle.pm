package Devel::Spy::TieHandle;
use strict;
use warnings;

sub UNTIE {}
sub DESTROY {}

1;

__END__

=head1 NAME

Devel::Spy::TieHandle - Tied logging wrapper for handles

=head1 SYNOPSIS

  tie *FH, 'Devel::Spy::TieHandle', \ $fh, $logging_function
    or croak;

  # Passed operation through to $fh and tattled about the
  # operation to $logging_function.
  print { *FH } 42;

=head1 CAVEATS

This has not been implemented. Feel free to add more and send me
patches. I'll also grant you permission to upload into the Devel::Spy
namespace if you're a clueful developer.

=head1 SEE ALSO

L<Devel::Spy>, L<Devel::Spy::_obj>, L<Devel::Spy::Util>,
L<Devel::Spy::TieHash>, L<Devel::Spy::TieArray>,
L<Devel::Spy::TieScalar>.
