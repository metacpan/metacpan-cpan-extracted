BEGIN { our @warnings; $SIG{__WARN__} = sub { push(@warnings, $_[0]); } }

use strict;
use warnings;

sub foo (&) {
  $_[0]->();
  ();
}

sub bar {
  my ($name, $val) = @_;
  no strict 'refs';
  *{$name} = sub (&) { $_[0]->($val); };
}

use Devel::BeginLift 'foo';

foo {
  bar "boom1" => "BOOM 1";
  bar "boom2" => "BOOM 2";
};

boom1 { warn "1: $_[0]\n"; };

boom2 { warn "2: $_[0]\n"; };

END {
  use Test::More 'no_plan';
  our @warnings;
  is(shift(@warnings), "1: BOOM 1\n", 'boom1');
  is(shift(@warnings), "2: BOOM 2\n", 'boom2');
  ok(!@warnings, 'No more warnings');
}
