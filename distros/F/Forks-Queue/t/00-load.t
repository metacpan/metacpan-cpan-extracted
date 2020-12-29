#! perl
use strict;
use warnings;
use Test::More;

diag "Forks::Queue test on $^O $]";
use_ok( 'Forks::Queue' );
use_ok( 'Forks::Queue::File' );
use_ok( 'Dir::Flock' );

{
    no warnings 'once';
    delete $Forks::Queue::OPTS{impl};
}
my $q = eval { Forks::Queue->new };
ok(!$q && $@, 'impl  option must be present to instantiate Forks::Queue');
diag "Forks::Queue ",$Forks::Queue::VERSION;
diag "Dir::Flock ",$Dir::Flock::VERSION;

done_testing();
