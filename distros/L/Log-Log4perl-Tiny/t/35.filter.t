# vim: filetype=perl :
use strict;
use warnings;

use Test::More;    # last test to print
use Log::Log4perl::Tiny qw< get_logger FILTER :easy >;

use lib 't';
use TestLLT qw( set_logger log_is log_like );

my $default = get_logger();

ok !exists($default->{filter}), 'no "filter" by default';
is FILTER(), undef, 'no filter from FILTER too';

Log::Log4perl->easy_init(
   {
      filter => sub {
         my $message = shift;
         $message =~ s{^}{# }gmxs;
         return $message;
      },
      level => 'INFO',
   }
);
set_logger(get_logger());

log_like {
   INFO 'whatever';
}
qr{(?mxs:\A\#.*whatever\s*\z)}, 'filter applied on one line';

log_like {
   INFO "whatever\nwhatever";
}
qr{(?mxs: \A\#.*?whatever\n\#\ whatever\s\z)},
  'filter applied on both lines';

FILTER(undef);
log_like {
   INFO "whatever\nwhatever";
}
qr{(?mxs: \A.*?whatever\nwhatever\s\z)}, 'no filter applied on both lines';
done_testing();
