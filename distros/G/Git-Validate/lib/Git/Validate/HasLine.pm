package Git::Validate::HasLine;
$Git::Validate::HasLine::VERSION = '0.001001';
use Moo::Role;

has line => (
   is => 'ro',
   required => 1,
);

has line_number => (
   is => 'ro',
   required => 1,
);

1;
