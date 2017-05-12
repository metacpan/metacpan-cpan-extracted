#!perl -T

use Test::More tests => 2;
use Log::Log4perl qw( :easy );
Log::Log4perl->easy_init($FATAL);

use Launcher::Cascade::FileReader;
use Launcher::Cascade::Simple;

my $A = new Launcher::Cascade::Simple
    -name => 'launcher A',
    -launch_hook => sub { 1 },
    -test_hook => sub { Launcher::Cascade::FileReader->new(-path => "$0.bak")->search('$0') != -1 ? SUCCESS : FAILURE },
;

$A->run();
$A->check_status();

ok($A->errors() =~ /Cannot read < $0\.bak:/);
ok($A->is_failure());
