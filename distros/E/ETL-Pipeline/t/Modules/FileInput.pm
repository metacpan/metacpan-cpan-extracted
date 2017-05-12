# This module does nothing. I use it for testing roles.
package FileInput;
use Moose;


sub get { return (); }
sub next_record { return 1; }
sub configure { }
sub finish { }
sub full_record { (); }

with 'ETL::Pipeline::Input::File';
with 'ETL::Pipeline::Input';

no Moose;
__PACKAGE__->meta->make_immutable;
