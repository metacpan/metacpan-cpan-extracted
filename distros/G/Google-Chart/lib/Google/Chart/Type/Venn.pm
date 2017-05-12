# $Id$

package Google::Chart::Type::Venn;
use Moose;

use constant parameter_value => 'v';

with 'Google::Chart::Type::Simple';

__PACKAGE__->meta->make_immutable;

no Moose;

1;

__END__

=head1 NAME 

Google::Chart::Type::Venn - Google::Chart Venn Type

=cut