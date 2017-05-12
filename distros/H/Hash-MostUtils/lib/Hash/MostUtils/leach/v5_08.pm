use strict;
use warnings;
package
	Hash::MostUtils::leach::v5_08; # don't index me, please
use base qw(Exporter);

our @EXPORT = qw(leach n_each);

require Hash::MostUtils::leach;

sub n_each($\[@%$]) { goto &Hash::MostUtils::leach::_n_each }
sub leach(\[@%$])   { unshift @_, 2; goto &n_each }

1;
