#######################################################################
#      $URL: svn+ssh://equilibrious@equilibrious.net/home/equilibrious/svnrepos/chrisdolan/Fuse-PDF/lib/Fuse/PDF/ErrnoHacks.pm $
#     $Date: 2008-06-06 22:47:54 -0500 (Fri, 06 Jun 2008) $
#   $Author: equilibrious $
# $Revision: 767 $
########################################################################
package #
  Fuse::PDF::ErrnoHacks;

use warnings;
use strict;
use POSIX qw();
use Carp qw(carp);
use English qw(-no_match_vars);

our $VERSION = '0.09';

BEGIN {
   # ENOATTR isn't commonly defined in POSIX.pm.  Try to find it, or use a fallback value.
   if (!defined &POSIX::ENOATTR) {
      if (open my $fh, '<', '/usr/include/sys/errno.h') {
         my $content = do { local $INPUT_RECORD_SEPARATOR = undef; <$fh> };
         close $fh or carp 'Failed to close errno.h';
         if ($content =~ m/\#define \s+ ENOATTR \s+ (0x\d+|\d+)/xms) {
            my $errno = $1;
            if ($errno =~ m/0x(\d+)/xms) {
               $errno = hex $1;
            }
            *ENOATTR = sub { return $errno; };
         }
      }
      if (!defined *ENOATTR{CODE}) {
         *ENOATTR = sub { return POSIX::EIO(); };
      }
   }
}

sub import {
   if (!defined &POSIX::ENOATTR) {
      no strict 'refs';  ## no critic(TestingAndDebugging::ProhibitNoStrict)
      *{caller() . '::ENOATTR'} = \&ENOATTR;
   }
   return;
}

1;

__END__

=pod

=for stopwords POSIX.pm

=head1 NAME

Fuse::PDF::ErrnoHacks - Workaround for missing POSIX.pm error number values

=head1 SYNOPSIS

In each package that needs C<ENOATTR>:

   use Fuse::PDF::ErrnoHacks;

That's it.

=head1 DESCRIPTION

For reasons I do not understand, C<use POSIX ':errno_h'> is missing
some values on (at least) Mac OS X 10.4.  This module detects the
missing constant and tries to read from F</usr/include/sys/errno.h>
directly.  If it can't find the constant there either, it substitutes
C<EIO> instead.

=head1 GENERATED CONSTANTS

=over

=item ENOATTR()

=back

=head1 LICENSE

Copyright 2007-2008 Chris Dolan, I<cdolan@cpan.org>

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<POSIX>

=head1 AUTHOR

Chris Dolan, I<cdolan@cpan.org>

=cut

# Local Variables:
#   mode: perl
#   perl-indent-level: 3
#   cperl-indent-level: 3
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab :
