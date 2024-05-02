package Devel::AssertOS::OSFeatures::Systemd;

our $VERSION = '1.0';

use Devel::CheckOS;
use strict;
use warnings;
no warnings 'redefine';

sub os_is { -d '/run/systemd/system' }
Devel::CheckOS::die_unsupported() unless(os_is());

sub expn {
    "The operating system uses systemd as init instead of something more sensible"
}

=head1 NAME

Devel::AssertOS::OSFeatures::Systemd - check whether
the OS we're running on uses systemd instead of a sensible init.

=head1 SYNOPSIS

See L<Devel::CheckOS> and L<Devel::AssertOS>

=head1 COPYRIGHT and LICENCE

Copyright 2024 David Cantrell

This software is free-as-in-speech software, and may be used, distributed, and modified under the terms of either the GNU General Public Licence version 2 or the Artistic Licence. It's up to you which one you use. The full text of the licences can be found in the files GPL2.txt and ARTISTIC.txt, respectively.

=cut

1;
