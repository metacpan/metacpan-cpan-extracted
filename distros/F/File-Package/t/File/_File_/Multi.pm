#!perl
#
#
package File::Package1;


use 5.001;
use strict;
use warnings;
use warnings::register;

use vars qw($VERSION $DATE $FILE);
$VERSION = '1.15';
$DATE = '2004/04/10';
$FILE = __FILE__;


package File::Package2;


use 5.001;
use strict;
use warnings;
use warnings::register;

use vars qw($VERSION $DATE $FILE);
$VERSION = '1.15';
$DATE = '2004/04/09';
$FILE = __FILE__;


package File::Package3;


use 5.001;
use strict;
use warnings;
use warnings::register;

use vars qw($VERSION $DATE $FILE);
$VERSION = '1.15';
$DATE = '2004/04/09';
$FILE = __FILE__;
