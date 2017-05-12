# $Id$

package Google::Chart::Fill;
use Moose::Role;

use constant parameter_name => 'chf';

with 'Google::Chart::QueryComponent::Simple';

no Moose;

1;

__END__

=head1 NAME

Google::Chart::Fill - Base Fill Role

=head1 SYNOPSIS

  package NewFillType;
  use Moose;

  with 'Google::Chart::Fill';

  no Moose;

  sub parameter_value { ... }

=cut