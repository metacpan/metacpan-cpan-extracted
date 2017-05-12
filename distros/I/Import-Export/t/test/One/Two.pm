package One::Two;

use strict;
use warnings;

use base qw/Import::Export/;

our %EX = (
	two => ['all']
);

use One 'all';

sub new { bless {}, $_[0] }

sub two { 'Whats' }

1;
