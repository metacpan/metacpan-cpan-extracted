# -*- perl -*-

#  Copyright 2005 Laurent Wacrenier
#
#  This file is part of Maildir-Quota
#
#  Maildir-Quota is free software; you can redistribute it and/or modify it
#  under the terms of the GNU Lesser General Public License as
#  published by the Free Software Foundation; either version 2 of the
#  License, or (at your option) any later version.
#
#  Maildir-Quota is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU Lesser General Public License for more details.
#
#  You should have received a copy of the GNU Lesser General Public
#  License along with Maildir-Quota; if not, write to the Free Software
#  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307
#  USA

# $Id: Quota.pm,v 1.4 2005/02/03 13:54:10 lwa Exp $

package Maildir::Quota;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
	
);
$VERSION = '0.3';

bootstrap Maildir::Quota $VERSION;

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

Maildir::Quota - Perl extension for Maildir++ soft quotas handling

=head1 SYNOPSIS

  use Maildir::Quota;

  sub Maildir::Quota::error {  # error handler
    warn("$_[0]\n");
  }
 
  my $q = new Maildir::Quota;

  my $bytes = $q->bytes;
  my $max_bytes = $q->max_bytes;
  my $files = $q->files;
  my $max_files = $q->max_files;

  if ($q->test($nbytes, $nfiles)) {
    if ( add the files in the maildir ) {
       $q->add($nbytes, $nfiles);
    }
  }

  if (... message removed ...) {
    $q->add(-$message_size, -1);
  }

  unless ($q->test) {
     die "overquota";
  }

  undef $q;  # flush quota description

=head1 DESCRIPTION

C<Maildir::Quota> is a perl module to edit and check Maildir++ soft quota
cache.

=head1 CONSTRUCTOR

=over 4

=item new ( DIRECTORY [, QUOTA DESCRIPTION ] )

Create a C<Maildir::Quota>. It recieve the directory where the Maildir is
and a optional quota description.

Quota description are a coma (,) separated list of quota
specifications.  A quota specification consists of a number, followed
by a letter specifying the type of quota. Currently the following
quota types are used: S - maximum size of messages in the maildir; C -
message count in the maildir.

If quota description is not given, the value is taken from the quota
cache file.

=back

=head1 METHODS

=over 4

=item test ( [ NBYTES [, NFILES ]] )

Return true if the Maildir can store NFILES messages of a total NBYTES
bytes. If NBYTES or NFILES are not defined, check is the Maildir is
overquota.

=item add ( [ NBYTES [, NFILES ]] )
Adds NFILES messages of a total NBYTES bytes to the soft quota cache.
If you plan remove messages, use negatives values to NFILE and NBYTES.

=item bytes
Returns the cached number of bytes or undef if an error occurs

=item max_bytes
Returns the number of bytes allowed in the Maildir or undef is this
value is not defined

=item files
Returns the cached number of files or undef if an error occurs

=item max_files
Returns the number of files allowed in the Maildir or undef is this
value is not defined

=back

=head1 ERROR HANDLING

If a Maildir::Quota::error subroutine is defined, all errors are send
to it. Maildir not found, invalid or empty quota description are not
errors.

=head1 LIMITATIONS

Quota file is opened in read-write mode. If cache recalculation occurs,
a new file is created. So, all add() operations must be done with
Mailbox owner UID/GID.

Trash folder is not counted within the quota.

Library just manage the size cache, it does not supperss nor add
message by itself.

=head1 AUTHOR

(Laurent Wacrenier) lwa@teaser.fr

=head1 SEE ALSO

mdq(3), maildirquota(7)

=cut
