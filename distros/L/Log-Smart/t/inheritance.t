use Test::More 'no_plan';
use lib 't';
use InheritanceTest;
use Log::Smart -name => 'inheritance.debug';
use IO::File;

LOG('inheritance test');
my $obj = InheritanceTest->new;
LOG($obj->say);

my $fh = IO::File->new('t/inheritance.debug');

my $line = $fh->getline;
chomp $line;
is($line, 'inheritance test', 'test1');

$fh->close;
