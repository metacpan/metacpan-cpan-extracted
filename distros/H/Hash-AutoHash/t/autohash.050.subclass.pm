package Child;
our $VERSION='1.00_2222';
use strict;
use Hash::AutoHash;
our @ISA=qw(Hash::AutoHash);
our @NORMAL_EXPORT_OK=qw(autohash_new child_new not_defined);
our %RENAME_EXPORT_OK=(child_xxx=>'autohash_keys');
our @RENAME_EXPORT_OK=(sub {"child_$_"},qw(autohash_new child_new)); 
our @EXPORT_OK=Child::helper->EXPORT_OK;
our @SUBCLASS_EXPORT_OK=Child::helper->SUBCLASS_EXPORT_OK;

sub child_method {
  return 'child method';
}

#################################################################################
# helper package exists to avoid polluting Child namespace with
#   subs that would mask accessor/mutator AUTOLOADs
#################################################################################
package Child::helper;
use strict;
use Hash::AutoHash;
BEGIN {
  our @ISA=qw(Hash::AutoHash::helper);
}

sub child_new {
  new Child @_;
}
sub child_function_not_exported {
  return "I am a child function that is not exported\n";
}

#################################################################################
package Grandchild;
our $VERSION='1.00_3333';
use strict;
use Hash::AutoHash;
our @ISA=qw(Child);
our @NORMAL_EXPORT_OK=qw(autohash_new child_new grandchild_new not_defined);
our %RENAME_EXPORT_OK=(grandchild_xxx=>'child_xxx',grandchild_yyy=>'autohash_values');
our @RENAME_EXPORT_OK=(sub {"grandchild_$_"},qw(autohash_new child_new grandchild_new)); 
our @EXPORT_OK=Grandchild::helper->EXPORT_OK;
our @SUBCLASS_EXPORT_OK=Grandchild::helper->SUBCLASS_EXPORT_OK;

sub grandchild_method {
  return 'grandchild method';
}
#################################################################################
# helper package exists to avoid polluting Grandchild namespace with
#   subs that would mask accessor/mutator AUTOLOADs
#################################################################################
package Grandchild::helper;
use strict;
BEGIN {
  our @ISA=qw(Child::helper);
}

sub grandchild_new {
  new Grandchild @_;
}
sub grandchild_function_not_exported {
  return "I am a grandchild function that is not exported\n";
}

1;
