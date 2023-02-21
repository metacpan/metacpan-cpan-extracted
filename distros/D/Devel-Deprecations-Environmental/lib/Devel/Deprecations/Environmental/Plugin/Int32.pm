package Devel::Deprecations::Environmental::Plugin::Int32;

use strict;
use warnings;

use base 'Devel::Deprecations::Environmental';

use Devel::CheckOS qw(os_is);

our $VERSION = '1.001';

=head1 NAME

Devel::Deprecations::Environmental::Plugin::Int32

=head1 DESCRIPTION

A plugin for L<Devel::Deprecations::Environmental> to emit warnings when perl has 32-bit integers

=head1 SYNOPSIS

    use Devel::Deprecations::Environmental qw(Int32);

=head1 AUTHOR, LICENCE and COPYRIGHT

Copyright 2023 David Cantrell E<lt>F<david@cantrell.org.uk>E<gt>

This software is free-as-in-speech software, and may be used, distributed, and
modified under the terms of either the GNU General Public Licence version 2 or
the Artistic Licence. It's up to you which one you use. The full text of the
licences can be found in the files GPL2.txt and ARTISTIC.txt, respectively.

=head1 CONSPIRACY

This module is also free-as-in-mason software.

=cut

sub reason { "32 bit integers" }
sub is_deprecated { os_is('HWCapabilities::Int32') }

1;
