use strict;
use warnings FATAL => 'all';
use English '-no_match_vars';

use Test::More tests => 1 + 1;
use Test::NoWarnings;
use Test::Warn;

use Encoding::HandleUtf8 qw( fix_encoding );

############################################################################

subtest 'GH-4 - unsupported reference warning ignore list' => sub {
  plan tests => 2;

  local @Encoding::HandleUtf8::IGNORE_LIST = qw( Encoding::HandleUtf8::t::IgnoreMe );

  sub Encoding::HandleUtf8::t::IgnoreMe::new {
    return bless {}, shift;
  }

  sub Encoding::HandleUtf8::t::IgnoreMeNot::new {
    return bless {}, shift;
  }

  warning_is(
    sub {
      eval {
        local $SIG{__WARN__} = sub { die @_; return 0; };
        my $x = Encoding::HandleUtf8::t::IgnoreMe->new;
        fix_encoding input => $x;
        1;
      } or warn $EVAL_ERROR;
    },
    undef,
    q{IgnoreMe gets ignored},
  );

  warning_is(
    sub {
      eval {
        local $SIG{__WARN__} = sub { die @_; return 0; };
        my $x = Encoding::HandleUtf8::t::IgnoreMeNot->new;
        fix_encoding input => $x;
        1;
      } or warn $EVAL_ERROR;
    },
    q{unsupported reference 'Encoding::HandleUtf8::t::IgnoreMeNot'},
    q{IgnoreMeNot doesn't gets ignored},
  );

};

############################################################################
1;
