# vim: filetype=perl :
use strict;
use warnings;

use Test::More tests => 4;    # last test to print
use Log::Log4perl::Tiny qw( :easy get_logger );

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
eval { CarpingModule::somesub(); };
my $file = quotemeta(__FILE__);

is scalar(@warnings), 1, 'one warning was generated';
like $warnings[0], qr{(?mxs:
      \A sent\ from\ somesub\ in\ CarpingModule
         \ at .* $file \ line\ \d+\.?
      \s*\z
      )}, 'warning has the right message';

is scalar(@dies), 1, 'one die was generated';
like $dies[0], qr{(?mxs:
      \A sent\ from\ anothersub\ in\ CarpingModule
         \ at .* $file \ line\ \d+\.?
      \s*\z
      )}, 'warning has the right message';

done_testing();
