# Copyrights 2001-2017 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.

package Mail::Box::Tie;
use vars '$VERSION';
$VERSION = '3.002';


use strict;

use Carp;


#-------------------------------------------

sub TIEHASH(@)
{   my $class = (shift) . "::HASH";
    eval "require $class";   # bootstrap

    confess $@ if $@;
    $class->TIEHASH(@_);
}

#-------------------------------------------

sub TIEARRAY(@)
{   my $class = (shift) . "::ARRAY";
    eval "require $class";   # bootstrap

    confess $@ if $@;
    $class->TIEARRAY(@_);
}

#-------------------------------------------

1;
