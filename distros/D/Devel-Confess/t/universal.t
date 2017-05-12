use strict;
use warnings;
BEGIN {
  $ENV{DEVEL_CONFESS_OPTIONS} = '';
}
use Test::More ($ENV{RELEASE_TESTING} || eval {
  require UNIVERSAL::isa;
  require UNIVERSAL::can;
}) ? (tests => 1)
  : (skip_all => 'UNIVERSAL::can and UNIVERSAL::isa required for this test');
use Carp ();
use Carp::Heavy ();

use Devel::Confess qw(nowarnings);

{
  package Thing1;
  sub isa { UNIVERSAL::isa(@_) }
  sub can { UNIVERSAL::can(@_) }
}

my @warnings;
my $o = bless {}, 'Thing1';
local $SIG{__WARN__} = sub { push @warnings, $_[0] };
eval {
  die $o;
};
eval {
  die $o;
};

is join('', @warnings), '',
  "no warnings produced from error class with overridden can";
