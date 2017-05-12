use strict;
use warnings;
package
	Hash::MostUtils::leach::v5_10; # don't index me, please
use base qw(Exporter);

our @EXPORT = qw(leach n_each);

require Hash::MostUtils::leach;

sub n_each($\[@%$]) {
  if (ref($_[1]) eq 'REF') {
    $_[1] = ${$_[1]};
  }
  goto &Hash::MostUtils::leach::_n_each;
}

sub leach(\[@%$])   { unshift @_, 2; goto &n_each }
