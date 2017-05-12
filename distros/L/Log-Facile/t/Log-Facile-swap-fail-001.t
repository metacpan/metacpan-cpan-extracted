use strict;
use Test::More qw(no_plan);

use Log::Facile;

ok chdir $ENV{HOME};

my $log_file = './Log-Facile-swap.test.tmp.log';
ok unlink $log_file or warn 'file delete error - '.$! if -f $log_file;
ok my $logger = Log::Facile->new($log_file);

my $swap_dir = '/dummy/Log-Facile-test-dummy';
ok $logger->set('swap_dir', $swap_dir);
eval { $logger->swap(); };
like $@, qr/create swap dir error/, 'fail - '.$@;

$swap_dir = './Log-Facile-test-dummy';
ok $logger->set('swap_dir', $swap_dir);
ok mkdir $swap_dir if ! -d $swap_dir;
ok chmod 0111, $swap_dir or warn $!;
$logger->info('swap fail');
eval { $logger->swap($swap_dir); };
like $@, qr/current file move error/, 'fail - '.$@;

ok chmod 0755, $swap_dir or warn $!;
ok rmdir $swap_dir if -d $swap_dir;
__END__
