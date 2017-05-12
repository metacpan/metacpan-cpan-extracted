use strict;
use warnings;
use lib 't', 'lib';
use Test::More tests => 1;

use Kwiki::VimMode;

package dummy;
use Spiffy '-Base';
field 'block_text';
package main;

my $out;
my $self = dummy->new;

$self->block_text(<<'END');
# comment
# modeline - vim:set syn=off:
"string"
END
$out = Kwiki::VimMode::Wafl::to_html($self);
like $out, qr(<span class="synComment">);

