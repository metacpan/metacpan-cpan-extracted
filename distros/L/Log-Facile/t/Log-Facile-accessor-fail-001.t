use strict;
use Test::More qw(no_plan);

use Log::Facile;

ok chdir $ENV{HOME};

my $log_file = './Log-Facile-write.test.tmp.log';
ok unlink $log_file or croak $! if -f $log_file;
ok my $logger = Log::Facile->new($log_file);

eval { $logger->set('dummy', 1); };
like $@, qr/invalid field name :-P - dummy/, 'fail - '.$@;
eval { $logger->get('dummy'); };
like $@, qr/invalid field name :-P - dummy/, 'fail - '.$@;
eval { $logger->set($Log::Facile::TEMPLATE, 'DA', 'dummy'); };
like $@, qr/Can't use 'DA' to template because 'DATE' has already used/, 'fail - '.$@;
eval { $logger->set($Log::Facile::TEMPLATE, 'DATE_FORMAT', 'dummy'); };
like $@, qr/Can't use 'DATE_FORMAT' to template because 'DATE' has already used/, 'fail - '.$@;
eval { $logger->get($Log::Facile::TEMPLATE, 'DA'); };
like $@, qr/Can't use 'DA' to template because 'DATE' has already used/, 'fail - '.$@;
eval { $logger->get($Log::Facile::TEMPLATE, 'DATE_FORMAT'); };
like $@, qr/Can't use 'DATE_FORMAT' to template because 'DATE' has already used/, 'fail - '.$@;

ok unlink $log_file or croak $! if -f $log_file;
__END__
