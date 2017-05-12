# ----------------------------------------------------------------------------
#
# This module supports cached access to file properties.
#
# Copyright © 2010,2011 Brendt Wohlberg <wohl@cpan.org>
# See distribution LICENSE file for license details.
#
# Most recent modification: 4 November 2011
#
# ----------------------------------------------------------------------------

package File::Properties::PropsCache;
our $VERSION = 0.01;

use File::Properties::Error;
use File::Properties::Cache;
use File::Properties;
use base qw(File::Properties::Cache);

require 5.005;
use strict;
use warnings;
use Error qw(:try);


# ----------------------------------------------------------------------------
# Initialiser
# ----------------------------------------------------------------------------
sub _init {
  my $self = shift;
  my $dbfp = shift; # Database file path
  my $opts = shift; # Options hash

  $self->SUPER::_init($dbfp, $opts);
  File::Properties->_cacheinit($self, $opts);
}


# ----------------------------------------------------------------------------
# Create File::Properties object for specified path
# ----------------------------------------------------------------------------
sub properties {
  my $self = shift;
  my $path = shift; # File path

  return File::Properties->new($path, $self);
}


# ----------------------------------------------------------------------------
# End of method definitions
# ----------------------------------------------------------------------------


1;
__END__

=head1 NAME

File::Properties::PropsCache - Perl module implementing a cache for
disk file properties

=head1 SYNOPSIS

  use File::Properties::PropsCache;

  my $fpc = File::Properties::PropsCache->new('cache.db');

  my $fp = $fpc->properties('/path/to/file');
  print "File properties:\n" . $fp->string . "\n";


=head1 ABSTRACT

  File::Properties::PropsCache is a Perl module implementing a cache
  for disk file properties.

=head1 DESCRIPTION

  File::Properties::PropsCache is a Perl module implementing a cache
  for disk file properties. Its only purpose is to provide an
  alternative interface for cache creation and construction for the
  File::Properties class.

=over 4

=item B<new>

  my $opts = {'CachedPath' => 1};
  my $fpc = File::Properties::PropsCache->new($path, $opts);

Constructs a new File::Properties::PropsCache object.

=item B<properties>

   my $fp = $fpc->properties($path);
   print "Properties of $path:\n" . $fp->string . "\n";

Construct the File::Properties object for the file at $path.

=back

=head1 SEE ALSO

L<File::Properties>, L<File::Properties::Cache>

=head1 AUTHOR

Brendt Wohlberg E<lt>wohl@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010,2011 by Brendt Wohlberg

This library is available under the terms of the GNU General Public
License (GPL), described in the LICENSE file included in this
distribution.

=cut
