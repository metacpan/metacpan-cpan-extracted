#
# This file is part of Games-Risk
#
# This software is Copyright (c) 2008 by Jerome Quelin.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#
use 5.010;
use strict;
use warnings;

package Games::Risk::I18n;
# ABSTRACT: internationalization utilities for prisk
$Games::Risk::I18n::VERSION = '4.000';
# should come before locale::textdomain use
use Games::Risk::Utils qw{ $SHAREDIR };

use Encode;
use Exporter::Lite;
use Locale::TextDomain 'Games-Risk', $SHAREDIR->subdir("locale")->stringify;

our @EXPORT_OK = qw{ T };


# -- public subs


sub T { return decode('utf8', __($_[0])); }


1;

__END__

=pod

=head1 NAME

Games::Risk::I18n - internationalization utilities for prisk

=head1 VERSION

version 4.000

=head1 SYNOPSIS

    use Games::Risk::I18n qw{ T };
    say T('message');

=head1 DESCRIPTION

This module handles the game's internationalization (i18n). It is using
C<Locale::TextDomain> underneath, so refer to this module's documentation
for more information.

=head1 METHODS

=head2 my $locstr = T( $string )

Performs a call to C<gettext> on C<$string>, convert it from utf8 and
return the result. Note that i18n is using C<Locale::TextDomain>
underneath, so refer to this module for more information.

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2008 by Jerome Quelin.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
