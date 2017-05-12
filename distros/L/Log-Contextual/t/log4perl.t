use strict;
use warnings;

use Test::More;

if (
   eval <<'EOE'
require Log::Log4perl;
die if $Log::Log4perl::VERSION < 1.29;
1
EOE
  ) {
   plan tests => 2;
} else {
   plan skip_all => 'Log::Log4perl 1.29 not installed'
}

use FindBin;
unlink 'myerrs.log' if -e 'myerrs.log';
Log::Log4perl->init("$FindBin::Bin/log4perl.conf");
use Log::Contextual qw( :log set_logger );
set_logger(Log::Log4perl->get_logger);

my @elines;

push @elines, __LINE__ and log_error { 'err FIRST' };

sub foo {
   push @elines, __LINE__ and log_error { 'err SECOND' };
}
foo();
open my $log, '<', 'myerrs.log';
my @datas = <$log>;
close $log;

is $datas[0], "file:t/log4perl.t line:$elines[0] method:main:: - err FIRST\n",
  'file and line work with Log4perl';
is $datas[1],
  "file:t/log4perl.t line:$elines[1] method:main::foo - err SECOND\n",
  'file and line work with Log4perl in a sub';

unlink 'myerrs.log';
