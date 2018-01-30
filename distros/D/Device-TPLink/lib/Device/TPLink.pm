package Device::TPLink;

use 5.008003;
use strict;
use warnings;

=head1 NAME

Device::TPLink - Access TP-Link Device APIs from Perl

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';


=head1 SYNOPSIS

This module does nothing by itself. Use the other modules in the package to control your TP-Link device either directly over TCP or using the Kasa cloud service.

=head1 SUBROUTINES/METHODS

None. Check out the "See Also" section for the modules in this package that you should be using instead of this one.

=head1 AUTHOR

Verlin Henderson, C<< <verlin at gmail.com> >>

=head1 BUGS / SUPPORT

To report any bugs or feature requests, please use the github issue tracker: L<https://github.com/verlin/Device-TPLink/issues>

=head1 ACKNOWLEDGEMENTS

I am not associated with TP-Link in any way, except as a customer. The information on the TP-Link protocol came from several sources, including:

=over 4

=item * IT Nerd Space

L<http://itnerd.space/2017/01/22/how-to-control-your-tp-link-hs100-smartplug-from-internet/>

Original blog post that I found that gave me the idea to write a Perl module.

=item * softScheck's "tplink-smartplug" project on GitHub

L<https://github.com/softScheck/tplink-smartplug>

Great documentation on the TP-Link smart plug devices, including a more-or-less complete documentation of the JSON API.

=item * GadgetReactor's "pyHS100" project on GitHub

L<https://github.com/GadgetReactor/pyHS100/>

A python library to control TP-Link gear. Their issue tracker gave me the details needed to communicate with the device directly over TCP.

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2018 Verlin Henderson.

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

1; # End of Device::TPLink
