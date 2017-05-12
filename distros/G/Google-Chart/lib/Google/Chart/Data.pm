# $Id$

package Google::Chart::Data;
use Moose::Role;

use constant parameter_name => 'chd';

with 'Google::Chart::QueryComponent::Simple';

has 'dataset' => (
    is => 'rw',
    isa => 'ArrayRef',
    required => 1,
    default => sub { +[] }
);

no Moose;

1;

__END__

=head1 NAME

Google::Chart::Data - Google::Chart Data Role

=cut
