package Devel::AssertOS::Linux::RHEL;

use Devel::CheckOS;
use strict;
use warnings;

use Devel::CheckOS::Helpers::LinuxOSrelease 'distributor_id';

no warnings 'redefine';

our $VERSION = '1.0';

sub os_is {
    my $id = distributor_id;

    Devel::CheckOS::os_is('Linux') &&
    defined($id) &&
    $id eq 'rhel';
}

sub expn { "The Linux distribution is some version of RHEL (Redhat Enterprise)" }

Devel::CheckOS::die_unsupported() unless ( os_is() );

=head1 COPYRIGHT and LICENCE

Copyright 2024 David Cantrell

This software is free-as-in-speech software, and may be used, distributed, and modified under the terms of either the GNU General Public Licence version 2 or the Artistic Licence. It's up to you which one you use. The full text of the licences can be found in the files GPL2.txt and ARTISTIC.txt, respectively.

=cut

1;


