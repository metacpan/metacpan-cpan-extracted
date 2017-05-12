#! perl
use strict;
use warnings;
use Test::More;

diag "Forks::Queue test on $^O $]";
use_ok( 'Forks::Queue' );
use_ok( 'Forks::Queue::File' );

delete $Forks::Queue::OPTS{impl};
my $q = eval { Forks::Queue->new };
ok(!$q && $@, 'impl  option must be present to instantiate Forks::Queue');

done_testing();
