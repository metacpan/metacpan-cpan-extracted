#
# This file is part of Games-Pandemic
#
# This software is Copyright (c) 2009 by Jerome Quelin.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 2, June 1991
#
use 5.010;
use strict;
use warnings;

package Games::Pandemic::I18n;
{
  $Games::Pandemic::I18n::VERSION = '1.120510';
}
# ABSTRACT: internationalization utilities for pandemic

# should come before locale::textdomain use
use Games::Pandemic::Utils qw{ $SHAREDIR };

use Encode;
use Exporter::Lite;
use Locale::TextDomain 'Games-Pandemic', $SHAREDIR->subdir("locale")->stringify;

our @EXPORT_OK = qw{ T };


# -- public subs


sub T { return decode('utf8', __($_[0])); }


1;


=pod

=head1 NAME

Games::Pandemic::I18n - internationalization utilities for pandemic

=head1 VERSION

version 1.120510

=head1 DESCRIPTION

This module provides some helper subs for internationalizing pandemic.

=head1 METHODS

=head2 my $locstr = T( $string )

Performs a call to C<gettext> on C<$string>, convert it from utf8 and
return the result. Note that i18n is using C<Locale::TextDomain>
underneath, so refer to this module for more information.

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2009 by Jerome Quelin.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut


__END__

