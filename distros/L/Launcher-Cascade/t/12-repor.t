#!perl -T

use Test::More tests => 3;
use Log::Log4perl qw( :easy );
Log::Log4perl->easy_init($FATAL);

use Launcher::Cascade::Simple;
use Launcher::Cascade::FileReader;

my $f = new Launcher::Cascade::FileReader
    -path => $0,
    -context_before => 3,
    -context_after => 3,
;

my $A = new Launcher::Cascade::Simple
    -name => 'Launcher A',
    -test_hook => sub { $f->search('context_before'); $_[0]->add_error($f->context()) },
    -launch_hook => sub { $_[0]->add_error('Starting'); 1 },
;

$A->run();
$A->check_status();

my $report = $A->errors();

ok($report =~ /^Starting/m);
ok($report =~ /^    my \$f = new Launcher::Cascade::FileReader$/m);
ok($report =~ /^        -context_before/m);
