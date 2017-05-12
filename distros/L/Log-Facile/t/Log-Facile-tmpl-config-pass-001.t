use strict;
use Test::More qw(no_plan);

use Log::Facile;

ok chdir $ENV{HOME};

my $log_file = './Log-Facile-tmpl-config.test.tmp.log';
ok unlink $log_file or croak $! if -f $log_file;
ok my $logger = Log::Facile->new($log_file);

# normal pattern
is $logger->get($Log::Facile::TEMPLATE, 'TEMPLATE'), 'DATE [LEVEL] MESSAGE';
is $logger->get($Log::Facile::TEMPLATE, 'DATE'), undef;
is $logger->get($Log::Facile::TEMPLATE, 'LEVEL'), undef;
is $logger->get($Log::Facile::TEMPLATE, 'MESSAGE'), undef;

ok $logger->debug('debug off');
ok $logger->set('debug_flag', 1);
ok $logger->debug("debug on");
ok $logger->info("info");
ok $logger->error("error");
ok $logger->warn("warn");
ok $logger->fatal("fatal");

my $regexp_array_001 = [ 
    '\d{4}\/\d{2}\/\d{2} \d{2}:\d{2}:\d{2} \[DEBUG\] debug on',
    '\d{4}\/\d{2}\/\d{2} \d{2}:\d{2}:\d{2} \[INFO\] info',
    '\d{4}\/\d{2}\/\d{2} \d{2}:\d{2}:\d{2} \[ERROR\] error',
    '\d{4}\/\d{2}\/\d{2} \d{2}:\d{2}:\d{2} \[WARN\] warn',
    '\d{4}\/\d{2}\/\d{2} \d{2}:\d{2}:\d{2} \[FATAL\] fatal',
];

ok open my $io, $log_file or warn 'file open error - '.$!;
my $i = 0;
while (<$io>) {
   my $regexp = ${$regexp_array_001}[$i];
   if ( defined $regexp ) {
       ok $_ =~ /$regexp/, 'output - |'.$regexp.'|'.$_.'|';
   }
   $i++;
}
ok close $io or warn 'file close error - '.$!;

is $logger->get($Log::Facile::TEMPLATE, 'TEMPLATE'), 'DATE [LEVEL] MESSAGE';
is $logger->get($Log::Facile::TEMPLATE, 'DATE'), undef;
is $logger->get($Log::Facile::TEMPLATE, 'LEVEL'), undef;
is $logger->get($Log::Facile::TEMPLATE, 'MESSAGE'), undef;

ok unlink $log_file or croak $! if -f $log_file;

# config template
ok $logger->set($Log::Facile::TEMPLATE, 'COMMON_VALUE', 'LOVE');
ok $logger->set($Log::Facile::TEMPLATE, 'TEMPLATE', 'DATE (LEVEL) MESSAGE with COMMON_VALUE');
is $logger->get($Log::Facile::TEMPLATE, 'TEMPLATE'), 'DATE (LEVEL) MESSAGE with COMMON_VALUE';

ok $logger->set('debug_flag', 1);
ok $logger->debug("debug on");
ok $logger->info("info");
ok $logger->error("error");
ok $logger->warn("warn");
ok $logger->fatal("fatal");

my $regexp_array_002 = [ 
    '\d{4}\/\d{2}\/\d{2} \d{2}:\d{2}:\d{2} \(DEBUG\) debug on with LOVE',
    '\d{4}\/\d{2}\/\d{2} \d{2}:\d{2}:\d{2} \(INFO\) info with LOVE',
    '\d{4}\/\d{2}\/\d{2} \d{2}:\d{2}:\d{2} \(ERROR\) error with LOVE',
    '\d{4}\/\d{2}\/\d{2} \d{2}:\d{2}:\d{2} \(WARN\) warn with LOVE',
    '\d{4}\/\d{2}\/\d{2} \d{2}:\d{2}:\d{2} \(FATAL\) fatal with LOVE',
];

ok open $io, $log_file or warn 'file open error - '.$!;
$i = 0;
while (<$io>) {
   my $regexp = ${$regexp_array_002}[$i];
   ok $_ =~ /$regexp/, 'output - |'.$regexp.'|'.$_.'|';
   $i++;
}
ok close $io or warn 'file close error - '.$!;

ok unlink $log_file or croak $! if -f $log_file;
__END__
