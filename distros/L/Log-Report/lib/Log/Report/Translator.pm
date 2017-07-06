# Copyrights 2007-2017 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
package Log::Report::Translator;
use vars '$VERSION';
$VERSION = '1.21';


use warnings;
use strict;

use Log::Report 'log-report';


sub new(@) { my $class = shift; (bless {}, $class)->init({@_}) }
sub init($) { shift }

#------------

#------------

# this is called as last resort: if a translator cannot find
# any lexicon or has no matching language.
sub translate($$$)
{   my $msg = $_[1];

      defined $msg->{_count} && $msg->{_count} != 1
    ? $msg->{_plural}
    : $msg->{_msgid};
}


sub load($@) { undef }

1;
