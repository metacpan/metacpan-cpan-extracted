package Digest::DJB32::PP;

use 5.006;
use strict;
use warnings;
use Exporter qw< import >;

our @EXPORT= qw< djb >;


=head1 NAME

Digest::DJB32::PP - Pure Perl version of Digest::DJB32

=head1 VERSION

Version 1.00

=cut

our $VERSION = '1.00';


=head1 SYNOPSIS

  use Digest::DJB32::PP
  
  my $hash = djb("abc123");

=head1 DESCRIPTION

Digest::DJB32:PP is a pure Perl implementation of D. J. Bernstein's hash which returns a 32-bit unsigned value for any variable-length input string.

=head1 EXPORT

Export by default C<djb> function.

=head1 FUNCTIONS

=head2 djb

Return the hash of the given argument.

B<Example:>

  my $hash = djb("abc123");

=cut

sub djb {
    my @bytes = unpack("C*", shift);
    #print STDERR "*** bytes = @bytes\n";
  	my $ValLow = 5381;
  	my $ValHight = 0;
  	
  	foreach my $i (@bytes) {
  	  $ValLow = ($ValLow << 5) + $ValLow + $i;
  	  $ValHight = ($ValHight << 5) + $ValHight + ($ValLow >> 16);
  	  $ValLow &= 0x0000ffff;
  	  $ValHight &= 0x0000ffff;
  	}
	  #$Val = ((($Val << 5) + $Val + $_) & 0x03ffffff) for @bytes
	  return $ValLow | $ValHight<<16;
}

=head1 AUTHOR

Richard THIBERT, C<< <thibs at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-digest-djb32-pp at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Digest-DJB32-PP>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Digest::DJB32::PP


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Digest-DJB32-PP>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Digest-DJB32-PP>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Digest-DJB32-PP>

=item * Search CPAN

L<http://search.cpan.org/dist/Digest-DJB32-PP/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2015 Richard THIBERT.

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

1; # End of Digest::DJB32::PP
