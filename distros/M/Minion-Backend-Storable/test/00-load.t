use Mojo::Base -strict;
use Test::More;

use_ok 'Minion';
diag "Testing Minion $Minion::VERSION, Perl $], $^X";
use_ok 'Minion::Backend::Storable';

done_testing();
