# ----------------------------------------------------------------------------
#
# This is an exception handling module for File::Properties.
#
# Copyright © 2010,2011 Brendt Wohlberg <wohl@cpan.org>
# See distribution LICENSE file for license details.
#
# Most recent modification: 5 November 2011
#
# ----------------------------------------------------------------------------

package File::Properties::Error;
our $VERSION = 0.01;

require 5.005;
use strict;
use warnings;
use Error qw(:try);

use base qw(Error);
use overload ('""' => 'string');
$File::Properties::Error::Debug = 0;


# ----------------------------------------------------------------------------
# Constructor
# ----------------------------------------------------------------------------
sub new {
  my $self = shift;
  my $text = "" . shift;
  my $obrf = shift;

  local $Error::Depth = $Error::Depth + 1;
  local $Error::Debug = 1 if ($File::Properties::Error::Debug > 1);

  $self->SUPER::new('-text' => $text, '-object' => $obrf);
}


# ----------------------------------------------------------------------------
# Construct string from object
# ----------------------------------------------------------------------------
sub string {
  my $self = shift;

  my $txt;
  if ($File::Properties::Error::Debug == 0) {
    $txt = $self->text . "\n";
  } else {
    $txt = $self->stacktrace if ($File::Properties::Error::Debug);
  }

 if ($File::Properties::Error::Debug > 2 and defined($self->object)
   and ref($self->object) =~ /^File::/) {
    $txt .= "Exception occurred in object: " .$self->object . "\n";
    if ($File::Properties::Error::Debug > 3) {
      $txt .= "Object state:\n";
      my ($k,$v);
      foreach $k ( sort keys %{$self->object} ) {
	$v = defined $self->object->{$k} ? $self->object->{$k} : "[undef]";
	$txt .= "  $k: $v\n";
      }
    }
  }

  return $txt;
}


# ----------------------------------------------------------------------------
# End of method definitions
# ----------------------------------------------------------------------------


1;
__END__

=head1 NAME

File::Properties::Error - Exception handling module for File::Properties

=head1 SYNOPSIS

  use File::Properties::Error;

  $File::Properties::Error::Debug = 2;

  throw File::Properties::Error("Error text", $objectref);

=head1 DESCRIPTION

  File::Properties::Error is a Perl module for representing errors in
  File::Properties and associated modiles. It is derived from the
  Error exception handling module.

=head1 SEE ALSO

L<Error>

=head1 AUTHOR

Brendt Wohlberg E<lt>wohl@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010,2011 by Brendt Wohlberg

This library is available under the terms of the GNU General Public
License (GPL), described in the LICENSE file included in this
distribution.

=cut
