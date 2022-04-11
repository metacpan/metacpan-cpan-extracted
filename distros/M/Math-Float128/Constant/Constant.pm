
package Math::Float128::Constant;
use strict;
use warnings;

require Exporter;
*import = \&Exporter::import;
require DynaLoader;

our $VERSION = '0.16';
#$VERSION = eval $VERSION;
Math::Float128::Constant->DynaLoader::bootstrap($VERSION);

@Math::Float128::Constant::EXPORT = ();
@Math::Float128::Constant::EXPORT_OK = ();

sub dl_load_flags {0} # Prevent DynaLoader from complaining and croaking

sub _issue_19550 { # https://github.com/Perl/perl5/issues/19550
  my $inf = 999 ** (999 ** 999);
  my $discard = "$inf";
  my $inf_copy = $inf;
  # Using Math::Float128::Constant::_is_NOK_and_POK():
  return 1
    if(!_is_NOK_and_POK($inf) && _is_NOK_and_POK($inf_copy));
  return 0;
}

1;
