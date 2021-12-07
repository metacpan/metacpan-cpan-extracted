# This module does nothing. I use it for testing roles.
package Output;
use Moose;


sub close { }
sub open { }
sub write { }
with 'ETL::Pipeline::Output';


no Moose;
__PACKAGE__->meta->make_immutable;
