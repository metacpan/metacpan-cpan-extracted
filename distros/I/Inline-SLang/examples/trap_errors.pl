#
# $Id: trap_errors.pl,v 1.1 2005/01/04 16:18:07 dburke Exp $
#
# Evaluate a S-Lang statement which contains an error
#

use strict;
use Inline 'SLang';

# Call the S-Lang function
#
my $ans;
eval { $ans = mydiv (0.0); };
print "The S-Lang error was:\n$@\n";

# Evaluate S-:ang code directly
#
eval { Inline::SLang::sl_eval( "10.0/0.0;" ); };
print "The S-Lang error was:\n$@\n";

__END__
__SLang__

define mydiv(y) { return 10.0 / y; }

