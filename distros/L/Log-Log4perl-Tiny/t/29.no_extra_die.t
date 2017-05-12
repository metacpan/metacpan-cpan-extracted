# vim: filetype=perl :
use strict;
use warnings;

use Test::More tests => 3;    # last test to print
use Log::Log4perl::Tiny qw( :easy get_logger :no_extra_logdie_message );

use lib 't';
use TestLLT qw( set_logger log_is );
use CarpingModule;

my @lines;
Log::Log4perl->easy_init(
   {
      format => '%m%n',
      level  => $INFO,
      fh     => sub { push @lines, $_[0] },
   }
);
my $logger = get_logger();
set_logger($logger);

my (@warnings, @dies);
$SIG{__WARN__} = sub {
   push @warnings, @_;
};
$SIG{__DIE__} = sub {
   push @dies, @_;
};

# override exit function to see if we pass here
my $exit_called;
{
   no warnings;
   *Log::Log4perl::Tiny::_exit = sub {
      $exit_called = 1;
   };
}

CarpingModule::somesub();

ok $exit_called, 'exit was called';
is scalar(@warnings), 0, 'no warning was generated';
is scalar(@dies), 0, 'no die was generated';
done_testing();
