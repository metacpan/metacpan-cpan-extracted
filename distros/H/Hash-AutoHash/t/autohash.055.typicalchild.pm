package TypicalChild;
our $VERSION='1.00_4444';

use strict;
use Hash::AutoHash;
our @ISA=qw(Hash::AutoHash);
our @NORMAL_EXPORT_OK=();
our @RENAME_EXPORT_OK=sub {s/^autohash/typicalchild/; $_};
our @EXPORT_OK=TypicalChild::helper->EXPORT_OK;
our @SUBCLASS_EXPORT_OK=TypicalChild::helper->SUBCLASS_EXPORT_OK;


#################################################################################
# helper package exists to avoid polluting TypicalChild namespace with
#   subs that would mask accessor/mutator AUTOLOADs
#################################################################################
package TypicalChild::helper;
use strict;
use Hash::AutoHash qw(autohash_tie autohash_set);
use Tie::Hash::MultiValue;	# an example tied hash class
BEGIN {				# BEGIN needed so @ISA defined before EXPORT_OK computed
  our @ISA=qw(Hash::AutoHash::helper);
}

sub _new {
  my($helper_class,$class,@args)=@_;
  my $self=autohash_tie Tie::Hash::MultiValue;
  autohash_set($self,@args);
  bless $self,$class;
}

1;
