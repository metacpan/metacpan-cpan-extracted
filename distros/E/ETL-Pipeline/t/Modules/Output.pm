# This module does nothing. I use it for testing roles.
package Output;
use Moose;


sub set { }
sub write_record { return 1; }
sub new_record { }
sub configure { }
sub finish { }

with 'ETL::Pipeline::Output';

no Moose;
__PACKAGE__->meta->make_immutable;
