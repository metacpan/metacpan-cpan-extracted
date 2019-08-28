use strict;
use warnings;
use Test::More;


require_ok('Geoffrey::Converter::Pg');
use_ok 'Geoffrey::Converter::Pg';

require_ok('Geoffrey::Action::Constraint::Default');
use_ok 'Geoffrey::Action::Constraint::Default';

my $converter = Geoffrey::Converter::Pg->new();
my $object = new_ok( 'Geoffrey::Action::Constraint::Default', [ 'converter', $converter ] );

done_testing;
