#line 1
package Module::Package::Dist::RDF;

use 5.008003;
our $VERSION = '0.001';

package Module::Package::Dist::RDF::standard;

use 5.008003;
use strict;
use base qw[Module::Package::Dist];
our $VERSION = '0.001';

sub _main
{
	my ($self) = @_;
	$self->mi->trust_meta_yml;
	$self->mi->auto_install;
}

1;