package Git::Validate::Error::LongLine;
$Git::Validate::Error::LongLine::VERSION = '0.001001';
use Moo;

use overload q("") => '_stringify';

with 'Git::Validate::HasLine';

has '+line_number' => ( default => 1 );

has max_length => (
   is => 'ro',
   default => 72,
);

sub _stringify {
   sprintf 'line %d is too long, max of %d chars, instead it is %d',
      $_[0]->line_number, $_[0]->max_length, length $_[0]->line
}

1;
