package Devel::Deprecations::Environmental::Plugin::OldPerl;

use strict;
use warnings;

use base 'Devel::Deprecations::Environmental';

use Config;

our $VERSION = '1.000';

=head1 NAME

Devel::Deprecations::Environmental::Plugin::OldPerl

=head1 DESCRIPTION

A plugin for L<Devel::Deprecations::Environmental> to emit warnings when perl is too old

=head1 SYNOPSIS

If you want to say that perl 5.14.0 is the earliest that you will support:

    use Devel::Deprecations::Environmental OldPerl => { older_than '5.14.0' }

=head1 AUTHOR, LICENCE and COPYRIGHT

Copyright 2022 David Cantrell E<lt>F<david@cantrell.org.uk>E<gt>

This software is free-as-in-speech software, and may be used, distributed, and
modified under the terms of either the GNU General Public Licence version 2 or
the Artistic Licence. It's up to you which one you use. The full text of the
licences can be found in the files GPL2.txt and ARTISTIC.txt, respectively.

=head1 CONSPIRACY

This module is also free-as-in-mason software.

=cut

sub reason { sprintf("Perl too old (got %s, need %s)", $Config{version}, $_[-1]->{older_than}) }

sub is_deprecated {
    my $minimum_version = $_[-1]->{older_than} ||
        die(__PACKAGE__.": 'older_than' parameter is mandatory\n");
    my @minimum_version_parts = (split(/\./, "$minimum_version", 3), 0, 0)[0..2];

    # can't use /\D/a because /a is a 5.14-ism
    if(grep { /[^0-9]/ } @minimum_version_parts) {
        die(__PACKAGE__.": $minimum_version isn't a plausible perl version\n")
    }

    my @current_version_parts = split(/\./, $Config{version});

    _parts_to_int(@current_version_parts) < _parts_to_int(@minimum_version_parts);
}

sub _parts_to_int {
    return 1000000 * $_[0] +
              1000 * $_[1] +
                     $_[2]
}

1;
