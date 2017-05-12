# $Id$

package Google::Chart::QueryComponent;
use Moose::Role;

requires 'as_query';

no Moose;

1;

__END__

=head1 NAME

Google::Chart::QueryComponent - Google::Chart Query Component

=head1 SYNOPSIS

  package MyStuff;
  use Moose;
  with 'Google::Chart::QueryComponent';

=head1 METHODS

=head2 as_query

=cut
