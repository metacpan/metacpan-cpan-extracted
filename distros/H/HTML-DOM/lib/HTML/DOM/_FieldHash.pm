package HTML::DOM::_FieldHash;

our $VERSION = '0.058';

BEGIN {
 if(eval { require Hash::Util::FieldHash }) {
  import Hash::Util::FieldHash qw < fieldhashes >;
 } else {
  require Tie::RefHash::Weak;
  VERSION Tie::RefHash::Weak 0.08; # fieldhashes
  import Tie::RefHash::Weak qw < fieldhashes >;
 }
}

@ISA = Exporter;
@EXPORT = 'fieldhashes';
require Exporter;
