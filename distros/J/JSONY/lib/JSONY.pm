use strict; use warnings;
package JSONY;

use version;
our $VERSION = '0.1.19'; $VERSION = version->declare("v$VERSION");

use Pegex::Parser;
use JSONY::Grammar;
use JSONY::Receiver;

sub new {
    bless {}, $_[0];
}

sub load {
    Pegex::Parser->new(
        grammar => JSONY::Grammar->new,
        receiver => JSONY::Receiver->new,
        # debug => 1,
    )->parse($_[1]);
}

1;
