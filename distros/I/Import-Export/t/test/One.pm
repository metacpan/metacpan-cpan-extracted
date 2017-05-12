package One;

use strict;
use warnings;

use base qw/Import::Export/;

our %EX = (
	one => [qw/all/],
);

sub one { 'Hello World' }

sub new { bless {}, $_[0] }

1;
